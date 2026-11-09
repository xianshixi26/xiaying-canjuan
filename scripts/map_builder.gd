extends RefCounted
## 地图构建器 · 落雁村 v2（D-023：48x32 扩图 + 环境细节 + 交互点）
## 代码搭建：TileMapLayer 地面 + 装饰道具 + 碰撞体 + 宝箱/调查点/房门坐标。

const TILE := 64
const GRID_W := 48
const GRID_H := 32

const TILE_TEX := {
	"paper": "res://assets/tiles/paper.png",
	"grass": "res://assets/tiles/grass.png",
	"path": "res://assets/tiles/path.png",
	"water": "res://assets/tiles/water.png",
}
const PROP_TEX := {
	"tree": "res://assets/props/tree.png",
	"tree2": "res://assets/props/tree2.png",
	"pine": "res://assets/props/pine.png",
	"rock": "res://assets/props/rock.png",
	"bush": "res://assets/props/bush.png",
	"hut": "res://assets/props/hut.png",
	"hut2": "res://assets/props/hut2.png",
	"fence": "res://assets/props/fence.png",
	"flower": "res://assets/props/flower.png",
	"well": "res://assets/props/well.png",
	"signpost": "res://assets/props/signpost.png",
	"lantern_post": "res://assets/props/lantern_post.png",
	"oracle": "res://assets/props/oracle.png",
	"gate": "res://assets/props/gate.png",
}

## 构建整张地图；返回 {name, bounds, player_spawn, enemy_spawns, doors, chests, clues}
static func build(parent: Node2D) -> Dictionary:
	var half := Vector2(GRID_W, GRID_H) * float(TILE) * 0.5
	var huts := [Vector2i(13, 8), Vector2i(33, 8), Vector2i(11, 23), Vector2i(35, 24), Vector2i(20, 5), Vector2i(29, 27)]
	var doors: Array = []
	for h in huts:
		doors.append(_tile_to_world(h.x, h.y) + Vector2(0, 40))
	var info := {
		"name": "落雁村",
		"bounds": Rect2(-half, half * 2.0),
		"player_spawn": _tile_to_world(24, 20),
		"enemy_spawns": [
			_tile_to_world(7, 5), _tile_to_world(40, 6), _tile_to_world(43, 20),
			_tile_to_world(6, 18), _tile_to_world(41, 28), _tile_to_world(16, 29),
			_tile_to_world(31, 13), _tile_to_world(9, 28), _tile_to_world(18, 11),
			_tile_to_world(36, 19), _tile_to_world(28, 24), _tile_to_world(13, 15),
		],
		"doors": doors,
		"oracle": _tile_to_world(20, 18),
		"baiji_pos": _tile_to_world(24, 13),
		"boss_gate": _tile_to_world(44, 4),
		"chests": [
			_tile_to_world(8, 11), _tile_to_world(39, 12), _tile_to_world(15, 27),
			_tile_to_world(31, 28), _tile_to_world(43, 15), _tile_to_world(21, 21),
		],
		"clues": [
			_tile_to_world(18, 7), _tile_to_world(28, 9), _tile_to_world(14, 19),
			_tile_to_world(33, 18), _tile_to_world(22, 25), _tile_to_world(38, 25),
			_tile_to_world(8, 13), _tile_to_world(41, 10),
		],
	}
	_build_ground(parent)
	_build_props(parent, info, huts)
	return info

static func _tile_to_world(tx: int, ty: int) -> Vector2:
	return Vector2((tx + 0.5) - GRID_W * 0.5, (ty + 0.5) - GRID_H * 0.5) * float(TILE)

static func _hash(n: int) -> float:
	var s := sin(float(n) * 12.9898 + 78.233) * 43758.5453
	return s - floor(s)

## 地块类型：十字主路 / 池塘 / 广场 / 草地 / 纸地
static func _tile_type(tx: int, ty: int) -> String:
	if ty == 15 or ty == 16 or tx == 23 or tx == 24:
		return "path"
	var pond := Vector2(38.5, 25.5)
	var d := Vector2((tx + 0.5 - pond.x) / 5.0, (ty + 0.5 - pond.y) / 3.5)
	if d.length() <= 1.0:
		return "water"
	if Vector2(tx - 24, ty - 16).length() <= 3.5:
		return "paper"
	if _grass_mask(tx, ty):
		return "paper"  # 夯土斑块作变化（D-035：草地为全图基调，不再露白）
	return "grass"

static func _grass_mask(tx: int, ty: int) -> bool:
	var v := sin(tx * 0.29) * cos(ty * 0.26) + sin((tx + ty) * 0.16) * 0.65
	v += (_hash(tx * 131 + ty * 17) - 0.5) * 0.9
	return v > 0.18

static func _build_ground(parent: Node2D) -> void:
	var layer := TileMapLayer.new()
	layer.name = "Ground"
	layer.z_index = -1
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var source_ids := {}
	for key in TILE_TEX:
		var src := TileSetAtlasSource.new()
		src.texture = load(str(TILE_TEX[key]))
		src.texture_region_size = Vector2i(TILE, TILE)
		for i in 4:
			src.create_tile(Vector2i(i, 0))
		source_ids[key] = ts.add_source(src)
	layer.tile_set = ts
	for ty in GRID_H:
		for tx in GRID_W:
			var t := _tile_type(tx, ty)
			var v := int(floor(_hash(tx * 92821 + ty * 68917) * 4.0)) % 4
			layer.set_cell(Vector2i(tx, ty), int(source_ids[t]), Vector2i(v, 0))
	parent.add_child(layer)

static func _build_props(parent: Node2D, _info: Dictionary, huts: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261108

	# ---- 房屋（门口朝向主路）----
	for h in huts:
		var key := "hut" if (h.x + h.y) % 2 == 0 else "hut2"
		_add_prop(parent, str(PROP_TEX[key]), _tile_to_world(h.x, h.y), "rect", Vector2(180, 120), -6.0)

	# ---- 环境道具：水井 / 告示牌 / 灯柱 / 卦摊 ----
	_add_prop(parent, str(PROP_TEX["well"]), _tile_to_world(27, 19), "circle", 34.0, -4.0)
	_add_prop(parent, str(PROP_TEX["oracle"]), _tile_to_world(20, 18), "circle", 22.0, -2.0)
	_add_prop(parent, str(PROP_TEX["gate"]), _tile_to_world(44, 4), "circle", 30.0, -2.0)
	for p in [Vector2i(22, 12), Vector2i(26, 21), Vector2i(21, 18)]:
		_add_prop(parent, str(PROP_TEX["signpost"]), _tile_to_world(p.x, p.y), "circle", 12.0, -2.0)
	for p in [Vector2i(22, 7), Vector2i(22, 11), Vector2i(22, 22), Vector2i(22, 27),
			Vector2i(26, 7), Vector2i(26, 27), Vector2i(12, 14), Vector2i(18, 17),
			Vector2i(32, 14), Vector2i(38, 17), Vector2i(12, 17), Vector2i(38, 14)]:
		_add_prop(parent, str(PROP_TEX["lantern_post"]), _tile_to_world(p.x, p.y), "circle", 12.0, -2.0)

	# ---- 树：边缘林带 ----
	for ty in GRID_H:
		for tx in GRID_W:
			var edge := tx < 2 or tx > GRID_W - 3 or ty < 2 or ty > GRID_H - 3
			if not edge:
				continue
			var t := _tile_type(tx, ty)
			if t == "path" or t == "water":
				continue
			if rng.randf() > 0.72:
				continue
			_add_tree(parent, rng, _tile_to_world(tx, ty) + Vector2(rng.randf_range(-14, 14), rng.randf_range(-10, 10)))
	# ---- 树丛（散点加密）----
	var groves := [
		Vector2i(6, 5), Vector2i(44, 5), Vector2i(5, 27), Vector2i(45, 28),
		Vector2i(16, 3), Vector2i(34, 3), Vector2i(7, 15), Vector2i(44, 12),
		Vector2i(15, 12), Vector2i(36, 13), Vector2i(19, 28), Vector2i(28, 22),
		Vector2i(31, 20), Vector2i(16, 21),
	]
	for g in groves:
		for i in 5:
			_add_tree(parent, rng, _tile_to_world(g.x, g.y) + Vector2(rng.randf_range(-80, 80), rng.randf_range(-55, 55)))

	# ---- 散布：石 / 灌木 / 花（加密）----
	for i in 26:
		_add_prop(parent, str(PROP_TEX["rock"]), _scatter_tile(rng, huts), "circle", 30.0, -4.0)
	for i in 30:
		_add_prop(parent, str(PROP_TEX["bush"]), _scatter_tile(rng, huts), "", 0.0, -2.0)
	for i in 50:
		_add_prop(parent, str(PROP_TEX["flower"]), _scatter_tile(rng, huts), "", 0.0, -2.0)

	# ---- 篱笆（田边）----
	for i in 4:
		_add_prop(parent, str(PROP_TEX["fence"]), _tile_to_world(3 + i, 18) + Vector2(32, 8), "", 0.0, 0.0)
	for i in 4:
		_add_prop(parent, str(PROP_TEX["fence"]), _tile_to_world(38 + i, 12) + Vector2(32, 8), "", 0.0, 0.0)
	for i in 3:
		_add_prop(parent, str(PROP_TEX["fence"]), _tile_to_world(25 + i, 29) + Vector2(32, 8), "", 0.0, 0.0)

	# ---- 池塘边缘碰撞 ----
	for ty in GRID_H:
		for tx in GRID_W:
			if _tile_type(tx, ty) != "water":
				continue
			var border := false
			for nb: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var n := Vector2i(tx, ty) + nb
				if n.x < 0 or n.y < 0 or n.x >= GRID_W or n.y >= GRID_H or _tile_type(n.x, n.y) != "water":
					border = true
					break
			if border:
				var body := StaticBody2D.new()
				var shape := CollisionShape2D.new()
				var r := RectangleShape2D.new()
				r.size = Vector2(TILE, TILE)
				shape.shape = r
				body.add_child(shape)
				body.position = _tile_to_world(tx, ty)
				parent.add_child(body)

static func _add_tree(parent: Node2D, rng: RandomNumberGenerator, pos: Vector2) -> void:
	var keys := ["tree", "tree2", "pine"]
	var key: String = keys[rng.randi_range(0, 2)]
	_add_prop(parent, str(PROP_TEX[key]), pos, "circle", 26.0, -2.0)

## 随机空地（避开小径/水面/广场/房屋/交互点）
static func _scatter_tile(rng: RandomNumberGenerator, huts: Array) -> Vector2:
	for i in 40:
		var tx := rng.randi_range(2, GRID_W - 3)
		var ty := rng.randi_range(2, GRID_H - 3)
		var t := _tile_type(tx, ty)
		if t == "path" or t == "water":
			continue
		if Vector2(tx - 24, ty - 16).length() < 3.5:
			continue
		var near_hut := false
		for h in huts:
			if Vector2(tx - h.x, ty - h.y).length() < 2.6:
				near_hut = true
				break
		if near_hut:
			continue
		return _tile_to_world(tx, ty) + Vector2(rng.randf_range(-18, 18), rng.randf_range(-12, 12))
	return Vector2(rng.randf_range(-100, 100), rng.randf_range(-100, 100))

## 添加道具：精灵 + 可选碰撞体；道具原点=贴地位置（供 y-sort 使用）
static func _add_prop(parent: Node2D, tex_path: String, pos: Vector2, collider_kind: String, col_size, y_offset: float = 0.0) -> void:
	var tex: Texture2D = load(tex_path)
	if tex == null:
		push_warning("贴图缺失: " + tex_path)
		return
	var root := Node2D.new()
	root.position = pos
	var spr := Sprite2D.new()
	spr.texture = tex
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	spr.offset = Vector2(0, -tex.get_height() * 0.5 + y_offset)
	root.add_child(spr)
	if collider_kind != "":
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		if collider_kind == "circle":
			var c := CircleShape2D.new()
			c.radius = float(col_size)
			shape.shape = c
			shape.position = Vector2(0, -c.radius * 0.55)
		else:
			var r := RectangleShape2D.new()
			r.size = col_size
			shape.shape = r
			shape.position = Vector2(0, -r.size.y * 0.5 - 8.0)
		body.add_child(shape)
		root.add_child(body)
	parent.add_child(root)
