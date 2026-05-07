---
name: external-skill-installation
description: Install external skills from GitHub or npm into Hermes Agent. Handles the common pattern where skills installed via 'npx skills add' end up in ~/.agents/skills/ but need to be copied to ~/.hermes/skills/ to work with Hermes. Use when user wants to install external skills, mentions "install skill", "add skill from GitHub", or encounters skill not found errors after installation.
---

# External Skill Installation

Install and integrate external skills from GitHub repositories or npm packages into Hermes Agent.

## When to Use

- User requests installing a skill from GitHub
- User mentions "install skill", "add skill", "npx skills add"  
- A skill was installed but isn't recognized by Hermes (not showing in skills_list)
- Error: "Skill 'name' not found" after apparent successful installation

## Installation Process

### Phase 1: Install via Skills CLI

```bash
# Install from GitHub repository
npx skills add username/repository-name

# Install with automatic confirmation
npx skills add username/repository-name --yes
```

**Expected behavior**: Skills CLI installs to `~/.agents/skills/`

### Phase 2: Verify Installation Location

```bash
# Check if skill was installed
ls ~/.agents/skills/ | grep skill-name

# Check if Hermes can see it
skill_view skill-name
```

### Phase 3: Bridge to Hermes (if needed)

If skill_view fails with "Skill not found", the skill needs to be copied:

```bash
# Copy from agents directory to Hermes directory
cp -r ~/.agents/skills/skill-name ~/.hermes/skills/

# Verify successful integration
skill_view skill-name
```

### Phase 4: Verify Functionality

```bash
# Check skill appears in listing
skills_list | grep skill-name

# Test skill loading
skill_view skill-name
```

## Common Issues & Solutions

### Issue: Skill installs but isn't recognized
**Symptoms**: `npx skills add` succeeds, but `skill_view` returns "Skill not found"
**Cause**: Skill installed to `~/.agents/skills/` but Hermes looks in `~/.hermes/skills/`
**Solution**: Copy skill directory manually

### Issue: Permission errors during copy
**Symptoms**: `cp: permission denied`
**Solution**: Check directory permissions, use `sudo` if necessary

### Issue: Skill conflicts
**Symptoms**: Skill with same name already exists
**Solution**: Check existing skill first, consider renaming or updating

## Directory Structure

```
~/.agents/skills/          # Skills CLI installation location
├── skill-name/
│   ├── SKILL.md
│   ├── assets/
│   └── templates/

~/.hermes/skills/          # Hermes Agent skill location  
├── skill-name/           # Copied from ~/.agents/skills/
│   ├── SKILL.md
│   ├── assets/
│   └── templates/
```

## Verification Steps

1. **Installation Success**: Check `~/.agents/skills/skill-name/` exists
2. **Hermes Integration**: Verify `skill_view skill-name` works
3. **Functionality Test**: Try using the skill with appropriate trigger phrases
4. **File Integrity**: Ensure all assets (templates, scripts, etc.) copied correctly

## Troubleshooting

### Skills CLI Issues
- Network connectivity problems during clone
- Authentication issues for private repositories  
- Version conflicts with existing tools

### Integration Issues
- Directory permission problems
- Path resolution issues
- SKILL.md format validation errors

## Best Practices

1. **Always verify after installation** - Don't assume `npx skills add` success means Hermes integration
2. **Check for updates** - Some skills may update their integration requirements
3. **Backup before copying** - Keep original installation intact
4. **Test thoroughly** - Verify all skill features work after integration

## Examples

### Darwin Skill Installation
```bash
# 1. Install via skills CLI
npx skills add alchaincyf/darwin-skill --yes

# 2. Verify installation location  
ls ~/.agents/skills/darwin-skill/

# 3. Copy to Hermes (if needed)
cp -r ~/.agents/skills/darwin-skill ~/.hermes/skills/

# 4. Test integration
skill_view darwin-skill
```

### General External Skill
```bash
# 1. Install any GitHub skill
npx skills add username/skillname

# 2. Check if Hermes recognizes it
skills_list | grep skillname

# 3. Bridge if necessary
if ! skill_view skillname; then
    cp -r ~/.agents/skills/skillname ~/.hermes/skills/
fi
```

## Phase 0: Evaluate Before Installing

Before installing from GitHub, evaluate whether the skill is worth your time. Installing everything creates noise in your skills list and increases coordination overhead for your agent.

### Evaluation Rubric (4 Dimensions, ~5 min assessment)

| Dimension | Weight | What to Check |
|-----------|--------|---------------|
| **Architecture** | 25% | Structured workflow steps? R-I-A1-A2-E-B pattern? Frontmatter complete (name/description/triggers)? |
| **Trigger Design** | 25% | Description mentions exact activation phrases? Clear about what NOT to use it for (boundaries)? |
| **Practical Utility** | 30% | Concrete execution steps vs. vague principles? Completion criteria? Stop conditions? Fallback paths? |
| **Maintenance** | 20% | Active repo (commits within 6 months)? Dependencies clearly stated? Known issues documented? |

### Quick Evaluation Steps

1. **Read SKILL.md via raw GitHub URL** — `curl -sL "https://raw.githubusercontent.com/USER/REPO/main/SKILL.md" | head -80`
2. **Check commit history** — Recent commits = actively maintained
3. **Assess trigger clarity** — Vague triggers ("helps with X") are weak; exact phrases are strong
4. **Check for completion criteria** — Does it say what "done" looks like?
5. **Identify boundaries** — Does it explicitly say what NOT to use it for?

### Recommendation Framework

| Score | Recommendation | Action |
|-------|---------------|--------|
| 8-10/10 | High value, clearly defined | Install immediately if it matches your current project |
| 6-7/10 | Useful but has gaps | Install only if directly relevant to current work; defer otherwise |
| 4-5/10 | Marginal value | Skip unless you're actively developing similar skills |
| <4/10 | Low quality | Skip |

### Red Flags That Outweigh High Scores

- No SKILL.md or SKILL.md is a placeholder/link to external docs
- Only English triggers (if your user works in Chinese)
- Heavy dependencies not mentioned in the skill itself
- No completion criteria — impossible to know when it's "done"

### Example: hv-analysis Evaluation

```
Architecture:      9/10  — R-I-A1-A2-E-B, parallel subagents, PDF output script
Trigger Design:    8/10  — Exact Chinese phrases, clear boundaries (not for simple definitions)
Practical Utility: 7/10  — Concrete steps, QC checklist, but output is report not action
Maintenance:       8/10  — Active commits (5 days ago), dependencies listed
─────────────────────────────────────────────────────────────────────────────
Weighted Total:    8.0/10 → "Install if you need deep research; defer otherwise"
```

## Installation Pattern B: Local Zip Archives (book2skill packages)

Many skill collections are distributed as zip files containing a `skills/` subdirectory with multiple skills in a consistent structure:

```
skill-package.zip
├── INDEX.md              # Skill navigation/index
├── REFERENCE_GRAPH.md    # Skill interdependency graph
├── TEST_PROMPTS.json    # Pressure test prompts
└── [skill-name]/
    └── SKILL.md         # One SKILL.md per skill
```

### Installation Steps

```bash
# 1. Create target directory
mkdir -p ~/.hermes/skills/[package-name]

# 2. Extract zip to target (NOT ~/.agents/skills/)
unzip -o "/path/to/package.zip" -d ~/.hermes/skills/[package-name]/

# 3. Verify structure
ls ~/.hermes/skills/[package-name]/
ls ~/.hermes/skills/[package-name]/skills/   # Should list individual skill dirs
```

### Key Distinction from npx Pattern

| Pattern | Source | Destination | Skill Count |
|---------|--------|-------------|-------------|
| npx/add | GitHub/npm | ~/.agents/skills/ → copy | 1 per repo |
| Zip archive | Local file | ~/.hermes/skills/ directly | Many per archive |

Zip archives install **directly** to `~/.hermes/skills/`. No intermediate `~/.agents/skills/` step needed.

### Verify Integration

```bash
# List all skills to confirm appearance
skills_list | grep [package-name]

# Check individual skill
skill_view [package-name]/[skill-name]
```

### Common Zip Packages

| Package | Skills | Source File |
|---------|--------|-------------|
| xiaomiao | 27 (小而美/极简创业) | 小而美skills.zip |
| systems-thinking | 25 (系统之美) | systems-thinking.zip |
| (user's custom) | Varies | Varies |

## Installation Pattern C: Multi-Repo Skill Authors

Some prolific skill authors distribute their skills across **multiple GitHub repositories**, not just one. When looking for a user's skills, always check their GitHub profile for all repos, not just the main one.

### Discovery Workflow

```
1. Find author's GitHub profile (e.g., github.com/lijigang)
2. Look for repos with "skill" in the name
3. Check each repo independently — each may have different skills
4. Clone each repo to /tmp (if GitHub blocked)
5. Copy each skill dir to ~/.hermes/skills/
```

### Real Example: 李继刚 (lijigang)

| Repo | Skills Found |
|------|-------------|
| `lijigang/ljg-skills` | 17 skills (ljg-card, ljg-paper, ljg-roundtable, etc.) |
| `lijigang/ljg-skill-roundtable` | Standalone roundtable skill |
| `lijigang/ljg-skill-paper` | Standalone paper skill |
| `lijigang/ljg-skill-the-one` | Standalone "the one" skill |

**Total: 20 skills across 4 repos**

### Installation Commands

```bash
# Clone all repos to /tmp (GitHub may be blocked from this machine)
git clone https://github.com/lijigang/ljg-skills.git /tmp/ljg-skills
git clone https://github.com/lijigang/ljg-skill-roundtable.git /tmp/ljg-skill-roundtable
git clone https://github.com/lijigang/ljg-skill-paper.git /tmp/ljg-skill-paper
git clone https://github.com/lijigang/ljg-skill-the-one.git /tmp/ljg-skill-the-one

# Copy each skill individually
for skill_dir in /tmp/ljg-skills/skills/ljg-*; do
    skill_name=$(basename "$skill_dir")
    cp -r "$skill_dir" ~/.hermes/skills/"$skill_name"
done

# Copy standalone skills
cp -r /tmp/ljg-skill-roundtable/skills/ljg-roundtable ~/.hermes/skills/
cp -r /tmp/ljg-skill-paper/skills/ljg-paper ~/.hermes/skills/
cp -r /tmp/ljg-skill-the-one/skills/ljg-the-one ~/.hermes/skills/

# Verify
hermes skills list | grep ljg
```

### Key Insight

When you find one skill from an author, **always check if they have more skills in other repos**. prolific creators often iterate — newer or specialized skills get their own repos.

### /tmp Workaround

GitHub may be blocked from the machine but `git clone` from `/tmp` works (proxy/git config already set). Always clone to `/tmp` first, then copy to `~/.hermes/skills/`.

## Future Considerations

This manual copying step may be temporary. Future versions of Hermes might:
- Automatically discover skills in `~/.agents/skills/`
- Provide native skill installation commands
- Offer symlink-based integration

Monitor Hermes documentation for updates to this workflow.