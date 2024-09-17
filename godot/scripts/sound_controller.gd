extends Node

var _node_audio_bgm 		: AudioStreamPlayer = null
var _bgm_queued_id			: int 				= -1
var _callback_bgm			: Callable = Callable()
var _callback_bgm_done		: bool = true
var _bgm_active_tween		: Tween = null

var _node_audio_sfx 		: AudioStreamPlayer = null
var _callback_sfx			: Callable = Callable()
var _callback_sfx_done		: bool = true

var _node_audio_voice 		: AudioStreamPlayer = null
var _callback_voice 		: Callable = Callable()
var _callback_voice_done 	: bool = true

var _bgm_loopmap_dict 	= {}

signal on_sfx_done
signal on_voice_done
signal on_bgm_done

func _ready():
	_node_audio_bgm = AudioStreamPlayer.new()
	_node_audio_bgm.finished.connect(stop_bgm)
	_node_audio_sfx = AudioStreamPlayer.new()
	_node_audio_voice = AudioStreamPlayer.new()
	_node_audio_voice.finished.connect(stop_voiceline)
	
	_node_audio_sfx.finished.connect(Callable(on_sfx_done.emit))
	
	add_child(_node_audio_bgm)
	add_child(_node_audio_sfx)
	add_child(_node_audio_voice)
	
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

func play_bgm(id : int):
	# This is not accurate but the audio sections for both LAYTON2DS and LAYTON2HD
	#     don't disassemble nicely and it's faster to hack this then read assembly
	#     or do call fixups for everything
	
	# TODO - Check audio behaviour
	if _bgm_active_tween != null:
		_bgm_active_tween.kill()
	_node_audio_bgm.volume_db = 0
		
	if id == _bgm_queued_id:
		return
	
	_bgm_queued_id = id
	var id_base 	: String = "BG_%03d.ogg" % id
	var loop_base 	: float = 0
	
	if id_base in _bgm_loopmap_dict:
		loop_base = _bgm_loopmap_dict[id_base]
	else:
		print("Audio: BGM missing key in loopmap dict!")
	
	id_base = Lt2Utils.get_asset_path("sound/bgm/%s" % id_base)
	if not(ResourceLoader.exists(id_base)):
		print("Audio: BGM failed loading, targetted resource %s" % id_base)
		return
	
	var audio : AudioStreamOggVorbis = load(id_base)
	audio.loop = true
	audio.loop_offset = loop_base
	_node_audio_bgm.stream = audio
	_node_audio_bgm.play()

func stop_bgm():
	print("Sound: Unimplemented Stop BGM")

func fade_bgm(target_vol : float):
	# TODO - Not accurate
	fade_bgm_2(target_vol, 0.5)

func play_bgm_2():
	print("Sound: Unimplemented Play BGM 2")

func fade_bgm_2(target_vol : float, duration : float):
	# TODO - Set quadratic falloff instead of linear
	if _bgm_active_tween != null:
		_bgm_active_tween.kill()
	
	# TODO - Global mixing for channel volumes
	target_vol = (1 - clamp(target_vol, 0, 1)) * -60
		
	var _bgm_active_tween = get_tree().create_tween()
	_bgm_active_tween.finished.connect(Callable(on_bgm_done.emit))
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
