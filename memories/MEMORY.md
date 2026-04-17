Hermes 消息平台集成: 已创建 hermes-messaging-integration skill。支持飞书 (Feishu)、企业微信 (WeCom) 原生接入，以及通过 itchat 实现的个人微信机器人方案。包含自动化配置脚本 setup_feishu.py 和个人微信集成脚本 wechat_personal_bot.py。用户偏好通过主流即时通讯工具管理 AI 任务。
§
Project structure: multi_platform_publisher.py (core), wechat_publisher.py (WeChat API), api_server.py (Flask API on port 8080), publisher_config.json (credentials). WeChat requires AppID/AppSecret and handles draft/publish flow. Weibo uses OAuth2. System uses JSON-based local storage in content/ directory. Use 'python3' for execution.
§
User is developing a multi-platform automated publishing system for the medical beauty industry (WeChat, Weibo, Zhihu, etc.). Environment: macOS, Python 3.9/3.10. Prefers 'python3' command. Project includes a Flask API server (api_server.py) and a management UI (web_interface.html/demo.html). Current focus: 'GEO visibility reports' for medical beauty. Data source: '医美行业GEO可见度报告_专业版.pdf'. System uses JSON-based local storage in content/ directory. Flask API runs on port 8080. Dependencies: pymupdf, pymupdf4llm, flask, requests, schedule.
§
User is developing a multi-platform automated publishing system for the medical beauty industry. Current focus: 'GEO visibility reports' (based on '医美行业GEO可见度报告_专业版.pdf'). System includes a specialized publisher (medical_beauty_publisher.py) and a dedicated dashboard (medical_beauty_dashboard.html). Preferred environment: macOS, Python 3.9 (python3). Key platforms: WeChat, Weibo, Zhihu, Xiaohongshu, Douyin.
§
GEOFlow 智能系统集成: 已建立与 GEOFlow (PHP+PostgreSQL) 的深度集成。支持通过 API (port 18080) 进行认证、任务监控、内容统计及自动化审核。已创建 geoflow_cli.py 和 hermes_geoflow_integration.py，实现了从关键词分析到内容策略生成的完整链路。用户当前正通过该系统处理医美行业 (Medical Beauty) 的 GEO 可见度报告。登录凭据已验证 (admin/admin888)，支持自动化创建 SEO 优化任务。
§
海珠学院相关技能文件存储于/Users/xuan/Desktop/学院工具包/06-AI技能包，包括：AI工具使用手册.md、皮肤水光增长引擎·课程体系设计.md、课件工具引用指南（讲师版）.md、皮肤水光增长引擎·核心卡片.md、AI诊断Skill-快速参考.md、AI工具演示方案（Module 6用）.md、工具与模块整合说明.md。
§
Medcxy 视频 (/Users/xuan/Desktop/medcxy-video/): 复刻 Nano Banana Pro 风格，GSAP + HyperFrames 技术栈。IP: douzai→v5_happy, douding→v3_thumbsup, douya→v4_flag。美学标准极高——不接受廉价设计，Scene 3 曾因不够精致被重做。
§
§
openclaw 卸载未完成: 用户要求卸载 /Users/xuan/.npm-global/bin/openclaw，切换话题后未继续。