#!/bin/bash
# env-quick.sh — Claude Code 快速环境信息收集
# 输出结构化文本，供 Claude 直接格式化展示
# 兼容 Linux / macOS / Windows Git Bash

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"

echo "=== VERSIONS ==="
echo "claude_version: $(claude --version 2>/dev/null || echo 'N/A')"
echo "node_version: $(node --version 2>/dev/null || echo 'N/A')"
echo "npm_version: $(npm --version 2>/dev/null || echo 'N/A')"
echo "claude_path: $(which claude 2>/dev/null || where claude 2>/dev/null || echo 'N/A')"
echo "os: $(uname -s 2>/dev/null || echo 'N/A')"
echo "shell: ${SHELL:-N/A}"
echo "home: ${HOME:-N/A}"

echo ""
echo "=== GLOBAL_PACKAGES ==="
npm list -g --depth=0 2>/dev/null || echo "N/A"

echo ""
echo "=== SETTINGS_MODEL ==="
if [ -f "${CLAUDE_DIR}/settings.json" ]; then
    python -c "
import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    d = json.load(f)
env = d.get('env', {})
print('model:', d.get('model', 'N/A'))
print('anthropic_model:', env.get('ANTHROPIC_MODEL', 'N/A'))
print('base_url:', env.get('ANTHROPIC_BASE_URL', 'N/A'))
print('sonnet:', env.get('ANTHROPIC_DEFAULT_SONNET_MODEL', 'N/A'))
print('opus:', env.get('ANTHROPIC_DEFAULT_OPUS_MODEL', 'N/A'))
print('haiku:', env.get('ANTHROPIC_DEFAULT_HAIKU_MODEL', 'N/A'))
plugins = d.get('enabledPlugins', {})
print('enabled_plugins:', ', '.join(f'{k}={v}' for k, v in plugins.items()) if plugins else 'N/A')
" "${CLAUDE_DIR}/settings.json" 2>/dev/null || echo "model: N/A"
else
    echo "model: N/A (settings.json not found)"
fi

echo ""
echo "=== SETTINGS_LOCAL_PERMISSIONS ==="
if [ -f "${CLAUDE_DIR}/settings.local.json" ]; then
    python -c "
import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    d = json.load(f)
perms = d.get('permissions', {}).get('allow', [])
mcp_tools = [p for p in perms if p.startswith('mcp__')]
print('mcp_permissions:', ', '.join(mcp_tools) if mcp_tools else 'N/A')
other_count = len(perms) - len(mcp_tools)
print('other_permissions_count:', other_count)
" "${CLAUDE_DIR}/settings.local.json" 2>/dev/null || echo "mcp_permissions: N/A"
else
    echo "mcp_permissions: N/A (settings.local.json not found)"
fi

echo ""
echo "=== PLUGINS ==="
if [ -f "${CLAUDE_DIR}/plugins/installed_plugins.json" ]; then
    python -c "
import json, sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    d = json.load(f)
plugins = d.get('plugins', {})
for name, entries in plugins.items():
    e = entries[0] if entries else {}
    print(f'{name}|{e.get(\"version\", \"N/A\")}|{e.get(\"scope\", \"N/A\")}|{e.get(\"installPath\", \"N/A\")}')
" "${CLAUDE_DIR}/plugins/installed_plugins.json" 2>/dev/null || echo "N/A"
else
    echo "N/A (installed_plugins.json not found)"
fi

echo ""
echo "=== SKILLS ==="
if [ -d "${CLAUDE_DIR}/skills" ]; then
    for item in "${CLAUDE_DIR}/skills"/*; do
        [ -e "$item" ] || continue
        name=$(basename "$item")
        if [ -L "$item" ]; then
            target=$(readlink "$item" 2>/dev/null || echo "N/A")
            skill_file="$item/SKILL.md"
        else
            target="dir"
            skill_file="$item/SKILL.md"
        fi
        if [ -f "$skill_file" ]; then
            desc=$(sed -n 's/^description: *//p' "$skill_file" | head -1 | sed 's/^"//;s/"$//')
            echo "${name}|${target}|${desc}"
        else
            echo "${name}|${target}|(SKILL.md not found)"
        fi
    done
else
    echo "N/A (skills directory not found)"
fi

echo ""
echo "=== PLUGIN_SKILLS ==="
if [ -d "${CLAUDE_DIR}/plugins/cache" ]; then
    find "${CLAUDE_DIR}/plugins/cache" -path "*/skills/*/SKILL.md" -exec sh -c '
        dir=$(dirname "$1")
        skill=$(basename "$dir")
        plugin=$(echo "$1" | sed "s|.*/cache/||" | cut -d"/" -f1-2)
        desc=$(sed -n "s/^description: *//p" "$1" | head -1 | sed "s/^\"//;s/\"$//")
        echo "${plugin}|${skill}|${desc}"
    ' _ {} \; 2>/dev/null | sort -u
else
    echo "N/A"
fi

echo ""
echo "=== RULES ==="
if [ -f "${CLAUDE_DIR}/CLAUDE.md" ]; then
    python -c "
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    content = f.read()
lines = content.strip().split('\n')
# 提取规则优先级
priority = []
in_priority = False
for line in lines:
    if '规则优先级' in line:
        in_priority = True
        continue
    if in_priority:
        if line.strip().startswith(('#', '**', '-')):
            break
        if line.strip():
            priority.append(line.strip())
# 提取执行规范条目
rules = []
for line in lines:
    if line.strip().startswith('## 规则'):
        rules.append(line.strip())
print('priority:', ' > '.join(priority) if priority else 'N/A')
print('execution_rules:', '; '.join(rules) if rules else 'N/A')
" "${CLAUDE_DIR}/CLAUDE.md" 2>/dev/null || echo "N/A"
else
    echo "N/A (CLAUDE.md not found)"
fi

echo ""
echo "=== END ==="
