extends Sprite2D
## 一次性像素特效（D-023）：播放完帧序列后自毁

var fps := 16.0
var _t := 0.0

func _process(delta: float) -> void:
	_t += delta
	var f := int(_t * fps)
	if f >= hframes:
		queue_free()
	else:
		frame = f
