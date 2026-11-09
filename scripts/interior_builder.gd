extends RefCounted
## 室内构建器 · 民居（D-023：房屋多房间，F 进出）
## 双房间布局：厅堂 + 内室（月亮门连通），家具陈设，出口在南侧门口。
## 返回 {bounds, exit_pos, spawn_pos, chest_pos, nodes: Array}

const TILE := 64

const TILE_TEX := {
	"paper": "res://assets/tiles/paper.png",
	"path": "res://assets/tiles/path.png",
	"wall": "res://assets/tiles/wall.png",
}
const PROP_TEX := {
	"table": "res://assets/props/table.png",
	"shelf": "res://assets/props/shelf.png",
	"bed": "res://assets/props/bed.png",
	"lantern_post": "res://assets/props/lantern_post.png",
	"chest": "res://assets/props/chest.png",
}

static func build(parent: Node2D) -> Dictionary:
	var half := Vector2(22 * TILE, 14 * TILE) * 0.5
	var nodes: Array = []

	# ---- 地面与墙体（TileMap）----
	var layer := TileMapLayer.new()
	layer.name = "Interior"
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var ts := TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	var ids := {}
	for key in TILE_TEX:
		var src := TileSetAtlasSource.new()
		src.texture = load(str(TILE_TEX[key]))
		src.texture_region_size = Vector2i(TILE, TILE)
		for i in 4:
			src.create_tile(Vector2i(i, 0))
		ids[key] = ts.add_source(src)
	layer.tile_set = ts
	for ty in range(-7, 7):
		for tx in range(-11, 11):
			var edge := tx == -11 or tx == 10 or ty == -7 or ty == 6
			# 南墙留门（中央两格）
			if ty == 6 and (tx == -1 or tx == 0):
				edge = false
			# 内墙（隔出内室）：x=-2 一列，留月亮门
			var inner := tx == -2 and ty != -1 and ty != 0
			var t := "wall" if (edge or inner) else "path"  # 石板地面（D-035 室内充实）
			var v := int(floor(abs(sin(float(tx * 92821 + ty * 68917))) * 4.0)) % 4
			layer.set_cell(Vector2i(tx, ty), int(ids[t]), Vector2i(v, 0))
	parent.add_child(layer)
	nodes.append(layer)

	# ---- 墙体碰撞 ----
	var walls := [
		Rect2(-half.x, -half.y, half.x * 2, TILE),                       # 顶
		Rect2(-half.x, -half.y, TILE, half.y * 2),                       # 左
		Rect2(half.x - TILE, -half.y, TILE, half.y * 2),                 # 右
		Rect2(-half.x, half.y - TILE, half.x - TILE * 2, TILE),          # 底左（留门）
		Rect2(TILE, half.y - TILE, half.x - TILE * 2, TILE),             # 底右（留门）
		Rect2(-2 * TILE, -half.y, TILE, 6 * TILE),                       # 内墙上段
		Rect2(-2 * TILE, TILE, TILE, half.y - TILE * 2),                 # 内墙下段
	]
	for r in walls:
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = r.size
		shape.shape = rs
		body.add_child(shape)
		body.position = r.position + r.size * 0.5
		parent.add_child(body)
		nodes.append(body)

	# ---- 家具 ----
	var furn := [
		["table", Vector2(-4, -1) * TILE, "rect", Vector2(150, 60)],
		["table", Vector2(4, 2) * TILE, "rect", Vector2(150, 60)],
		["shelf", Vector2(-8, -5) * TILE, "rect", Vector2(80, 50)],
		["shelf", Vector2(-7, -5) * TILE, "rect", Vector2(80, 50)],
		["shelf", Vector2(7, -5) * TILE, "rect", Vector2(80, 50)],
		["bed", Vector2(5, -2) * TILE, "rect", Vector2(70, 120)],
		["lantern_post", Vector2(-8, 4) * TILE, "circle", 16.0],
		["lantern_post", Vector2(8, 4) * TILE, "circle", 16.0],
		["lantern_post", Vector2(-8, -2) * TILE, "circle", 16.0],
		["lantern_post", Vector2(0, -6) * TILE, "circle", 16.0],
	]
	for f in furn:
		var root := Node2D.new()
		root.position = f[1]
		var spr := Sprite2D.new()
		spr.texture = load(str(PROP_TEX[f[0]]))
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		spr.offset = Vector2(0, -spr.texture.get_height() * 0.5)
		root.add_child(spr)
		var body := StaticBody2D.new()
		var shape := CollisionShape2D.new()
		if f[2] == "circle":
			var c := CircleShape2D.new()
			c.radius = float(f[3])
			shape.shape = c
			shape.position = Vector2(0, -8)
		else:
			var rs := RectangleShape2D.new()
			rs.size = f[3]
			shape.shape = rs
			shape.position = Vector2(0, -f[3].y * 0.5)
		body.add_child(shape)
		root.add_child(body)
		parent.add_child(root)
		nodes.append(root)

	return {
		"bounds": Rect2(-half, half * 2.0),
		"exit_pos": Vector2(0, half.y - TILE * 1.5),
		"spawn_pos": Vector2(0, half.y - TILE * 2.5),
		"chest_pos": Vector2(4, -4) * TILE,
		"nodes": nodes,
	}
