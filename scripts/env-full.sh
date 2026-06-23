#!/bin/bash
# env-full.sh — Claude Code 完整环境验证
# 输出结构化文本，供 Claude 直接格式化展示
# 兼容 Linux / macOS / Windows Git Bash

set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# 先执行快速信息收集
bash "${SCRIPT_DIR}/env-quick.sh" 2>/dev/null

echo ""
echo "=== NETWORK_CHECK ==="
http_code=$(curl -s --connect-timeout 5 -o /dev/null -w "%{http_code}" https://api.github.com 2>/dev/null || echo "FAIL")
if [ "$http_code" = "000" ] || [ "$http_code" = "FAIL" ]; then
    echo "status: UNREACHABLE"
    echo "提示: 无法连接外网（github.com 等）"
    echo "提示: 如使用本地代理，请确保代理已启动并设置环境变量："
    echo "提示:   export HTTPS_PROXY=http://127.0.0.1:<端口>"
    echo "提示:   export HTTP_PROXY=http://127.0.0.1:<端口>"
    echo "skip_mcp_test: true"
    echo "skip_outdated_check: true"
else
    echo "status: OK (HTTP ${http_code})"
    echo "skip_mcp_test: false"
    echo "skip_outdated_check: false"
fi

echo ""
echo "=== PLUGIN_INTEGRITY ==="
if [ -f "${CLAUDE_DIR}/plugins/installed_plugins.json" ]; then
    python -c "
import json, sys, os
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    d = json.load(f)
plugins = d.get('plugins', {})
for name, entries in plugins.items():
    e = entries[0] if entries else {}
    path = e.get('installPath', '')
    issues = []
    if not path:
        issues.append('no install path')
    elif not os.path.exists(path):
        issues.append('install path missing')
    else:
        plugin_json = os.path.join(path, '.claude-plugin', 'plugin.json')
        if not os.path.exists(plugin_json):
            issues.append('plugin.json missing')
        skills_dir = os.path.join(path, 'skills')
        if os.path.exists(skills_dir):
            for skill_name in os.listdir(skills_dir):
                skill_md = os.path.join(skills_dir, skill_name, 'SKILL.md')
                if not os.path.exists(skill_md):
                    issues.append(f'skill {skill_name}/SKILL.md missing')
        # 检查 mcp.json 是否存在
        mcp_json = os.path.join(path, 'mcp.json')
        has_mcp = os.path.exists(mcp_json)
        if has_mcp:
            issues.append('has mcp config')
    status = 'OK' if not issues or issues == ['has mcp config'] else ', '.join(issues)
    mcp_flag = 'YES' if 'has mcp config' in issues else 'NO'
    print(f'{name}|{status}|mcp={mcp_flag}')
" "${CLAUDE_DIR}/plugins/installed_plugins.json" 2>/dev/null || echo "N/A"
else
    echo "N/A"
fi

echo ""
echo "=== SKILL_INTEGRITY ==="
if [ -d "${CLAUDE_DIR}/skills" ]; then
    for item in "${CLAUDE_DIR}/skills"/*; do
        [ -e "$item" ] || continue
        name=$(basename "$item")
        issues=""
        if [ -L "$item" ]; then
            if [ ! -e "$item" ]; then
                issues="broken symlink"
            elif [ ! -f "$item/SKILL.md" ]; then
                issues="SKILL.md missing"
            fi
        else
            if [ ! -f "$item/SKILL.md" ]; then
                issues="SKILL.md missing"
            fi
        fi
        echo "${name}|${issues:-OK}"
    done
else
    echo "N/A"
fi

echo ""
echo "=== NPM_OUTDATED ==="
# 先检查网络状态
net_status=$(curl -s --connect-timeout 3 -o /dev/null -w "%{http_code}" https://registry.npmjs.org 2>/dev/null || echo "FAIL")
if [ "$net_status" = "000" ] || [ "$net_status" = "FAIL" ]; then
    echo "SKIPPED (network unreachable)"
else
    outdated=$(npm outdated -g 2>/dev/null || true)
    if [ -z "$outdated" ]; then
        echo "ALL_UP_TO_DATE"
    else
        echo "$outdated"
    fi
fi

echo ""
echo "=== MCP_SERVERS ==="
# 列出配置中推断的 MCP 服务器（从权限规则提取）
if [ -f "${CLAUDE_DIR}/settings.local.json" ]; then
    python -c "
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    d = json.load(f)
perms = d.get('permissions', {}).get('allow', [])
servers = set()
for p in perms:
    if p.startswith('mcp__'):
        parts = p.split('__')
        if len(parts) >= 2:
            servers.add(parts[1])
for s in sorted(servers):
    print(s)
" "${CLAUDE_DIR}/settings.local.json" 2>/dev/null || echo "N/A"
else
    echo "N/A"
fi

echo ""
echo "=== RULES_FULL ==="
if [ -f "${CLAUDE_DIR}/CLAUDE.md" ]; then
    cat "${CLAUDE_DIR}/CLAUDE.md"
else
    echo "N/A (CLAUDE.md not found)"
fi

echo ""
echo "=== END ==="
