extends Lt2GamemodeBaseClass

var _is_interactable : bool = false

func _has_autoevent() -> bool:
	var collection = obj_state.db_autoevent.get_room_entries(obj_state.get_id_room())
	if collection == null:
		return false
	
	var entry = collection.get_entry(obj_state.chapter)
	if entry == null:
		return false
	
	var entry_ev_inf = obj_state.dlz_ev_inf2.find_entry(entry.id_event)
	if entry_ev_inf == null:
		obj_state.id_event = entry.id_event
		return true
		
	if entry_ev_inf.idx_event_viewed != obj_state.id_event_held_autoevent:
		if not(obj_state.flags_event_viewed.get_bit(entry_ev_inf.idx_event_viewed)):
			obj_state.id_event = entry.id_event
			return true
	return false

# Called when the node enters the scene tree for the first time.
func _ready():
	if _has_autoevent():
		# Will not have faded in, stop early.
		print("AutoEvent %d" % obj_state.id_event)
		obj_state.set_gamemode(Lt2Constants.GAMEMODES.DRAMA_EVENT)
		completed.emit()
	else:
		_load_room_data()

func _load_room_data():
	pass
	
func _update_chapter():
	var idx_chapter = obj_state.db_storyflag.get_group_index_from_chapter(obj_state.chapter)
	if idx_chapter == -1:
		idx_chapter = 0
	
	var storyflag_entry : Lt2DatabaseStoryFlag.StoryFlagEntry = null
	var condition_entry : Lt2DatabaseStoryFlag.StoryFlagConditional = null
	var nz_lst_entry : DlzNazoList.DlzEntryNzLst = null
	var puzzle_data : Lt2State.PuzzleState = null
	
	while idx_chapter < Lt2DatabaseStoryFlag.MAX_COUNT_CHAPTERS:
		
		storyflag_entry = obj_state.db_storyflag.get_group_at_index(idx_chapter)
		if storyflag_entry == null:
			return
		
		for idx_condition in range(Lt2DatabaseStoryFlag.MAX_COUNT_CONDITIONS):
			condition_entry = storyflag_entry.conditions[idx_condition]
			match condition_entry.type:
				1:
					if not(obj_state.flags_storyflag.get_bit(condition_entry.data)):
						obj_state.chapter = storyflag_entry.chapter
						return
				2:
					nz_lst_entry = obj_state.dlz_nz_lst.find_entry(condition_entry.data)
					if nz_lst_entry != null:
						puzzle_data = obj_state.get_puzzle_state(nz_lst_entry.id_external)
						if puzzle_data != null and not(puzzle_data.solved):
							obj_state.chaper = storyflag_entry.chapter
							return
				_:
					pass
		
		idx_chapter += 1

func _check_event_counter(entry : Lt2DatabasePlaceFlag.PlaceFlagSubRoomEntry) -> bool:
	if entry.idx_event_counter >= obj_state.flags_event_counter.get_byte_length():
		return false
	
	match entry.decode_mode:
		0:
			return obj_state.flags_event_counter.get_byte(entry.idx_event_counter) - entry.decode_data == 0
		1:
			return obj_state.flags_event_counter.get_byte(entry.idx_event_counter) - entry.decode_data != 0
		2:
			return entry.decode_data <= obj_state.flags_event_counter.get_byte(entry.idx_event_counter)
		_:
			return false

func _update_subroom():
	
	_update_chapter()
	
	var idx_subroom = 0
	var working_subroom = 0
	var placeflag_entry : Lt2DatabasePlaceFlag.PlaceFlagRoomEntry = obj_state.db_placeflag.get_room(obj_state.get_id_room())
	var placeflag_subroom_entry : Lt2DatabasePlaceFlag.PlaceFlagSubRoomEntry = null
	for proposed_subroom in range(1, Lt2DatabasePlaceFlag.COUNT_MAX_SUBROOMS):
		placeflag_subroom_entry = placeflag_entry.get_entry(proposed_subroom)
		if placeflag_subroom_entry.is_chapter_invalid():
			break
		
		working_subroom = idx_subroom
		if placeflag_subroom_entry.chapter_start <= obj_state.chapter and placeflag_subroom_entry.chapter_end >= obj_state.chapter:
			working_subroom = proposed_subroom
			
			if not(placeflag_subroom_entry.is_event_counter_invalid()):
				working_subroom = idx_subroom
				if _check_event_counter(placeflag_subroom_entry):
					working_subroom = proposed_subroom
			
		idx_subroom = working_subroom
	obj_state.set_id_subroom(idx_subroom)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
