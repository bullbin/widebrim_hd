class_name Lt2AssetPlaceData

extends RefCounted

const COUNT_MAX_HINT 	: int = 4
const COUNT_MAX_TOBJ 	: int = 16
const COUNT_MAX_BGANI 	: int = 12
const COUNT_MAX_EVENT 	: int = 16
const COUNT_MAX_EXIT 	: int = 12

class BoundedObject:
	var bounding : Rect2i = Rect2i(0,0,0,0)
	
	func is_valid() -> bool:
		return bounding.size.x > 0 and bounding.size.y > 0
	
	func read_contents(file : FileAccess):
		bounding.position.x = file.get_16()
		bounding.position.y = file.get_16()
		bounding.size.x = file.get_16()
		bounding.size.y = file.get_16()

class HintCoin:
	extends BoundedObject

class TObj:
	extends BoundedObject
	
	var id_char : int = 0
	var id_text : int = 0
	
	func read_contents(file : FileAccess):
		super(file)
		id_char = file.get_16()
		id_text = file.get_32()

class BgAni:
	var pos 	: Vector2i = Vector2i(0,0)
	var name 	: String = ""
	
	func is_valid():
		return len(name) > 0
	
	func read_contents(file : FileAccess):
		pos.x = file.get_16()
		pos.y = file.get_16()
		name = file.get_buffer(30).get_string_from_utf8()	# TODO - encoding

class EventSpawner:
	extends BoundedObject
	
	var id_image : int = 0
	var id_event : int = 0
	
	func read_contents(file : FileAccess):
		super(file)
		id_image = file.get_16()
		id_event = file.get_16()

class Exit:
	extends BoundedObject
	
	var position_map 	: Vector2i = Vector2i(0,0)
	var id_image 		: int = 0	# TODO - Make enum
	var id_sound 		: int = 0	# ''
	var destination 	: int = 0
	
	var _flags 	: int = 0
	
	func set_flags(flags : int):
		_flags = flags
	
	func does_spawn_event() -> bool:
		return _flags >= 0x02
	
	func does_spawn_exclamation() -> bool:
		return _flags == 0x03
	
	func allow_immediate_activation() -> bool:
		return (_flags & 0x01) > 0
	
	func read_contents(file : FileAccess):
		super(file)
		id_image = file.get_8()
		_flags = file.get_8()
		file.get_8()
		id_sound = file.get_8()
		position_map.x = file.get_16()
		position_map.y = file.get_16()
		destination = file.get_16()
	
var id_nametag 		: int = 0
var id_bg_main 		: int = 0
var id_bg_sub 		: int = 0
var id_sound 		: int = 0
var position_map 	: Vector2i = Vector2i(0,0)
var hint_coins 		: Array[HintCoin] = []
var exits 			: Array[Exit] = []
var t_objs 			: Array[TObj] = []
var bg_anim 		: Array[BgAni] = []
var event_spawners 	: Array[EventSpawner] = []

func _init(path_data : String):
	var file = FileAccess.open(Lt2Utils.get_asset_path(path_data), FileAccess.READ)
	if file != null:
		id_nametag = file.get_8()
		file.seek(0x18)
		position_map.x = file.get_16()
		position_map.y = file.get_16()
		id_bg_main = file.get_8()
		id_bg_sub = file.get_8()
		
		var temp_hint : HintCoin = null
		var encountered_empty = false
		for _idx in range(COUNT_MAX_HINT):
			temp_hint = HintCoin.new()
			temp_hint.read_contents(file)
			
			if encountered_empty:
				continue
			elif temp_hint.is_valid():
				hint_coins.append(temp_hint)
			else:
				encountered_empty = true
		
		var temp_tobj : TObj = null
		encountered_empty = false
		for _idx in range(COUNT_MAX_TOBJ):
			temp_tobj = TObj.new()
			temp_tobj.read_contents(file)
			
			if encountered_empty:
				continue
			elif temp_tobj.is_valid():
				t_objs.append(temp_tobj)
			else:
				encountered_empty = true
		
		var temp_bgani : BgAni = null
		encountered_empty = false
		for _idx in range(COUNT_MAX_BGANI):
			temp_bgani = BgAni.new()
			temp_bgani.read_contents(file)
			
			if encountered_empty:
				continue
			elif temp_bgani.is_valid():
				bg_anim.append(temp_bgani)
			else:
				encountered_empty = true
		
		var temp_event : EventSpawner = null
		encountered_empty = false
		for _idx in range(COUNT_MAX_EVENT):
			temp_event = EventSpawner.new()
			temp_event.read_contents(file)
			
			if encountered_empty:
				continue
			elif temp_event.is_valid():
				event_spawners.append(temp_event)
			else:
				encountered_empty = true
		
		var temp_exit : Exit = null
		encountered_empty = false
		for _idx in range(COUNT_MAX_EXIT):
			temp_exit = Exit.new()
			temp_exit.read_contents(file)
			
			if encountered_empty:
				continue
			elif temp_exit.is_valid():
				exits.append(temp_exit)
			else:
				encountered_empty = true
		
		for _idx in range(0x30):
			file.get_8()
		
		id_sound = file.get_16()
