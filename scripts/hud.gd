extends Control
## HUD v2（D-028 UI 重设计）：像素国风面板系统
## 面板=纸底+墨框+红角饰；钥匙帽图标；角色肖像；分级色彩
## 面板：Tab 图鉴 ｜ C 属性 ｜ B 背包 ｜ V 连招链（数字键编排/Backspace 撤销/X 清空）

const MoveDB := preload("res://scripts/move_database.gd")

const C_INK := Color(0.10, 0.10, 0.16)
const C_PAPER := Color(0.93, 0.90, 0.82)
const C_PAPER_D := Color(0.82, 0.78, 0.68)
const C_RED := Color(0.72, 0.16, 0.13)
const C_GOLD := Color(0.85, 0.66, 0.28)
const C_BLUE := Color(0.36, 0.50, 0.72)
const C_GREEN := Color(0.42, 0.56, 0.30)
const C_GRAY := Color(0.45, 0.43, 0.40)

var player: Node2D
var move_list: Array = []
var place_name := "落雁村"
var prompt_text := ""
var day_text := "第 1 日 · 午时"

var _font: Font = null
var _fsize := 20
var _hint_text := ""
var _hint_time := 0.0
var _manual_open := false
var _attr_open := false
var _bag_open := false
var _chain_open := false

func _process(delta: float) -> void:
	_hint_time = maxf(_hint_time - delta, 0.0)
	queue_redraw()

func show_hint(text: String) -> void:
	_hint_text = text
	_hint_time = 2.6

func set_prompt(text: String) -> void:
	prompt_text = text

func _toggle(panel: String) -> void:
	_manual_open = panel == "manual" and not _manual_open
	_attr_open = panel == "attr" and not _attr_open
	_bag_open = panel == "bag" and not _bag_open
	_chain_open = panel == "chain" and not _chain_open

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_manual"):
		_toggle("manual")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_attr"):
		_toggle("attr")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_bag"):
		_toggle("bag")
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_chain"):
		_toggle("chain")
		get_viewport().set_input_as_handled()
	elif _chain_open and event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		var arr := _discovered_list()
		if k >= KEY_1 and k <= KEY_9:
			var idx: int = k - KEY_1
			if idx < arr.size():
				player.chain_append(str(arr[idx]["id"]))
				get_viewport().set_input_as_handled()
		elif k == KEY_0 and arr.size() > 9:
			player.chain_append(str(arr[9]["id"]))
			get_viewport().set_input_as_handled()
		elif k == KEY_BACKSPACE:
			player.chain_pop()
			get_viewport().set_input_as_handled()
		elif k == KEY_X:
			player.chain_clear()
			get_viewport().set_input_as_handled()

func _discovered_list() -> Array:
	var out: Array = []
	if not is_instance_valid(player):
		return out
	var disc = player.get("discovered")
	for mv in move_list:
		if disc != null and disc.has(str(mv["id"])):
			out.append(mv)
	return out

# ================= 绘制 =================

func _draw() -> void:
	_font = get_theme_default_font()
	if _font == null:
		return
	_fsize = get_theme_default_font_size()
	var w := get_viewport_rect().size.x
	var h := get_viewport_rect().size.y

	_draw_player_panel()
	_draw_top_right(w)
	if _hint_time > 0.0:
		_draw_banner(w)
	if prompt_text != "":
		_draw_prompt(w, h)
	_draw_legend(w, h)

	if _manual_open:
		_draw_manual(w, h)
	elif _attr_open:
		_draw_attr(w, h)
	elif _bag_open:
		_draw_bag(w, h)
	elif _chain_open:
		_draw_chain(w, h)

## 纸底面板：纸面 + 墨框 + 内细线 + 红角饰
func _draw_panel(rect: Rect2, alpha: float = 0.95) -> void:
	draw_rect(rect, Color(C_PAPER, alpha))
	draw_rect(rect, Color(C_INK, 0.95), false, 2.0)
	draw_rect(rect.grow(-4.0), Color(C_INK, 0.22), false, 1.0)
	for c in [rect.position + Vector2(5, 5), Vector2(rect.end.x - 5, rect.position.y + 5),
			Vector2(rect.position.x + 5, rect.end.y - 5), rect.end - Vector2(5, 5)]:
		draw_circle(c, 3.5, Color(C_RED, 0.9))

func _draw_keycap(pos: Vector2, letter: String) -> void:
	draw_rect(Rect2(pos, Vector2(20, 20)), Color(0.16, 0.16, 0.22))
	draw_rect(Rect2(pos, Vector2(20, 4)), Color(0.34, 0.34, 0.44))
	draw_rect(Rect2(pos, Vector2(20, 20)), C_INK, false, 1.0)
	draw_string(_font, pos + Vector2(5, 15), letter, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 4, Color(0.95, 0.92, 0.85))

func _draw_bar(rect: Rect2, ratio: float, c_dark: Color, c_light: Color) -> void:
	draw_rect(rect, Color(C_INK, 0.9))
	var inner := rect.grow(-2.0)
	draw_rect(inner, Color(0.30, 0.26, 0.22))
	var fill := Rect2(inner.position, Vector2(inner.size.x * clampf(ratio, 0.0, 1.0), inner.size.y))
	draw_rect(fill, c_dark)
	if fill.size.x > 3.0:
		draw_rect(Rect2(fill.position + Vector2(1, 1), Vector2(fill.size.x - 2, 3)), c_light)

func _draw_player_panel() -> void:
	var rect := Rect2(16, 14, 306, 116)
	_draw_panel(rect)
	# 肖像
	var portrait := Rect2(26, 26, 58, 58)
	draw_rect(portrait, Color(C_INK, 0.85))
	if is_instance_valid(player):
		var spr: Sprite2D = player.get("_spr")
		if spr != null and spr.texture != null:
			draw_texture_rect_region(spr.texture, portrait.grow(-2.0), Rect2(0, 0, 64, 64))
	draw_rect(portrait, C_INK, false, 2.0)
	# 名号与命格
	draw_string(_font, Vector2(98, 48), "无名少侠", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize + 4, C_INK)
	var mg := "未定命格"
	if is_instance_valid(player):
		mg = str(player.get("mingge"))
	draw_string(_font, Vector2(98, 72), "命格·" + mg, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 3, Color(C_GOLD, 1.0))
	# 气血/内力
	var hp := 100.0
	var max_hp := 100.0
	var mp := 100.0
	var max_mp := 100.0
	if is_instance_valid(player):
		hp = player.hp
		max_hp = player.max_hp
		mp = player.mp
		max_mp = player.max_mp
	draw_string(_font, Vector2(98, 96), "气血", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 4, C_INK)
	_draw_bar(Rect2(142, 82, 168, 14), hp / max_hp, Color(C_RED), Color(0.92, 0.45, 0.38))
	draw_string(_font, Vector2(98, 118), "内力", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 4, C_INK)
	_draw_bar(Rect2(142, 104, 168, 14), mp / max_mp, Color(C_BLUE), Color(0.62, 0.74, 0.92))
	draw_string(_font, Vector2(236, 96), "%d/%d" % [int(hp), int(max_hp)], HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 5, C_INK)
	draw_string(_font, Vector2(236, 118), "%d/%d" % [int(mp), int(max_mp)], HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 5, C_INK)

func _draw_top_right(w: float) -> void:
	var rect := Rect2(w - 244, 14, 228, 68)
	_draw_panel(rect)
	draw_string(_font, rect.position + Vector2(18, 30), place_name, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize + 2, C_INK)
	draw_string(_font, rect.position + Vector2(18, 54), day_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 3, Color(C_GRAY))

func _draw_banner(w: float) -> void:
	var alpha := clampf(_hint_time, 0.0, 1.0)
	var tsize := _fsize + 4
	var tw := _font.get_string_size(_hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, tsize).x
	var rect := Rect2(w * 0.5 - tw * 0.5 - 26.0, 128.0, tw + 52.0, 46.0)
	draw_rect(rect, Color(C_PAPER.r, C_PAPER.g, C_PAPER.b, 0.92 * alpha))
	draw_rect(rect, Color(C_INK.r, C_INK.g, C_INK.b, 0.9 * alpha), false, 2.0)
	draw_circle(rect.position + Vector2(14, 23), 7.0, Color(C_RED.r, C_RED.g, C_RED.b, 0.9 * alpha))
	draw_string(_font, rect.position + Vector2(32, 31), _hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, tsize, Color(C_INK.r, C_INK.g, C_INK.b, alpha))

func _draw_prompt(w: float, h: float) -> void:
	var y := h - 118.0
	var tw := _font.get_string_size(prompt_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize).x
	var x := w * 0.5 - (tw + 34.0) * 0.5
	draw_rect(Rect2(x - 10, y - 20, tw + 52, 30), Color(C_PAPER, 0.85))
	draw_rect(Rect2(x - 10, y - 20, tw + 52, 30), Color(C_INK, 0.8), false, 1.5)
	_draw_keycap(Vector2(x, y - 16), "F")
	draw_string(_font, Vector2(x + 28, y + 2), prompt_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize, C_INK)

func _draw_legend(w: float, h: float) -> void:
	var rect := Rect2(16, h - 54, w - 32, 40)
	_draw_panel(rect, 0.88)
	draw_string(_font, rect.position + Vector2(16, 26),
		"J 攻　K 破　L 闪　U 御　I 气　R 连招　F 交互　Q 金疮药　E 回气散　1-5 切武器　C 属性　B 背包　V 连招编排　Tab 图鉴",
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 5, Color(C_INK, 0.9))

# ================= 覆盖面板 =================

func _panel_frame(w: float, h: float, title: String) -> Rect2:
	var rect := Rect2(w * 0.5 - 380.0, h * 0.5 - 250.0, 760.0, 500.0)
	_draw_panel(rect)
	draw_string(_font, rect.position + Vector2(28, 46), title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize + 6, C_INK)
	draw_line(rect.position + Vector2(24, 60), Vector2(rect.end.x - 24, rect.position.y + 60), Color(C_INK, 0.5), 1.0)
	draw_string(_font, rect.end - Vector2(150, 24), "（Tab 关闭）", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 4, Color(C_GRAY))
	return rect

func _tier_color(tier: String) -> Color:
	match tier:
		"高阶":
			return Color(C_RED)
		"中阶":
			return Color(C_BLUE)
		_:
			return Color(C_GREEN)

func _draw_manual(w: float, h: float) -> void:
	var rect := _panel_frame(w, h, "武 学 图 鉴 · " + _weapon_name())
	var y := rect.position.y + 100.0
	var disc = player.get("discovered") if is_instance_valid(player) else null
	for mv in move_list:
		var known: bool = disc != null and disc.has(str(mv["id"]))
		if known:
			draw_string(_font, rect.position + Vector2(32, y), str(mv["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize + 2, _tier_color(str(mv["tier"])))
			_draw_seq(Vector2(rect.position.x + 240, y - 15), mv["seq"])
			draw_string(_font, rect.position + Vector2(420, y), str(mv["desc"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 4, Color(C_GRAY))
		else:
			draw_string(_font, rect.position + Vector2(32, y), "？？？", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize + 2, Color(C_GRAY, 0.7))
			draw_string(_font, rect.position + Vector2(420, y), "未领悟——多试试按键组合", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 4, Color(C_GRAY, 0.6))
		y += 46.0

func _draw_seq(pos: Vector2, seq) -> void:
	var names := {"attack": "J", "heavy": "K", "dodge": "L", "block": "U", "qi": "I"}
	var x := pos.x
	for a in seq:
		_draw_keycap(Vector2(x, pos.y), str(names.get(a, "?")))
		x += 26.0

func _draw_attr(w: float, h: float) -> void:
	var rect := _panel_frame(w, h, "属 性 · " + _weapon_name())
	var stats: Dictionary = player.get("stats") if is_instance_valid(player) else {}
	var mg := str(player.get("mingge")) if is_instance_valid(player) else "未定命格"
	var labels := ["力道", "身法", "根骨", "悟性", "内力", "气运"]
	var descs := ["外功伤害", "攻速移速闪避", "气血防御", "悟性连招", "内力真元", "机缘掉落"]
	var y := rect.position.y + 110.0
	for i in labels.size():
		var col := 0 if i < 3 else 1
		var x := rect.position.x + 40.0 + col * 370.0
		var yy := y + (i % 3) * 62.0
		draw_string(_font, Vector2(x, yy), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize + 2, C_INK)
		draw_string(_font, Vector2(x + 90, yy), str(int(stats.get(labels[i], 0))), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize + 6, Color(C_RED))
		draw_string(_font, Vector2(x, yy + 22), descs[i], HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 5, Color(C_GRAY))
	var by := rect.position.y + 330.0
	draw_string(_font, rect.position + Vector2(40, by), "派生：气血 %d ｜ 内力 %d ｜ 气血=100+根骨×5 ｜ 伤害×(1+力道×2%%)" % [int(player.max_hp), int(player.max_mp)] if is_instance_valid(player) else "", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 3, C_INK)
	draw_string(_font, rect.position + Vector2(40, by + 34), "命格·" + mg + "（卦摊抽签后生效，见村中卦摊）", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 1, Color(C_GOLD))
	draw_string(_font, rect.position + Vector2(40, by + 76), "提示：命格抽签（卦摊 F）一次性改变初始属性；升级加点后续版本接入。", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 5, Color(C_GRAY))

func _draw_bag(w: float, h: float) -> void:
	var rect := _panel_frame(w, h, "背 包")
	var inv: Dictionary = player.get("inventory") if is_instance_valid(player) else {}
	var items := [["potion", "金疮药", "回复气血 50（Q 快捷使用）"], ["ether", "回气散", "回复内力 50（E 快捷使用）"], ["herb", "草药", "材料·制药（后续版本）"], ["iron", "玄铁", "材料·锻造（后续版本）"]]
	var y := rect.position.y + 110.0
	for it in items:
		var n := int(inv.get(it[0], 0))
		draw_string(_font, rect.position + Vector2(40, y), it[1], HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize + 2, C_INK if n > 0 else Color(C_GRAY, 0.6))
		draw_string(_font, rect.position + Vector2(220, y), "× " + str(n), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize + 2, Color(C_RED) if n > 0 else Color(C_GRAY, 0.6))
		draw_string(_font, rect.position + Vector2(320, y), it[2], HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 4, Color(C_GRAY))
		y += 52.0
	draw_string(_font, rect.position + Vector2(40, rect.position.y + 380), "宝箱与调查点可获得物品；Q/E 快捷服药。", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 4, Color(C_GRAY))

func _draw_chain(w: float, h: float) -> void:
	var rect := _panel_frame(w, h, "连 招 链 · 自 创 武 功 · " + _weapon_name())
	var arr: Array = player.get("chains").get(str(player.get("weapon")["id"]), []) if is_instance_valid(player) else []
	# 当前链条
	draw_string(_font, rect.position + Vector2(40, 100), "当前连招链（战斗中按 R 依序施展）：", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize, C_INK)
	var x := rect.position.x + 40.0
	for i in 5:
		var slot := Rect2(x, rect.position.y + 116.0, 128.0, 44.0)
		draw_rect(slot, Color(C_PAPER_D, 0.9))
		draw_rect(slot, Color(C_INK, 0.8), false, 1.5)
		if i < arr.size():
			var mv := MoveDB.move_by_id(str(arr[i]))
			if not mv.is_empty():
				draw_string(_font, slot.position + Vector2(10, 28), str(mv["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 3, _tier_color(str(mv["tier"])))
		else:
			draw_string(_font, slot.position + Vector2(10, 28), "空", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 3, Color(C_GRAY, 0.6))
		if i < 4:
			draw_string(_font, Vector2(slot.end.x + 4, slot.position.y + 30), "›", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize + 6, Color(C_GRAY))
		x += 144.0
	# 可编排招式（已领悟，编号）
	draw_string(_font, rect.position + Vector2(40, 208), "已领悟招式（按数字键加入连招链 / Backspace 撤销 / X 清空）：", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 2, C_INK)
	var list := _discovered_list()
	var y := rect.position.y + 240.0
	for i in list.size():
		var mv: Dictionary = list[i]
		var col := 0 if i < 5 else 1
		var xx := rect.position.x + 40.0 + col * 370.0
		var yy := y + (i % 5) * 44.0
		_draw_keycap(Vector2(xx, yy - 15), str((i + 1) % 10))
		draw_string(_font, Vector2(xx + 30, yy), str(mv["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 2, _tier_color(str(mv["tier"])))
	if list.is_empty():
		draw_string(_font, rect.position + Vector2(40, y), "尚无领悟招式——先去搓招领悟（Tab 查看出招表）", HORIZONTAL_ALIGNMENT_LEFT, -1.0, _fsize - 2, Color(C_GRAY))

func _weapon_name() -> String:
	if is_instance_valid(player):
		var wpn = player.get("weapon")
		if wpn != null and not wpn.is_empty():
			return str(wpn["name"])
	return ""
