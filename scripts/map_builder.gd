extends RefCounted
## 地图构建器 · 落雁村（垂直切片第一图，D-018 / D-019）
## 代码搭建：TileMapLayer 地面（纸地/草地/小径/池塘）+ 装饰道具（树/屋/石/篱/花）+ 碰撞体。
## 布局为固定噪声与种子，可复现；美术是程序生成的水墨占位纹理（assets/），可整体替换。

const TILE := 64
const GRID_W := 32
const GRID_H := 24

const TILE_TEX := {
	"paper": "res://assets/tiles/paper.png",
	"grass": "res://assets/tiles/grass.png",
	"path": "res://assets/tiles/path.png",
	"water": "res://assets/tiles/water.png",
}
const PROP_TEX := {
	"tree": "res://assets/props/tree.png",
	"tree2": "res://assets/props/tree2.png",
	"rock": "res://assets/props/rock.png",
	"bush": "res://assets/props/bush.png",
	"hut": "res://assets/props/hut.png",
	"hut2": "res://assets/props/hut2.png",
	"fence": "res://assets/props/fence.png",
	"flower": "res://assets/props/flower.png",
}

## 构建整张地图；返回 {name, bounds: Rect2, player_spawn: Vector2, enemy_spawns: Array}
static func build(parent: Node2D) -> Dictionary:
	var half := Vector2(GRID_W, GRID_H) * float(TILE) * 0.5
	var info := {
		"name": "落雁村",
		"bounds": Rect2(-half, half * 2.0),
		"player_spawn": _tile_to_world(16, 15),
		"enemy_spawns": [
			_tile_to_world(6, 4), _tile_to_world(26, 5), _tile_to_world(28, 18),
			_tile_to_world(5, 20), _tile_to_world(23, 21), _tile_to_world(11, 8),
		],
	}
	_build_ground(parent)
	_build_props(parent, info)
	return info

static func _tile_to_world(tx: int, ty: int) -> Vector2:
	return Vector2((tx + 0.5) - GRID_W * 0.5, (ty + 0.5) - GRID_H * 0.5) * float(TILE)

static func _hash(n: int) -> float:
	var s := sin(float(n) * 12.9898 + 78.233) * 43758.5453
	return s - floor(s)

## 地块类型：十字小径 / 池塘 / 广场 / 草地斑块 / 纸地
static func _tile_type(tx: int, ty: int) -> String:
	if ty == 11 or ty == 12 or tx == 15 or tx == 16:
		return "path"
	var pond := Vector2(26.5, 18.5)
	var d := Vector2((tx + 0.5 - pond.x) / 3.4, (ty + 0.5 - pond.y) / 2.4)
	if d.length() <= 1.0:
		return "water"
	if Vector2(tx - 16, ty - 12).length() <= 3.2:
		return "paper"
	if _grass_mask(tx, ty):
		return "grass"
	return "paper"

static func _grass_mask(tx: int, ty: int) -> bool:
	var v := sin(tx * 0.31) * cos(ty * 0.27) + sin((tx + ty) * 0.17) * 0.6
	v += (_hash(tx * 131 + ty * 17) - 0.5) * 0.9
	return v > 0.25

static func _build_ground(parent: Node2D) -> void:
	var layer := TileMapLayer.new()
	layer.name = "Ground"
	layer.z_index = -1
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

static func _build_props(parent: Node2D, _info: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261107

	# ---- 房屋（固定布局，门口朝向主路）----
	var huts := [
		[_tile_to_world(8, 7), "hut"], [_tile_to_world(23, 7), "hut2"],
		[_tile_to_world(7, 18), "hut2"], [_tile_to_world(23, 18), "hut"],
	]
	for h in huts:
		_add_prop(parent, str(PROP_TEX[h[1]]), h[0], "rect", Vector2(180, 120), -6.0)

	# ---- 树：边缘林带 ----
	for ty in GRID_H:
		for tx in GRID_W:
			var edge := tx < 2 or tx > GRID_W - 3 or ty < 2 or ty > GRID_H - 3
			if not edge:
				continue
			var t := _tile_type(tx, ty)
			if t == "path" or t == "water":
				continue
			if rng.randf() > 0.75:
				continue
			_add_tree(parent, rng, _tile_to_world(tx, ty) + Vector2(rng.randf_range(-14, 14), rng.randf_range(-10, 10)))
	# ---- 树丛（村庄外围）----
	var groves := [Vector2i(5, 4), Vector2i(27, 5), Vector2i(4, 19), Vector2i(27, 20), Vector2i(12, 3), Vector2i(20, 22)]
	for g in groves:
		for i in 4:
			_add_tree(parent, rng, _tile_to_world(g.x, g.y) + Vector2(rng.randf_range(-70, 70), rng.randf_range(-50, 50)))

	# ---- 散布：石 / 灌木 / 花 ----
	for i in 14:
		_add_prop(parent, str(PROP_TEX["rock"]), _scatter_tile(rng), "circle", 30.0, -4.0)
	for i in 12:
		_add_prop(parent, str(PROP_TEX["bush"]), _scatter_tile(rng), "", 0.0, -2.0)
	for i in 26:
		_add_prop(parent, str(PROP_TEX["flower"]), _scatter_tile(rng), "", 0.0, -2.0)

	# ---- 篱笆（田边）----
	for i in 3:
		_add_prop(parent, str(PROP_TEX["fence"]), _tile_to_world(3 + i, 15) + Vector2(32, 8), "", 0.0, 0.0)
	for i in 3:
		_add_prop(parent, str(PROP_TEX["fence"]), _tile_to_world(25 + i, 11) + Vector2(32, 8), "", 0.0, 0.0)

	# ---- 池塘边缘碰撞（水面不可通行）----
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
	var key := "tree" if rng.randf() > 0.5 else "tree2"
	_add_prop(parent, str(PROP_TEX[key]), pos, "circle", 26.0, -2.0)

## 随机空地（避开小径/水面/广场/房屋/出生点）
static func _scatter_tile(rng: RandomNumberGenerator) -> Vector2:
	for i in 40:
		var tx := rng.randi_range(2, GRID_W - 3)
		var ty := rng.randi_range(2, GRID_H - 3)
		var t := _tile_type(tx, ty)
		if t == "path" or t == "water":
			continue
		if Vector2(tx - 16, ty - 12).length() < 3.5:
			continue
		if Vector2(tx - 16, ty - 15).length() < 2.2:
			continue
		var near_hut := false
		for h in [Vector2i(8, 7), Vector2i(23, 7), Vector2i(7, 18), Vector2i(23, 18)]:
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
