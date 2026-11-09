extends Control
## 游戏开始界面（D-031）：主菜单 / 命格抽签 / 设置
## 操作：W/S 选择，F/Enter 确认，←→ 调整，Esc 返回；鼠标点击亦可

const C_INK := Color(0.10, 0.10, 0.16)
const C_PAPER := Color(0.93, 0.90, 0.82)
const C_RED := Color(0.72, 0.16, 0.13)
const C_GOLD := Color(0.85, 0.66, 0.28)
const C_GRAY := Color(0.45, 0.43, 0.40)
const UI_PANEL := preload("res://assets/ui/panel.png")

const MINGGE_TABLE := [
	{"name": "武曲星临凡", "quality": "天品", "mods": {"力道": 3}, "desc": "天生神力，破招凌厉"},
	{"name": "扫地僧命格", "quality": "天品", "mods": {"悟性": 3, "内力": 1}, "desc": "悟性过人，武学精进"},
	{"name": "灵猫身法", "quality": "地品", "mods": {"身法": 2, "气运": 1}, "desc": "来去如风，闪转腾挪"},
	{"name": "铁臂罗汉", "quality": "地品", "mods": {"根骨": 2, "力道": 1}, "desc": "皮糙肉厚，力大无穷"},
	{"name": "夜猫子", "quality": "地品", "mods": {"身法": 1, "气运": 2}, "desc": "夜战占优，机缘不绝"},
	{"name": "寻常百姓", "quality": "凡品", "mods": {"根骨": 1}, "desc": "平平无奇，大器晚成"},
	{"name": "书呆子", "quality": "凡品", "mods": {"悟性": 2, "力道": -1}, "desc": "读书误了练武"},
	{"name": "天煞孤星", "quality": "隐藏", "mods": {"力道": -1, "气运": 4}, "desc": "福祸相依，机缘逆天"},
]

var state := "menu"           # menu / roll / settings
var menu_idx := 0
var settings_idx := 0
var rolling := false
var roll_time := 0.0
var roll_result := {}
var rolled := false
var _font: Font = null
var _fsize := 20
var _name_edit: LineEdit = null
var _hit_rects: Array = []    # 鼠标点击热区 [{rect, action}]

func _ready() -> void:
	_font = _load_font()
	_name_edit = LineEdit.new()
	_name_edit.text = "无名少侠"
	_name_edit.position = Vector2(440, 330)
	_name_edit.size = Vector2(400, 44)
	_name_edit.visible = false
	_name_edit.add_theme_font_size_override("font_size", 22)
	add_child(_name_edit)

func _load_font() -> Font:
	var font := FontFile.new()
	for path in ["C:/Windows/Fonts/simhei.ttf", "C:/Windows/Fonts/msyh.ttc"]:
		if FileAccess.file_exists(path) and font.load_dynamic_font(path) == OK:
			return font
	return ThemeDB.fallback_font

func _process(delta: float) -> void:
	if rolling:
		roll_time += delta
		if roll_time >= 1.2:
			rolling = false
			rolled = true
			roll_result = _roll()
	queue_redraw()

## 抽签：品质受"先天机缘"轻微影响
func _roll() -> Dictionary:
	var r := randf()
	var pool: Array = []
	if r > 0.86:
		pool = _by_q("天品")
	elif r > 0.45:
		pool = _by_q("地品")
	else:
		pool = _by_q("凡品") + _by_q("隐藏")
	return pool[randi() % pool.size()]

func _by_q(q: String) -> Array:
	var out: Array = []
	for m in MINGGE_TABLE:
		if str(m["quality"]) == q:
			out.append(m)
	return out

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		match state:
			"menu":
				if k == KEY_S or k == KEY_DOWN:
					menu_idx = (menu_idx + 1) % 4
				elif k == KEY_W or k == KEY_UP:
					menu_idx = (menu_idx + 3) % 4
				elif k in [KEY_F, KEY_ENTER, KEY_SPACE]:
					_activate(menu_idx)
				elif k == KEY_ESCAPE:
					get_tree().quit()
			"roll":
				if not rolled and not rolling and k in [KEY_F, KEY_ENTER, KEY_SPACE]:
					_name_edit.release_focus()
					rolling = true
					roll_time = 0.0
				elif rolled and k in [KEY_F, KEY_ENTER, KEY_SPACE]:
					_start_game()
				elif k == KEY_ESCAPE:
					state = "menu"
					_name_edit.visible = false
			"settings":
				if k == KEY_S or k == KEY_DOWN:
					settings_idx = (settings_idx + 1) % 3
				elif k == KEY_W or k == KEY_UP:
					settings_idx = (settings_idx + 2) % 3
				elif k == KEY_A or k == KEY_LEFT:
					_adjust(-1)
				elif k == KEY_D or k == KEY_RIGHT:
					_adjust(1)
				elif k in [KEY_F, KEY_ENTER] and settings_idx == 2:
					state = "menu"
				elif k == KEY_ESCAPE:
					state = "menu"
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for item in _hit_rects:
			if (item["rect"] as Rect2).has_point(event.position):
				item["action"].call()
				return

func _adjust(d: int) -> void:
	match settings_idx:
		0:
			var opts := ["简单", "普通", "困难"]
			var i := (opts.find(GameState.difficulty) + d + 3) % 3
			GameState.difficulty = opts[i]
		1:
			GameState.volume = clampf(GameState.volume + d * 0.1, 0.0, 1.0)

func _activate(idx: int) -> void:
	match idx:
		0:
			state = "roll"
			rolled = false
			rolling = false
			roll_result = {}
			_name_edit.visible = true
		1:
			if GameState.has_save():
				GameState.load_game()
				get_tree().change_scene_to_file("res://scenes/Main.tscn")
		2:
			state = "settings"
		3:
			get_tree().quit()

func _start_game() -> void:
	var nm := _name_edit.text.strip_edges()
	GameState.pending_name = nm if nm != "" else "无名少侠"
	GameState.pending_mingge = roll_result
	GameState.pending_load = {}
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

# ================= 绘制 =================

func _draw() -> void:
	var w := size.x
	var h := size.y
	_hit_rects.clear()
	# 背景：宣纸 + 远山淡墨
	draw_rect(Rect2(0, 0, w, h), Color(0.90, 0.87, 0.79))
	draw_circle(Vector2(w * 0.18, h * 0.82), 220.0, Color(0.60, 0.60, 0.62, 0.10))
	draw_circle(Vector2(w * 0.84, h * 0.78), 260.0, Color(0.60, 0.60, 0.62, 0.10))
	draw_circle(Vector2(w * 0.5, h * 1.05), 380.0, Color(0.55, 0.55, 0.58, 0.10))
	# 标题
	draw_string(_font, Vector2(0, 130), "侠 影 残 卷", HORIZONTAL_ALIGNMENT_CENTER, w, 84, C_INK)
	draw_string(_font, Vector2(0, 180), "——  一 剑 入 江 湖 ， 半 纸 写 恩 仇  ——", HORIZONTAL_ALIGNMENT_CENTER, w, 22, Color(C_GRAY))
	# 红印
	draw_rect(Rect2(w * 0.5 + 240, 70, 54, 54), Color(C_RED))
	draw_string(_font, Vector2(w * 0.5 + 240, 106), "侠影", HORIZONTAL_ALIGNMENT_CENTER, 54, 22, Color(0.96, 0.92, 0.84))

	match state:
		"menu":
			_draw_menu(w, h)
		"roll":
			_draw_roll(w, h)
		"settings":
			_draw_settings(w, h)
	draw_string(_font, Vector2(0, h - 24), "W/S 选择 ｜ F/Enter 确认 ｜ ←→ 调整 ｜ Esc 返回/退出", HORIZONTAL_ALIGNMENT_CENTER, w, 18, Color(C_GRAY))

func _panel(rect: Rect2, alpha := 0.95) -> void:
	# AI 山水面板框九宫格拉伸（D-034）
	var t := UI_PANEL
	var sw := t.get_width() / 3
	var sh := t.get_height() / 3
	var cw := rect.size.x / 3.0
	var ch := rect.size.y / 3.0
	var mod := Color(1, 1, 1, alpha)
	draw_texture_rect_region(t, Rect2(rect.position, Vector2(cw, ch)), Rect2(0, 0, sw, sh), mod)
	draw_texture_rect_region(t, Rect2(rect.position + Vector2(rect.size.x - cw, 0), Vector2(cw, ch)), Rect2(t.get_width() - sw, 0, sw, sh), mod)
	draw_texture_rect_region(t, Rect2(rect.position + Vector2(0, rect.size.y - ch), Vector2(cw, ch)), Rect2(0, t.get_height() - sh, sw, sh), mod)
	draw_texture_rect_region(t, Rect2(rect.end - Vector2(cw, ch), Vector2(cw, ch)), Rect2(t.get_width() - sw, t.get_height() - sh, sw, sh), mod)
	draw_texture_rect_region(t, Rect2(rect.position + Vector2(cw, 0), Vector2(rect.size.x - 2 * cw, ch)), Rect2(sw, 0, t.get_width() - 2 * sw, sh), mod)
	draw_texture_rect_region(t, Rect2(rect.position + Vector2(cw, rect.size.y - ch), Vector2(rect.size.x - 2 * cw, ch)), Rect2(sw, t.get_height() - sh, t.get_width() - 2 * sw, sh), mod)
	draw_texture_rect_region(t, Rect2(rect.position + Vector2(0, ch), Vector2(cw, rect.size.y - 2 * ch)), Rect2(0, sh, sw, t.get_height() - 2 * sh), mod)
	draw_texture_rect_region(t, Rect2(rect.position + Vector2(rect.size.x - cw, ch), Vector2(cw, rect.size.y - 2 * ch)), Rect2(t.get_width() - sw, sh, sw, t.get_height() - 2 * sh), mod)
	draw_texture_rect_region(t, Rect2(rect.position + Vector2(cw, ch), rect.size - Vector2(cw * 2, ch * 2)), Rect2(sw, sh, t.get_width() - 2 * sw, t.get_height() - 2 * sh), mod)

func _draw_menu(w: float, h: float) -> void:
	var items := ["新 的 开 始", "继 续 征 程", "设      置", "退 出 游 戏"]
	var rect := Rect2(w * 0.5 - 210, 250, 420, 320)
	_panel(rect)
	for i in items.size():
		var y := 300.0 + i * 66.0
		var sel := i == menu_idx
		if sel:
			draw_rect(Rect2(w * 0.5 - 180, y - 32, 360, 48), Color(C_RED, 0.12))
			draw_circle(Vector2(w * 0.5 - 156, y - 8), 6.0, Color(C_RED))
		var col := C_INK if sel else Color(C_GRAY)
		draw_string(_font, Vector2(0, y), items[i], HORIZONTAL_ALIGNMENT_CENTER, w, 34 if sel else 30, col)
		_hit_rects.append({"rect": Rect2(w * 0.5 - 190, y - 36, 380, 52), "action": _activate.bind(i)})
	# 存档信息
	var sub := "尚无存档"
	if GameState.has_save():
		var info := GameState.save_info()
		sub = "存档：Lv.%d · 第 %d 日 · %s" % [info["level"], info["day"], info["saved_at"]]
		if menu_idx == 1:
			draw_string(_font, Vector2(0, 600), sub, HORIZONTAL_ALIGNMENT_CENTER, w, 20, Color(C_GOLD))
		else:
			draw_string(_font, Vector2(0, 600), sub, HORIZONTAL_ALIGNMENT_CENTER, w, 20, Color(C_GRAY))
	else:
		draw_string(_font, Vector2(0, 600), sub, HORIZONTAL_ALIGNMENT_CENTER, w, 20, Color(C_GRAY))

func _draw_roll(w: float, h: float) -> void:
	var rect := Rect2(w * 0.5 - 340, 240, 680, 360)
	_panel(rect)
	draw_string(_font, Vector2(0, 292), "卦  象  抽  签", HORIZONTAL_ALIGNMENT_CENTER, w, 36, C_INK)
	draw_string(_font, Vector2(0, 322), "一签定命，不可更改（可改名）", HORIZONTAL_ALIGNMENT_CENTER, w, 18, Color(C_GRAY))
	if rolling:
		var names: Dictionary = MINGGE_TABLE[randi() % MINGGE_TABLE.size()]
		draw_string(_font, Vector2(0, 430), "…… 签 筒 摇 动 ……", HORIZONTAL_ALIGNMENT_CENTER, w, 40, Color(C_GOLD))
		draw_string(_font, Vector2(0, 480), str(names["name"]), HORIZONTAL_ALIGNMENT_CENTER, w, 30, Color(C_GRAY))
	elif not rolled:
		draw_string(_font, Vector2(0, 430), "按下 F，抽出你的命格", HORIZONTAL_ALIGNMENT_CENTER, w, 26, Color(C_GRAY))
		var b := Rect2(w * 0.5 - 110, 460, 220, 56)
		_draw_button(b, "抽  签（F）", true)
		_hit_rects.append({"rect": b, "action": func() -> void:
			_name_edit.release_focus()
			rolling = true
			roll_time = 0.0
		})
	else:
		var q := str(roll_result["quality"])
		var qc := C_RED if q == "天品" else (Color(0.36, 0.50, 0.72) if q == "地品" else (Color(C_GRAY) if q == "凡品" else C_GOLD))
		draw_string(_font, Vector2(0, 388), "签 文 落 定", HORIZONTAL_ALIGNMENT_CENTER, w, 22, Color(C_GRAY))
		draw_string(_font, Vector2(0, 432), str(roll_result["name"]), HORIZONTAL_ALIGNMENT_CENTER, w, 42, qc)
		draw_string(_font, Vector2(0, 462), "【" + q + "】 " + str(roll_result["desc"]), HORIZONTAL_ALIGNMENT_CENTER, w, 20, Color(C_GRAY))
		var mods: Dictionary = roll_result["mods"]
		var txt := ""
		for k in mods.keys():
			txt += "%s %+d　" % [k, int(mods[k])]
		draw_string(_font, Vector2(0, 492), txt, HORIZONTAL_ALIGNMENT_CENTER, w, 22, C_INK)
		var b := Rect2(w * 0.5 - 130, 516, 260, 56)
		_draw_button(b, "踏 入 江 湖（F）", true)
		_hit_rects.append({"rect": b, "action": _start_game})

func _draw_settings(w: float, h: float) -> void:
	var rect := Rect2(w * 0.5 - 300, 250, 600, 300)
	_panel(rect)
	draw_string(_font, Vector2(0, 300), "设      置", HORIZONTAL_ALIGNMENT_CENTER, w, 32, C_INK)
	var rows := [
		["难  度", "%s（受伤 %d%%）" % [GameState.difficulty, int(GameState.damage_factor() * 100)]],
		["音  量", "▮".repeat(int(GameState.volume * 10)) + "▯".repeat(10 - int(GameState.volume * 10))],
		["返  回", ""],
	]
	for i in rows.size():
		var y := 360.0 + i * 62.0
		var sel := i == settings_idx
		if sel:
			draw_rect(Rect2(w * 0.5 - 260, y - 30, 520, 46), Color(C_RED, 0.12))
			draw_circle(Vector2(w * 0.5 - 236, y - 7), 6.0, Color(C_RED))
		draw_string(_font, Vector2(w * 0.5 - 200, y), rows[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 26, C_INK if sel else Color(C_GRAY))
		draw_string(_font, Vector2(w * 0.5 + 10, y), rows[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 24, C_INK if sel else Color(C_GRAY))
		_hit_rects.append({"rect": Rect2(w * 0.5 - 260, y - 32, 520, 48), "action": func() -> void:
			settings_idx = i
			if i == 2:
				state = "menu"
			else:
				_adjust(1)
		})

func _draw_button(rect: Rect2, text: String, active: bool) -> void:
	draw_rect(rect, Color(C_RED if active else C_GRAY, 0.16))
	draw_rect(rect, Color(C_INK, 0.85), false, 2.0)
	draw_string(_font, rect.position + Vector2(0, rect.size.y * 0.62), text, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 26, C_INK)
