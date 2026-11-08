extends CharacterBody2D
## 玩家控制器（原型 v0.3）：基础动作 + 武器系统 + 组合招式引擎 + 内力
## 基础键：J攻 / K破 / L闪 / U御（按住）/ I气 ｜ 1-5 切换武器（正式版由拾取/装备驱动）
## 组合：按键序列在时间窗口内命中当前武器的招式表即触发（D-016 武器-招式绑定）
## 渲染：水墨占位——墨色形体 + 印章红点缀

signal hp_changed(hp: float, max_hp: float)
signal mp_changed(mp: float, max_mp: float)

const MoveDB := preload("res://scripts/move_database.gd")
const ComboSystem := preload("res://scripts/combo_system.gd")
const ProjectileScript := preload("res://scripts/projectile.gd")
const EffectScript := preload("res://scripts/effect.gd")
const SlashEffect := preload("res://scripts/slash_effect.gd")

const SPEED := 260.0
const ACCEL := 2000.0
const FRICTION := 2400.0

const DASH_SPEED := 680.0
const DASH_TIME := 0.16
const DASH_COOLDOWN := 0.55

const BLOCK_SPEED_RATIO := 0.45
const BLOCK_DAMAGE_RATIO := 0.3

const MP_REGEN := 12.0

var arena_half := Vector2(760.0, 520.0)  # 场地边界（由地图构建器注入）

var max_hp := 100.0
var hp := 100.0
var max_mp := 100.0
var mp := 100.0
var facing := Vector2.RIGHT

var hud: Node = null
var weapon_list: Array = []   # 全部武器
var weapon: Dictionary = {}   # 当前武器
var weapon_idx := 0
var weapon_unlocked := {"sword": true}  # 初始仅剑，其余靠宝箱/调查点（D-023）
var move_list: Array = []     # 当前武器招式组（供 HUD 武学图鉴）
var discovered := {}          # 已领悟招式 id -> true
# ---- 属性/命格/背包/连招链（D-028）----
var stats := {"力道": 5, "身法": 5, "根骨": 5, "悟性": 5, "内力": 5, "气运": 5}
var mingge := "未定命格"
var inventory := {"potion": 2, "ether": 1, "herb": 0, "iron": 0}
const ITEMS := {"potion": "金疮药", "ether": "回气散", "herb": "草药", "iron": "玄铁"}
var chains := {}              # 武器id -> Array[招式id]
var _chain_idx := 0
var _chain_timer := 0.0

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
var _spr: Sprite2D = null
var _w_spr: Sprite2D = null
var _anim_t := 0.0

func _ready() -> void:
	weapon_list = MoveDB.get_weapons()
	_combo = ComboSystem.new([])
	_spr = Sprite2D.new()
	_spr.texture = load("res://assets/actors/hero.png")
	_spr.hframes = 4
	_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_spr.offset = Vector2(0, -32)
	add_child(_spr)
	_w_spr = Sprite2D.new()  # 手持武器模型（D-023）
	_w_spr.texture = load("res://assets/actors/weapons.png")
	_w_spr.hframes = 5
	_w_spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(_w_spr)
	set_weapon(0)
	refresh_derived()
	hp = max_hp
	mp = max_mp

# ================= 属性/命格/背包/连招链（D-028） =================

func refresh_derived() -> void:
	max_hp = 100.0 + float(stats["根骨"]) * 5.0
	max_mp = 100.0 + float(stats["内力"]) * 5.0
	hp = minf(hp, max_hp)
	mp = minf(mp, max_mp)

func apply_mingge(m: Dictionary) -> void:
	mingge = str(m["name"])
	var mods: Dictionary = m["mods"]
	for k in mods.keys():
		stats[k] = int(stats[k]) + int(mods[k])
	refresh_derived()
	hp = max_hp
	mp = max_mp

func use_item(id: String) -> void:
	if int(inventory.get(id, 0)) <= 0:
		_hint("没有【%s】了" % str(ITEMS.get(id, id)))
		return
	inventory[id] = int(inventory[id]) - 1
	match id:
		"potion":
			hp = minf(hp + 50.0, max_hp)
			_hint("服用【金疮药】：气血 +50")
		"ether":
			mp = minf(mp + 50.0, max_mp)
			_hint("服用【回气散】：内力 +50")
		_:
			_hint("获得材料：" + str(ITEMS.get(id, id)))
	hp_changed.emit(hp, max_hp)

func add_item(id: String, n: int) -> void:
	inventory[id] = int(inventory.get(id, 0)) + n

func chain_append(move_id: String) -> void:
	var wid := str(weapon["id"])
	if not chains.has(wid):
		chains[wid] = []
	var arr: Array = chains[wid]
	if arr.size() >= 5:
		_hint("连招链已满（5 段）")
		return
	arr.append(move_id)
	_hint("连招链 +【%s】" % str(MoveDB.move_by_id(move_id).get("name", move_id)))

func chain_pop() -> void:
	var arr: Array = chains.get(str(weapon["id"]), [])
	if arr.size() > 0:
		arr.pop_back()

func chain_clear() -> void:
	chains[str(weapon["id"])] = []

func chain_exec() -> void:
	var arr: Array = chains.get(str(weapon["id"]), [])
	if arr.is_empty():
		_hint("尚未编排连招链（按 V 编排）")
		return
	if _chain_timer <= 0.0:
		_chain_idx = 0
	_chain_timer = 3.0
	var mid: String = str(arr[_chain_idx % arr.size()])
	_chain_idx += 1
	var mv := MoveDB.move_by_id(mid)
	if not mv.is_empty():
		_resolve_move(mv)

## 切换武器：更换招式组与基础攻击参数（D-016）；未解锁武器不可用（D-023）
func set_weapon(idx: int) -> void:
	if weapon_list.is_empty():
		return
	var i := clampi(idx, 0, weapon_list.size() - 1)
	var wid := str(weapon_list[i]["id"])
	if not bool(weapon_unlocked.get(wid, false)):
		_hint("尚未获得该武器（探索宝箱/调查点获取）")
		return
	weapon_idx = i
	weapon = weapon_list[i]
	move_list = MoveDB.moves_for(wid)
	_combo.set_moves(move_list)
	_attack_cd = 0.0
	_heavy_cd = 0.0
	if _w_spr != null:
		_w_spr.frame = i
	if hud != null:
		hud.move_list = move_list
	if not weapon.is_empty():
		_hint("切换武器：%s（%s）——招式组已改变" % [str(weapon["name"]), str(weapon["type"])])

## 解锁并立即装备武器（宝箱/调查点获得时调用）
func grant_weapon(wid: String) -> void:
	weapon_unlocked[wid] = true
	for i in weapon_list.size():
		if str(weapon_list[i]["id"]) == wid:
			set_weapon(i)
			return

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
	_chain_timer = maxf(_chain_timer - delta, 0.0)
	_combo.tick(delta)
	mp = minf(mp + MP_REGEN * delta, max_mp)

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var blocking := Input.is_action_pressed("block")

	if _dash_time > 0.0:
		_dash_time -= delta
		velocity = facing * DASH_SPEED
	elif input_dir != Vector2.ZERO:
		facing = input_dir.normalized()
		var speed := SPEED * (1.0 + float(stats["身法"]) * 0.012) * (BLOCK_SPEED_RATIO if blocking else 1.0)
		velocity = velocity.move_toward(input_dir * speed, ACCEL * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)

	move_and_slide()
	position = position.clamp(-arena_half, arena_half)
	# 行走动画与朝向（技能：4 帧行走循环）
	if velocity.length() > 30.0:
		_anim_t += delta
		_spr.frame = int(_anim_t * 8.0) % 4
	else:
		_spr.frame = 0
	if absf(facing.x) > 0.15:
		_spr.flip_h = facing.x < 0.0
	_spr.self_modulate = Color(2.2, 0.7, 0.7) if _hit_flash > 0.0 else Color.WHITE
	if _w_spr != null:
		# 手持武器：常态在手侧；攻击时沿弧线挥舞（2px 量化保持像素感，D-024）
		var swing := 0.0
		var remain := maxf(_slash_time, _heavy_time)
		if remain > 0.0:
			var total := 0.25 if _heavy_time > 0.0 else 0.18
			var t := 1.0 - clampf(remain / total, 0.0, 1.0)
			swing = lerpf(-1.15, 1.15, t)
		var w_ang := facing.angle() + swing
		var w_off := Vector2(cos(w_ang), sin(w_ang)) * 22.0 + Vector2(0, -12)
		_w_spr.offset = (w_off / 2.0).round() * 2.0
		_w_spr.flip_h = facing.x < 0.0
		_w_spr.self_modulate = _spr.self_modulate
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		var move = _combo.push_action("attack")
		if _attack_cd <= 0.0 and _dash_time <= 0.0:
			_attack_cd = float(weapon["atk_cd"])
			_slash_time = 0.18
			_spawn_slash(false)
			if str(weapon["atk_kind"]) == "ranged":
				_spawn_projectile(facing, float(weapon["atk_damage"]), float(weapon["atk_knock"]))
			else:
				_hit_enemies(float(weapon["atk_range"]), float(weapon["atk_arc"]), float(weapon["atk_damage"]), float(weapon["atk_knock"]))
		_resolve_move(move)
	elif event.is_action_pressed("heavy"):
		var move = _combo.push_action("heavy")
		if _heavy_cd <= 0.0:
			_heavy_cd = float(weapon["heavy_cd"])
			_heavy_time = 0.25
			_spawn_slash(true)
			if str(weapon["heavy_kind"]) == "ranged":
				_spawn_projectile(facing, float(weapon["heavy_damage"]), float(weapon["heavy_knock"]))
			else:
				_hit_enemies(float(weapon["heavy_range"]), float(weapon["heavy_arc"]), float(weapon["heavy_damage"]), float(weapon["heavy_knock"]))
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
	elif event.is_action_pressed("chain_exec"):
		chain_exec()
	elif event.is_action_pressed("use_potion"):
		use_item("potion")
	elif event.is_action_pressed("use_ether"):
		use_item("ether")
	elif event.is_action_pressed("slot_1"):
		set_weapon(0)
	elif event.is_action_pressed("slot_2"):
		set_weapon(1)
	elif event.is_action_pressed("slot_3"):
		set_weapon(2)
	elif event.is_action_pressed("slot_4"):
		set_weapon(3)
	elif event.is_action_pressed("slot_5"):
		set_weapon(4)

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
	# 位移效果（负值=后撤）
	if float(move["dash"]) != 0.0:
		velocity = facing * float(move["dash"])
	# 伤害效果
	match str(move["kind"]):
		"projectile":
			if _qi_cd > 0.0:
				return true
			_qi_cd = QI_CD
			_spawn_projectile(facing, float(move["damage"]), float(move["knock"]))
		"spread":
			if _qi_cd > 0.0:
				return true
			_qi_cd = QI_CD
			_spawn_spread(move)
		_:
			if str(move["kind"]) == "burst" or float(move["damage"]) >= 40.0:
				_spawn_burst()
			_hit_enemies(float(move["range"]), float(move["arc"]), float(move["damage"]), float(move["knock"]))
	return true

## 武器光色（D-025：剑光配色随武器）
func _weapon_glow() -> Color:
	match str(weapon.get("type", "剑")):
		"刀":
			return Color(1.0, 0.55, 0.3)
		"拳掌":
			return Color(1.0, 0.85, 0.45)
		"暗器":
			return Color(0.6, 1.0, 0.7)
		"棍":
			return Color(0.85, 0.7, 1.0)
	return Color(0.65, 0.82, 1.0)

## 剑光扫弧（轻击窄弧 / 重击宽弧红光）
func _spawn_slash(heavy: bool) -> void:
	var fx = SlashEffect.new()
	fx.mode = "slash"
	fx.base_angle = facing.angle()
	fx.radius = 92.0 if heavy else 76.0
	fx.sweep = 1.5 if heavy else 1.2
	fx.duration = 0.3 if heavy else 0.24
	fx.color_glow = Color(1.0, 0.42, 0.22) if heavy else _weapon_glow()
	fx.color_core = Color(1.0, 0.96, 0.88)
	fx.global_position = global_position
	get_parent().add_child(fx)

func _spawn_burst() -> void:
	var fx = SlashEffect.new()
	fx.mode = "burst"
	fx.duration = 0.32
	fx.color_glow = _weapon_glow()
	fx.color_core = Color(1.0, 0.96, 0.88)
	fx.global_position = global_position
	get_parent().add_child(fx)

const QI_CD := 0.45

func _basic_qi() -> void:
	if _qi_cd > 0.0:
		return
	_qi_cd = QI_CD
	_spawn_projectile(facing, 25.0, 160.0)

func _spawn_projectile(dir: Vector2, damage: float, knock: float) -> void:
	var proj = ProjectileScript.new()
	proj.setup(dir.normalized(), damage, knock, global_position + dir.normalized() * 30.0)
	get_parent().add_child(proj)

func _spawn_spread(move: Dictionary) -> void:
	var count := int(move.get("projectiles", 3))
	for i in count:
		var t := 0.0 if count <= 1 else (float(i) / float(count - 1) - 0.5) * 1.0
		_spawn_projectile(facing.rotated(t), float(move["damage"]), float(move["knock"]))

func _try_dash() -> void:
	if _dash_cd > 0.0:
		return
	_dash_cd = DASH_COOLDOWN
	_dash_time = DASH_TIME
	_invincible = DASH_TIME + 0.05

## 扇形命中判定（力道加成，D-028）
func _hit_enemies(range: float, arc_deg: float, damage: float, knock: float, dash: float = 0.0) -> void:
	damage *= 1.0 + float(stats["力道"]) * 0.02
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
	# 落影（角色本体为像素精灵，见 _ready）
	draw_circle(Vector2(0, 2), 13.0, Color(0.18, 0.16, 0.2, 0.28))
	# 轻击刀光
	if _slash_time > 0.0:
		var aim := facing.angle()
		var sweep := deg_to_rad(float(weapon.get("atk_arc", 110.0)))
		draw_arc(Vector2.ZERO, 58.0, aim - sweep * 0.5, aim + sweep * 0.5, 28, Color(0.96, 0.94, 0.88, 0.9), 7.0, true)
		draw_arc(Vector2.ZERO, 66.0, aim - sweep * 0.42, aim + sweep * 0.42, 24, Color(0.12, 0.12, 0.15, 0.35), 3.0, true)
	# 重击刀光（宽）
	if _heavy_time > 0.0:
		var aim2 := facing.angle()
		var sweep2 := deg_to_rad(float(weapon.get("heavy_arc", 140.0)))
		draw_arc(Vector2.ZERO, 72.0, aim2 - sweep2 * 0.5, aim2 + sweep2 * 0.5, 30, Color(0.78, 0.16, 0.15, 0.55), 9.0, true)
	# 格挡架势
	if Input.is_action_pressed("block"):
		var aim3 := facing.angle()
		draw_arc(Vector2.ZERO, 30.0, aim3 - 1.2, aim3 + 1.2, 20, Color(0.28, 0.38, 0.52, 0.85), 6.0, true)
	# 闪避残影圈
	if _dash_time > 0.0:
		draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 32, Color(0.78, 0.16, 0.15, 0.5), 2.0, true)
