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
# ---- 剧情（D-030）----
var story_stage := 0
var clue_count := 0
var _boss_gate_pos := Vector2.ZERO
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
	# 剧情节点（D-030）
	_register_npc(info["baiji_pos"], "res://assets/actors/baiji.png", "npc_baiji", "与白霁交谈")
	_boss_gate_pos = info["boss_gate"]
	_interactables.append({"pos": _boss_gate_pos, "kind": "boss_gate", "label": "进入幽泉坛", "node": null, "world": "village", "opened": false})
	hud.quest_text = "与村中的白霁交谈"
	hud.choice_picked.connect(_on_choice)
	# 开局状态（D-031）：新游戏命格注入 / 读档恢复
	if GameState.pending_load.is_empty():
		if not GameState.pending_mingge.is_empty():
			player.apply_mingge(GameState.pending_mingge)
			hud.show_hint("命格·%s 已入体" % str(GameState.pending_mingge["name"]))
	else:
		GameState.apply_to(player, self, GameState.pending_load)
		GameState.pending_load = {}
		hud.show_hint("存档读取成功，江湖再会")
		match story_stage:
			1:
				hud.quest_text = "调查村中线索（%d/3）" % mini(clue_count, 3)
			2:
				hud.quest_text = "前往东北山门，诛杀殷无昼"
			3:
				hud.quest_text = "回村寻白霁，当面对质"
			4:
				hud.quest_text = "江湖已定"
	hud.get_parent().process_mode = Node.PROCESS_MODE_ALWAYS  # 暂停时 HUD 保持响应
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
	# Boss 血条同步（D-030）
	if hud.boss_max > 0.0:
		var found := false
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if bool(enemy.get("is_boss")):
				hud.boss_hp = enemy.hp
				found = true
				break
		if not found:
			hud.boss_max = 0.0
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
			"npc_baiji":
				_talk_baiji()
			"boss_gate":
				_enter_boss()

# ================= 剧情任务（D-030） =================

func _register_npc(pos: Vector2, tex: String, kind: String, label: String) -> void:
	var root := Node2D.new()
	root.position = pos
	var spr := Sprite2D.new()
	spr.texture = load(tex)
	spr.hframes = 4
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.offset = Vector2(0, -32)
	root.add_child(spr)
	add_child(root)
	_interactables.append({"pos": pos, "kind": kind, "label": label, "node": root, "world": "village", "opened": false})

func _talk_baiji() -> void:
	match story_stage:
		0:
			hud.say("白霁", "少侠节哀……令师秦无咎之死，绝非寻常山贼所为。")
			hud.say("白霁", "在下听风楼楼主白霁。江湖传言，幽泉教正在搜罗《沧溟诀》残页……")
			hud.say("白霁", "村中石碑竹简或有线索。请调查三处调查点，再来寻我。")
			story_stage = 1
			hud.quest_text = "调查村中线索（0/3）"
		1:
			if clue_count >= 3:
				hud.say("白霁", "果然……残页现世，幽泉教蠢蠢欲动。")
				hud.say("白霁", "幽泉坛入口在东北山门。教主殷无昼武功深不可测，多加小心。")
				story_stage = 2
				hud.quest_text = "前往东北山门，诛杀殷无昼"
			else:
				hud.say("白霁", "线索还不够。村中石碑竹简，还需调查三处。")
		2:
			hud.say("白霁", "先诛殷无昼。他的密室里，或许有你要的答案。")
		3:
			hud.say("白霁", "少侠可曾想过——你走的每一步，都是别人安排好的？")
			hud.say("白霁", "令师秦无咎，并没有死。")
			hud.say("秦无咎", "……为师借你之手除掉殷无昼，取回另一半《沧溟诀》。")
			hud.say("秦无咎", "如今残页尽归我手。徒儿，你要如何？")
			hud.show_choices([
				"一剑诛心：手刃师父，毁去残卷",
				"释然放手：废其武功，守墓思过",
				"入魔夺经：夺取完整《沧溟诀》",
			])
		_:
			hud.say("白霁", "……（一切已成定局）")

func _enter_boss() -> void:
	if story_stage < 2:
		hud.say("", "（山门瘴气逼人，凶险未明。先回村与白霁商议对策。）")
		return
	if hud.boss_max > 0.0:
		hud.show_hint("殷无昼就在附近！")
		return
	if story_stage >= 3:
		hud.show_hint("幽坛已破，空无一人。")
		return
	var enemy := EnemyScript.new()
	enemy.is_boss = true
	enemy.tex_path = "res://assets/actors/boss.png"
	enemy.attack_damage = 16.0
	enemy.speed = 110.0
	enemy.xp = 200
	enemy.setup(player, _boss_gate_pos + Vector2(0, -90), 420.0)
	enemy.set_night(is_night)
	add_child(enemy)
	hud.boss_name = "幽泉教主·殷无昼"
	hud.boss_max = 420.0
	hud.boss_hp = 420.0
	hud.quest_text = "诛杀幽泉教主·殷无昼"
	hud.say("殷无昼", "秦无咎的徒弟？来得正好——把残页交出来！")

func on_boss_defeated() -> void:
	if story_stage != 2:
		return
	story_stage = 3
	hud.boss_max = 0.0
	player.add_xp(200)
	hud.say("殷无昼（绝笔）", "……我不过是一枚棋子。白霁背后之人……你的师父……秦无咎……")
	hud.say("", "（你从密室搜出往来书信，真相渐渐浮出水面。）")
	hud.quest_text = "回村寻白霁，当面对质"

func _on_choice(idx: int) -> void:
	story_stage = 4
	match idx:
		0:
			hud.show_ending("结局·诛心",
				"你拾起地上的剑。「师父，你教我剑法、教我做人，却把我当刀。」剑光起落，秦无咎倒在他自己的棋盘旁。你将《沧溟诀》残页尽数投入火中，转身走入江湖。从此世间再无沧溟诀，只剩一个无名的剑客。")
		1:
			hud.show_ending("结局·释然",
				"你废去师父武功，将他带回落雁村。他在坟前日日守着——其实坟里埋的是谁，已经不重要了。残卷归还各宗门，江湖渐平。每年清明，村口多了一个扫墓的人。")
		2:
			hud.show_ending("结局·入魔",
				"你取过完整《沧溟诀》，扶起白霁：「从今日起，听风楼听我号令。」秦无咎大笑而亡。多年后，江湖人提起「白衣楼主」与他身后的影子，无不色变。（二周目·入魔线开启）")

## 卦摊（D-031 后命格在开局抽取；此处为天命批注）
func _roll_mingge(it: Dictionary) -> void:
	it["opened"] = true
	var mg := str(player.get("mingge"))
	if mg != "未定命格":
		hud.say("卦摊老人", "你已于入世时抽得命格【%s】，天命已定，善自珍重。" % mg)
	else:
		hud.say("卦摊老人", "你尚未抽签……也罢，老朽为你补上一签。")
		var pool := _by_quality("地品") + _by_quality("凡品")
		var m: Dictionary = pool[randi() % pool.size()]
		player.apply_mingge(m)
		hud.show_hint("补签·%s（%s）：%s" % [str(m["name"]), str(m["quality"]), str(m["desc"])])

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
	clue_count += 1
	if story_stage == 1:
		hud.quest_text = "调查村中线索（%d/3）" % mini(clue_count, 3)
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
		"pause": [KEY_ESCAPE],
		"chain_exec": [KEY_R],
		"use_potion": [KEY_Q],
		"use_ether": [KEY_E],
		"toggle_manual": [KEY_TAB],
		"toggle_attr": [KEY_C],
		"toggle_bag": [KEY_B],
		"toggle_chain": [KEY_V],
		"toggle_sect": [KEY_N],
		"qgong": [KEY_X],
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
