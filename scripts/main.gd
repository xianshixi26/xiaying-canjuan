extends Node2D
## 主场景（原型 v0.6）：落雁村（48x32 扩图）+ 民居室内（F 进出）+ 交互系统
## 交互：房门(F 进入) / 宝箱(F 开启，出武器) / 调查点(F 调查，出线索/武器)
## 初始武器仅剑，其余武器通过宝箱/调查点获取（D-023）。
## 输入动作在此动态注册（后续接入按键设置界面时迁移到 project.godot）。

const EnemyScript := preload("res://scripts/enemy.gd")
const MapBuilder := preload("res://scripts/map_builder.gd")
const InteriorBuilder := preload("res://scripts/interior_builder.gd")

const WEAPON_NAMES := {"saber": "雁翎刀", "fist": "铁砂掌", "dart": "透骨钉", "staff": "齐眉棍"}
## 命格表（D-028：卦摊抽签，一次机会）
const MINGGE_TABLE := [
	{"name": "武曲星临凡", "quality": "天品", "mods": {"力道": 3}, "desc": "天生神力"},
	{"name": "扫地僧命格", "quality": "天品", "mods": {"悟性": 3, "内力": 1}, "desc": "悟性过人"},
	{"name": "灵猫身法", "quality": "地品", "mods": {"身法": 2, "气运": 1}, "desc": "来去如风"},
	{"name": "铁臂罗汉", "quality": "地品", "mods": {"根骨": 2, "力道": 1}, "desc": "皮糙肉厚"},
	{"name": "夜猫子", "quality": "地品", "mods": {"身法": 1, "气运": 2}, "desc": "夜战占优"},
	{"name": "寻常百姓", "quality": "凡品", "mods": {"根骨": 1}, "desc": "平平无奇"},
	{"name": "书呆子", "quality": "凡品", "mods": {"悟性": 2, "力道": -1}, "desc": "读书误了练武"},
	{"name": "天煞孤星", "quality": "隐藏", "mods": {"力道": -1, "气运": 4}, "desc": "福祸相依"},
]
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
var _spawn_points: Array = []
var _spawn_timer := 6.0
# ---- 昼夜（D-029）----
var day_count := 1
var day_time := 0.38
var is_night := false
var _world_tint: CanvasModulate = null
const ENEMY_CAP := 14
const SPAWN_INTERVAL := 10.0
const DAY_LENGTH := 240.0   # 现实 240 秒 = 游戏一天

func _ready() -> void:
	y_sort_enabled = true
	_register_actions()
	_setup_font()
	_world_tint = CanvasModulate.new()  # 天色渐变（只影响世界层，HUD 不受影响）
	add_child(_world_tint)
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
	_spawn_points = info["enemy_spawns"]
	for pos: Vector2 in info["chests"]:
		_register_chest(pos, "village")
	for pos: Vector2 in info["clues"]:
		_register_clue(pos, "village")
	for pos: Vector2 in info["doors"]:
		_interactables.append({"pos": pos, "kind": "door", "label": "进入房屋", "node": null, "world": "village", "opened": false})
	_interactables.append({"pos": info["oracle"], "kind": "oracle", "label": "抽签问卦（一次机会）", "node": null, "world": "village", "opened": false})
	# 快照村庄节点（室内外切换用）
	for c in get_children():
		if c != player and c != hud.get_parent():
			_village_nodes.append(c)
	print("《侠影残卷》原型 v0.6 启动成功｜F 交互（宝箱/调查点/房屋）｜J攻 K破 L闪 U御 I气｜1-5 切换武器（初始仅剑）｜Tab 武学图鉴")

func _process(delta: float) -> void:
	var it := _nearest_interactable()
	hud.set_prompt("" if it.is_empty() else "按 F %s" % str(it["label"]))
	# 昼夜时钟（D-029）
	day_time += delta / DAY_LENGTH
	if day_time >= 1.0:
		day_time -= 1.0
		day_count += 1
	var night_now := day_time > 0.58 or day_time < 0.06
	if night_now != is_night:
		is_night = night_now
		_apply_night_effects()
	_world_tint.color = _tint_color()
	hud.day_text = "第 %d 日 · %s" % [day_count, _shichen()]
	# 敌人持续反复生成（D-024）：仅村庄、远离玩家处刷新；夜晚刷新更快
	if not in_interior:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_timer = 6.0 if is_night else SPAWN_INTERVAL
			_try_spawn_enemy()

## 昼夜切换：敌人强化/还原（D-029）
func _apply_night_effects() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_night(is_night)
	hud.show_hint("夜幕降临，危机四伏……（敌人强化、刷新加速）" if is_night else "天色破晓，平安无事")

func _tint_color() -> Color:
	var t := day_time
	if t < 0.06:
		return Color(0.52, 0.58, 0.80)   # 深夜
	elif t < 0.16:
		return Color(1.0, 0.88, 0.84)    # 清晨
	elif t < 0.52:
		return Color(1.0, 1.0, 1.0)      # 白昼
	elif t < 0.62:
		return Color(1.0, 0.80, 0.62)    # 黄昏
	return Color(0.52, 0.58, 0.80)       # 夜晚

func _shichen() -> String:
	var names := ["子时·深夜", "丑时", "寅时", "卯时·清晨", "辰时", "巳时", "午时·正午", "未时", "申时", "酉时·黄昏", "戌时", "亥时"]
	return names[int(day_time * 12.0) % 12]

func _try_spawn_enemy() -> void:
	if get_tree().get_nodes_in_group("enemies").size() >= ENEMY_CAP:
		return
	var candidates: Array = []
	for pos: Vector2 in _spawn_points:
		if player.global_position.distance_to(pos) > 480.0:
			candidates.append(pos)
	if candidates.is_empty():
		return
	var pos: Vector2 = candidates[randi() % candidates.size()]
	var enemy := EnemyScript.new()
	enemy.position = pos
	enemy.setup(player, pos)
	enemy.set_night(is_night)
	add_child(enemy)

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
			"oracle":
				_roll_mingge(it)

## 卦摊抽签（D-028）：品质受气运影响
func _roll_mingge(it: Dictionary) -> void:
	it["opened"] = true
	var luck := float(player.get("stats").get("气运", 5))
	var roll := randf() + luck * 0.02
	var pool: Array = []
	if roll > 0.85:
		pool = _by_quality("天品")
	elif roll > 0.45:
		pool = _by_quality("地品")
	else:
		pool = _by_quality("凡品") + _by_quality("隐藏")
	var m: Dictionary = pool[randi() % pool.size()]
	player.apply_mingge(m)
	hud.show_hint("签落定·%s（%s）：%s" % [str(m["name"]), str(m["quality"]), str(m["desc"])])

func _by_quality(q: String) -> Array:
	var out: Array = []
	for m in MINGGE_TABLE:
		if str(m["quality"]) == q:
			out.append(m)
	return out

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
		player.add_item("potion", 2)
		player.add_item("herb", 1)
		hud.show_hint("开启宝箱：金疮药 ×2、草药 ×1")

func _investigate(it: Dictionary) -> void:
	it["opened"] = true
	var idx := randi() % CLUE_TEXTS.size()
	player.add_item("herb", 1)
	hud.show_hint("调查发现（草药×1）：" + CLUE_TEXTS[idx])
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
		"chain_exec": [KEY_R],
		"use_potion": [KEY_Q],
		"use_ether": [KEY_E],
		"toggle_manual": [KEY_TAB],
		"toggle_attr": [KEY_C],
		"toggle_bag": [KEY_B],
		"toggle_chain": [KEY_V],
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
