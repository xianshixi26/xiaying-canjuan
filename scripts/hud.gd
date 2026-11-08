extends Control
## HUD（原型 v0.2）：水墨风信息条 + 领悟提示 + 武学图鉴（Tab 开关）

const MoveDB := preload("res://scripts/move_database.gd")

var player: Node2D
var move_list: Array = []
var place_name := "落雁村"
var prompt_text := ""

func set_prompt(text: String) -> void:
	prompt_text = text

var _hint_text := ""
var _hint_time := 0.0
var _manual_open := false

func _process(delta: float) -> void:
	_hint_time = maxf(_hint_time - delta, 0.0)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_manual"):
		_manual_open = not _manual_open

func show_hint(text: String) -> void:
	_hint_text = text
	_hint_time = 2.4

func _draw() -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	var size := get_theme_default_font_size()
	var ink := Color(0.12, 0.12, 0.15)
	var w := get_viewport_rect().size.x
	var h := get_viewport_rect().size.y

	# 标题 + 当前武器
	draw_string(font, Vector2(24, 42), "《侠影残卷》原型 v0.3", HORIZONTAL_ALIGNMENT_LEFT, -1.0, size + 4, ink)
	var wname := "青锋剑"
	var wtype := "剑"
	if is_instance_valid(player):
		var wpn = player.get("weapon")
		if wpn != null and not wpn.is_empty():
			wname = str(wpn["name"])
			wtype = str(wpn["type"])
	draw_string(font, Vector2(24, 72), "武器：%s（%s）｜按 1-5 切换　　地点：%s" % [wname, wtype, place_name], HORIZONTAL_ALIGNMENT_LEFT, -1.0, size - 2, Color(0.12, 0.12, 0.15, 0.8))

	# 气血 / 内力
	var hp := 100.0
	var max_hp := 100.0
	var mp := 100.0
	var max_mp := 100.0
	if is_instance_valid(player):
		hp = player.hp
		max_hp = player.max_hp
		mp = player.mp
		max_mp = player.max_mp
	draw_string(font, Vector2(24, 78), "气血", HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, ink)
	_draw_bar(Rect2(84, 60, 260, 16), hp / max_hp, Color(0.72, 0.18, 0.16))
	draw_string(font, Vector2(24, 108), "内力", HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, ink)
	_draw_bar(Rect2(84, 90, 260, 16), mp / max_mp, Color(0.28, 0.38, 0.52))
	draw_string(font, Vector2(356, 78), "%d / %d" % [int(hp), int(max_hp)], HORIZONTAL_ALIGNMENT_LEFT, -1.0, size - 2, ink)
	draw_string(font, Vector2(356, 108), "%d / %d" % [int(mp), int(max_mp)], HORIZONTAL_ALIGNMENT_LEFT, -1.0, size - 2, ink)

	# 时辰（昼夜系统 Phase 4 接入，现为占位）
	draw_string(font, Vector2(w - 190, 42), "第 1 日 · 午时", HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, ink)

	# 领悟 / 招式提示（居中上方）
	if _hint_time > 0.0:
		var alpha := clampf(_hint_time, 0.0, 1.0)
		var tsize := size + 6
		var tw := font.get_string_size(_hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, tsize).x
		var box := Rect2(w * 0.5 - tw * 0.5 - 18.0, 64.0, tw + 36.0, 42.0)
		draw_rect(box, Color(0.95, 0.93, 0.86, 0.85 * alpha))
		draw_rect(box, Color(0.12, 0.12, 0.15, 0.6 * alpha), false, 1.5)
		draw_string(font, Vector2(w * 0.5 - tw * 0.5, 93.0), _hint_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, tsize, Color(0.12, 0.12, 0.15, alpha))

	# 交互提示（就近可交互物）
	if prompt_text != "":
		draw_string(font, Vector2(24, h - 62), "▸ " + prompt_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, Color(0.72, 0.18, 0.16))
	# 操作提示
	draw_string(font, Vector2(24, h - 28), "WASD 移动｜F 交互｜J 攻｜K 破｜L 闪｜U 御｜I 气｜1-5 切换武器｜Tab 图鉴", HORIZONTAL_ALIGNMENT_LEFT, -1.0, size - 2, Color(0.12, 0.12, 0.15, 0.75))

	# 武学图鉴
	if _manual_open:
		_draw_manual(font, size, ink, w, h)

func _draw_manual(font: Font, size: int, ink: Color, w: float, h: float) -> void:
	var list: Array = move_list
	var wname := ""
	if is_instance_valid(player):
		var live = player.get("move_list")
		if live != null:
			list = live
		var pw = player.get("weapon")
		if pw != null and not pw.is_empty():
			wname = str(pw["name"])
	var panel := Rect2(w * 0.5 - 320.0, h * 0.5 - 235.0, 640.0, 470.0)
	draw_rect(panel, Color(0.95, 0.93, 0.86, 0.95))
	draw_rect(panel, Color(0.12, 0.12, 0.15, 0.85), false, 2.0)
	draw_string(font, panel.position + Vector2(24, 42), "武 学 图 鉴 · %s（Tab 关闭）" % wname, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size + 4, ink)
	var y := panel.position.y + 88.0
	for move in list:
		var disc = player.get("discovered") if is_instance_valid(player) else null
		var known: bool = bool(disc != null and disc.has(str(move["id"])))
		if known:
			draw_string(font, panel.position + Vector2(24, y), "%s  ［%s］" % [str(move["name"]), MoveDB.seq_text(move["seq"])], HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, ink)
			draw_string(font, panel.position + Vector2(24, y + 22), str(move["desc"]), HORIZONTAL_ALIGNMENT_LEFT, -1.0, size - 4, Color(0.12, 0.12, 0.15, 0.65))
		else:
			draw_string(font, panel.position + Vector2(24, y), "？？？  ［未领悟——多试试按键组合］", HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, Color(0.12, 0.12, 0.15, 0.45))
		y += 52.0

func _draw_bar(rect: Rect2, ratio: float, color: Color) -> void:
	draw_rect(rect, Color(0.12, 0.12, 0.15, 0.25))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(ratio, 0.0, 1.0), rect.size.y)), color)
	draw_rect(rect, Color(0.12, 0.12, 0.15, 0.6), false, 1.0)
