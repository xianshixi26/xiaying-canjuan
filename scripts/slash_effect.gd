extends Node2D
## 剑光特效（D-025）：slash 剑光扫弧 / burst 冲击环 / hit 受击闪光
## 渲染：分层辉光弧（外晕→亮核）+ 渐隐拖尾 + 起手闪光 + 光粒飞散

var mode := "slash"
var base_angle := 0.0
var radius := 78.0
var sweep := 1.25          # 单侧扫角（弧度）
var duration := 0.26
var color_core := Color(1.0, 0.98, 0.9)
var color_glow := Color(1.0, 0.8, 0.35)

var _t := 0.0

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t > duration + 0.15:
		queue_free()

func _draw() -> void:
	match mode:
		"slash":
			_draw_slash()
		"burst":
			_draw_burst()
		_:
			_draw_hit()

func _draw_slash() -> void:
	var p := clampf(_t / duration, 0.0, 1.0)
	var fade := 1.0 - clampf(_t / (duration + 0.12), 0.0, 1.0)
	var head := base_angle + lerpf(-sweep, sweep, p)
	var tail := head - (sweep * 1.6) * (1.0 - p * 0.4)
	# 拖尾弧：外层辉光 → 内层亮核（6 层渐变）
	for i in 6:
		var w := 26.0 - i * 4.2
		var a := (0.06 + i * 0.055) * fade
		var col := color_glow if i < 4 else color_core
		draw_arc(Vector2.ZERO, radius, tail, head, 40, Color(col.r, col.g, col.b, a), w, true)
	draw_arc(Vector2.ZERO, radius, tail, head, 40, Color(color_core.r, color_core.g, color_core.b, 0.9 * fade), 5.0, true)
	# 起手闪光（摆动初段）
	if _t < duration * 0.35:
		var fa := 0.5 * (1.0 - _t / (duration * 0.35))
		for r in range(6, 28, 6):
			draw_arc(Vector2.ZERO, float(r), base_angle - 0.9, base_angle + 0.9, 20, Color(color_core.r, color_core.g, color_core.b, fa * 0.45), 4.0, true)
	# 光粒飞散
	for i in 5:
		var ang := head - 0.18 * float(i)
		var rr := radius + 6.0 + float(i) * 5.0
		var px := Vector2(cos(ang), sin(ang)) * rr
		draw_circle(px, maxf(1.2, 3.0 - i * 0.4), Color(color_glow.r, color_glow.g, color_glow.b, (0.7 - i * 0.12) * fade))

func _draw_burst() -> void:
	var p := clampf(_t / duration, 0.0, 1.0)
	var fade := 1.0 - p
	# 扩散冲击环（3 圈错层）
	for i in 3:
		var rr := 20.0 + p * 140.0 - float(i) * 16.0
		if rr <= 0.0:
			continue
		var a := (0.5 - i * 0.13) * fade
		draw_arc(Vector2.ZERO, rr, 0.0, TAU, 48, Color(color_glow.r, color_glow.g, color_glow.b, a), 10.0 - i * 2.5, true)
	draw_arc(Vector2.ZERO, 20.0 + p * 140.0, 0.0, TAU, 48, Color(color_core.r, color_core.g, color_core.b, 0.85 * fade), 4.0, true)
	if p < 0.5:
		draw_circle(Vector2.ZERO, 26.0 * (1.0 - p * 2.0), Color(color_core.r, color_core.g, color_core.b, 0.5 * (1.0 - p * 2.0)))

func _draw_hit() -> void:
	var p := clampf(_t / 0.22, 0.0, 1.0)
	var fade := 1.0 - p
	for i in 6:
		var ang := TAU * float(i) / 6.0 + 0.3
		var r0 := 4.0 + p * 22.0
		var d0 := Vector2(cos(ang), sin(ang))
		draw_line(d0 * r0, d0 * (r0 + 10.0), Color(color_glow.r, color_glow.g, color_glow.b, 0.8 * fade), 3.0, true)
	draw_circle(Vector2.ZERO, 8.0 * (1.0 - p * 0.6), Color(color_core.r, color_core.g, color_core.b, 0.9 * fade))
