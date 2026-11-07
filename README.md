# 《侠影残卷》（暂定名）— 2D 武侠动作探索 RPG

Godot 4.x 开发。核心玩法：**组合键搓招 + 自创连招链**——玩家通过按键组合创造属于自己的武侠招式。

## 文档索引

| 文档 | 作用 |
|---|---|
| [docs/PRD.md](docs/PRD.md) | 需求文档：游戏完整设计方案 |
| [docs/WORKFLOW.md](docs/WORKFLOW.md) | 开发工作流：一问一答、验收、回滚规则 |
| [docs/DECISIONS.md](docs/DECISIONS.md) | 决策日志：可追溯、回滚依据 |

## 当前状态

- **阶段**：📄 方案与文档（Phase 0 未开始）
- **当前步骤**：等待设计者验收 PRD + 工作流 + 决策日志
- **待验收项**：`docs/` 三份文档
- **阻塞问题**：无

## 快速开始

（Phase 0 项目初始化后补充：Godot 打开 `project.godot` 的方式与目录说明。）

## 回滚指南

见 `docs/WORKFLOW.md §3`。简述：`git log` 定位步骤提交 → `git revert` 保留历史回滚（首选）或 `git reset --hard` 整步重来 → 在决策日志记录回滚决策。
