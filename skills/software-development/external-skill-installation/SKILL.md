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

## Future Considerations

This manual copying step may be temporary. Future versions of Hermes might:
- Automatically discover skills in `~/.agents/skills/`
- Provide native skill installation commands
- Offer symlink-based integration

Monitor Hermes documentation for updates to this workflow.