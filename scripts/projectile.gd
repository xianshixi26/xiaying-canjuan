extends Node2D
## 剑气（原型）：直线飞行，命中首个敌人后消散

var dir := Vector2.RIGHT
var speed := 520.0
var damage := 25.0
var knock := 120.0
var life := 1.2

func setup(p_dir: Vector2, p_damage: float, p_knock: float, start_pos: Vector2) -> void:
	dir = p_dir.normalized()
	damage = p_damage
	knock = p_knock
	global_position = start_pos

func _physics_process(delta: float) -> void:
	position += dir * speed * delta
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if position.distance_to(enemy.global_position) < 26.0:
			enemy.take_damage(damage, dir * knock)
			queue_free()
			return
	queue_redraw()

func _draw() -> void:
	# 剑气辉光（D-025）：外层晕光 + 亮核 + 渐隐拖尾
	for i in 4:
		draw_circle(Vector2.ZERO, 16.0 - i * 3.5, Color(0.55, 0.75, 1.0, 0.12 + i * 0.1))
	for i in 3:
		draw_circle(-dir * (10.0 + i * 9.0), 7.0 - i * 2.0, Color(0.65, 0.82, 1.0, 0.35 - i * 0.1))
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.98, 0.9, 0.95))
