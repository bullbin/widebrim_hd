class_name Lt2Constants

enum LANGUAGES {
	JP,
	EN_EU,
	EN_US,
	ES,
	FR,
	IT,
	DE,
	NL,
	KO
}

const LANGUAGE_TO_LANGUAGE = {
	LANGUAGES.JP 	: "jp",
	LANGUAGES.EN_EU : "en",
	LANGUAGES.EN_US : "en",
	LANGUAGES.ES 	: "es",
	LANGUAGES.FR 	: "fr",
	LANGUAGES.IT 	: "it",
	LANGUAGES.DE 	: "de",
	LANGUAGES.NL 	: "nl",
	LANGUAGES.KO	: "ko"
}

const LANGUAGE_TO_REGION = {
	LANGUAGES.JP	: "jp",
	LANGUAGES.EN_EU	: "eu",
	LANGUAGES.EN_US : "us",
	LANGUAGES.ES 	: "eu",
	LANGUAGES.FR 	: "eu",
	LANGUAGES.IT 	: "eu",
	LANGUAGES.DE 	: "eu",
	LANGUAGES.NL 	: "eu",
	LANGUAGES.KO 	: "eu"
}

enum SCRIPT_OPERANDS {
	INVALID,
	EXIT_SCRIPT,
	FADE_IN,
	FADE_OUT,
	TEXT_WINDOW,
	SET_PLACE,
	SET_GAME_MODE,
	SET_END_GAME_MODE,
	SET_MOVIE_NUM,
	SET_DRAMA_EVENT_NUM,
	SET_AUTO_EVENT_NUM,
	SET_PUZZLE_NUM,
	SET_FONT_USER_COLOR,
	SET_NUM_TOUCH,
	ADD_MATCH,
	ADD_MATCH_SOLUTION,
	SET_GRID_POSITION,
	SET_GRID_SIZE,
	SET_BLOCK_SIZE,
	ADD_BLOCK,
	ADD_ON_OFF_BUTTON,
	ADD_SPRITE,
	SET_SHAPE_SOLUTION_POSITION,
	SET_MAX_DIST,
	ADD_TRACE_POINT,
	SET_FILL_POS,
	ADD_IN_POINT,
	ADD_OUT_POINT,
	SET_TRACE_CORRECT_ZONE,
	GRID_ADD_BLOCK,
	GRID_ADD_LETTER,
	ADD_CUP,
	SET_LIQUID_COLOR,
	LOAD_BG,
	LOAD_SUB_BG,
	SET_TYPE,
	SET_LINE_COLOR,
	SET_PEN_COLOR,
	SET_GRID_TYPE_RANGE,
	ENABLE_NANAME,
	ADD_TOUCH_POINT,
	ADD_CHECK_LINE,
	SPRITE_ON,
	SPRITE_OFF,
	DO_SPRITE_FADE,
	DRAW_CHAPTER,
	ADD_TOUCH_SPRITE,
	SET_SPRITE_ALPHA,
	SET_SPRITE_POS,
	WAIT_FRAME,
	FADE_IN_ONLY_MAIN,
	FADE_OUT_ONLY_MAIN,
	SET_EVENT_COUNTER,
	ADD_EVENT_COUNTER,
	OR_EVENT_COUNTER,
	MODIFY_BGPAL,
	MODIFY_SUB_BGPAL,
	ADD_TILE,
	ADD_POINT,
	SET_NUM_SOLUTION,
	ADD_TILE_SOLUTION,
	ADD_TILE_ROTATE_SOLUTION,
	ADD_SOLUTION,
	SET_SPRITE_ANIMATION,
	SET_PANCAKE_NUM,
	SET_ANSWER_BOX,
	SET_ANSWER,
	SET_DRAW_INPUT_BG,
	SET_KNIGHT_INFO,
	ADD_DRAG2,
	ADD_DRAG2_ANIM,
	ADD_DRAG2_POINT,
	ADD_DRAG2_CHECK,
	FADE_OUT_BGM,
	SET_TILE_ON_OFF2_INFO,
	ADD_TILE_ON_OFF2_CHECK,
	SET_ROSE_INFO,
	ADD_ROSE_WALL,
	SET_SLIDE2_INFO,
	ADD_SLIDE2_RANGE,
	ADD_SLIDE2_CHECK,
	ADD_SLIDE2_SPRITE,
	ADD_SLIDE2_OBJECT,
	ADD_SLIDE2_OBJECT_RANGE,
	TILE2_ADD_SPRITE,
	TILE2_ADD_POINT,
	TILE2_ADD_POINT_GRID,
	TILE2_ADD_OBJECT_NORMAL,
	TILE2_ADD_OBJECT_ROTATE,
	TILE2_ADD_OBJECT_RANGE,
	TILE2_ADD_CHECK_NORMAL,
	TILE2_ADD_CHECK_ROTATE,
	SET_VOICE_ID,
	PLAY_STREAM,
	PLAY_SOUND,
	FADE_IN_BGM,
	TILE2_SWAP_ON,
	GAME_OVER,
	PLAY_BGM,
	SKATE_SET_INFO,
	SKATE_ADD_WALL,
	PEG_SOL_ADD_OBJECT,
	COUPLE_SET_INFO,
	LAMP_SET_INFO,
	LAMP_ADD_LINE,
	WAIT_INPUT,
	SHAKE_BG,
	SHAKE_SUB_BG,
	WAIT_VSYNC_OR_PEN_TOUCH,
	TILE2_ADD_OBJECT_RANGE2,
	ADD_TILE_ON_OFF2_DISABLE,
	LAMP_ADD_DISABLE,
	ADD_MEMO,
	DO_HUKAMARU_ADD_SCREEN,
	FADE_OUT_FRAME,
	SET_EVENT_TEA,
	DO_SUB_ITEM_ADD_SCREEN,
	DO_STOCK_SCREEN,
	DO_NAZOBA_LIST_SCREEN,
	DO_ITEM_ADD_SCREEN,
	SET_SUB_ITEM,
	DO_SUB_GAME_ADD_SCREEN,
	RELEASE_ITEM,
	DO_SAVE_SCREEN,
	DRAW_FRAMES,
	HUKAMARU_CLEAR,
	SET_SPRITE_SHAKE,
	FADE_OUT_FRAME_MAIN,
	FADE_IN_FRAME,
	FADE_IN_FRAME_MAIN,
	FLASH_SCREEN,
	CHECK_COUNTER_AUTO_EVENT,
	DO_PHOTO_PIECE_ADD_SCREEN,
	TILE2_ADD_REPLACE,
	MAX_TRACE_RESULT,
	FADE_OUT_FRAME_SUB,
	FADE_IN_FRAME_SUB,
	ENV_STOP,
	FADE_OUT_BGM2,
	FADE_IN_BGM2,
	PLAY_BGM2,
	STOP_STREAM,
	WAIT_FRAME2,
	SESTOP,
	SET_REPEAT_AUTO_EVENT_ID,
	RELEASE_REPEAT_AUTO_EVENT_ID,
	SET_FIRST_TOUCH,
	MOKUTEKI_SCREEN,
	DO_NAMING_HAM_SCREEN,
	DO_LOST_PIECE_SCREEN,
	DO_IN_PARTY_SCREEN,
	DO_OUT_PARTY_SCREEN,
	SEPLAY,
	PLAY_STREAM2,
	DO_DIARY_ADD_SCREEN,
	ENDING_MESSAGE,
	EVENT_SELECT,
	RETURN_STATION_SCREEN,
	COMPLETE_WINDOW,
	ENV_PLAY,
	FADE_OUT_SE,
	ENDING_ADD_CHALLENGE,
	SET_SUB_TITLE,
	SET_FULL_SCREEN,
	SET_BRIDGE_INFO,
	SET_TRACE_INFO,
	SET_PEG_SOL_INFO,
	SET_PANCAKE_OFFSET,
	TILE2_KEY_OFFSET,
	SET_TRACE_ARROW,
	SET_BAND_TYPE,
	TILE2_TOUCH_COUNTER,
	DRAW_WAIT_INPUT,
	SET_EVENT_BAND_TYPE}

enum GAMEMODES {
	INVALID,
	RESET,
	ROOM,
	DRAMA_EVENT,
	MOVIE,
	START_PUZZLE,
	END_PUZZLE,
	STAY_PUZZLE,
	PUZZLE,
	UNK_NAZO,
	TITLE,
	NARRATION,
	SUB_CAMERA,
	SUB_HERB_TEA,
	SUB_HAMSTER,
	BAG,
	NAME,
	JITEN_BAG,
	MYSTERY,
	STAFF,
	JITEN_WIFI,
	MEMO,
	CHALLENGE,
	EVENT_TEA,
	UNK_SUB_PHOTO_0,
	UNK_SUB_PHOTO_1,
	SECRET_MENU,
	WIFI_SECRET_MENU,
	TOP_SECRET_MENU,
	JITEN_SECRET,
	ART_MODE,
	CHR_VIEW_MODE,
	MUSIC_MODE,
	VOICE_MODE,
	MOVIE_VIEW_MODE,
	HAMSTER_NAME,
	NINTENDO_WFC_SETUP,
	WIFI_DOWNLOAD_PUZZLE,
	PASSCODE,
	CODE_INPUT_PANDORA,
	CODE_INPUT_FUTURE,
	DIARY,
	NAZOBA
}

const STRING_TO_GAMEMODE_VALUE = {"room"		:GAMEMODES.ROOM,
								"drama event"   :GAMEMODES.DRAMA_EVENT,
								"puzzle"        :GAMEMODES.PUZZLE,
								"movie"         :GAMEMODES.MOVIE,
								"narration"     :GAMEMODES.NARRATION,
								"menu"          :GAMEMODES.BAG,
								"staff"         :GAMEMODES.STAFF,
								"name"          :GAMEMODES.HAMSTER_NAME,
								"challenge"     :GAMEMODES.CHALLENGE,
								"sub herb"      :GAMEMODES.SUB_HERB_TEA,
								"sub camera"    :GAMEMODES.SUB_CAMERA,
								"sub ham"       :GAMEMODES.SUB_HAMSTER,
								"passcode"      :GAMEMODES.PASSCODE,
								"diary"         :GAMEMODES.DIARY,
								"nazoba"        :GAMEMODES.NAZOBA}

const SCREEN_CONTROLLER_DEFAULT_FADE 	: float 	= 0.25

const TIMING_LT2_TO_MILLISECONDS		: float 	= 1.0/60.0

# 640 1024
# 768 1136
# 640 1252
const RESOLUTION_TARGET 				: Vector2i = Vector2i(768, 1252)
const CONFIG_GAME_LANGUAGE : LANGUAGES = LANGUAGES.EN_EU
