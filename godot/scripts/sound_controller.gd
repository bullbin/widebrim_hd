extends Node

@onready var _node_audio_bgm 	: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var _node_audio_sfx 	: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var _node_audio_voice 	: AudioStreamPlayer = AudioStreamPlayer.new()

var _callback_voice 			: Callable = Callable()
var _callback_voice_done 		: bool = true

# TODO - Not accurate!
@onready var _node_audio_env_si : AudioStreamPlayer = AudioStreamPlayer.new()
@onready var _node_audio_env_ge : AudioStreamPlayer = AudioStreamPlayer.new()

@onready var _bgm_active_tween	: Tween = create_tween()

var _bgm_queued_id			: int 				= -1
var _si_queued_id			: int 				= -1
var _ge_queued_id			: int 				= -1

var _bgm_loopmap_dict 	= {}
var _ge_loopmap_dict = {}
var _si_loopmap_dict = {}

signal on_sfx_done
signal on_voice_done

# TODO - 2_Sound_SE_Play_Preresolved_ID
# Game splits into channels per voice bank, not like this
#     Doesn't explain how ENV works though

func _ready():
	_node_audio_bgm.finished.connect(stop_bgm)
	_node_audio_voice.finished.connect(stop_voiceline)
	_node_audio_sfx.finished.connect(Callable(on_sfx_done.emit))
	
	add_child(_node_audio_bgm)
	add_child(_node_audio_sfx)
	add_child(_node_audio_voice)
	add_child(_node_audio_env_si)
	add_child(_node_audio_env_ge)
	
	var file = FileAccess.open(Lt2Utils.get_asset_path("sound/bgm/metadata.csv"), FileAccess.READ)
	if file != null:
		while not file.eof_reached():
			var line = file.get_csv_line()
			if len(line) != 2:
				continue
			if not(line[1].is_valid_float()):
				continue
			_bgm_loopmap_dict[line[0]] = float(line[1])
		
		file.close()
	
	file = FileAccess.open(Lt2Utils.get_asset_path("sound/ge/metadata.csv"), FileAccess.READ)
	if file != null:
		while not file.eof_reached():
			var line = file.get_csv_line()
			if len(line) != 2:
				continue
			if not(line[1].is_valid_float()):
				continue
			_ge_loopmap_dict[line[0]] = float(line[1])
		
		file.close()
	
	file = FileAccess.open(Lt2Utils.get_asset_path("sound/si/metadata.csv"), FileAccess.READ)
	if file != null:
		while not file.eof_reached():
			var line = file.get_csv_line()
			if len(line) != 2:
				continue
			if not(line[1].is_valid_float()):
				continue
			_si_loopmap_dict[line[0]] = float(line[1])
		
		file.close()

func _kill_tween():
	_bgm_active_tween.kill()

func play_bgm(id : int):
	# This is not accurate but the audio sections for both LAYTON2DS and LAYTON2HD
	#     don't disassemble nicely and it's faster to hack this then read assembly
	#     or do call fixups for everything
	
	# TODO - Check audio behaviour
	_kill_tween()
	_node_audio_bgm.volume_db = 0
		
	if id == _bgm_queued_id:
		return
	
	_bgm_queued_id = id
	var id_base 	: String = "BG_%03d.ogg" % id
	var loop_base 	: float = 0
	
	if id_base in _bgm_loopmap_dict:
		loop_base = _bgm_loopmap_dict[id_base]
	
	id_base = Lt2Utils.get_asset_path("sound/bgm/%s" % id_base)
	if not(ResourceLoader.exists(id_base)):
		print("Audio: BGM failed loading, targetted resource %s" % id_base)
		_node_audio_bgm.stop()
		return
	
	var audio : AudioStreamOggVorbis = load(id_base)
	audio.loop = true
	audio.loop_offset = loop_base
	_node_audio_bgm.stream = audio
	_node_audio_bgm.play()

func stop_bgm():
	# TODO - Not validated, just want to suppress
	_kill_tween()
	_node_audio_bgm.stop()

func fade_bgm(target_vol : float):
	# TODO - Not accurate
	fade_bgm_2(target_vol, 0.5)

func play_bgm_2():
	print("Sound: Unimplemented Play BGM 2")

func fade_bgm_2(target_vol : float, duration : float):
	# TODO - Set quadratic falloff instead of linear
	_kill_tween()
	
	# TODO - Global mixing for channel volumes
	target_vol = (1 - clamp(target_vol, 0, 1)) * -60
	_bgm_active_tween = create_tween()
	_bgm_active_tween.tween_property(_node_audio_bgm, "volume_db", target_vol, duration)

func play_sfx(audio : AudioStream) -> bool:
	if _node_audio_sfx.playing:
		_node_audio_sfx.stop()
		_node_audio_sfx.finished.emit()

	if audio != null:
		audio.loop = false
		_node_audio_sfx.stream = audio
		_node_audio_sfx.play()
	return audio != null

func play_voiceline(id_root : int, id_sub : int, callback : Callable = Callable()):
	var stream = load(Lt2Utils.get_asset_path("sound/%03d_%d.ogg" % [id_root, id_sub]))

	if _node_audio_voice.playing:
		_node_audio_voice.stop()
	
	_callback_voice = callback
	_callback_voice_done = false
	_node_audio_voice.stream = stream
	_node_audio_voice.play()

func stop_voiceline():
	on_voice_done.emit()
	if not(_callback_voice_done):
		if not(_callback_voice.is_null()):
			_callback_voice.call()
		_callback_voice_done = true

func play_env(id : int):
	# Uses ID to find channel to resume!
	if id >= 200:
		# SI
		_node_audio_env_si.play()
	elif id >= 50:
		# GE
		_node_audio_env_ge.play()
	
func stop_env():
	_node_audio_env_ge.stop()
	_node_audio_env_si.stop()

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
	
	var target_path = ""
	var name_file = ""
	var audio_temp : AudioStream = null
	print("Env ", id_env, " BGM", entry_env.id_bgm, " GE", entry_env.id_sfx_ge, " SI", entry_env.id_sfx_si)
	
	if _node_audio_env_si.playing:
		_node_audio_env_si.stop()
		
	if entry_env.id_sfx_si != -1 and entry_env.id_sfx_si != _si_queued_id:
		# HACK - not accurate
		if entry_env.id_sfx_si < 200:
			target_path = "sound/si/231_%03d.ogg" % entry_env.id_sfx_si	# 230 also has extra IDs...
		else:
			target_path = "sound/si/%03d.ogg" % entry_env.id_sfx_si
		
		name_file = target_path.split("/")[-1]
		target_path = Lt2Utils.get_asset_path(target_path)
		
		_node_audio_env_si.stream = null
		if ResourceLoader.exists(target_path):
			audio_temp = load(target_path)
			if audio_temp != null:
				if name_file in _si_loopmap_dict:
					audio_temp.loop = true
					audio_temp.loop_offset = _si_loopmap_dict[name_file]
					
				_node_audio_env_si.stream = audio_temp
				# NOTE - Playing this seems wrong, often it's door opening noises which we don't want

	if (_node_audio_env_ge.playing and entry_env.id_sfx_ge != -1 and _ge_queued_id != entry_env.id_sfx_ge) or not(immediate_bgm):
		_node_audio_env_ge.stop()
		
	if entry_env.id_sfx_ge != -1 and entry_env.id_sfx_ge != _ge_queued_id:
		# HACK - not accurate
		if entry_env.id_sfx_ge < 100:
			target_path = "sound/ge/100_%03d.ogg" % entry_env.id_sfx_ge
		else:
			target_path = "sound/ge/%03d.ogg" % entry_env.id_sfx_ge
			
		name_file = target_path.split("/")[-1]
		target_path = Lt2Utils.get_asset_path(target_path)

		_node_audio_env_ge.stream = null
		if ResourceLoader.exists(target_path):
			audio_temp = load(target_path)
			if audio_temp != null:
				if name_file in _ge_loopmap_dict:
					audio_temp.loop = true
					audio_temp.loop_offset = _ge_loopmap_dict[name_file]
					
				_node_audio_env_ge.stream = audio_temp
	
	if entry_env.id_sfx_si != -1:
		_si_queued_id = entry_env.id_sfx_si
	if entry_env.id_sfx_ge != -1:
		_ge_queued_id = entry_env.id_sfx_ge
	
	if immediate_bgm:
		# TODO - Check if BGM stops before this
		if not(_node_audio_env_ge.playing):
			_node_audio_env_ge.play()
		if entry_env.id_bgm != -1:
			play_bgm(entry_env.id_bgm)
