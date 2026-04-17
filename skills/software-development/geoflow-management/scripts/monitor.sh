#!/bin/bash
# GEOFlow 系统监控脚本
# 用于检查系统健康状态和性能指标

set -e

# 配置
GEOFLOW_URL=${GEOFLOW_URL:-"http://localhost"}
API_TOKEN=${GEOFLOW_API_TOKEN:-""}
ALERT_WEBHOOK=${GEOFLOW_ALERT_WEBHOOK:-""}
LOG_FILE="/tmp/geoflow_monitor.log"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}✗${NC} $1" | tee -a "$LOG_FILE"
}

# API 请求函数
api_request() {
    local endpoint="$1"
    local method="${2:-GET}"
    
    if [[ -z "$API_TOKEN" ]]; then
        log_error "API Token 未设置"
        return 1
    fi
    
    curl -s -X "$method" \
        -H "Authorization: Bearer $API_TOKEN" \
        -H "Content-Type: application/json" \
        -w "HTTPSTATUS:%{http_code}" \
        "$GEOFLOW_URL/api/v1/$endpoint" 2>/dev/null
}

# 解析 API 响应
parse_response() {
    local response="$1"
    local http_code=$(echo "$response" | sed -n 's/.*HTTPSTATUS:\([0-9]*\)$/\1/p')
    local body=$(echo "$response" | sed 's/HTTPSTATUS:[0-9]*$//')
    
    if [[ "$http_code" -eq 200 ]]; then
        echo "$body"
        return 0
    else
        log_error "API 请求失败: HTTP $http_code"
        return 1
    fi
}

# 发送告警
send_alert() {
    local message="$1"
    local severity="${2:-warning}"
    
    if [[ -n "$ALERT_WEBHOOK" ]]; then
        local payload=$(cat <<EOF
{
    "text": "GEOFlow 系统告警",
    "attachments": [{
        "color": "$([[ $severity == "error" ]] && echo "danger" || echo "warning")",
        "fields": [{
            "title": "告警信息",
            "value": "$message",
            "short": false
        }],
        "ts": $(date +%s)
    }]
}
EOF
)
        
        curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "$payload" \
            "$ALERT_WEBHOOK" > /dev/null
    fi
}

# 检查 Docker 容器状态
check_docker_containers() {
    log "检查 Docker 容器状态..."
    
    local containers=("geoflow_app" "geoflow_db" "geoflow_redis" "geoflow_nginx")
    local failed_containers=()
    
    for container in "${containers[@]}"; do
        if docker ps --format "table {{.Names}}" | grep -q "^$container$"; then
            local status=$(docker ps --format "table {{.Names}}\t{{.Status}}" | grep "^$container" | cut -f2)
            log_success "容器 $container: $status"
        else
            log_error "容器 $container: 未运行"
            failed_containers+=("$container")
        fi
    done
    
    if [[ ${#failed_containers[@]} -gt 0 ]]; then
        send_alert "Docker 容器异常: ${failed_containers[*]}" "error"
        return 1
    fi
    
    return 0
}

# 检查系统 API 状态
check_api_health() {
    log "检查 API 健康状态..."
    
    local response=$(api_request "system/health")
    if parse_response "$response" > /dev/null; then
        log_success "API 服务正常"
        return 0
    else
        log_error "API 服务异常"
        send_alert "GEOFlow API 服务不可用" "error"
        return 1
    fi
}

# 检查数据库连接
check_database() {
    log "检查数据库连接..."
    
    if docker exec geoflow_db pg_isready -q; then
        log_success "数据库连接正常"
        
        # 检查数据库大小
        local db_size=$(docker exec geoflow_db psql -U geoflow -d geoflow -t -c "SELECT pg_size_pretty(pg_database_size('geoflow'));" 2>/dev/null | xargs)
        log "数据库大小: $db_size"
        
        return 0
    else
        log_error "数据库连接失败"
        send_alert "GEOFlow 数据库连接失败" "error"
        return 1
    fi
}

# 检查磁盘空间
check_disk_space() {
    log "检查磁盘空间..."
    
    local usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    
    if [[ $usage -lt 80 ]]; then
        log_success "磁盘使用率: ${usage}%"
    elif [[ $usage -lt 90 ]]; then
        log_warning "磁盘使用率较高: ${usage}%"
        send_alert "磁盘使用率警告: ${usage}%" "warning"
    else
        log_error "磁盘空间不足: ${usage}%"
        send_alert "磁盘空间严重不足: ${usage}%" "error"
        return 1
    fi
    
    return 0
}

# 检查任务队列状态
check_task_queue() {
    log "检查任务队列状态..."
    
    local response=$(api_request "tasks?status=pending,running")
    if local body=$(parse_response "$response"); then
        local pending_count=$(echo "$body" | jq -r '.data | map(select(.status == "pending")) | length' 2>/dev/null || echo "0")
        local running_count=$(echo "$body" | jq -r '.data | map(select(.status == "running")) | length' 2>/dev/null || echo "0")
        
        log "待处理任务: $pending_count"
        log "执行中任务: $running_count"
        
        # 检查是否有积压的任务
        if [[ $pending_count -gt 100 ]]; then
            log_warning "任务积压严重: $pending_count 个待处理任务"
            send_alert "任务队列积压: $pending_count 个待处理任务" "warning"
        else
            log_success "任务队列正常"
        fi
        
        return 0
    else
        log_error "无法获取任务队列状态"
        return 1
    fi
}

# 检查系统资源使用情况
check_system_resources() {
    log "检查系统资源使用情况..."
    
    # CPU 使用率
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
    log "CPU 使用率: ${cpu_usage}%"
    
    # 内存使用率
    local mem_usage=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}')
    log "内存使用率: ${mem_usage}%"
    
    # 检查是否超过阈值
    if (( $(echo "$mem_usage > 90" | bc -l) )); then
        log_warning "内存使用率过高: ${mem_usage}%"
        send_alert "系统内存使用率过高: ${mem_usage}%" "warning"
    fi
    
    return 0
}

# 检查日志文件大小
check_log_files() {
    log "检查日志文件..."
    
    local log_dirs=("./logs" "/var/log/nginx" "/var/log")
    
    for log_dir in "${log_dirs[@]}"; do
        if [[ -d "$log_dir" ]]; then
            local large_logs=$(find "$log_dir" -name "*.log" -size +100M 2>/dev/null)
            
            if [[ -n "$large_logs" ]]; then
                log_warning "发现大型日志文件:"
                echo "$large_logs" | while read -r logfile; do
                    local size=$(du -h "$logfile" | cut -f1)
                    log "  $logfile: $size"
                done
            fi
        fi
    done
    
    return 0
}

# 清理临时文件
cleanup_temp_files() {
    log "清理临时文件..."
    
    # 清理超过7天的日志文件
    find ./logs -name "*.log" -mtime +7 -delete 2>/dev/null || true
    
    # 清理临时缓存
    if docker exec geoflow_app test -d /tmp/geoflow_cache; then
        docker exec geoflow_app find /tmp/geoflow_cache -mtime +1 -delete 2>/dev/null || true
    fi
    
    log_success "临时文件清理完成"
    return 0
}

# 生成系统报告
generate_report() {
    log "生成系统监控报告..."
    
    local report_file="/tmp/geoflow_report_$(date +%Y%m%d_%H%M%S).json"
    
    cat > "$report_file" <<EOF
{
    "timestamp": "$(date -Iseconds)",
    "system": {
        "uptime": "$(uptime -p)",
        "load_average": "$(uptime | awk -F'load average:' '{print $2}')",
        "disk_usage": "$(df -h / | awk 'NR==2 {print $5}')",
        "memory_usage": "$(free | grep Mem | awk '{printf("%.1f%%", $3/$2 * 100.0)}')"
    },
    "docker": {
        "running_containers": $(docker ps -q | wc -l),
        "total_containers": $(docker ps -a -q | wc -l)
    },
    "geoflow": {
        "api_status": "$(api_request "system/health" > /dev/null && echo "healthy" || echo "unhealthy")",
        "database_status": "$(docker exec geoflow_db pg_isready -q && echo "connected" || echo "disconnected")"
    }
}
EOF
    
    log "报告已生成: $report_file"
    return 0
}

# 主函数
main() {
    local checks_passed=0
    local total_checks=0
    
    log "========== GEOFlow 系统监控开始 =========="
    
    # 执行各项检查
    local checks=(
        "check_docker_containers"
        "check_api_health" 
        "check_database"
        "check_disk_space"
        "check_task_queue"
        "check_system_resources"
        "check_log_files"
    )
    
    for check in "${checks[@]}"; do
        ((total_checks++))
        if $check; then
            ((checks_passed++))
        fi
        echo
    done
    
    # 清理和报告
    cleanup_temp_files
    generate_report
    
    # 总结
    log "========== 监控完成 =========="
    log "检查项目: $checks_passed/$total_checks 通过"
    
    if [[ $checks_passed -eq $total_checks ]]; then
        log_success "系统运行正常"
        exit 0
    else
        log_error "发现 $((total_checks - checks_passed)) 个问题"
        exit 1
    fi
}

# 处理命令行参数
case "${1:-}" in
    "containers")
        check_docker_containers
        ;;
    "api")
        check_api_health
        ;;
    "database")
        check_database
        ;;
    "disk")
        check_disk_space
        ;;
    "tasks")
        check_task_queue
        ;;
    "resources")
        check_system_resources
        ;;
    "logs")
        check_log_files
        ;;
    "cleanup")
        cleanup_temp_files
        ;;
    "report")
        generate_report
        ;;
    *)
        main
        ;;
esac