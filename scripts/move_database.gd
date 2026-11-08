extends RefCounted
## 招式数据库（原型 v0.3）：武器 + 招式组（D-016 武器-招式绑定）
##
## 武器字段：atk_kind/heavy_kind = melee 近战扇形 / ranged 远程弹道；
##           atk_* / heavy_* = 基础攻击（轻击/重击）参数。
## 招式字段：seq = 基础动作序列（attack攻 / heavy破 / dodge闪 / block御 / qi气）；
##           kind = melee 近战爆发 / projectile 弹道 / spread 扇形弹幕 / burst 周身爆发；
##           damage/knock/dash/cost/projectiles = 效果参数；
##           manual = true 表示需秘籍解锁（秘籍系统接入后启用；当前全部可"摸索领悟"）。

static func get_weapons() -> Array:
	return [
		{
			"id": "sword", "name": "青锋剑", "type": "剑", "desc": "攻守均衡",
			"atk_kind": "melee", "atk_damage": 20.0, "atk_range": 82.0, "atk_arc": 110.0, "atk_knock": 180.0, "atk_cd": 0.3,
			"heavy_kind": "melee", "heavy_damage": 32.0, "heavy_range": 96.0, "heavy_arc": 140.0, "heavy_knock": 260.0, "heavy_cd": 0.6,
		},
		{
			"id": "saber", "name": "雁翎刀", "type": "刀", "desc": "刚猛高伤，出手偏慢",
			"atk_kind": "melee", "atk_damage": 26.0, "atk_range": 90.0, "atk_arc": 130.0, "atk_knock": 220.0, "atk_cd": 0.38,
			"heavy_kind": "melee", "heavy_damage": 42.0, "heavy_range": 110.0, "heavy_arc": 160.0, "heavy_knock": 300.0, "heavy_cd": 0.75,
		},
		{
			"id": "fist", "name": "铁砂掌", "type": "拳掌", "desc": "贴身快打，出手最快",
			"atk_kind": "melee", "atk_damage": 14.0, "atk_range": 70.0, "atk_arc": 90.0, "atk_knock": 120.0, "atk_cd": 0.2,
			"heavy_kind": "melee", "heavy_damage": 26.0, "heavy_range": 80.0, "heavy_arc": 110.0, "heavy_knock": 220.0, "heavy_cd": 0.5,
		},
		{
			"id": "dart", "name": "透骨钉", "type": "暗器", "desc": "远程压制，近身乏力",
			"atk_kind": "ranged", "atk_damage": 12.0, "atk_range": 0.0, "atk_arc": 0.0, "atk_knock": 100.0, "atk_cd": 0.25,
			"heavy_kind": "ranged", "heavy_damage": 22.0, "heavy_range": 0.0, "heavy_arc": 0.0, "heavy_knock": 180.0, "heavy_cd": 0.5,
		},
		{
			"id": "staff", "name": "齐眉棍", "type": "棍", "desc": "大范围控场",
			"atk_kind": "melee", "atk_damage": 18.0, "atk_range": 100.0, "atk_arc": 140.0, "atk_knock": 200.0, "atk_cd": 0.34,
			"heavy_kind": "melee", "heavy_damage": 30.0, "heavy_range": 120.0, "heavy_arc": 180.0, "heavy_knock": 280.0, "heavy_cd": 0.65,
		},
	]

static func get_moves() -> Array:
	return [
		# ===== 剑：均衡 =====
		{"id": "j_sanzhan", "weapon": "sword", "name": "三连斩", "seq": ["attack", "attack", "attack"], "kind": "melee",
			"damage": 26.0, "range": 92.0, "arc": 130.0, "knock": 160.0, "dash": 160.0, "cost": 0.0, "tier": "低阶", "manual": false,
			"desc": "连续三击收势，向前突进补刀"},
		{"id": "j_zhuiying", "weapon": "sword", "name": "追影刺", "seq": ["dodge", "attack"], "kind": "melee",
			"damage": 46.0, "range": 120.0, "arc": 60.0, "knock": 180.0, "dash": 320.0, "cost": 0.0, "tier": "中阶", "manual": false,
			"desc": "闪身后突刺，单点高伤"},
		{"id": "j_huifeng", "weapon": "sword", "name": "防反·回风拂柳", "seq": ["block", "attack"], "kind": "melee",
			"damage": 38.0, "range": 100.0, "arc": 200.0, "knock": 240.0, "dash": 0.0, "cost": 0.0, "tier": "中阶", "manual": false,
			"desc": "架势未收即出剑，以守为攻"},
		{"id": "j_jianqi", "weapon": "sword", "name": "剑气纵横", "seq": ["qi"], "kind": "projectile",
			"damage": 25.0, "range": 0.0, "arc": 0.0, "knock": 160.0, "dash": 0.0, "cost": 20.0, "tier": "低阶", "manual": false,
			"desc": "剑气离体，远程打击"},
		{"id": "j_cangming", "weapon": "sword", "name": "终结·沧溟一现", "seq": ["attack", "heavy", "qi"], "kind": "burst",
			"damage": 62.0, "range": 150.0, "arc": 360.0, "knock": 320.0, "dash": 0.0, "cost": 40.0, "tier": "高阶", "manual": false,
			"desc": "残卷所载绝学一击，周身爆发"},
		{"id": "j_liao", "weapon": "sword", "name": "撩剑式", "seq": ["heavy", "attack"], "kind": "melee",
			"damage": 36.0, "range": 96.0, "arc": 130.0, "knock": 260.0, "dash": 0.0, "cost": 0.0, "tier": "低阶", "manual": false,
			"desc": "反手撩剑，挑飞来敌"},
		{"id": "j_huifeng_luo", "weapon": "sword", "name": "回风落雁", "seq": ["attack", "dodge"], "kind": "melee",
			"damage": 30.0, "range": 110.0, "arc": 200.0, "knock": 180.0, "dash": -280.0, "cost": 0.0, "tier": "中阶", "manual": false,
			"desc": "旋身回斩，向后撤步脱身"},
		{"id": "j_yanfan", "weapon": "sword", "name": "燕返", "seq": ["dodge", "heavy"], "kind": "melee",
			"damage": 44.0, "range": 120.0, "arc": 150.0, "knock": 240.0, "dash": -200.0, "cost": 0.0, "tier": "中阶", "manual": false,
			"desc": "闪身错步，反手重斩"},
		{"id": "j_pokong", "weapon": "sword", "name": "破空剑气", "seq": ["heavy", "qi"], "kind": "projectile",
			"damage": 48.0, "range": 0.0, "arc": 0.0, "knock": 200.0, "dash": 0.0, "cost": 25.0, "tier": "高阶", "manual": false,
			"desc": "凝气成剑，贯穿远敌"},
		{"id": "j_yuqi", "weapon": "sword", "name": "御气剑阵", "seq": ["block", "qi"], "kind": "burst",
			"damage": 34.0, "range": 130.0, "arc": 360.0, "knock": 300.0, "dash": 0.0, "cost": 30.0, "tier": "中阶", "manual": false,
			"desc": "护身剑气震开四周之敌"},

		# ===== 刀：刚猛 =====
		{"id": "d_pishan", "weapon": "saber", "name": "劈山式", "seq": ["attack", "attack", "attack"], "kind": "melee",
			"damage": 34.0, "range": 110.0, "arc": 150.0, "knock": 240.0, "dash": 120.0, "cost": 0.0, "tier": "低阶", "manual": false,
			"desc": "三刀劈落，势大力沉"},
		{"id": "d_tiaoshan", "weapon": "saber", "name": "挑山式", "seq": ["attack", "attack", "heavy"], "kind": "melee",
			"damage": 46.0, "range": 100.0, "arc": 120.0, "knock": 300.0, "dash": 0.0, "cost": 0.0, "tier": "中阶", "manual": false,
			"desc": "连击转重击，大力挑飞"},
		{"id": "d_duanyue", "weapon": "saber", "name": "断岳", "seq": ["heavy", "attack"], "kind": "melee",
			"damage": 34.0, "range": 120.0, "arc": 200.0, "knock": 260.0, "dash": 0.0, "cost": 0.0, "tier": "低阶", "manual": false,
			"desc": "重击开路，横扫大范围"},
		{"id": "d_daofeng", "weapon": "saber", "name": "刀风", "seq": ["qi"], "kind": "projectile",
			"damage": 28.0, "range": 0.0, "arc": 0.0, "knock": 180.0, "dash": 0.0, "cost": 20.0, "tier": "低阶", "manual": false,
			"desc": "刀气破空，远程斩击"},
		{"id": "d_qianjun", "weapon": "saber", "name": "终结·千钧斩", "seq": ["attack", "heavy", "heavy"], "kind": "burst",
			"damage": 70.0, "range": 140.0, "arc": 300.0, "knock": 340.0, "dash": 0.0, "cost": 40.0, "tier": "高阶", "manual": false,
			"desc": "蓄势双劈，千钧之力"},

		# ===== 拳掌：快打 =====
		{"id": "f_lianhuan", "weapon": "fist", "name": "连环掌", "seq": ["attack", "attack", "attack"], "kind": "melee",
			"damage": 22.0, "range": 75.0, "arc": 110.0, "knock": 100.0, "dash": 80.0, "cost": 0.0, "tier": "低阶", "manual": false,
			"desc": "疾风连掌，贴身速攻"},
		{"id": "f_bengquan", "weapon": "fist", "name": "崩拳", "seq": ["heavy", "attack"], "kind": "melee",
			"damage": 30.0, "range": 85.0, "arc": 120.0, "knock": 260.0, "dash": 0.0, "cost": 0.0, "tier": "低阶", "manual": false,
			"desc": "重掌之后一记崩劲"},
		{"id": "f_qinlong", "weapon": "fist", "name": "擒龙手", "seq": ["dodge", "attack"], "kind": "melee",
			"damage": 40.0, "range": 90.0, "arc": 60.0, "knock": 200.0, "dash": 240.0, "cost": 0.0, "tier": "中阶", "manual": false,
			"desc": "欺身擒拿，专破敌势"},
		{"id": "f_zhangfeng", "weapon": "fist", "name": "掌风", "seq": ["qi"], "kind": "projectile",
			"damage": 18.0, "range": 0.0, "arc": 0.0, "knock": 120.0, "dash": 0.0, "cost": 15.0, "tier": "低阶", "manual": false,
			"desc": "劈空掌力，伤敌于丈外"},
		{"id": "f_kaibei", "weapon": "fist", "name": "终结·开碑手", "seq": ["attack", "heavy", "qi"], "kind": "burst",
			"damage": 55.0, "range": 130.0, "arc": 360.0, "knock": 300.0, "dash": 0.0, "cost": 40.0, "tier": "高阶", "manual": false,
			"desc": "掌劲贯地，碑石俱裂"},

		# ===== 暗器：远程 =====
		{"id": "a_manhua", "weapon": "dart", "name": "漫天花雨", "seq": ["attack", "attack", "attack"], "kind": "spread",
			"damage": 18.0, "range": 0.0, "arc": 0.0, "knock": 100.0, "dash": 0.0, "cost": 0.0, "tier": "低阶", "manual": false,
			"projectiles": 3, "desc": "三钉齐发，扇形覆盖"},
		{"id": "a_dujili", "weapon": "dart", "name": "毒蒺藜", "seq": ["heavy", "attack"], "kind": "projectile",
			"damage": 40.0, "range": 0.0, "arc": 0.0, "knock": 160.0, "dash": 0.0, "cost": 0.0, "tier": "中阶", "manual": false,
			"desc": "重钉破甲（毒伤效果后续接入）"},
		{"id": "a_houtiao", "weapon": "dart", "name": "后跃投掷", "seq": ["dodge", "qi"], "kind": "projectile",
			"damage": 30.0, "range": 0.0, "arc": 0.0, "knock": 200.0, "dash": -260.0, "cost": 15.0, "tier": "中阶", "manual": false,
			"desc": "向后跃开，反手一钉"},
		{"id": "a_jinshen", "weapon": "dart", "name": "近身防", "seq": ["block", "attack"], "kind": "melee",
			"damage": 26.0, "range": 90.0, "arc": 180.0, "knock": 220.0, "dash": 0.0, "cost": 0.0, "tier": "低阶", "manual": false,
			"desc": "被近身时肘击脱困"},
		{"id": "a_baoyu", "weapon": "dart", "name": "终结·暴雨梨花", "seq": ["attack", "heavy", "qi"], "kind": "spread",
			"damage": 26.0, "range": 0.0, "arc": 0.0, "knock": 160.0, "dash": 0.0, "cost": 40.0, "tier": "高阶", "manual": false,
			"projectiles": 5, "desc": "五钉齐出，漫天梨花"},

		# ===== 棍：控场 =====
		{"id": "g_hengsao", "weapon": "staff", "name": "横扫千军", "seq": ["attack", "attack", "attack"], "kind": "melee",
			"damage": 30.0, "range": 115.0, "arc": 200.0, "knock": 220.0, "dash": 120.0, "cost": 0.0, "tier": "低阶", "manual": false,
			"desc": "长棍横扫，逼退群敌"},
		{"id": "g_gunya", "weapon": "staff", "name": "棍压", "seq": ["attack", "attack", "heavy"], "kind": "melee",
			"damage": 48.0, "range": 110.0, "arc": 130.0, "knock": 300.0, "dash": 0.0, "cost": 0.0, "tier": "中阶", "manual": false,
			"desc": "棍势如山，当头压下"},
		{"id": "g_yueji", "weapon": "staff", "name": "跃击", "seq": ["dodge", "attack"], "kind": "melee",
			"damage": 44.0, "range": 120.0, "arc": 90.0, "knock": 240.0, "dash": 300.0, "cost": 0.0, "tier": "中阶", "manual": false,
			"desc": "纵身跃起，一棍砸落"},
		{"id": "g_gunhua", "weapon": "staff", "name": "棍花", "seq": ["block", "attack"], "kind": "melee",
			"damage": 36.0, "range": 110.0, "arc": 240.0, "knock": 260.0, "dash": 0.0, "cost": 0.0, "tier": "中阶", "manual": false,
			"desc": "舞棍成花，守中带攻"},
		{"id": "g_dinghai", "weapon": "staff", "name": "终结·定海一击", "seq": ["attack", "heavy", "qi"], "kind": "burst",
			"damage": 66.0, "range": 150.0, "arc": 360.0, "knock": 340.0, "dash": 0.0, "cost": 40.0, "tier": "高阶", "manual": false,
			"desc": "一棍定海，四野俱震"},
	]

## 按武器 id 过滤招式组
static func moves_for(weapon_id: String) -> Array:
	var out: Array = []
	for move in get_moves():
		if str(move["weapon"]) == weapon_id:
			out.append(move)
	return out

## 把输入序列翻译成按键提示文本，如 ["attack","attack","heavy"] → "攻-攻-破"
static func seq_text(seq: Array) -> String:
	var names := {"attack": "攻", "heavy": "破", "dodge": "闪", "block": "御", "qi": "气"}
	var out := ""
	for i in seq.size():
		if i > 0:
			out += "-"
		out += str(names.get(seq[i], seq[i]))
	return out
