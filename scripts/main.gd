extends Node2D
## 主场景（原型 v0.1）：水墨占位场景 + 玩家 + 敌人 + HUD
## 说明：输入动作在此动态注册；后续"按键设置"步骤会迁移到 project.godot 的 [input] 段。

const EnemyScript := preload("res://scripts/enemy.gd")

const PAPER := Color(0.95, 0.93, 0.86)
const INK_WASH := Color(0.45, 0.45, 0.50, 0.22)
const INK_WASH_DARK := Color(0.30, 0.30, 0.36, 0.30)

## 场景装饰（固定数据，保证可复现）：[位置, 半径, 深浅]
var _decor: Array = [
	[Vector2(-620, -320), 70.0, 0], [Vector2(-540, -260), 46.0, 1],
	[Vector2(640, -300), 64.0, 0], [Vector2(560, -360), 40.0, 1],
	[Vector2(-660, 300), 58.0, 0], [Vector2(-580, 360), 38.0, 1],
	[Vector2(620, 320), 72.0, 0], [Vector2(540, 380), 42.0, 1],
	[Vector2(-120, -420), 52.0, 1], [Vector2(180, 440), 56.0, 1],
	[Vector2(-320, 60), 34.0, 1], [Vector2(340, -60), 36.0, 1],
	[Vector2(-40, 120), 30.0, 1], [Vector2(80, -160), 28.0, 1],
]

@onready var player: CharacterBody2D = $Player
@onready var hud: Control = $HUD/HUDPanel

func _ready() -> void:
	_register_actions()
	_setup_font()
	_spawn_enemies()
	hud.player = player
	hud.move_list = player.move_list
	print("《侠影残卷》原型 v0.2 启动成功｜J攻 K破 L闪 U御 I气｜连招：J-J-J / J-J-K / K-J / L-J / U-J / J-K-I｜Tab 武学图鉴")

## 注册输入动作（键位草案见 PRD §2.1；仅在动作缺失时创建，避免重复注册）
func _register_actions() -> void:
	var bindings := {
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"attack": [KEY_J, KEY_SPACE],
		"heavy": [KEY_K],
		"dodge": [KEY_L, KEY_SHIFT],
		"block": [KEY_U],
		"qi": [KEY_I],
		"toggle_manual": [KEY_TAB],
	}
	for action: String in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for key: int in bindings[action]:
				var ev := InputEventKey.new()
				ev.physical_keycode = key
				InputMap.action_add_event(action, ev)

## 加载系统中文字体（Godot 4 默认字体不含中文字形）
func _setup_font() -> void:
	var font := FontFile.new()
	var candidates := [
		"C:/Windows/Fonts/simhei.ttf",
		"C:/Windows/Fonts/msyh.ttc",
		"C:/Windows/Fonts/simsun.ttc",
	]
	for path: String in candidates:
		if FileAccess.file_exists(path) and font.load_dynamic_font(path) == OK:
			var theme := Theme.new()
			theme.default_font = font
			theme.default_font_size = 20
			get_tree().root.theme = theme
			print("中文字体已加载：", path)
			return
		push_warning("未找到可用中文字体，HUD 中文可能显示为方框")

func _spawn_enemies() -> void:
	var spawns := [Vector2(320, -180), Vector2(-380, 160), Vector2(520, 260), Vector2(-560, -240), Vector2(140, 420)]
	for pos: Vector2 in spawns:
		var enemy := EnemyScript.new()
		enemy.position = pos
		enemy.setup(player, pos)
		add_child(enemy)

func _draw() -> void:
	# 宣纸底
	draw_rect(Rect2(-820, -580, 1640, 1160), PAPER)
	# 远山淡墨（装饰）
	for item: Array in _decor:
		var color := INK_WASH_DARK if item[2] == 0 else INK_WASH
		draw_circle(item[0], item[1], color)
	# 场地边界（浓墨笔触）
	draw_rect(Rect2(-770, -530, 1540, 1060), Color(0.12, 0.12, 0.15, 0.85), false, 3.0)
