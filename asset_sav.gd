# Note: I haven't looked much into the HD state system, so types aren't guaranteed
# This is based on the NDS version. Should be very, very similar
class_name Lt2AssetSaveSlot

extends Object

var _name : String 			= "NO NAME"
var _is_complete : bool 	= false

var flags_event_viewed 	= AddressableBitField.new(128)
var flags_storyflag		= AddressableBitField.new(16)
var flags_event_counter = AddressableBitField.new(128)
var flags_items 		= AddressableBitField.new(1)
var flags_menu_new 		= AddressableBitField.new(2)
var flags_photo_piece 	= AddressableBitField.new(2)
var flags_tutorial 		= AddressableBitField.new(2)
var flags_party_member 	= AddressableBitField.new(1)

var _header_time_elapsed 				= 0
var _header_count_puzzle_solved	 		= 0
var _header_count_puzzle_encountered 	= 0
var _header_idx_last_room 				= 0

var hint_coin_encountered 		= 10
var hint_coin_remaining 		= 10

var _id_room 		= 1
var _id_room_sub 	= 0
var _time_elapsed 	= 0
var _chapter 		= 5

var _picarats 		= 0
#var _flags_memo 		= PackedByteArray()

var id_event_held_autoevent = -1
var id_event_immediate		= -1

var _objective 		= 100

func _init():
	pass

func set_id_room(id : int):
	_id_room = id

func get_id_room() -> int:
	return _id_room
