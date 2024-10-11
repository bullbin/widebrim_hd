extends Node

# Some notes on audio implementation:
#     This is a very high level guess at what the game does with audio. There are some confirmed
#     behaviours:
#     - The game separates audio into different banks and loads each into different structures
#     - The game uses an ID system to resolve which bank audio should be played from
#     - The game has some polyphony between banks, i.e., certain banks can play different audio
#           simultaneously. Not all banks support this, e.g., BGM!
#
# In general this implementation follows enough of the original game that all audio effects play.
# It's not expected to replicate missing audio effects, polyphonic behaviours, etc. But it is worth
# remembering that LAYTON2HD uses a whole different audio engine to the DS games and manages to
# retain similar behaviour. The engine itself only ever accesses audio subsystems though high
# level functions to middleware which is mimicked here.

# TODO - 2_Sound_SE_Play_Preresolved_ID

class CriMonophonicChannel:
	extends Node2D
	
	var active_id = -1
	var player = null
	var vol_tween = create_tween()
	var loopmap := {}
	var path_base := ""
	var base_name := ""
	var base_name_alt := ""
	
	func _init(template_base : String, template_name : String, template_name_alt : String):
		path_base = template_base
		base_name = template_name
		base_name_alt = template_name_alt
		load_loopmap_dict(path_base % "metadata.csv")
	
	func _ready() -> void:
		player = AudioStreamPlayer.new()
		add_child(player)
	
	func kill_tween():
		vol_tween.kill()
	
	func load_loopmap_dict(path_dict):
		var file = FileAccess.open(Lt2Utils.get_asset_path(path_dict), FileAccess.READ)
		if file != null:
			while not file.eof_reached():
				var line = file.get_csv_line()
				if len(line) != 2:
					continue
				if not(line[1].is_valid_float()):
					continue
				loopmap[line[0]] = float(line[1])
			
			file.close()
	
	func fade_volume(target_vol : float, duration : float):
		kill_tween()
	
		# TODO - Global mixing for channel volumes
		target_vol = (1 - clamp(target_vol, 0, 1)) * -60
		vol_tween = create_tween()
		vol_tween.tween_property(player, "volume_db", target_vol, duration)
	
	func _get_path_from_id(id : int) -> String:
		if base_name_alt != "":
			if ResourceLoader.exists(Lt2Utils.get_asset_path(path_base % (base_name_alt % id))):
				return base_name_alt % id
		return base_name % id
	
	func _apply_loopmap_and_start_channel(id : int, audio : AudioStream, channel : AudioStreamPlayer, start_now : bool):
		channel.volume_db = 0
		
		var path_audio := _get_path_from_id(id)
		var loop_base := 0.0
		var loop := false
		
		if path_audio in loopmap:
			loop_base = loopmap[path_audio]
			loop = true
		
		channel.stream = audio
		channel.stream.loop = loop
		channel.stream.loop_offset = loop_base
		
		if start_now:
			channel.play()
	
	func replay(start_now : bool):
		play(active_id, start_now)
	
	func play(id : int, start_now : bool, allow_overlap : bool = false):
		var path_audio := _get_path_from_id(id)
		path_audio = path_base % path_audio
		play_preresolved(id, load(Lt2Utils.get_asset_path(path_audio)), start_now, allow_overlap) 
	
	func play_preresolved(id : int, audio : AudioStream, start_now : bool, allow_overlap : bool = false):
		kill_tween()
		
		# If already loaded, play the track if paused and stop
		if id == active_id:
			if start_now:
				if not(player.playing) or allow_overlap:
					player.play()
			else:
				player.stop()
			player.volume_db = 0
			return
		else:
			player.stop()
		
		# Else, load the next track
		active_id = id
		_apply_loopmap_and_start_channel(id, audio, player, start_now)

	func resume():
		player.play()
	
	func stop():
		player.stop()

class CriPolyphonicChannel:
	extends CriMonophonicChannel
	
	var polyphonic_limit : int = 1
	var player_inactive_idx : Array[int] = []
	
	func _init(template_base : String, template_name : String, template_name_alt : String, polyphonic_count : int):
		super(template_base, template_name, template_name_alt)
		polyphonic_limit = polyphonic_count
		active_id = {}
	
	func _ready() -> void:
		player = []
		var channel : AudioStreamPlayer = null
		for i in range(polyphonic_limit):
			channel = AudioStreamPlayer.new()
			channel.finished.connect(_remove_unused_player.bind(i))
			player_inactive_idx.append(i)
			player.append(channel)
			add_child(channel)
	
	func fade_volume(target_vol : float, duration : float):
		kill_tween()
		# TODO - Global mixing for channel volumes
		target_vol = (1 - clamp(target_vol, 0, 1)) * -60
		vol_tween = create_tween()
		vol_tween.set_parallel()
		for chan in player:
			vol_tween.tween_property(chan, "volume_db", target_vol, duration)
	
	func _remove_unused_player(target_idx : int):
		var target_key : int = -1
		for id in active_id:
			if active_id[id] == target_idx:
				target_key = id
				break
		
		if target_key == -1 or player[target_idx].playing:
			print("Bad: Audio ID removed too early!")
			return
		
		player[target_idx].stop()
		active_id.erase(target_key)
		player_inactive_idx.append(target_idx)
	
	func _get_spare_player(ids_to_keep : Array[int]) -> int:
		# Favor unused (stopped tracks are reclaimed)
		if player_inactive_idx.size() > 0:
			return player_inactive_idx.pop_back()
		
		var channel : AudioStreamPlayer = null
		for id in active_id:
			if id in ids_to_keep:
				continue
			
			channel = player[active_id[id]]
			if not(channel.playing):
				_stop_and_reclaim_player(id)
				return player_inactive_idx.pop_back()
		
		print("Bad: Could not reclaim audio node!")
		return -1
	
	func _stop_and_reclaim_player(id : int):
		if id not in active_id:
			return
		
		player[active_id[id]].stop()
		player_inactive_idx.append(active_id[id])
		active_id.erase(id)
	
	func play_preresolved(id : int, audio : AudioStream, start_now : bool, allow_overlap : bool = false):
		kill_tween()
		
		var channel : AudioStreamPlayer = null
		# If already loaded, play the track if paused and stop
		if id in active_id:
			channel = player[active_id[id]]
			if start_now:
				if not(channel.playing) or allow_overlap:
					channel.play()
			else:
				channel.stop()
			channel.volume_db = 0
			return
		
		# Else, load the next track
		var idx_spare_channel = _get_spare_player([])
		if idx_spare_channel == -1:
			return
		
		active_id[id] = idx_spare_channel
		channel = player[idx_spare_channel]
		_apply_loopmap_and_start_channel(id, audio, channel, start_now)
	
	func replay(start_now : bool):
		for id in active_id:
			play(id, start_now)

	func resume():
		for idx in range(polyphonic_limit):
			if idx not in player_inactive_idx:
				player[idx].play()
		
	func stop():
		# Do not reclaim, these may be resumed later. Will be classed as paused when reusing tracks
		for idx in range(polyphonic_limit):
			if idx not in player_inactive_idx:
				player[idx].stop()

# TODO - Polyphony is definitely used, number of simultaneous channels is unknown
@onready var _node_audio_bgm 	:= CriMonophonicChannel.new("sound/bgm/%s", "BG_%03d.ogg", "")
@onready var _node_audio_si 	:= CriPolyphonicChannel.new("sound/si/%s", "%03d.ogg", "231_%03d.ogg", 4)
@onready var _node_audio_ge 	:= CriPolyphonicChannel.new("sound/ge/%s", "%03d.ogg", "100_%03d.ogg", 4)
@onready var _node_audio_sy 	:= CriPolyphonicChannel.new("sound/sy/%s", "%03d.ogg", "", 4)
@onready var _node_audio_sample := AudioStreamPlayer.new()

func _ready():
	add_child(_node_audio_bgm)
	add_child(_node_audio_si)
	add_child(_node_audio_ge)
	add_child(_node_audio_sy)
	add_child(_node_audio_sample)

func play_bgm(id : int):
	# This is not accurate but the audio sections for both LAYTON2DS and LAYTON2HD
	#     don't disassemble nicely and it's faster to hack this then read assembly
	#     or do call fixups for everything
	
	# TODO - Check audio behaviour
	_node_audio_bgm.play(id, true)

func stop_bgm():
	# TODO - Not validated, just want to suppress
	_node_audio_bgm.stop()

func fade_bgm(target_vol : float):
	# TODO - Not accurate
	fade_bgm_2(target_vol, 0.5)

func play_bgm_2():
	print("Sound: Unimplemented Play BGM 2")

func fade_bgm_2(target_vol : float, duration : float):
	_node_audio_bgm.fade_volume(target_vol, duration)

func play_sample_sfx(id : int):
	_node_audio_sample.stop()
	_node_audio_sample.stream = Lt2Utils.get_sample_audio_from_sfx_id(id)
	_node_audio_sample.play()

func play_preresolved_synth_sfx(id : int, audio : AudioStream, allow_overlap : bool = false):
	if id >= 200:
		_node_audio_si.play_preresolved(id, audio, true, allow_overlap)
	elif id >= 50:
		_node_audio_ge.play_preresolved(id, audio, true, allow_overlap)
	else:
		_node_audio_sy.play_preresolved(id, audio, true, allow_overlap)

func play_synth_sfx(id : int, allow_overlap : bool = false):
	# TODO - Not strictly correct, this doesn't handle edge cases
	# Some IDs are multipart, the SDK can also have 4len IDs but this isn't used
	if id >= 200:
		_node_audio_si.play(id, true, allow_overlap)
	elif id >= 50:
		_node_audio_ge.play(id, true, allow_overlap)
	else:
		_node_audio_sy.play(id, true, allow_overlap)

func play_voiceline(id_root : int, id_sub : int):
	_node_audio_sample.stop()
	_node_audio_sample.stream = load(Lt2Utils.get_asset_path("sound/%03d_%d.ogg" % [id_root, id_sub]))
	_node_audio_sample.play()

func stop_voiceline():
	_node_audio_sample.stop()

func play_env(id : int):
	# Uses ID to find channel to resume!
	if id >= 200:
		# SI
		_node_audio_si.resume()
	elif id >= 50:
		# GE
		_node_audio_ge.resume()
	
func stop_env():
	_node_audio_ge.stop()
	_node_audio_si.stop()

# REF - 2_Sound_LoadSoundSet
func load_environment(dlzSoundSet : DlzSoundSet, id_env : int, immediate_bgm : bool):
	# Each area is assigned an 'environment' of sound. These are stored in the Sound Set DLZ
	# I don't entirely understand what this is doing (it seems to rely on files being missing
	#     to work correctly and the addressing is strange). Some of the magic appears to be
	#     dependent on how Criware/Procyon is packaging the files - they can have an ID and sub-ID
	#     and sound effects usually not permitted by ID range can be detected by sub-ID.
	
	# TODO - Clean up syntax by just overriding entry_ev -1 entries to current stored IDs
	
	var entry_env = dlzSoundSet.find_entry(id_env)
	if entry_env == null:
		return

	print("Env ", id_env, " BGM", entry_env.id_bgm, " GE", entry_env.id_sfx_ge, " SI", entry_env.id_sfx_si)
	
	if entry_env.id_sfx_si == -1:
		_node_audio_si.replay(false)
	else:
		_node_audio_si.play(entry_env.id_sfx_si, false)

	if entry_env.id_sfx_ge == -1:
		_node_audio_ge.replay(immediate_bgm)
	else:
		_node_audio_ge.play(entry_env.id_sfx_ge, immediate_bgm)
	
	if entry_env.id_bgm == -1:
		_node_audio_bgm.replay(immediate_bgm)
	else:
		_node_audio_bgm.play(entry_env.id_bgm, immediate_bgm)
