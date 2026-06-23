---
name: env-report
description: "Claude Code 环境自检工具。仅通过命令触发，不自动执行。"
user-invocable: true
allowed-tools: Bash, Read, Write, ListMcpResourcesTool, mcp__github__get_me, mcp__context7__resolve-library-id, mcp__Firecrawl__firecrawl_search, mcp__chrome-devtools-mcp__list_pages, Glob, Grep, WebFetch
---

# env-report — Claude Code 环境自检

## 命令格式

| 命令 | 行为 |
|------|------|
| `/env-report` | 快速摘要 |
| `/env-report --full` | 完整验证（含 MCP 连通性测试） |
| `/env-report --output` | 快速摘要 + 输出报告文件 |
| `/env-report --full --output` | 完整验证 + 输出报告文件 |

解析用户输入的参数，确定执行模式：
- `has_full`：是否包含 `--full`
- `has_output`：是否包含 `--output`

---

## 执行流程

脚本位于 `${CLAUDE_SKILL_DIR}/scripts/` 目录下（即 `~/.claude/skills/env-report/scripts/`）。

---

### 第1步：运行信息收集脚本

**快速模式**执行：

```bash
bash ~/.claude/skills/env-report/scripts/env-quick.sh
```

**完整模式**执行：

```bash
bash ~/.claude/skills/env-report/scripts/env-full.sh
```

脚本输出为结构化文本，各段以 `=== 段名 ===` 分隔。解析各段内容，提取信息。

---

### 第2步：MCP 连通性测试（仅 `--full`）

从脚本输出的 `=== NETWORK_CHECK ===` 段判断网络状态。

**网络不可达时（status: UNREACHABLE）：** 跳过此步，后续输出中注明网络问题。

**网络正常时：** 调用 `ListMcpResourcesTool` 获取已连接的 MCP 服务器，然后并行调用以下低开销工具：

| 服务器名称包含 | 测试工具 | 测试参数 |
|----------------|----------|----------|
| `github` | `mcp__github__get_me` | 无参数 |
| `context7` | `mcp__context7__resolve-library-id` | libraryName: "react", query: "test" |
| `Firecrawl` 或 `firecrawl` | `mcp__Firecrawl__firecrawl_search` | query: "test", limit: 1 |
| `chrome-devtools` | `mcp__chrome-devtools-mcp__list_pages` | 无参数 |
| 其他 | 标记为"已连接（未测试）" |

所有调用并行发出。成功标记 ✅，失败标记 ❌，不中断流程。

---

### 第3步：输出结果

根据脚本输出和（如有）MCP 测试结果，按以下格式输出终端摘要：

```
## Claude Code 环境摘要

| 项目 | 值 |
|------|-----|
| Claude Code 版本 | {版本} |
| Node.js / npm | {版本} |
| 当前模型 | {模型名} |
| API 代理 | {地址或"直连"} |
| 操作系统 | {OS 信息} |

### MCP 服务器 ({数量}个)

[快速模式]
| 服务器 | 类型 | 资源数 |
|--------|------|--------|

[完整模式]
| 服务器 | 类型 | 连通性 | 资源数 |
|--------|------|--------|--------|

### 插件 ({数量}个)

[快速模式]
| 插件 | 版本 | 状态 |
|------|------|------|

[完整模式]
| 插件 | 版本 | 状态 | 完整性 |
|------|------|------|--------|

### 技能 ({数量}个)

| 技能 | 来源 | 功能简述 |
|------|------|----------|

### 全局工具 ({数量}个)

| 工具 | 版本 |
|------|------|

[完整模式，如有可更新]
### 可更新项

| 工具 | 当前版本 | 最新版本 |
|------|----------|----------|

### 规则体系

[快速模式]
- {规则摘要}

[完整模式]
输出 `=== RULES_FULL ===` 段的完整内容（即 CLAUDE.md 全文）
```

**完整模式末尾额外提示：**
```
完整验证完成。如需生成报告文件，请使用 /env-report --full --output
```

**`--output` 模式额外操作：**

将终端内容扩展为完整报告文件 `Claude-Code-环境报告.md`，写入当前工作目录，包含：
- 完整的环境信息表格
- 每个 MCP 服务器的详细信息（端点、认证方式、可用工具列表）
- 每个插件的详细信息（安装路径、来源仓库、包含的技能列表）
- 每个技能的完整描述和触发条件
- 内置工具完整清单
- 规则体系完整内容
- 环境架构图（ASCII）

生成后提示：`报告已保存至 {当前目录}/Claude-Code-环境报告.md`

---

## 注意事项

- 所有输出使用简体中文
- 脚本输出中的 `N/A` 表示该项不可用或未找到
- 文件不存在时脚本会跳过，不报错
- 网络不可达时跳过需要外网的步骤，不中断流程
