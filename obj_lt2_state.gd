class_name Lt2State

extends Lt2AssetSaveSlot

const PATH_PLACEFLAG : String = "place/placeflag.dat"
const PATH_AUTOEVENT : String = "place/autoevent2.dat"
const PATH_STORYFLAG : String = "place/storyflag.dat"
const PATH_DLZ_EVINF : String = "rc/ev_inf2.dat"
const PATH_DLZ_TMDEF : String = "rc/tm_def.dat"
const PATH_DLZ_NZLST : String = "rc/nz_lst.dat"
const PATH_DLZ_EVFIX : String = "rc/ev_fix.dat"

var id_event : int = 0
var id_movie : int = 0
var id_voice : int = -1

var _gamemode 		: Lt2Constants.GAMEMODES = Lt2Constants.GAMEMODES.INVALID
var _gamemode_next 	: Lt2Constants.GAMEMODES = Lt2Constants.GAMEMODES.INVALID

var db_autoevent = Lt2DatabaseAutoEvent.new(PATH_AUTOEVENT)
var db_placeflag = Lt2DatabasePlaceFlag.new(PATH_PLACEFLAG)
var db_storyflag = Lt2DatabaseStoryFlag.new(PATH_STORYFLAG)
var dlz_ev_inf2  = DlzEventInfo.new(PATH_DLZ_EVINF)
var dlz_tm_def   = DlzTimeDefinition.new(PATH_DLZ_TMDEF)
var dlz_nz_lst   = DlzNazoList.new(PATH_DLZ_NZLST)
var dlz_ev_fix	 = DlzEventBase.new(PATH_DLZ_EVFIX)

var first_touch_enabled : bool = false

func _init():
	super()

func set_gamemode(gamemode : Lt2Constants.GAMEMODES):
	if Lt2Constants.GAMEMODES.find_key(gamemode) != null:
		_gamemode = gamemode
		return true
	_gamemode = Lt2Constants.GAMEMODES.INVALID
	return false
	
func set_gamemode_next(gamemode : Lt2Constants.GAMEMODES):
	if Lt2Constants.GAMEMODES.find_key(gamemode) != null:
		_gamemode_next = gamemode
		return true
	_gamemode_next = Lt2Constants.GAMEMODES.INVALID
	return false

func get_gamemode() -> Lt2Constants.GAMEMODES:
	return _gamemode

func get_gamemode_next() -> Lt2Constants.GAMEMODES:
	return _gamemode_next

func set_id_room(id : int):
	if id != get_id_room():
		id_event_held_autoevent = -1
	super(id)

func get_puzzle_state_internal(id_internal : int) -> Lt2AssetSaveSlot.PuzzleState:
	var entry_nazo = dlz_nz_lst.find_entry(id_internal)
	if entry_nazo != null:
		return get_puzzle_state_external(entry_nazo.id_external)
	return null

func get_event_viewed(id_event : int) -> bool:
	var entry_event = dlz_ev_fix.find_entry(id_event)
	if entry_event != null:
		return flags_event_viewed.get_bit(entry_event.idx_event_viewed)
	return false

func set_event_viewed(id_event : int, is_viewed : bool):
	var entry_event = dlz_ev_fix.find_entry(id_event)
	if entry_event != null:
		flags_event_viewed.set_bit(entry_event.idx_event_viewed, is_viewed)
