extends Node

var _node_audio_bgm 		: AudioStreamPlayer = null
var _callback_bgm			: Callable = Callable()
var _callback_bgm_done		: bool = true

var _node_audio_sfx 		: AudioStreamPlayer = null
var _callback_sfx			: Callable = Callable()
var _callback_sfx_done		: bool = true

var _node_audio_voice 		: AudioStreamPlayer = null
var _callback_voice 		: Callable = Callable()
var _callback_voice_done 	: bool = true

var _bgm_loopmap_dict 	= {}

func _ready():
	_node_audio_bgm = AudioStreamPlayer.new()
	_node_audio_bgm.finished.connect(stop_bgm)
	_node_audio_sfx = AudioStreamPlayer.new()
	_node_audio_voice = AudioStreamPlayer.new()
	_node_audio_voice.finished.connect(stop_voiceline)
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
	pass

func fade_bgm():
	pass

func play_bgm_2():
	pass

func fade_bgm_2():
	pass

func play_sfx(audio : AudioStream):
	audio.loop = false
	_node_audio_sfx.stream = audio
	_node_audio_sfx.play()

func play_voiceline(id_root : int, id_sub : int, callback : Callable = Callable()):
	var stream = load(Lt2Utils.get_asset_path("sound/%03d_%d.ogg" % [id_root, id_sub]))

	if _node_audio_voice.playing:
		_node_audio_voice.stop()
	
	_callback_voice = callback
	_callback_voice_done = false
	_node_audio_voice.stream = stream
	_node_audio_voice.play()

func stop_voiceline():
	if not(_callback_voice_done):
		if not(_callback_voice.is_null()):
			_callback_voice.call()
		_callback_voice_done = true
