# Claude Orchestration

**[English](README.md) | [한국어](README.ko.md) | [日本語](README.ja.md) | [中文](README.zh.md) | [Español](README.es.md) | [Deutsch](README.de.md) | [Français](README.fr.md) | [हिन्दी](README.hi.md) | [ไทย](README.th.md) | [Tiếng Việt](README.vi.md)**

多个 Claude CLI 代理通过基于文件的异步通信协作进行游戏开发。

一个 bat 文件完成所有配置。代理自主领取任务、实现功能、审查代码并管理项目看板——全部通过 markdown 文件协调。

## 工作原理

```
orchestrate.bat  (双击运行)
    |
    |-- 依赖检查 (Git, Claude CLI)
    |-- 选择游戏项目文件夹 (现代对话框)
    |-- 自动检测引擎 (Unity / Godot / Unreal)
    |-- 交互式设置:
    |       Git 远程仓库、提交策略、开发方向、
    |       代理模式、审查级别、文档扫描
    |-- 生成项目配置 + 代理提示词
    |-- 在独立终端中启动代理
    v
  4 个代理并行运行，通过 orchestration/ 进行通信
```

## 代理

| 代理 | 角色 | 职责 |
|------|------|------|
| **Supervisor** | 协调者 | 资源创建、代码质量审计、错误修复、任务管理 |
| **Developer** | 构建者 | 实现游戏逻辑、编写测试、提交代码 |
| **Client** | 审查者 | 多角色 QA 审查、质量反馈 |
| **Coordinator** | 管理者 | 看板同步、待办事项补充、规格编写、代理监控 |

## 系统要求

| 程序 | 是否必需 | 安装方式 |
|------|----------|----------|
| Git for Windows | 是 | https://git-scm.com/download/win |
| Node.js 18+ | 是 | https://nodejs.org |
| Claude CLI | 是 | `npm install -g @anthropic-ai/claude-code` |
| Windows Terminal | 推荐 | Windows 10/11 已预装 |

## 快速开始

```bash
# 1. 克隆仓库
git clone git@github.com:darkhtk/orchestration-general_00.git
cd orchestration-general_00

# 2. 双击 orchestrate.bat
#    - 选择你的游戏项目文件夹
#    - 自动检测引擎、目录、现有文档
#    - 询问设置问题（方向、代理模式等）
#    - 启动代理

# 或从命令行运行：
orchestrate.bat "C:\path\to\your\game"
```

## 设置选项

交互式设置会询问：

| 选项 | 可选值 | 默认值 |
|------|--------|--------|
| **现有文档** | 扫描项目文档供代理在首次循环时读取 | 是 |
| **Git** | 初始化仓库、设置远程 URL | 自动检测 |
| **提交/推送策略** | task / review / batch / manual | task |
| **开发方向** | stabilize / feature / polish / content / custom | feature |
| **代理模式** | full (4) / lean (2) / solo (1) | full |
| **审查级别** | strict / standard / minimal | standard |

## 创建的内容

当你在游戏项目上运行 orchestrate.bat 时，会创建以下内容：

```
your-game-project/
  orchestration/
    project.config.md        # 所有设置（代理每次循环都会读取）
    BOARD.md                 # 看板（待办 > 进行中 > 审查中 > 已完成）
    BACKLOG_RESERVE.md       # 供开发者领取的任务池
    agents/                  # 代理角色定义
    prompts/                 # 代理启动提示词
    templates/               # 文档模板（任务、审查、规格等）
    tasks/                   # 任务规格 (TASK-001.md, ...)
    reviews/                 # 审查结果 (REVIEW-001-v1.md, ...)
    decisions/               # Supervisor 决策
    discussions/             # 代理讨论（异步辩论）
      concluded/             # 已结束的讨论
    specs/                   # 功能规格 (SPEC-R-001.md, ...)
    logs/                    # 各代理循环日志
    .run_SUPERVISOR.sh       # 代理运行脚本
    .run_DEVELOPER.sh
    .run_CLIENT.sh
    .run_COORDINATOR.sh
```

## 工作流程

```
待办 --> 进行中 --> 审查中 --> 已完成
            ^           |
            '-- 驳回 <--'
```

1. **Supervisor/Coordinator** 在 BACKLOG_RESERVE 中创建任务
2. **Developer** 领取最优先的任务并实现
3. Developer 将任务移至审查中
4. **Client** 执行多角色审查（4 个审查者角色）
5. 通过 -> 已完成 / 需要修改 -> 驳回 -> Developer 修复

## 代理模式

### Full（4 个代理）
所有代理均处于活动状态。完整的审查周期、看板管理、资源创建。

### Lean（2 个代理）
仅 Developer + Supervisor。没有专门的审查者或协调者。Supervisor 负责审查和看板同步。

### Solo（1 个代理）
单个 Developer 代理合并所有角色。自我审查、自我管理看板。适用于小型项目或独立开发。

## 恢复运行

如果你在已有 `orchestration/` 的项目上运行 orchestrate.bat，它会检测现有配置：

```
  检测到现有编排配置！
  模式: full    方向: stabilize

  1) Resume      - 仅启动代理（跳过设置）
  2) Reconfigure - 重新运行设置
  3) Cancel
```

## 其他工具

| 文件 | 功能 |
|------|------|
| `add-feature.bat` | 用自然语言描述功能 -> 自动生成任务 + 规格 |
| `monitor.bat` | 监控 Unity/Godot 编辑器日志中的运行时错误，自动创建 bug 任务 |

## 核心机制

### FREEZE
在 BOARD.md 顶部添加 FREEZE 通知 -> 所有代理立即停止。移除后恢复运行。

### 讨论
代理可以在 `discussions/` 中发起异步辩论。用于设计决策、优先级变更、协议改进。所有代理在各自部分回复，然后由 Supervisor 做出结论。

### 自动推进
Developer 可以自动推进任务而无需等待 Supervisor。QA/平衡任务完全跳过审查。新系统任务始终需要 Client 审查。

## 支持的引擎

| 引擎 | 自动检测 | 错误日志 | 示例配置 |
|------|----------|----------|----------|
| Unity | `.meta` 文件, `Assets/` | Editor.log | `sample-config/unity-2d-rpg.config.md` |
| Godot | `project.godot` | Godot Output | `sample-config/godot-platformer.config.md` |
| Unreal | `*.uproject` | Saved/Logs | - |

## 文件概览

```
orchestrate.bat          # 主入口（设置 + 启动）
add-feature.bat          # 通过文字描述添加功能
monitor.bat              # 运行时错误监控
pick-folder.ps1          # 现代文件夹选择对话框 (IFileDialog COM)
auto-setup.sh            # 引擎检测、配置生成、交互式设置
init.sh                  # 目录结构创建
launch.sh                # 跨平台代理启动器
extract-features.sh      # 分析代码库 -> FEATURES.md
seed-backlog.sh          # FEATURES.md -> 任务 + 规格
add-feature.sh           # 自然语言 -> 任务 + 规格
monitor.sh               # Editor.log 监控 + 错误报告
project.config.md        # 空白配置模板
framework/
  agents/                # 代理角色定义（4 个文件）
  prompts/               # 代理循环提示词（4 个文件）
  templates/             # 文档模板（7 个文件）
sample-config/           # Unity/Godot 示例配置
```

## 许可证

MIT
