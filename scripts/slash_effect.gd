extends Node2D
## 特效（D-033）：Meowa AI 像素特效帧带渲染
## slash 斩击弧（4帧）｜burst 冲击环（4帧）｜hit 受击火花（4帧）
## 帧带透明底、像素辉光；slash 按朝向旋转/镜像，收尾渐隐

const TEX_SLASH := preload("res://assets/fx/meowa_slash.png")
const TEX_RING := preload("res://assets/fx/meowa_ring.png")
const TEX_SPARK := preload("res://assets/fx/meowa_spark.png")

var mode := "slash"           # slash / burst / hit
var base_angle := 0.0
var radius := 78.0            # 决定绘制尺寸
var sweep := 1.25             # 兼容旧接口
var duration := 0.26
var color_core := Color(1.0, 0.98, 0.9)   # 兼容旧接口
var color_glow := Color(1.0, 0.8, 0.35)   # 兼容旧接口
var flip := false
var tint := Color.WHITE
var tex_override: Texture2D = null   # 敌方红色斩击等变体（D-035）

var _t := 0.0

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t > duration + 0.12:
		queue_free()

func _draw() -> void:
	var sheet: Texture2D = TEX_SLASH
	var frames := 4
	match mode:
		"burst":
			sheet = TEX_RING
		"hit":
			sheet = TEX_SPARK
	if mode == "slash" and tex_override != null:
		sheet = tex_override
	var p := clampf(_t / duration, 0.0, 1.0)
	var f := mini(int(p * frames), frames - 1)
	var fw: int = sheet.get_width() / frames
	var region := Rect2(f * fw, 0, fw, sheet.get_height())
	var s := radius * 2.4
	if mode == "hit":
		s = radius * 1.6
	var target := Rect2(-Vector2(s, s) * 0.5, Vector2(s, s))
	# 收尾渐隐
	var fade := 1.0 - clampf((_t - duration * 0.5) / (duration * 0.7), 0.0, 1.0)
	var rot := base_angle if mode == "slash" else 0.0
	var sx := -1.0 if (flip and mode == "slash") else 1.0
	draw_set_transform(Vector2.ZERO, rot, Vector2(sx, 1.0))
	draw_texture_rect_region(sheet, target, region, Color(tint.r, tint.g, tint.b, fade * tint.a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
