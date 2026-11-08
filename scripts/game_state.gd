extends Node
## 全局状态（D-031）：新游戏参数 / 存档读写 / 设置
## Autoload 单例（project.godot [autoload] 注册）

const SAVE_PATH := "user://save_1.json"

var pending_name := "无名少侠"
var pending_mingge := {}
var pending_load := {}
var difficulty := "普通"
var volume := 0.8

## 难度受伤系数
func damage_factor() -> float:
	match difficulty:
		"简单":
			return 0.75
		"困难":
			return 1.35
	return 1.0

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_info() -> Dictionary:
	if not has_save():
		return {}
	var data := _read()
	return {
		"level": int(data.get("level", 1)),
		"day": int(data.get("day_count", 1)),
		"saved_at": str(data.get("saved_at", "")),
	}

func _read() -> Dictionary:
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	return parsed if parsed is Dictionary else {}

## 存档：全状态持久化（属性/命格/背包/武器/连招链/图鉴/剧情/昼夜/位置）
func save_game(player: Node, main: Node) -> bool:
	var data := {
		"version": 1,
		"name": pending_name,
		"mingge": pending_mingge,
		"difficulty": difficulty,
		"level": player.level, "xp": player.xp, "stat_points": player.stat_points,
		"money": player.money, "fame": player.fame, "sect": player.sect,
		"learned_sect_moves": player.learned_sect_moves.keys(),
		"stats": player.stats,
		"inventory": player.inventory,
		"weapon_unlocked": player.weapon_unlocked,
		"chains": player.chains,
		"discovered": player.discovered.keys(),
		"story_stage": main.story_stage, "clue_count": main.clue_count,
		"day_count": main.day_count, "day_time": main.day_time,
		"pos_x": player.global_position.x, "pos_y": player.global_position.y,
		"saved_at": Time.get_datetime_string_from_system(),
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "\t"))
	return true

func load_game() -> void:
	pending_load = _read()

func apply_to(player: Node, main: Node, data: Dictionary) -> void:
	pending_name = str(data.get("name", pending_name))
	pending_mingge = data.get("mingge", {})
	difficulty = str(data.get("difficulty", "普通"))
	player.level = int(data.get("level", 1))
	player.xp = int(data.get("xp", 0))
	player.stat_points = int(data.get("stat_points", 0))
	player.money = int(data.get("money", 50))
	player.fame = int(data.get("fame", 0))
	player.sect = str(data.get("sect", ""))
	for id in data.get("learned_sect_moves", []):
		player.learned_sect_moves[str(id)] = true
	var st: Dictionary = data.get("stats", {})
	for k in st.keys():
		player.stats[k] = int(st[k])
	var inv: Dictionary = data.get("inventory", {})
	for k in inv.keys():
		player.inventory[k] = int(inv[k])
	var wu: Dictionary = data.get("weapon_unlocked", {})
	for k in wu.keys():
		player.weapon_unlocked[k] = bool(wu[k])
	player.chains = data.get("chains", {})
	for id in data.get("discovered", []):
		player.discovered[str(id)] = true
	main.story_stage = int(data.get("story_stage", 0))
	main.clue_count = int(data.get("clue_count", 0))
	main.day_count = int(data.get("day_count", 1))
	main.day_time = float(data.get("day_time", 0.38))
	player.position = Vector2(float(data.get("pos_x", 0.0)), float(data.get("pos_y", 0.0)))
	player.refresh_derived()
	player.hp = player.max_hp
	player.mp = player.max_mp
	if player.chains.is_empty() == false:
		player.set_weapon(0)
