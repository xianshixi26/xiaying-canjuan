# 《侠影残卷》（暂定名）— 2D 武侠动作探索 RPG

Godot 4.x 开发。核心玩法：**组合键搓招 + 自创连招链**——玩家通过按键组合创造属于自己的武侠招式。

## 文档索引

| 文档 | 作用 |
|---|---|
| [docs/PRD.md](docs/PRD.md) | 需求文档：游戏完整设计方案 |
| [docs/WORKFLOW.md](docs/WORKFLOW.md) | 开发工作流：一问一答、验收、回滚规则 |
| [docs/DECISIONS.md](docs/DECISIONS.md) | 决策日志：可追溯、回滚依据 |

## 当前状态

- **阶段**：🔨 Phase 0/1（最小可运行原型）
- **当前步骤**：Step 0.1 原型 v0.1 已完成，**待设计者验收**
- **待验收项**：可运行原型 v0.1（水墨占位场景 + 移动/攻击/闪避 + 敌人 + HUD）
- **阻塞问题**：无

## 快速开始

1. 运行 Godot 4.7.2（`D:\Godot\Godot_v4.7.2-stable_win64.exe`），导入本目录的 `project.godot`；
   或命令行直接运行：`Godot_v4.7.2-stable_win64.exe --path <本目录>`
2. 在编辑器中按 **F5** 运行主场景。
3. 操作：**WASD** 移动 ｜ **J/空格** 攻击 ｜ **K/Shift** 闪避（带无敌帧）。
4. 画面为水墨风占位图形（宣纸底 + 墨点 + 印章红），正式美术素材后续制作。

## 回滚指南

见 `docs/WORKFLOW.md §3`。简述：`git log` 定位步骤提交 → `git revert` 保留历史回滚（首选）或 `git reset --hard` 整步重来 → 在决策日志记录回滚决策。
