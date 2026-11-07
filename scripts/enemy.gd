extends CharacterBody2D
## 敌人原型：徘徊 → 追击 → 近身攻击（红头巾=敌对标识）

var max_hp := 60.0
var hp := 60.0
var speed := 130.0
var aggro_range := 420.0
var attack_range := 52.0
var attack_damage := 10.0
var attack_interval := 1.2

var player: Node2D
var _attack_cd := 0.0
var _hit_flash := 0.0
var _wander_time := 0.0
var _wander_dir := Vector2.ZERO
var _knockback := Vector2.ZERO

func _ready() -> void:
	add_to_group("enemies")

func setup(p_player: Node2D, _pos: Vector2, p_hp: float = 60.0) -> void:
	player = p_player
	max_hp = p_hp
	hp = p_hp

func _physics_process(delta: float) -> void:
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_hit_flash = maxf(_hit_flash - delta, 0.0)
	_knockback = _knockback.move_toward(Vector2.ZERO, 1200.0 * delta)

	var target_dir := Vector2.ZERO
	if is_instance_valid(player):
		var to_player := player.global_position - global_position
		var dist := to_player.length()
		if dist < aggro_range:
			if dist > attack_range:
				target_dir = to_player.normalized()
			elif _attack_cd <= 0.0:
				_attack_cd = attack_interval
				if player.has_method("take_damage"):
					player.take_damage(attack_damage)
		else:
			target_dir = _wander(delta)
	else:
		target_dir = _wander(delta)

	velocity = velocity.move_toward(target_dir * speed, 1200.0 * delta) + _knockback
	move_and_slide()
	queue_redraw()

func _wander(delta: float) -> Vector2:
	_wander_time -= delta
	if _wander_time <= 0.0:
		_wander_time = randf_range(1.0, 2.5)
		_wander_dir = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) if randf() > 0.4 else Vector2.ZERO
	return _wander_dir

func take_damage(dmg: float, knock: Vector2 = Vector2.ZERO) -> void:
	hp -= dmg
	_hit_flash = 0.15
	_knockback = (_knockback + knock).limit_length(320.0)  # 限制击退叠加，防止被打飞过远（D-015）
	if hp <= 0.0:
		queue_free()  # 原型：直接消失（正式版接入掉落/经验）

func _draw() -> void:
	draw_circle(Vector2(2, 13), 15.0, Color(0.2, 0.2, 0.22, 0.16))
	var body := Color(0.35, 0.34, 0.38)
	if _hit_flash > 0.0:
		body = Color(0.72, 0.18, 0.16)
	draw_circle(Vector2.ZERO, 15.0, body)
	# 红头巾（敌对标识）
	draw_circle(Vector2(0, -12), 7.0, Color(0.68, 0.16, 0.15))
	# 血条
	if hp < max_hp:
		draw_rect(Rect2(-22, -34, 44, 5), Color(0.12, 0.12, 0.15, 0.35))
		draw_rect(Rect2(-22, -34, 44.0 * clampf(hp / max_hp, 0.0, 1.0), 5), Color(0.72, 0.18, 0.16))
