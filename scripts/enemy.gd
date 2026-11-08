extends CharacterBody2D
## 敌人原型（像素小人）：徘徊 → 追击 → 近身攻击
## 渲染：16x16 逻辑px 精灵（4 帧行走，技能动画规范）+ 落影 + 头顶血条

const EffectScript := preload("res://scripts/effect.gd")
const SlashEffect := preload("res://scripts/slash_effect.gd")

var max_hp := 60.0
var hp := 60.0
var speed := 130.0
var aggro_range := 420.0
var attack_range := 52.0
var attack_damage := 10.0
var attack_interval := 1.2

var player: Node2D
var xp := 20                  # 击败经验（D-029）
var base_damage := 10.0
var base_speed := 130.0
var _spr: Sprite2D
var _attack_cd := 0.0
var _hit_flash := 0.0
var _anim_t := 0.0
var _wander_time := 0.0
var _wander_dir := Vector2.ZERO
var _knockback := Vector2.ZERO

func _ready() -> void:
	add_to_group("enemies")
	_spr = Sprite2D.new()
	_spr.texture = load("res://assets/actors/brigand.png")
	_spr.hframes = 4
	_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_spr.offset = Vector2(0, -32)
	add_child(_spr)

func setup(p_player: Node2D, _pos: Vector2, p_hp: float = 60.0) -> void:
	player = p_player
	max_hp = p_hp
	hp = p_hp
	base_damage = attack_damage
	base_speed = speed

## 昼夜强化（D-029）：夜晚敌人更危险
func set_night(n: bool) -> void:
	attack_damage = base_damage * (1.3 if n else 1.0)
	speed = base_speed * (1.15 if n else 1.0)

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

	# 行走动画与朝向（技能：4 帧循环，速度匹配）
	if velocity.length() > 30.0:
		_anim_t += delta
		_spr.frame = int(_anim_t * 8.0) % 4
	else:
		_spr.frame = 0
	if absf(velocity.x) > 8.0:
		_spr.flip_h = velocity.x < 0.0
	_spr.self_modulate = Color(2.2, 0.7, 0.7) if _hit_flash > 0.0 else Color.WHITE
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
	_knockback = (_knockback + knock).limit_length(320.0)  # 限制击退叠加（D-015）
	var fx = SlashEffect.new()
	fx.mode = "hit"
	fx.duration = 0.22
	fx.color_glow = Color(1.0, 0.8, 0.35)
	fx.color_core = Color(1.0, 0.98, 0.9)
	fx.global_position = global_position + Vector2(0, -34)
	get_parent().add_child(fx)
	if hp <= 0.0:
		if is_instance_valid(player) and player.has_method("add_xp"):
			player.add_xp(xp)  # 击败获得经验（D-029）
		queue_free()  # 原型：直接消失（正式版接入掉落/经验）

func _draw() -> void:
	draw_circle(Vector2(0, 2), 13.0, Color(0.18, 0.16, 0.2, 0.28))
	if hp < max_hp:
		draw_rect(Rect2(-22, -78, 44, 5), Color(0.12, 0.12, 0.15, 0.35))
		draw_rect(Rect2(-22, -78, 44.0 * clampf(hp / max_hp, 0.0, 1.0), 5), Color(0.72, 0.18, 0.16))
