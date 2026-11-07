extends Control
## HUD（原型）：水墨风信息条 + 操作提示（CanvasLayer 全屏 Control，_draw 绘制）

var player: Node2D

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var font := get_theme_default_font()
	if font == null:
		return
	var size := get_theme_default_font_size()
	var ink := Color(0.12, 0.12, 0.15)

	# 标题
	draw_string(font, Vector2(24, 42), "《侠影残卷》原型 v0.1", HORIZONTAL_ALIGNMENT_LEFT, -1.0, size + 4, ink)

	# 气血 / 内力
	var hp := 100.0
	var max_hp := 100.0
	if is_instance_valid(player) and player.has_method("take_damage"):
		hp = player.hp
		max_hp = player.max_hp
	draw_string(font, Vector2(24, 78), "气血", HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, ink)
	_draw_bar(Rect2(84, 60, 260, 16), hp / max_hp, Color(0.72, 0.18, 0.16))
	draw_string(font, Vector2(24, 108), "内力", HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, ink)
	_draw_bar(Rect2(84, 90, 260, 16), 1.0, Color(0.28, 0.38, 0.52))
	draw_string(font, Vector2(356, 78), "%d / %d" % [int(hp), int(max_hp)], HORIZONTAL_ALIGNMENT_LEFT, -1.0, size - 2, ink)

	# 时辰（昼夜系统 Phase 4 接入，现为占位）
	draw_string(font, Vector2(size_of_viewport() - 190, 42), "第 1 日 · 午时", HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, ink)

	# 操作提示
	draw_string(font, Vector2(24, size_of_viewport_y() - 28), "WASD 移动  ｜  J/空格 攻击  ｜  K/Shift 闪避  ｜  水墨美术素材制作中（占位图形）", HORIZONTAL_ALIGNMENT_LEFT, -1.0, size - 2, Color(0.12, 0.12, 0.15, 0.75))

func _draw_bar(rect: Rect2, ratio: float, color: Color) -> void:
	draw_rect(rect, Color(0.12, 0.12, 0.15, 0.25))
	draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(ratio, 0.0, 1.0), rect.size.y)), color)
	draw_rect(rect, Color(0.12, 0.12, 0.15, 0.6), false, 1.0)

func size_of_viewport() -> float:
	return get_viewport_rect().size.x

func size_of_viewport_y() -> float:
	return get_viewport_rect().size.y
