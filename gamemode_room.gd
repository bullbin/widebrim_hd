extends Lt2GamemodeBaseClass

var _is_interactable : bool = false
var _place_data : Lt2AssetPlaceData = null

const PATH_DATA_PLACE : String = "place/data/n_place%d_%d.dat"
@onready var _node_anim_root : Control = get_node("anim_root")

var _node_bg_ani 		: Array[Lt2GodotAnimation] = []
var _node_event_spawner : Array[Lt2GodotAnimation] = []
var _node_exit			: Array[Lt2GodotAnimatedButton] = []

@onready var _text_place 		: Label = get_node("hud_ts/map_place/text_place")
@onready var _text_objective 	: Label = get_node("hud_ts/map_purpose/text_purpose")
@onready var _hud_ts			: Control	= get_node("hud_ts")

@onready var _btn_movemode		: Lt2GodotAnimatedButtonDeferred = get_node("hud_bs/movemode")

const EVENT_LIMIT_TEA : int = 30000
const EVENT_LIMIT_PUZZLE : int = 20000
const EVENT_LIMIT_MIN : int = 10000
const ID_EVENT_UNK	: int = 0x5303

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

func _set_event(id_event : int):
	if id_event < EVENT_LIMIT_TEA:
		if EVENT_LIMIT_PUZZLE <= id_event:
			var ev_entry = obj_state.dlz_ev_fix.find_entry(id_event)
			if ev_entry != null:
				var nz_state = obj_state.get_puzzle_state_internal(ev_entry.idx_puzzle_internal)
				if nz_state != null:
					if nz_state.solved:
						id_event += 2
					elif nz_state.encountered:
						id_event += 1
						if id_event == ID_EVENT_UNK:
							obj_state.set_event_viewed(id_event, true)
	else:
		# Tea related - not fully understood yet
		if obj_state.get_event_viewed(id_event):
			id_event += 4
			# TODO - Unknown here
		else:
			obj_state.set_event_viewed(id_event, true)
	
	var entry_inf = obj_state.dlz_ev_inf2.find_entry(id_event)
	if entry_inf == null:
		entry_inf = DlzEventInfo.DlzEntryEvInf2.new()
	
	match entry_inf.type_event:
		1:
			obj_state.set_event_viewed(id_event, true)
		2:
			if obj_state.get_event_viewed(id_event):
				id_event += 1
		5:
			var ev_entry = obj_state.dlz_ev_fix.find_entry(id_event)
			if ev_entry != null:
				if obj_state.get_puzzle_solved_count() >= ev_entry.idx_puzzle_internal:
					id_event += 2
				elif obj_state.get_event_viewed(id_event):
					id_event += 1
	
	obj_state.id_event = id_event
	obj_state.set_gamemode(Lt2Constants.GAMEMODES.DRAMA_EVENT)

func _do_on_movemode_start():
	# TODO - Click animation hidden, maybe modify btn code to ensure frame
	_btn_movemode.hide()
	for exit in _node_exit:
		exit.set_transparency(1.0)
		exit.show()
	
	print("MOVEMODE!")

func _do_on_event_start(idx : int):
	var trigger = _place_data.event_spawners[idx]
	print("EVENT ", trigger.id_event)
	_disable_all_triggers()
	_set_event(trigger.id_event)
	completed.emit()

func _do_on_tobj_start(idx : int):
	print(idx)
	
func _disable_all_triggers():
	pass

func _do_on_exit_start(idx : int):
	_disable_all_triggers()
	var exit = _place_data.exits[idx]
	
	if exit.does_spawn_event():
		print("EXIT EVENT ", exit.destination)
		# TODO - Do explamation effect
		_set_event(exit.destination)
		completed.emit()
	
	else:
		obj_state._id_room = exit.destination
		
		# TODO - Handoff (transition, same state reload, etc)
		obj_state.set_gamemode(Lt2Constants.GAMEMODES.ROOM)
		completed.emit()

func _do_on_hint_start(idx : int):
	print(idx)

# Called when the node enters the scene tree for the first time.
func _ready():
	node_screen_controller.configure_room_mode()
	_btn_movemode.activated.connect(_do_on_movemode_start)
	
	if _has_autoevent():
		# Will not have faded in, stop early.
		print("AutoEvent %d" % obj_state.id_event)
		obj_state.set_gamemode(Lt2Constants.GAMEMODES.DRAMA_EVENT)
		completed.emit()
	else:
		_load_room_data()

func _load_room_data():
	_update_subroom()
	print("Room data: %d@%d" % [obj_state.get_id_room(), obj_state.get_id_subroom()])
	_place_data = Lt2AssetPlaceData.new(PATH_DATA_PLACE % [obj_state.get_id_room(), obj_state.get_id_subroom()])

	var raw_text = FileAccess.open(Lt2Utils.get_asset_path("nazo/jiten/p_%d.txt" % _place_data.id_nametag), FileAccess.READ)
	if raw_text != null:
		_text_place.text = raw_text.get_as_text()
	else:
		_text_place.text = ""
	
	raw_text = FileAccess.open(Lt2Utils.get_asset_path("txt/mokuteki/goal_%d.txt" % obj_state.objective), FileAccess.READ)
	if raw_text != null:
		_text_objective.text = raw_text.get_as_text()
	else:
		_text_objective.text = ""
	
	node_screen_controller.set_background_bs("map/main%d.bgx" % _place_data.id_bg_main)
	node_screen_controller.set_background_ts("map/map%d.bgx" % _place_data.id_bg_sub)
	node_screen_controller.fade_in()
	
	_hud_ts.set_mapicon_position(_place_data.position_map)
	
	for bg_ani in _place_data.bg_anim:
		var anim = Lt2GodotAnimation.new("bgani/%s" % bg_ani.name)
		anim.set_flippable_position(bg_ani.pos)
		anim.set_animation_from_index(1)
		_node_anim_root.add_child(anim)
		_node_bg_ani.append(anim)
	
	var idx_spawner = 0
	for event_spawner in _place_data.event_spawners:
		if event_spawner.id_image != 0:
			var anim = Lt2GodotAnimation.new("eventobj/obj_%d.spr" % event_spawner.id_image)
			anim.set_flippable_position(event_spawner.bounding.position)
			anim.set_animation_from_index(1)
			_node_anim_root.add_child(anim)
			_node_event_spawner.append(anim)
		else:
			_node_event_spawner.append(null)
		
		var debug_zone = ActivatableRect.new()
		_node_anim_root.add_child(debug_zone)
		
		debug_zone.add_visualizer(Color(0,0,1.0))
		debug_zone.activated.connect(_do_on_event_start.bind(idx_spawner))
		debug_zone.size = event_spawner.bounding.size
		debug_zone.position = event_spawner.bounding.position
		idx_spawner += 1
	
	idx_spawner = 0
	for tobj in _place_data.t_objs:
		var zone = ActivatableRect.new()
		zone.position = tobj.bounding.position
		zone.size = tobj.bounding.size
		zone.activated.connect(_do_on_tobj_start.bind(idx_spawner))
		_node_anim_root.add_child(zone)
		idx_spawner += 1
	
	idx_spawner = 0
	for hint in _place_data.hint_coins:
		var zone = ActivatableRect.new()
		zone.position = hint.bounding.position
		zone.size = hint.bounding.size
		zone.activated.connect(_do_on_hint_start.bind(idx_spawner))
		_node_anim_root.add_child(zone)
		idx_spawner += 1
	
	idx_spawner = 0
	for exit in _place_data.exits:
		var node = Lt2GodotAnimatedButton.new("map/exit_%d.spr" % exit.id_image, "gfx2", "gfx", "", false, null)
		node.position = exit.bounding.position
		
		if exit.allow_immediate_activation():
			node.set_transparency(0.0)
		else:
			node.hide()
		
		node.set_custom_boundary(exit.bounding.size)
		node.activated.connect(_do_on_exit_start.bind(idx_spawner))
		_node_anim_root.add_child(node)
		_node_exit.append(node)
		
		idx_spawner += 1
	
func _parse_loaded_data():
	pass
	
func _update_chapter():
	var idx_chapter = obj_state.db_storyflag.get_group_index_from_chapter(obj_state.chapter)
	if idx_chapter == -1:
		idx_chapter = 0
	print("Storyflag update - chapter index ", idx_chapter, " (", obj_state.chapter, ")")
	
	var storyflag_entry : Lt2DatabaseStoryFlag.StoryFlagEntry = null
	var condition_entry : Lt2DatabaseStoryFlag.StoryFlagConditional = null
	var nz_lst_entry : DlzNazoList.DlzEntryNzLst = null
	var puzzle_data : Lt2State.PuzzleState = null
	
	while idx_chapter < Lt2DatabaseStoryFlag.MAX_COUNT_CHAPTERS:
		
		storyflag_entry = obj_state.db_storyflag.get_group_at_index(idx_chapter)
		print("\tTesting ", idx_chapter)
		if storyflag_entry == null:
			print("\tNull response.")
			return
		
		for idx_condition in range(Lt2DatabaseStoryFlag.MAX_COUNT_CONDITIONS):
			condition_entry = storyflag_entry.conditions[idx_condition]
			match condition_entry.type:
				1:
					print("\t\tStoryflag check, bit ", condition_entry.data)
					if not(obj_state.flags_storyflag.get_bit(condition_entry.data)):
						obj_state.chapter = storyflag_entry.chapter
						return
				2:
					nz_lst_entry = obj_state.dlz_nz_lst.find_entry(condition_entry.data)
					if nz_lst_entry != null:
						puzzle_data = obj_state.get_puzzle_state(nz_lst_entry.id_external)
						if puzzle_data != null and not(puzzle_data.solved):
							obj_state.chapter = storyflag_entry.chapter
							return
				_:
					pass
		
		idx_chapter += 1
	
	print("Chapter updated, now ", obj_state.chapter)

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
	
	print("Subroom updated, now ", idx_subroom)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
