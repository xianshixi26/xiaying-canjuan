extends CharacterBody2D
## 玩家控制器（原型 v0.1）：移动 / 攻击（扇形判定）/ 闪避（无敌帧）
## 渲染：水墨占位——墨色形体 + 印章红点缀

signal hp_changed(hp: float, max_hp: float)

const SPEED := 260.0
const ACCEL := 2000.0
const FRICTION := 2400.0

const ATTACK_RANGE := 82.0
const ATTACK_ARC_DEG := 110.0
const ATTACK_DAMAGE := 20.0
const ATTACK_COOLDOWN := 0.35

const DASH_SPEED := 680.0
const DASH_TIME := 0.16
const DASH_COOLDOWN := 0.55

const ARENA_HALF := Vector2(760.0, 520.0)

var max_hp := 100.0
var hp := 100.0
var facing := Vector2.RIGHT

var _attack_cd := 0.0
var _dash_cd := 0.0
var _dash_time := 0.0
var _slash_time := 0.0
var _invincible := 0.0
var _hit_flash := 0.0

func _physics_process(delta: float) -> void:
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_dash_cd = maxf(_dash_cd - delta, 0.0)
	_slash_time = maxf(_slash_time - delta, 0.0)
	_invincible = maxf(_invincible - delta, 0.0)
	_hit_flash = maxf(_hit_flash - delta, 0.0)

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if _dash_time > 0.0:
		_dash_time -= delta
		velocity = facing * DASH_SPEED
	elif input_dir != Vector2.ZERO:
		facing = input_dir.normalized()
		velocity = velocity.move_toward(input_dir * SPEED, ACCEL * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	move_and_slide()
	position = position.clamp(-ARENA_HALF, ARENA_HALF)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		_try_attack()
	elif event.is_action_pressed("dodge"):
		_try_dash()

func _try_attack() -> void:
	if _attack_cd > 0.0 or _dash_time > 0.0:
		return
	_attack_cd = ATTACK_COOLDOWN
	_slash_time = 0.18
	var aim := facing.angle()
	var half_arc := deg_to_rad(ATTACK_ARC_DEG * 0.5)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var to_enemy: Vector2 = enemy.global_position - global_position
		if to_enemy.length() > ATTACK_RANGE:
			continue
		if absf(wrapf(to_enemy.angle() - aim, -PI, PI)) <= half_arc:
			enemy.take_damage(ATTACK_DAMAGE, to_enemy.normalized() * 220.0)

func _try_dash() -> void:
	if _dash_cd > 0.0:
		return
	_dash_cd = DASH_COOLDOWN
	_dash_time = DASH_TIME
	_invincible = DASH_TIME + 0.05

func take_damage(dmg: float) -> void:
	if _invincible > 0.0:
		return
	hp = maxf(hp - dmg, 0.0)
	_hit_flash = 0.2
	_invincible = 0.4
	hp_changed.emit(hp, max_hp)
	if hp <= 0.0:
		_respawn()

func _respawn() -> void:
	hp = max_hp
	position = Vector2.ZERO
	velocity = Vector2.ZERO
	hp_changed.emit(hp, max_hp)
	print("[原型] 你被打倒了——原地复活（正式版将接入存档/重生点）")

func _draw() -> void:
	# 影子
	draw_circle(Vector2(2, 14), 16.0, Color(0.2, 0.2, 0.22, 0.18))
	# 身体（墨色；受击闪红）
	var body := Color(0.12, 0.12, 0.15)
	if _hit_flash > 0.0:
		body = Color(0.62, 0.15, 0.14)
	draw_circle(Vector2.ZERO, 16.0, body)
	# 发髻（淡墨）
	draw_circle(Vector2(-3, -9), 9.0, Color(0.32, 0.32, 0.38))
	# 兵器笔触（指向朝向）
	var dir := facing.normalized()
	draw_line(dir * 12.0, dir * 34.0, Color(0.16, 0.16, 0.2), 4.0, true)
	# 印章红点缀
	draw_circle(Vector2(9, 6), 4.0, Color(0.78, 0.16, 0.15))
	# 刀光
	if _slash_time > 0.0:
		var aim := facing.angle()
		var sweep := deg_to_rad(ATTACK_ARC_DEG)
		draw_arc(Vector2.ZERO, 58.0, aim - sweep * 0.5, aim + sweep * 0.5, 28, Color(0.96, 0.94, 0.88, 0.9), 7.0, true)
		draw_arc(Vector2.ZERO, 66.0, aim - sweep * 0.42, aim + sweep * 0.42, 24, Color(0.12, 0.12, 0.15, 0.35), 3.0, true)
	# 闪避残影圈
	if _dash_time > 0.0:
		draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 32, Color(0.78, 0.16, 0.15, 0.5), 2.0, true)
