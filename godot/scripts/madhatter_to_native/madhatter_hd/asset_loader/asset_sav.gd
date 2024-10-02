# Note: I haven't looked much into the HD state system, so types aren't guaranteed
# This is based on the NDS version. Should be very, very similar
class_name Lt2AssetSaveSlot

extends RefCounted

const COUNT_MAX_PUZZLE = 216
const COUNT_MAX_ROOM = 128

class PuzzleState:
	var encountered 	: bool = false
	var solved 			: bool = false
	var picked 			: bool = false
	var nazoba_enabled 	: bool = false
	var decay 			: int = 0
	var hint 			: int = 0
	
	func to_byte() -> int:
		return (int(encountered) + (int(solved) << 1) +
				((decay & 0x03) << 2) + ((hint & 0x03) << 4) +
				(int(nazoba_enabled) << 6) + (int(picked) << 7))
	
	func set_from_byte(val : int):
		encountered 	= (val & 0x01) > 0
		solved 			= (val & 0x02) > 0
		nazoba_enabled 	= (val & 0x40) > 0
		picked 			= (val & 0x80) > 0
		decay 	= (val >> 2) & 0x03
		hint 	= (val >> 4) & 0x03

class PackedRoomManager:
	var _room_data : PackedByteArray = PackedByteArray()
	
	func _init():
		@warning_ignore("integer_division")
		for idx_room in range(COUNT_MAX_ROOM / 2):
			_room_data.append(0)
	
	func _is_data_in_range(idx_place : int, idx_hint : int) -> bool:
		if idx_place < 0 or idx_place >= COUNT_MAX_ROOM:
			return false
		if idx_hint < 0 or idx_hint >= 4:
			return false
		return true
	
	func get_hint_state(idx_place : int, idx_hint : int) -> bool:
		if _is_data_in_range(idx_place, idx_hint):
			@warning_ignore("integer_division")
			var base_val = _room_data[idx_place / 2]
			if idx_place % 2 == 1:
				base_val = base_val >> 4
			base_val = (base_val >> idx_hint) & 0x01
			return base_val > 0
		return false
	
	func set_hint_state(idx_place : int, idx_hint : int, state : bool) -> bool:
		if _is_data_in_range(idx_place, idx_hint):
			@warning_ignore("integer_division")
			var base_val = _room_data[idx_place / 2]
			if idx_place % 2 == 1:
				idx_hint += 4
			var mask = 1 << idx_hint
			if state:
				base_val = base_val | mask
			@warning_ignore("integer_division")
			_room_data.set(idx_place / 2, base_val)
			return true
		return false
	
	func write_contents(file : FileAccess):
		file.store_buffer(_room_data)
	
	func read_contents(file : FileAccess):
		for idx_byte in range(len(_room_data)):
			_room_data.set(idx_byte, file.get_8())

class PlusNewBitField:
	var _unlocked : AddressableBitField = null
	var _new : AddressableBitField = null
	
	func _init(length_bytes : int):
		_unlocked = AddressableBitField.new(length_bytes)
		_new = AddressableBitField.new(length_bytes)
	
	func unlock_bit(idx : int):
		if not(_unlocked.get_bit(idx)):
			_unlocked.set_bit(idx, true)
			_new.set_bit(idx, true)
	
	func is_unlocked(idx : int) -> bool:
		return _unlocked.get_bit(idx)
	
	func is_new(idx : int) -> bool:
		return _new.get_bit(idx)
	
	func remove_new(idx : int):
		_new.set_bit(idx, false)
	
	func read_contents(file : FileAccess):
		_unlocked.read_contents(file)
		_new.read_contents(file)
	
	func write_contents(file : FileAccess):
		_unlocked.write_contents(file)
		_new.write_contents(file)

class MemoState:
	extends PlusNewBitField
	var last_page : int = 0
	
	func _init():
		super(16)

class CameraState:
	var available := AddressableBitField.new(2)
	var pieces := AddressableBitField.new(20)

class TeaState:
	var available_elements := AddressableBitField.new(1)
	var available_recipes := AddressableBitField.new(2)
	var solved := AddressableBitField.new(3)
	var stoe := AddressableBitField.new(1)	# STOE not understood yet

class PhotoPieceState:
	var interacted := AddressableBitField.new(4)
	var taken := AddressableBitField.new(2)
	var completed := AddressableBitField.new(2)
	var pieces := AddressableBitField.new(2)

class HamsterState:
	var level := 0
	var name := "NO NAME"
	var unlocked := AddressableBitField.new(10)	# TODO - This should be list of 10 ints
	var current_grid := AddressableBitField.new(48)	# TODO - Unideal to store like this (grid)
	var record := AddressableBitField.new(1)	# SHMM not understood yet

class FukamaruState:
	extends PlusNewBitField
	var _solved : AddressableBitField = null
	
	func _init():
		super(2)
		_solved = AddressableBitField.new(2)
	
	func solve(idx : int):
		unlock_bit(idx)
		_solved.set_bit(idx, true)
		# TODO - Maybe new here too
	
	func is_solved(idx : int) -> bool:
		return _solved.get_bit(idx)
	
	func read_contents(file : FileAccess):
		super(file)
		_solved.read_contents(file)
	
	func write_contents(file : FileAccess):
		super(file)
		_solved.write_contents(file)

var name 			:= "NO NAME"
var is_complete		:= false

var _puzzle_data : Array[PuzzleState] = []

var flags_event_viewed 	:= AddressableBitField.new(128)
var flags_storyflag		:= AddressableBitField.new(16)
var flags_event_counter := AddressableBitField.new(128)
var flags_items 		:= AddressableBitField.new(1)
var flags_menu_new 		:= AddressableBitField.new(2)
var flags_photo_piece 	:= AddressableBitField.new(2)
var flags_tutorial 		:= AddressableBitField.new(2)
var flags_party_member 	:= AddressableBitField.new(1)
var flags_code_entry	:= AddressableBitField.new(2)

var room_hint_state 	:= PackedRoomManager.new()
var memo_state 			:= MemoState.new()
var camera_state 		:= CameraState.new()
var anthony_diary_state := PlusNewBitField.new(2)
var tea_state 			:= TeaState.new()
var photo_piece_state 	:= PhotoPieceState.new()
var fukamaru_state 		:= FukamaruState.new()
var hamster_state		:= HamsterState.new()

var hint_coin_encountered 	:= 10
var hint_coin_remaining 	:= 10

var _id_room 		:= 1
var _id_room_sub 	:= 0
var chapter 		:= 5

var _picarats 		:= 0

var id_event_held_autoevent := -1
var id_event_immediate		:= -1
var id_last_jiten			:= 0

var objective 		:= 100

func _init():
	for _idx in range(COUNT_MAX_PUZZLE):
		_puzzle_data.append(PuzzleState.new())

func get_puzzle_state_external(idx_external : int) -> PuzzleState:
	if idx_external > 0 and idx_external <= len(_puzzle_data):
		return _puzzle_data[idx_external - 1]
	return null

func get_puzzle_solved_count() -> int:
	var output = 0
	for state in _puzzle_data:
		if state.solved:
			output += 1
	return output

func set_id_room(id : int):
	_id_room = id

func get_id_room() -> int:
	return _id_room

func set_id_subroom(id : int):
	_id_room_sub = id

func get_id_subroom() -> int:
	return _id_room_sub

func is_camera_assembled() -> bool:
	return false

func _signed_to_unsigned(signed : int, max_depth : int) -> int:
	var bound 	: int = 0x01 << (max_depth - 1)
	var clamped : int = min(max(signed, -bound), bound - 1)
	if clamped < 0:
		clamped += 1 << max_depth
	return clamped

func _unsigned_to_signed(unsigned : int, max_depth : int) -> int:
	var max_higher : int = 0x01 << max_depth
	var max_lower : int = 0x01 << (max_depth - 1)
	return (unsigned + max_lower) % max_higher - max_lower

func _s16_as_u16(val : int) -> int:
	return _signed_to_unsigned(val, 16)

func _s32_as_u32(val : int) -> int:
	return _signed_to_unsigned(val, 32)

func _u16_as_s16(val : int) -> int:
	return _unsigned_to_signed(val, 16)

# TODO - Slot
func write_save(path : String) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE_READ)
	if file != null:
		file.store_32(0)	# Checksum
		
		flags_event_viewed.write_contents(file)
		flags_storyflag.write_contents(file)
		flags_event_counter.write_contents(file)
		
		for idx_puzzle in range(COUNT_MAX_PUZZLE):
			file.store_8(_puzzle_data[idx_puzzle].to_byte())
		
		room_hint_state.write_contents(file)
		file.store_16(hint_coin_remaining)
		file.store_16(hint_coin_encountered)
		file.store_32(_picarats)
		file.store_32(chapter)
		file.store_32(_id_room)
		file.store_32(_id_room_sub)
		
		file.store_32(0)	# Padding
		file.store_32(0)	# Time1
		file.store_32(0)	# Time2
		
		camera_state.available.write_contents(file)
		camera_state.pieces.write_contents(file)
		
		for _idx_pad in range(30):
			file.store_8(0)
		
		tea_state.available_elements.write_contents(file)
		tea_state.available_recipes.write_contents(file)
		file.store_8(hamster_state.level)
		hamster_state.unlocked.write_contents(file)
		hamster_state.current_grid.write_contents(file)
		hamster_state.record.write_contents(file)
		tea_state.stoe.write_contents(file)
		
		for _idx_pad in range(3):
			file.store_8(0)

		memo_state.write_contents(file)
		fukamaru_state.write_contents(file)
		photo_piece_state.interacted.write_contents(file)
		photo_piece_state.taken.write_contents(file)
		photo_piece_state.completed.write_contents(file)
		flags_items.write_contents(file)
		flags_menu_new.write_contents(file)
		tea_state.solved.write_contents(file)
		
		var name_buff := hamster_state.name.to_utf8_buffer() # TODO - NDS uses shift-jis
		if name_buff.size() > 20:
			name_buff.resize(20)
		else:
			for _i in range(20 - name_buff.size()):
				name_buff.append(0)
		
		file.store_buffer(name_buff)
		
		photo_piece_state.pieces.write_contents(file)
		flags_tutorial.write_contents(file)
		
		file.store_8(0)
		
		file.store_16(_s16_as_u16(id_event_held_autoevent))
		file.store_16(_s16_as_u16(id_event_immediate))
		anthony_diary_state.write_contents(file)
		
		file.store_8(memo_state.last_page)
		file.store_8(id_last_jiten)
		flags_code_entry.write_contents(file)
		file.store_16(objective)
		flags_party_member.write_contents(file)

		file.close()
	return file != null

func read_save(path : String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file != null:
		file.seek(4)
		
		flags_event_viewed.read_contents(file)
		flags_storyflag.read_contents(file)
		flags_event_counter.read_contents(file)
		
		for idx_puzzle in range(COUNT_MAX_PUZZLE):
			_puzzle_data[idx_puzzle].set_from_byte(file.get_8())
		
		room_hint_state.read_contents(file)
		hint_coin_remaining = file.get_16()
		hint_coin_encountered = file.get_16()
		_picarats = file.get_32()
		chapter = file.get_32()
		_id_room = file.get_32()
		_id_room_sub = file.get_32()
		
		file.get_32()	# Unused
		file.get_32()	# TimeElapsed		
		file.get_32()	# TimeElapsedOverflow
		
		camera_state.available.read_contents(file)
		camera_state.pieces.read_contents(file)
		
		file.get_buffer(30) # Unused
		
		tea_state.available_elements.read_contents(file)
		tea_state.available_recipes.read_contents(file)
		hamster_state.level = file.get_8()
		hamster_state.unlocked.read_contents(file)
		hamster_state.current_grid.read_contents(file)
		hamster_state.record.read_contents(file)
		tea_state.stoe.read_contents(file)
		
		file.get_buffer(3)
		
		memo_state.read_contents(file)
		fukamaru_state.read_contents(file)
		photo_piece_state.interacted.read_contents(file)
		photo_piece_state.taken.read_contents(file)
		photo_piece_state.completed.read_contents(file)
		flags_items.read_contents(file)
		flags_menu_new.read_contents(file)
		tea_state.solved.read_contents(file)
		hamster_state.name = file.get_buffer(20).get_string_from_utf8() # NDS uses shift-jis
		photo_piece_state.pieces.read_contents(file)
		flags_tutorial.read_contents(file)
		
		file.get_8()
		
		id_event_held_autoevent = _u16_as_s16(file.get_16())
		id_event_immediate = _u16_as_s16(file.get_16())
		anthony_diary_state.read_contents(file)
		
		memo_state.last_page = file.get_8()
		id_last_jiten = file.get_8()
		flags_code_entry.read_contents(file)
		objective = file.get_16()
		flags_party_member.read_contents(file)
		
		file.close()
