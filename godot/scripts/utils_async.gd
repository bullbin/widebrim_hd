class_name Promise

extends RefCounted

enum PromiseMode {ANY, ALL}

var _signals : Array = []
var _remaining_signal_count : int = 0
var _mode : PromiseMode = PromiseMode.ANY
var _done : bool = false

signal satisfied

func _init(mode : PromiseMode):
	mode = _mode
	
func _on_signal_done():
	if not(_done):
		_remaining_signal_count -= 1
		if _mode == PromiseMode.ANY or _remaining_signal_count == 0:
			_done = true
			satisfied.emit()
		
func add_signal(sig : Signal):
	_signals.append(sig)
	_remaining_signal_count += 1
	sig.connect(_on_signal_done)
