# 🔍 env-report — Claude Code 环境自检 Skill

> 一键检测 Claude Code 运行环境的全景信息，包括版本、模型、MCP 服务器、插件、技能、全局工具和规则体系。

## ✨ 功能

- 📦 **版本检测**：Claude Code CLI、Node.js、npm 版本
- 🤖 **模型配置**：当前模型、API 代理地址、模型映射关系
- 🔌 **MCP 服务器**：自动发现已连接的 MCP 服务器，完整模式下执行连通性测试
- 🧩 **插件扫描**：列出所有插件的版本、来源、启用状态，完整模式下检查目录完整性
- 🛠️ **技能扫描**：扫描独立技能和插件附带的技能
- 📡 **全局工具**：列出 npm 全局安装的相关工具，完整模式下检查可更新项
- 📜 **规则体系**：提取 CLAUDE.md 中的规则摘要
- 🌐 **网络自适应**：检测外网连通性，网络不通时自动跳过需要网络的验证步骤

## 📥 安装

### 方式一：手动安装

```bash
# Linux / macOS
cp -r skills/env-report ~/.claude/skills/env-report

# Windows (PowerShell)
Copy-Item -Recurse skills\env-report $env:USERPROFILE\.claude\skills\env-report
```

### 方式二：克隆仓库后链接

```bash
git clone https://github.com/Cherish-RSran/claude-env-report-skills.git /tmp/env-report
ln -s /tmp/env-report/skills/env-report ~/.claude/skills/env-report
```

## 🚀 使用

在 Claude Code 会话中输入：

| 命令 | 说明 |
|------|------|
| `/env-report` | ⚡ 快速摘要：版本、模型、插件、技能、工具 |
| `/env-report --full` | 🔬 完整验证：快速摘要 + 网络检测 + MCP 连通性 + 插件完整性 + 可更新检查 |
| `/env-report --output` | 📄 快速摘要 + 生成 `Claude-Code-环境报告.md` 到当前目录 |
| `/env-report --full --output` | 📋 完整验证 + 生成报告文件 |

## 🏗️ 架构设计

```
skills/env-report/
├── SKILL.md              # 技能定义（Claude 读取的指令）
├── README.md             # 本文件（GitHub 展示用，不被 skill 读取）
└── scripts/
    ├── env-quick.sh      # 快速信息收集脚本（纯本地，零网络）
    └── env-full.sh       # 完整验证脚本（含网络检测、完整性检查）
```

**执行流程：**

1. 📤 Claude 调用脚本 → 脚本输出结构化文本
2. 📊 Claude 解析文本 → 格式化为表格展示
3. 🔗 `--full` 模式额外：Claude 调用 MCP 工具测试连通性

脚本负责所有本地信息收集（版本、配置、插件、技能、完整性），Claude 负责格式化展示和 MCP 连通性测试（MCP 工具只能由 Claude 调用）。

## ⚖️ 快速模式 vs 完整模式

| 能力 | ⚡ 快速模式 | 🔬 完整模式 (`--full`) |
|------|----------|---------------------|
| 版本/模型/配置信息 | ✅ | ✅ |
| MCP 服务器发现 | ✅ | ✅ |
| MCP 连通性测试 | ❌ | ✅ |
| 插件完整性检查 | ❌ | ✅ |
| 技能完整性检查 | ❌ | ✅ |
| npm 可更新检查 | ❌ | ✅ |
| 网络自适应跳过 | — | ✅ |

## 🌐 网络自适应

完整模式在执行验证前会先检测外网连通性（`curl api.github.com`）：

- ✅ **网络正常**：执行所有验证步骤
- ❌ **网络不可达**：跳过 MCP 连通性测试和 npm 可更新检查，在输出中注明原因，并提示配置代理的方法

```
⚠️ 网络不可达：无法连接外网（github.com 等）
提示：如使用本地代理，请确保代理已启动并设置环境变量：
  export HTTPS_PROXY=http://127.0.0.1:<端口>
  export HTTP_PROXY=http://127.0.0.1:<端口>
```

## 📋 输出示例

### ⚡ 快速模式终端输出

```
## Claude Code 环境摘要

| 项目 | 值 |
|------|-----|
| Claude Code 版本 | 2.1.186 |
| Node.js / npm | v24.14.1 / 11.11.0 |
| 当前模型 | claude-sonnet-4-6 或其他模型 |
| API 代理 | 直连 或 自定义代理地址 |
| 操作系统 | MINGW64_NT-10.0-19045 |

### MCP 服务器 (5个)

| 服务器 | 类型 | 资源数 |
|--------|------|--------|
| github | HTTP | 4 |
| context7 | stdio | 0 |
| Firecrawl | stdio | 0 |
| chrome-devtools-mcp | 浏览器 | 0 |
| web-to-mcp | 服务 | 0 |

### 插件 (4个)
### 技能 (19个)
### 全局工具 (5个)
### 规则体系
```

### 🔬 完整模式额外输出

```
### MCP 服务器 (5个)

| 服务器 | 类型 | 连通性 | 资源数 |
|--------|------|--------|--------|
| github | HTTP | ✅ | 4 |
| context7 | stdio | ✅ | 0 |
| Firecrawl | stdio | ✅ | 0 |
| chrome-devtools-mcp | 浏览器 | ✅ | 0 |
| web-to-mcp | 服务 | 已连接（未测试） | 0 |

### 📦 可更新项

| 工具 | 当前版本 | 最新版本 |
|------|----------|----------|
| firecrawl-mcp | 3.17.0 | 3.21.3 |
```

## 💡 设计原则

- ⚙️ **零配置**：安装即用，无需额外设置
- 🔍 **动态发现**：自动检测当前环境，不硬编码任何服务器或插件名称
- 🏎️ **脚本驱动**：信息收集由 shell 脚本完成，减少 Claude token 消耗
- 📉 **低开销**：快速模式零网络调用，完整模式使用最低开销的工具测试连通性
- 🌐 **网络自适应**：外网不通时自动降级，不卡死
- 🚫 **不自动触发**：仅通过 `/env-report` 系列命令手动触发
- 🌍 **通用兼容**：适用于任何人的 Claude Code 环境

## 📋 系统要求

- ✅ Claude Code CLI 已安装并可正常运行
- ✅ Node.js 和 npm（通常随 Claude Code 一起安装）
- ✅ Python 3（用于解析 JSON 配置文件）
- ✅ 完整模式需要外网访问（或已配置本地代理）

## 👤 作者

**Jace Peng** — [GitHub](https://github.com/Cherish-RSran) | [CSDN 博客](https://rsran.blog.csdn.net)

## 📄 许可

[MIT](LICENSE)
