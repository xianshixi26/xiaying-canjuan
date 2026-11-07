extends CharacterBody2D
## 玩家控制器（原型 v0.2）：基础动作 + 组合招式引擎 + 内力
## 基础键：J攻 / K破 / L闪 / U御（按住）/ I气（PRD §2.1 草案键位）
## 组合：按键序列在时间窗口内命中招式表即触发（见 move_database.gd）
## 渲染：水墨占位——墨色形体 + 印章红点缀

signal hp_changed(hp: float, max_hp: float)
signal mp_changed(mp: float, max_mp: float)

const MoveDB := preload("res://scripts/move_database.gd")
const ComboSystem := preload("res://scripts/combo_system.gd")
const ProjectileScript := preload("res://scripts/projectile.gd")

const SPEED := 260.0
const ACCEL := 2000.0
const FRICTION := 2400.0

const ATTACK_RANGE := 82.0
const ATTACK_ARC_DEG := 110.0
const ATTACK_DAMAGE := 20.0
const ATTACK_KNOCK := 180.0
const ATTACK_COOLDOWN := 0.3

const HEAVY_RANGE := 96.0
const HEAVY_ARC_DEG := 140.0
const HEAVY_DAMAGE := 32.0
const HEAVY_KNOCK := 260.0
const HEAVY_COOLDOWN := 0.6

const DASH_SPEED := 680.0
const DASH_TIME := 0.16
const DASH_COOLDOWN := 0.55

const BLOCK_SPEED_RATIO := 0.45
const BLOCK_DAMAGE_RATIO := 0.3

const QI_COST := 20.0
const QI_DAMAGE := 25.0
const QI_KNOCK := 160.0
const QI_COOLDOWN := 0.45

const MP_REGEN := 12.0
const ARENA_HALF := Vector2(760.0, 520.0)

var max_hp := 100.0
var hp := 100.0
var max_mp := 100.0
var mp := 100.0
var facing := Vector2.RIGHT

var hud: Node = null
var move_list: Array = []     # 招式数据（供 HUD 武学图鉴）
var discovered := {}          # 已领悟招式 id -> true

var _combo = null
var _attack_cd := 0.0
var _heavy_cd := 0.0
var _dash_cd := 0.0
var _qi_cd := 0.0
var _dash_time := 0.0
var _slash_time := 0.0
var _heavy_time := 0.0
var _invincible := 0.0
var _hit_flash := 0.0

func _ready() -> void:
	move_list = MoveDB.get_moves()
	_combo = ComboSystem.new(move_list)

func _physics_process(delta: float) -> void:
	_attack_cd = maxf(_attack_cd - delta, 0.0)
	_heavy_cd = maxf(_heavy_cd - delta, 0.0)
	_dash_cd = maxf(_dash_cd - delta, 0.0)
	_qi_cd = maxf(_qi_cd - delta, 0.0)
	_dash_time = maxf(_dash_time - delta, 0.0)
	_slash_time = maxf(_slash_time - delta, 0.0)
	_heavy_time = maxf(_heavy_time - delta, 0.0)
	_invincible = maxf(_invincible - delta, 0.0)
	_hit_flash = maxf(_hit_flash - delta, 0.0)
	_combo.tick(delta)
	mp = minf(mp + MP_REGEN * delta, max_mp)

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var blocking := Input.is_action_pressed("block")

	if _dash_time > 0.0:
		_dash_time -= delta
		velocity = facing * DASH_SPEED
	elif input_dir != Vector2.ZERO:
		facing = input_dir.normalized()
		var speed := SPEED * (BLOCK_SPEED_RATIO if blocking else 1.0)
		velocity = velocity.move_toward(input_dir * speed, ACCEL * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	move_and_slide()
	position = position.clamp(-ARENA_HALF, ARENA_HALF)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		var move = _combo.push_action("attack")
		if _attack_cd <= 0.0 and _dash_time <= 0.0:
			_attack_cd = ATTACK_COOLDOWN
			_slash_time = 0.18
			_hit_enemies(ATTACK_RANGE, ATTACK_ARC_DEG, ATTACK_DAMAGE, ATTACK_KNOCK)
		_resolve_move(move)
	elif event.is_action_pressed("heavy"):
		var move = _combo.push_action("heavy")
		if _heavy_cd <= 0.0:
			_heavy_cd = HEAVY_COOLDOWN
			_heavy_time = 0.25
			_hit_enemies(HEAVY_RANGE, HEAVY_ARC_DEG, HEAVY_DAMAGE, HEAVY_KNOCK)
		_resolve_move(move)
	elif event.is_action_pressed("dodge"):
		var move = _combo.push_action("dodge")
		_try_dash()
		_resolve_move(move)
	elif event.is_action_pressed("qi"):
		var move = _combo.push_action("qi")
		if not _resolve_move(move):
			_basic_qi()
	elif event.is_action_pressed("block"):
		_combo.push_action("block")

## 执行组合命中效果；返回 true 表示有招式被消耗/施展
func _resolve_move(move: Dictionary) -> bool:
	if move.is_empty():
		return false
	if float(move["cost"]) > 0.0:
		if mp < float(move["cost"]):
			_hint("内力不足，无法施展【%s】" % str(move["name"]))
			return true
		mp -= float(move["cost"])
	# 领悟 / 重复施展提示
	if not discovered.has(str(move["id"])):
		discovered[str(move["id"])] = true
		_hint("✦ 领悟新招式：%s（%s）" % [str(move["name"]), MoveDB.seq_text(move["seq"])])
	else:
		_hint("▸ %s！" % str(move["name"]))
	# 效果
	match str(move["kind"]):
		"projectile":
			if _qi_cd > 0.0:
				return true
			_qi_cd = QI_COOLDOWN
			_spawn_projectile(float(move["damage"]), float(move["knock"]))
		_:
			_hit_enemies(float(move["range"]), float(move["arc"]), float(move["damage"]), float(move["knock"]), float(move["dash"]))
	return true

func _basic_qi() -> void:
	if _qi_cd > 0.0:
		return
	if mp < QI_COST:
		_hint("内力不足")
		return
	mp -= QI_COST
	_qi_cd = QI_COOLDOWN
	_spawn_projectile(QI_DAMAGE, QI_KNOCK)

func _spawn_projectile(damage: float, knock: float) -> void:
	var proj = ProjectileScript.new()
	proj.setup(facing.normalized(), damage, knock, global_position + facing.normalized() * 30.0)
	get_parent().add_child(proj)

func _try_dash() -> void:
	if _dash_cd > 0.0:
		return
	_dash_cd = DASH_COOLDOWN
	_dash_time = DASH_TIME
	_invincible = DASH_TIME + 0.05

## 扇形命中判定
func _hit_enemies(range: float, arc_deg: float, damage: float, knock: float, dash: float = 0.0) -> void:
	if dash > 0.0:
		velocity = facing * dash
	var aim := facing.angle()
	var half := deg_to_rad(arc_deg * 0.5)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var to_enemy: Vector2 = enemy.global_position - global_position
		if to_enemy.length() > range:
			continue
		if arc_deg >= 360.0 or absf(wrapf(to_enemy.angle() - aim, -PI, PI)) <= half:
			enemy.take_damage(damage, to_enemy.normalized() * knock)

func take_damage(dmg: float) -> void:
	if _invincible > 0.0:
		return
	var blocked := Input.is_action_pressed("block")
	var final := dmg * (BLOCK_DAMAGE_RATIO if blocked else 1.0)
	hp = maxf(hp - final, 0.0)
	_hit_flash = 0.2
	_invincible = 0.4
	if blocked:
		_hint("格挡！伤害减免")
	hp_changed.emit(hp, max_hp)
	if hp <= 0.0:
		_respawn()

func _respawn() -> void:
	hp = max_hp
	mp = max_mp
	position = Vector2.ZERO
	velocity = Vector2.ZERO
	hp_changed.emit(hp, max_hp)
	print("[原型] 你被打倒了——原地复活（正式版将接入存档/重生点）")

func _hint(text: String) -> void:
	if hud != null and hud.has_method("show_hint"):
		hud.show_hint(text)

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
	# 轻击刀光
	if _slash_time > 0.0:
		var aim := facing.angle()
		var sweep := deg_to_rad(ATTACK_ARC_DEG)
		draw_arc(Vector2.ZERO, 58.0, aim - sweep * 0.5, aim + sweep * 0.5, 28, Color(0.96, 0.94, 0.88, 0.9), 7.0, true)
		draw_arc(Vector2.ZERO, 66.0, aim - sweep * 0.42, aim + sweep * 0.42, 24, Color(0.12, 0.12, 0.15, 0.35), 3.0, true)
	# 重击刀光（宽）
	if _heavy_time > 0.0:
		var aim2 := facing.angle()
		var sweep2 := deg_to_rad(HEAVY_ARC_DEG)
		draw_arc(Vector2.ZERO, 72.0, aim2 - sweep2 * 0.5, aim2 + sweep2 * 0.5, 30, Color(0.78, 0.16, 0.15, 0.55), 9.0, true)
	# 格挡架势
	if Input.is_action_pressed("block"):
		var aim3 := facing.angle()
		draw_arc(Vector2.ZERO, 30.0, aim3 - 1.2, aim3 + 1.2, 20, Color(0.28, 0.38, 0.52, 0.85), 6.0, true)
	# 闪避残影圈
	if _dash_time > 0.0:
		draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 32, Color(0.78, 0.16, 0.15, 0.5), 2.0, true)
