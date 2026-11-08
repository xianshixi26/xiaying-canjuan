extends Node2D
## 主场景（原型 v0.6）：落雁村（48x32 扩图）+ 民居室内（F 进出）+ 交互系统
## 交互：房门(F 进入) / 宝箱(F 开启，出武器) / 调查点(F 调查，出线索/武器)
## 初始武器仅剑，其余武器通过宝箱/调查点获取（D-023）。
## 输入动作在此动态注册（后续接入按键设置界面时迁移到 project.godot）。

const EnemyScript := preload("res://scripts/enemy.gd")
const MapBuilder := preload("res://scripts/map_builder.gd")
const InteriorBuilder := preload("res://scripts/interior_builder.gd")

const WEAPON_NAMES := {"saber": "雁翎刀", "fist": "铁砂掌", "dart": "透骨钉", "staff": "齐眉棍"}
const CLUE_TEXTS := [
	"竹简残文：'沧溟诀残页曾现于落雁村，师兄弟二人各执一半……'",
	"石碑刻痕：'醉剑翁每日黄昏在村口独饮，望的是来路。'",
	"布条血书：'白……霁……不可信……'（字迹潦草）",
	"告示：村长叮嘱——夜里林中多生人，切勿独行。",
	"树皮刻字：'秦无咎到此一游'——师父年轻时的手笔？",
	"瓦片下压着半张金疮药方（制药系统后续接入）。",
	"旧信：'师兄，功法之争，何必动刀。——无昼'",
	"孩童涂鸦：一个白衣人牵着一个小孩。",
]

@onready var player: CharacterBody2D = $Player
@onready var hud: Control = $HUD/HUDPanel

var _village_nodes: Array = []
var _interior_nodes: Array = []
var _interior_info: Dictionary = {}
var _interior_built := false
var in_interior := false
var _return_pos := Vector2.ZERO
var _village_bounds := Rect2()
var _interactables: Array = []
var _pending_weapons: Array = ["saber", "fist", "dart", "staff"]

func _ready() -> void:
	y_sort_enabled = true
	_register_actions()
	_setup_font()
	var info := MapBuilder.build(self)
	_village_bounds = info["bounds"]
	player.position = info["player_spawn"]
	player.arena_half = _village_bounds.size * 0.5 - Vector2(28, 28)
	_apply_camera(_village_bounds)
	hud.player = player
	hud.move_list = player.move_list
	hud.place_name = str(info["name"])
	for pos: Vector2 in info["enemy_spawns"]:
		var enemy := EnemyScript.new()
		enemy.position = pos
		enemy.setup(player, pos)
		add_child(enemy)
	for pos: Vector2 in info["chests"]:
		_register_chest(pos, "village")
	for pos: Vector2 in info["clues"]:
		_register_clue(pos, "village")
	for pos: Vector2 in info["doors"]:
		_interactables.append({"pos": pos, "kind": "door", "label": "进入房屋", "node": null, "world": "village", "opened": false})
	# 快照村庄节点（室内外切换用）
	for c in get_children():
		if c != player and c != hud.get_parent():
			_village_nodes.append(c)
	print("《侠影残卷》原型 v0.6 启动成功｜F 交互（宝箱/调查点/房屋）｜J攻 K破 L闪 U御 I气｜1-5 切换武器（初始仅剑）｜Tab 武学图鉴")

func _process(_delta: float) -> void:
	var it := _nearest_interactable()
	hud.set_prompt("" if it.is_empty() else "按 F %s" % str(it["label"]))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		var it := _nearest_interactable()
		if it.is_empty():
			return
		match str(it["kind"]):
			"door":
				enter_interior(Vector2(it["pos"]))
			"exit":
				exit_interior()
			"chest":
				_open_chest(it)
			"clue":
				_investigate(it)

# ================= 交互点 =================

func _register_chest(pos: Vector2, world: String) -> void:
	var root := Node2D.new()
	root.position = pos
	var spr := Sprite2D.new()
	spr.name = "Sprite2D"
	spr.texture = load("res://assets/props/chest.png")
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.offset = Vector2(0, -32)
	root.add_child(spr)
	add_child(root)
	_interactables.append({"pos": pos, "kind": "chest", "label": "开启宝箱", "node": root, "world": world, "opened": false})

func _register_clue(pos: Vector2, world: String) -> void:
	var root := Node2D.new()
	root.position = pos
	var spr := Sprite2D.new()
	spr.name = "Sprite2D"
	spr.texture = load("res://assets/props/clue.png")
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.offset = Vector2(0, -32)
	root.add_child(spr)
	add_child(root)
	_interactables.append({"pos": pos, "kind": "clue", "label": "调查", "node": root, "world": world, "opened": false})

func _nearest_interactable() -> Dictionary:
	var best: Dictionary = {}
	var best_d := 110.0
	for it in _interactables:
		if bool(it["opened"]) and str(it["kind"]) != "door" and str(it["kind"]) != "exit":
			continue
		if (str(it["world"]) == "interior") != in_interior:
			continue
		var d: float = player.global_position.distance_to(it["pos"])
		if d < best_d:
			best_d = d
			best = it
	return best

func _open_chest(it: Dictionary) -> void:
	it["opened"] = true
	var node: Node2D = it["node"]
	if node != null and node.has_node("Sprite2D"):
		node.get_node("Sprite2D").texture = load("res://assets/props/chest_open.png")
	if _pending_weapons.size() > 0:
		var wid: String = _pending_weapons.pop_front()
		player.grant_weapon(wid)
		hud.show_hint("✦ 开启宝箱：获得新武器【%s】！" % str(WEAPON_NAMES.get(wid, wid)))
	else:
		hud.show_hint("开启宝箱：获得【金疮药 ×2】（物品栏后续接入）")

func _investigate(it: Dictionary) -> void:
	it["opened"] = true
	var idx := randi() % CLUE_TEXTS.size()
	hud.show_hint("调查发现：" + CLUE_TEXTS[idx])
	if idx == 2 and _pending_weapons.size() > 0:
		var wid: String = _pending_weapons.pop_front()
		player.grant_weapon(wid)
		hud.show_hint("✦ 血布下藏着暗格：获得新武器【%s】！" % str(WEAPON_NAMES.get(wid, wid)))

# ================= 室内外切换（D-023） =================

func enter_interior(door_pos: Vector2) -> void:
	if not _interior_built:
		_interior_info = InteriorBuilder.build(self)
		_interior_nodes = _interior_info["nodes"]
		var chest_pos: Vector2 = _interior_info["chest_pos"]
		_register_chest(chest_pos, "interior")
		_interior_nodes.append(get_child(get_child_count() - 1))
		_interactables.append({
			"pos": _interior_info["exit_pos"], "kind": "exit", "label": "离开房屋",
			"node": null, "world": "interior", "opened": false,
		})
		_interior_built = true
	_set_world_active(_village_nodes, false)
	_set_world_active(_interior_nodes, true)
	in_interior = true
	_return_pos = door_pos + Vector2(0, 70)
	player.position = _interior_info["spawn_pos"]
	player.arena_half = _interior_info["bounds"].size * 0.5 - Vector2(28, 28)
	_apply_camera(_interior_info["bounds"])
	hud.place_name = "民居内"

func exit_interior() -> void:
	_set_world_active(_interior_nodes, false)
	_set_world_active(_village_nodes, true)
	in_interior = false
	player.position = _return_pos
	player.arena_half = _village_bounds.size * 0.5 - Vector2(28, 28)
	_apply_camera(_village_bounds)
	hud.place_name = "落雁村"

func _set_world_active(nodes: Array, active: bool) -> void:
	for n in nodes:
		if not is_instance_valid(n):  # 敌人死亡释放后跳过残留引用
			continue
		n.visible = active
		_set_collision(n, active)

func _set_collision(n: Node, active: bool) -> void:
	if not is_instance_valid(n):
		return
	if n is StaticBody2D:
		n.collision_layer = 1 if active else 0
	elif n is CharacterBody2D and n != player:
		n.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	for c in n.get_children():
		_set_collision(c, active)

func _apply_camera(b: Rect2) -> void:
	var cam: Camera2D = player.get_node("Camera2D")
	cam.limit_left = int(b.position.x)
	cam.limit_top = int(b.position.y)
	cam.limit_right = int(b.position.x + b.size.x)
	cam.limit_bottom = int(b.position.y + b.size.y)

# ================= 输入注册与字体 =================

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
		"interact": [KEY_F],
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
