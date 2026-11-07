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
	draw_circle(Vector2.ZERO, 10.0, Color(0.24, 0.30, 0.46, 0.9))
	draw_circle(-dir * 14.0, 6.0, Color(0.24, 0.30, 0.46, 0.5))
	draw_circle(-dir * 26.0, 3.5, Color(0.24, 0.30, 0.46, 0.25))
