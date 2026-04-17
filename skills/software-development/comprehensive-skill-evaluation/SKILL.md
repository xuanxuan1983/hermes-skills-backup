---
name: comprehensive-skill-evaluation
description: "Systematic evaluation of AI agent skills using Darwin's 8-dimension rubric with independent subagent assessment. Provides objective quality scoring, identifies improvement areas, and generates detailed evaluation reports. Use when user wants to 'evaluate skill quality', 'assess skill', 'skill review', 'skill评估', 'check skill quality', or 'analyze skill effectiveness'."
---

# Comprehensive Skill Evaluation

Systematic evaluation of AI agent skills using Darwin's proven 8-dimension rubric, with independent subagent assessment to ensure objectivity.

## When to Use

- User requests skill quality assessment or review
- Before deploying skills in production environments
- When comparing multiple skills for the same task
- As part of skill optimization workflow
- For skill portfolio quality management

## Evaluation Framework

Uses Darwin.skill's scientifically-designed 8-dimension rubric:

### Structure Dimensions (60 points)
1. **Frontmatter Quality** (8pts) - Metadata completeness and clarity
2. **Workflow Clarity** (15pts) - Step-by-step process definition
3. **Edge Case Coverage** (10pts) - Error handling and fallbacks
4. **Checkpoint Design** (7pts) - User confirmation points
5. **Instruction Specificity** (15pts) - Concrete, executable commands
6. **Resource Integration** (5pts) - File references and dependencies

### Effectiveness Dimensions (40 points)
7. **Overall Architecture** (15pts) - Structural coherence and design
8. **Practical Performance** (25pts) - Real-world execution quality

## Complete Evaluation Process

### Phase 1: Test Prompt Design

**Critical Step**: Design 2-3 test scenarios before evaluation

```
1. Analyze the skill's stated purpose and capabilities
2. Create test prompts covering:
   - Most typical use case (happy path)
   - Moderately complex scenario
   - Error/edge case scenario
3. Save test prompts with expected outcomes
4. Get user confirmation before proceeding
```

**Template for test-prompts.json:**
```json
[
  {
    "id": 1,
    "prompt": "Typical user request",
    "expected": "Expected behavior/output"
  },
  {
    "id": 2,
    "prompt": "Complex scenario",
    "expected": "Expected handling approach"
  }
]
```

### Phase 2: Independent Structural Assessment

**Use delegate_task for objectivity:**

```
Spawn independent subagent for structural evaluation:
- Task: "Evaluate skill structure using Darwin's 7 structural dimensions"
- Context: Provide skill path and evaluation criteria
- Goal: Objective scoring 1-10 for each dimension with reasoning
```

**Key Analysis Points:**
- Frontmatter completeness (name, description, triggers)
- Process clarity and executability
- Error handling comprehensiveness
- User interaction design
- Command specificity and examples
- File reference accuracy

### Phase 3: Effectiveness Assessment

**Use delegate_task for practical testing:**

```
Spawn independent subagent for effectiveness evaluation:
- Task: "Assess practical performance using test prompts"
- Method: Dry-run validation or actual execution
- Compare: With-skill vs without-skill baseline
```

**Evaluation Criteria:**
- Does output match user intent?
- Quality improvement vs baseline?
- Any negative skill-induced effects?
- Practical usability issues?

### Phase 4: Comprehensive Report Generation

**Calculate weighted scores:**
```
Total Score = Σ(dimension_score × weight) / 10
Structure Score = Sum of dimensions 1-6 (60 points max)
Effectiveness Score = Sum of dimensions 7-8 (40 points max)
```

**Generate detailed report including:**
- Dimension-by-dimension analysis
- Weighted total score
- Identified strengths and weaknesses
- Specific improvement recommendations
- Priority-ranked issues (P0, P1, P2)
- Expected improvement impact

## Report Template

```
# 🎯 Skill Evaluation Report - [SKILL_NAME]

## 📊 Overall Score: X.X/100

┌──────────────────────────┬───────┬──────────────┬──────────────┐
│ Skill                    │ Score │ 结构短板      │ 效果短板      │
├──────────────────────────┼───────┼──────────────┼──────────────┤
│ [skill-name]             │ XX.X  │ [weakness]    │ [weakness]    │
└──────────────────────────┴───────┴──────────────┴──────────────┘

## 📈 Detailed Scoring
[8-dimension breakdown table]

## 🌟 Key Strengths
- [Major advantages identified]

## ⚠️ Critical Issues
- [P0 problems requiring immediate fix]

## 📝 Improvement Roadmap
- P0: [Critical fixes]
- P1: [Important enhancements]
- P2: [Future optimizations]

## 🎯 Potential Impact
[Expected score improvement after fixes]
```

## Best Practices

### Objectivity Measures
- Always use independent subagents for evaluation
- Separate structural analysis from effectiveness testing
- Document evaluation mode (full_test vs dry_run)
- Record all scoring rationale

### Quality Assurance
- Verify all file references and paths
- Test commands in documented environment
- Validate examples and code samples
- Check for hardcoded values that limit reusability

### Report Standards
- Use quantitative scoring with qualitative explanation
- Prioritize issues by impact and effort
- Provide specific, actionable recommendations
- Include expected improvement estimates

## Common Evaluation Patterns

### High-Quality Skills (80+ points)
- Complete frontmatter with rich triggers
- Clear phase-based workflows
- Comprehensive error handling
- Practical, tested commands
- Good resource organization

### Medium-Quality Skills (60-79 points)  
- Basic functionality present but gaps exist
- Some workflow clarity issues
- Limited error handling
- Commands need more specificity
- Resource references may be incomplete

### Low-Quality Skills (<60 points)
- Poor or missing frontmatter
- Unclear or missing workflows
- Minimal error handling
- Vague or untested commands
- Broken or missing resource references

## Integration with Darwin Optimization

This evaluation creates the baseline for Darwin's hill-climbing optimization:
- results.tsv logging format
- Independent scoring methodology  
- Structured improvement identification
- Quantitative progress tracking

## Advanced Techniques

### Comparative Evaluation
When evaluating multiple skills for same function:
- Use identical test prompts
- Score relative effectiveness
- Identify complementary strengths
- Recommend skill portfolio strategy

### Evolution Tracking
For skills under development:
- Baseline scoring before changes
- Track dimension-level improvements
- Monitor regression risks
- Document optimization history

---

*Framework based on Darwin.skill methodology and proven evaluation practices*