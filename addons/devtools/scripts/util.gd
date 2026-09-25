class_name DEV_Util extends RefCounted


const EXACT_MATCH_BONUS          := 1000
const PREFIX_MATCH_BONUS         := 500  # Input is a prefix of the candidate
const SUBSTRING_MATCH_BONUS      := 200  # Input is found within the candidate (not at the start)
const FUZZY_MATCH_BONUS_PER_CHAR := 50   # For matches allowing typos/skipped chars
const CASE_MATCH_BONUS           := 10   # Extra points if case matches exactly
const HISTORY_BOOST_FACTOR       := 1.5  # Multiplier for items found in recent history
const CONSECUTIVE_CHAR_BONUS     := 20   # Bonus for each consecutive matching char in fuzzy/substring


static func cleanup_string(text: String) -> String:
	return text.to_lower().remove_chars("~").strip_edges()


static func get_default_window_size() -> Vector2i:
	var window_width := ProjectSettings.get_setting_with_override(&"display/window/size/window_width_override")
	var window_height := ProjectSettings.get_setting_with_override(&"display/window/size/window_height_override")
	
	if not window_width:
		window_width = ProjectSettings.get_setting_with_override(&"display/window/size/viewport_width")
	
	if not window_height:
		window_height = ProjectSettings.get_setting_with_override(&"display/window/size/viewport_height")
	
	return Vector2i(window_width, window_height)


static func calculate_score(candidate_name: String, user_input: String, command_history: Array = []) -> float:
	var base_score: float = 0.0

	if user_input.is_empty(): # No input, no score (or maybe score history?)
		# Optionally return a small base score for history items even with empty input?
		return 0.0

	# --- Basic Match Scoring ---
	if candidate_name == user_input:
		base_score = EXACT_MATCH_BONUS
	elif candidate_name.begins_with(user_input):
		base_score = PREFIX_MATCH_BONUS
		# Optional bonus: score higher if input is closer to full candidate length
		# var length_ratio = float(user_input.length()) / candidate_name.length()
		# base_score += length_ratio * 50 # Example bonus
	elif candidate_name.find(user_input) != -1:
		base_score = SUBSTRING_MATCH_BONUS
		# Optional penalty: Reduce score if match starts later in the string
		# var match_pos = candidate_name_lower.find(user_input_lower)
		# base_score -= match_pos * 5 # Example penalty
	else:
		# Try Fuzzy Match (Simplified - score based on matching chars in order)
		# Real fuzzy matching (like Levenshtein distance) is more complex.
		var fuzzy_score: float = calculate_fuzzy_score(candidate_name, user_input)
		if fuzzy_score > 0:
			# Ensure fuzzy doesn't overwrite a better match type unless it's higher
			base_score = max(base_score, fuzzy_score)
	
	# If no match found yet, return 0
	if base_score == 0.0:
		return 0.0
	
	# --- Refinements & Boosts ---
	var final_score: float = base_score
	
	## Type Weighting
	#var type_multiplier: float = 1.0
	#final_score *= type_multiplier
	
	# History Boost
	if candidate_name in command_history:
		# Could use frequency/recency from history for a more nuanced boost
		final_score *= HISTORY_BOOST_FACTOR
	
	# (Optional) Consecutive Character Bonus was partly included in fuzzy calc
	
	return final_score


static func calculate_fuzzy_score(candidate_lower: String, user_input_lower: String) -> float:
	if user_input_lower.is_empty(): return 0.0
	
	var score: float = 0.0
	var last_index: int = -1
	var consecutive_count: int = 0
	
	for i in range(user_input_lower.length()):
		var char_input = user_input_lower[i]
		# Find the next occurrence of char_input after last_index
		var found_index = candidate_lower.find(char_input, last_index + 1)
		
		if found_index != -1:
			score += FUZZY_MATCH_BONUS_PER_CHAR
			# Bonus for consecutive characters
			if found_index == last_index + 1:
				consecutive_count += 1
			else:
				# Add bonus for the previous run of consecutive chars (if any)
				if consecutive_count > 0:
					score += (consecutive_count * CONSECUTIVE_CHAR_BONUS)
				consecutive_count = 0 # Reset count for the new non-consecutive char
			
			last_index = found_index
		else:
			# Character not found in order, this is not a valid fuzzy match
			# according to this simple algorithm.
			return 0.0
	
	# Add bonus for the final run of consecutive chars (if any)
	if consecutive_count > 0:
		score += (consecutive_count * CONSECUTIVE_CHAR_BONUS)
	
	return score


static var shortcut_string_cache := {}


static func shortcut_from_string(string: String) -> Shortcut:
	if string.is_empty(): return null
	
	string = string.to_lower()
	
	if shortcut_string_cache.has(string):
		return shortcut_string_cache.get(string)
	
	var shortcut := Shortcut.new()
	
	var segs = string.split(',', false)
	for seg in segs:
		var event := event_from_string(seg)
		shortcut.events.append(event)
	
	return shortcut


static func event_from_string(string: String) -> InputEventKey:
	var event := InputEventKey.new()
	
	var segs := string.to_lower().split('+', false)
	
	for seg in segs:
		seg = seg.strip_edges()
		match seg:
			'shift': event.shift_pressed = true
			'ctrl': event.command_or_control_autoremap = true
			'alt': event.alt_pressed = true
			_:
				assert(event.key_label == KEY_NONE)
				assert(keys.has(seg))
				event.keycode = keys.get(seg)
	
	return event


static var keys := {
	'none': KEY_NONE,
	'special': KEY_SPECIAL,
	'escape': KEY_ESCAPE,
	'tab': KEY_TAB,
	'backtab': KEY_BACKTAB,
	'backspace': KEY_BACKSPACE,
	'enter': KEY_ENTER,
	'kp-enter': KEY_KP_ENTER,
	'insert': KEY_INSERT,
	'delete': KEY_DELETE,
	'pause': KEY_PAUSE,
	'print': KEY_PRINT,
	'sysreq': KEY_SYSREQ,
	'clear': KEY_CLEAR,
	'home': KEY_HOME,
	'end': KEY_END,
	'left': KEY_LEFT,
	'up': KEY_UP,
	'right': KEY_RIGHT,
	'down': KEY_DOWN,
	'pageup': KEY_PAGEUP,
	'pagedown': KEY_PAGEDOWN,
	'shift': KEY_SHIFT,
	'ctrl': KEY_CTRL,
	'meta': KEY_META,
	'alt': KEY_ALT,
	'capslock': KEY_CAPSLOCK,
	'numlock': KEY_NUMLOCK,
	'scrolllock': KEY_SCROLLLOCK,
	'f1': KEY_F1,
	'f2': KEY_F2,
	'f3': KEY_F3,
	'f4': KEY_F4,
	'f5': KEY_F5,
	'f6': KEY_F6,
	'f7': KEY_F7,
	'f8': KEY_F8,
	'f9': KEY_F9,
	'f10': KEY_F10,
	'f11': KEY_F11,
	'f12': KEY_F12,
	'f13': KEY_F13,
	'f14': KEY_F14,
	'f15': KEY_F15,
	'f16': KEY_F16,
	'f17': KEY_F17,
	'f18': KEY_F18,
	'f19': KEY_F19,
	'f20': KEY_F20,
	'f21': KEY_F21,
	'f22': KEY_F22,
	'f23': KEY_F23,
	'f24': KEY_F24,
	'f25': KEY_F25,
	'f26': KEY_F26,
	'f27': KEY_F27,
	'f28': KEY_F28,
	'f29': KEY_F29,
	'f30': KEY_F30,
	'f31': KEY_F31,
	'f32': KEY_F32,
	'f33': KEY_F33,
	'f34': KEY_F34,
	'f35': KEY_F35,
	'kp-multiply': KEY_KP_MULTIPLY,
	'kp-divide': KEY_KP_DIVIDE,
	'kp-subtract': KEY_KP_SUBTRACT,
	'kp-period': KEY_KP_PERIOD,
	'kp-add': KEY_KP_ADD,
	'kp-0': KEY_KP_0,
	'kp-1': KEY_KP_1,
	'kp-2': KEY_KP_2,
	'kp-3': KEY_KP_3,
	'kp-4': KEY_KP_4,
	'kp-5': KEY_KP_5,
	'kp-6': KEY_KP_6,
	'kp-7': KEY_KP_7,
	'kp-8': KEY_KP_8,
	'kp-9': KEY_KP_9,
	'menu': KEY_MENU,
	'hyper': KEY_HYPER,
	'help': KEY_HELP,
	'back': KEY_BACK,
	'forward': KEY_FORWARD,
	'stop': KEY_STOP,
	'refresh': KEY_REFRESH,
	'volumedown': KEY_VOLUMEDOWN,
	'volumemute': KEY_VOLUMEMUTE,
	'volumeup': KEY_VOLUMEUP,
	'mediaplay': KEY_MEDIAPLAY,
	'mediastop': KEY_MEDIASTOP,
	'mediaprevious': KEY_MEDIAPREVIOUS,
	'medianext': KEY_MEDIANEXT,
	'mediarecord': KEY_MEDIARECORD,
	'homepage': KEY_HOMEPAGE,
	'favorites': KEY_FAVORITES,
	'search': KEY_SEARCH,
	'standby': KEY_STANDBY,
	'openurl': KEY_OPENURL,
	'launchmail': KEY_LAUNCHMAIL,
	'launchmedia': KEY_LAUNCHMEDIA,
	'launch0': KEY_LAUNCH0,
	'launch1': KEY_LAUNCH1,
	'launch2': KEY_LAUNCH2,
	'launch3': KEY_LAUNCH3,
	'launch4': KEY_LAUNCH4,
	'launch5': KEY_LAUNCH5,
	'launch6': KEY_LAUNCH6,
	'launch7': KEY_LAUNCH7,
	'launch8': KEY_LAUNCH8,
	'launch9': KEY_LAUNCH9,
	'launcha': KEY_LAUNCHA,
	'launchb': KEY_LAUNCHB,
	'launchc': KEY_LAUNCHC,
	'launchd': KEY_LAUNCHD,
	'launche': KEY_LAUNCHE,
	'launchf': KEY_LAUNCHF,
	'globe': KEY_GLOBE,
	'keyboard': KEY_KEYBOARD,
	'jis-eisu': KEY_JIS_EISU,
	'jis-kana': KEY_JIS_KANA,
	'unknown': KEY_UNKNOWN,
	'space': KEY_SPACE,
	'exclam': KEY_EXCLAM,
	'quotedbl': KEY_QUOTEDBL,
	'numbersign': KEY_NUMBERSIGN,
	'dollar': KEY_DOLLAR,
	'percent': KEY_PERCENT,
	'ampersand': KEY_AMPERSAND,
	'apostrophe': KEY_APOSTROPHE,
	'parenleft': KEY_PARENLEFT,
	'parenright': KEY_PARENRIGHT,
	'asterisk': KEY_ASTERISK,
	'plus': KEY_PLUS,
	'comma': KEY_COMMA,
	'minus': KEY_MINUS,
	'period': KEY_PERIOD,
	'slash': KEY_SLASH,
	'0': KEY_0,
	'1': KEY_1,
	'2': KEY_2,
	'3': KEY_3,
	'4': KEY_4,
	'5': KEY_5,
	'6': KEY_6,
	'7': KEY_7,
	'8': KEY_8,
	'9': KEY_9,
	'colon': KEY_COLON,
	'semicolon': KEY_SEMICOLON,
	'less': KEY_LESS,
	'equal': KEY_EQUAL,
	'greater': KEY_GREATER,
	'question': KEY_QUESTION,
	'at': KEY_AT,
	'a': KEY_A,
	'b': KEY_B,
	'c': KEY_C,
	'd': KEY_D,
	'e': KEY_E,
	'f': KEY_F,
	'g': KEY_G,
	'h': KEY_H,
	'i': KEY_I,
	'j': KEY_J,
	'k': KEY_K,
	'l': KEY_L,
	'm': KEY_M,
	'n': KEY_N,
	'o': KEY_O,
	'p': KEY_P,
	'q': KEY_Q,
	'r': KEY_R,
	's': KEY_S,
	't': KEY_T,
	'u': KEY_U,
	'v': KEY_V,
	'w': KEY_W,
	'x': KEY_X,
	'y': KEY_Y,
	'z': KEY_Z,
	'bracketleft': KEY_BRACKETLEFT,
	'backslash': KEY_BACKSLASH,
	'bracketright': KEY_BRACKETRIGHT,
	'asciicircum': KEY_ASCIICIRCUM,
	'underscore': KEY_UNDERSCORE,
	'tilde': KEY_QUOTELEFT,
	'braceleft': KEY_BRACELEFT,
	'bar': KEY_BAR,
	'braceright': KEY_BRACERIGHT,
	'asciitilde': KEY_ASCIITILDE,
	'yen': KEY_YEN,
	'section': KEY_SECTION,
}
