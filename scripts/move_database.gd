extends RefCounted
## 招式数据库（原型 v0.2）
## 字段：
##   seq     = 基础动作序列（attack攻 / heavy破 / dodge闪 / block御 / qi气）
##   kind    = melee 近战爆发 / projectile 剑气 / burst 周身爆发
##   damage  = 组合命中时的伤害；knock = 击退；dash = 突进速度；cost = 内力消耗
##   manual  = true 表示需秘籍解锁（秘籍系统接入后启用；当前全部可"摸索领悟"）

static func get_moves() -> Array:
	return [
		{
			"id": "san_lian_zhan", "name": "三连斩",
			"seq": ["attack", "attack", "attack"], "kind": "melee",
			"damage": 26.0, "range": 92.0, "arc": 130.0, "knock": 160.0, "dash": 160.0,
			"cost": 0.0, "tier": "低阶", "manual": false,
			"desc": "连续三击收势，向前突进补刀",
		},
		{
			"id": "tiao_shan", "name": "挑山式",
			"seq": ["attack", "attack", "heavy"], "kind": "melee",
			"damage": 42.0, "range": 100.0, "arc": 120.0, "knock": 300.0, "dash": 0.0,
			"cost": 0.0, "tier": "中阶", "manual": false,
			"desc": "连击转重击，大力挑飞",
		},
		{
			"id": "duan_yue", "name": "断岳",
			"seq": ["heavy", "attack"], "kind": "melee",
			"damage": 30.0, "range": 110.0, "arc": 180.0, "knock": 220.0, "dash": 0.0,
			"cost": 0.0, "tier": "低阶", "manual": false,
			"desc": "重击开路，横扫大范围",
		},
		{
			"id": "zhui_ying_ci", "name": "追影刺",
			"seq": ["dodge", "attack"], "kind": "melee",
			"damage": 46.0, "range": 120.0, "arc": 60.0, "knock": 180.0, "dash": 320.0,
			"cost": 0.0, "tier": "中阶", "manual": false,
			"desc": "闪身后突刺，单点高伤",
		},
		{
			"id": "hui_feng", "name": "防反·回风拂柳",
			"seq": ["block", "attack"], "kind": "melee",
			"damage": 38.0, "range": 100.0, "arc": 200.0, "knock": 240.0, "dash": 0.0,
			"cost": 0.0, "tier": "中阶", "manual": false,
			"desc": "架势未收即出剑，以守为攻",
		},
		{
			"id": "jian_qi", "name": "剑气纵横",
			"seq": ["qi"], "kind": "projectile",
			"damage": 25.0, "range": 0.0, "arc": 0.0, "knock": 160.0, "dash": 0.0,
			"cost": 20.0, "tier": "低阶", "manual": false,
			"desc": "剑气离体，远程打击",
		},
		{
			"id": "cangming_yixian", "name": "终结·沧溟一现",
			"seq": ["attack", "heavy", "qi"], "kind": "burst",
			"damage": 62.0, "range": 150.0, "arc": 360.0, "knock": 320.0, "dash": 0.0,
			"cost": 40.0, "tier": "高阶", "manual": false,
			"desc": "残卷所载绝学一击，周身爆发",
		},
	]

## 把输入序列翻译成按键提示文本，如 ["attack","attack","heavy"] → "攻-攻-破"
static func seq_text(seq: Array) -> String:
	var names := {"attack": "攻", "heavy": "破", "dodge": "闪", "block": "御", "qi": "气"}
	var out := ""
	for i in seq.size():
		if i > 0:
			out += "-"
		out += str(names.get(seq[i], seq[i]))
	return out
