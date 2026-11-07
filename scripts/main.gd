extends Node2D
## 主场景（原型 v0.4）：落雁村地图（D-018 垂直切片）+ 玩家 + 敌人 + HUD
## 输入动作在此动态注册（后续接入按键设置界面时迁移到 project.godot 的 [input] 段）。

const EnemyScript := preload("res://scripts/enemy.gd")
const MapBuilder := preload("res://scripts/map_builder.gd")

@onready var player: CharacterBody2D = $Player
@onready var hud: Control = $HUD/HUDPanel

func _ready() -> void:
	y_sort_enabled = true  # 道具与角色按 y 排序（前后遮挡）
	_register_actions()
	_setup_font()
	var info := MapBuilder.build(self)
	# 玩家与相机
	player.position = info["player_spawn"]
	player.arena_half = info["bounds"].size * 0.5 - Vector2(28, 28)
	var cam: Camera2D = player.get_node("Camera2D")
	var b: Rect2 = info["bounds"]
	cam.limit_left = int(b.position.x)
	cam.limit_top = int(b.position.y)
	cam.limit_right = int(b.position.x + b.size.x)
	cam.limit_bottom = int(b.position.y + b.size.y)
	# HUD
	hud.player = player
	hud.move_list = player.move_list
	hud.place_name = str(info["name"])
	# 敌人（分布在村庄外围，避免一拥而上）
	for pos: Vector2 in info["enemy_spawns"]:
		var enemy := EnemyScript.new()
		enemy.position = pos
		enemy.setup(player, pos)
		add_child(enemy)
	print("《侠影残卷》原型 v0.4 启动成功｜地图：落雁村｜J攻 K破 L闪 U御 I气｜1-5 切换武器｜Tab 武学图鉴")

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
		"slot_1": [KEY_1],
		"slot_2": [KEY_2],
		"slot_3": [KEY_3],
		"slot_4": [KEY_4],
		"slot_5": [KEY_5],
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
