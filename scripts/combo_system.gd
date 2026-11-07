extends RefCounted
## 组合招式引擎（纯逻辑：无渲染/无场景依赖，状态可序列化——为联机预留，见 D-009）
## 用法：每次基础动作按下时 push_action()，返回命中的招式（空字典=无组合命中）。
## 匹配规则：输入序列在时间窗口内做尾部匹配，多招式命中时取最长序列。

const WINDOW := 0.9       # 相邻按键最大间隔（秒）
const BUFFER_LIFE := 2.0  # 输入在缓冲区的保留时长（秒）

var moves: Array = []
var _buffer: Array = []   # [{"action": String, "time": float}]
var _clock := 0.0

func _init(p_moves: Array) -> void:
	moves = p_moves

func tick(delta: float) -> void:
	_clock += delta
	while _buffer.size() > 0 and _clock - float(_buffer[0]["time"]) > BUFFER_LIFE:
		_buffer.pop_front()

## 记录一次基础动作输入，返回命中的招式（Dictionary），未命中返回空字典
func push_action(action: String) -> Dictionary:
	_buffer.append({"action": action, "time": _clock})
	var best: Dictionary = {}
	for move in moves:
		if bool(move["manual"]):
			continue  # 需秘籍解锁的招式暂不可用（秘籍系统接入后改写此标记）
		var seq: Array = move["seq"]
		if _tail_matches(seq) and (best.is_empty() or seq.size() > best["seq"].size()):
			best = move
	if not best.is_empty():
		_buffer.clear()  # 命中后清空，重新起手
	return best

## 当前缓冲区输入（供 HUD 显示搓招过程）
func get_buffer_actions() -> Array:
	var out: Array = []
	for entry in _buffer:
		out.append(str(entry["action"]))
	return out

func _tail_matches(seq: Array) -> bool:
	if seq.is_empty() or _buffer.size() < seq.size():
		return false
	var start := _buffer.size() - seq.size()
	for i in seq.size():
		var entry: Dictionary = _buffer[start + i]
		if str(entry["action"]) != str(seq[i]):
			return false
		if i > 0:
			var prev: Dictionary = _buffer[start + i - 1]
			if float(entry["time"]) - float(prev["time"]) > WINDOW:
				return false
	return true
