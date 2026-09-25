class_name SoundscaperSettings extends RefCounted


const STRICT_MODE := &"audio/soundscaper/strict_mode"
const TODO_FILE := &"audio/soundscaper/todo_file"
const SOUNDBANK_DIR := &"audio/soundscaper/soundbank_dir"
const FALLBACK_EVENT_PATH := &"audio/soundscaper/fallback_event_path"
const SFX_POOL_SIZE := &"audio/soundscaper/sound_effect_pool_size"
const EVENT_SPECIFIER_METADATA_KEY := &"audio/soundscaper/event_specifier_metadata_key"


const SETTINGS := {
	STRICT_MODE: {
		"default": false,
		"flags": {
			"debug": true,
		},
	},
	TODO_FILE: {
		"default": "",
		"hint": PROPERTY_HINT_GLOBAL_SAVE_FILE,
		"flags": {
			"editor": "res://dev/sound_event_todo.txt",
			"debug": "user://sound_event_todo.txt",
		},
	},
	SOUNDBANK_DIR: {
		"default": "",
		"hint": PROPERTY_HINT_DIR,
	},
	FALLBACK_EVENT_PATH: {
		"default": "res://addons/soundscaper/fallback.tres",
		"hint": PROPERTY_HINT_FILE,
	},
	SFX_POOL_SIZE: {
		"default": 64,
		"hint": PROPERTY_HINT_DIR,
	},
	EVENT_SPECIFIER_METADATA_KEY: {
		"default": &"sfx_spec",
	},
}


static func register_settings() -> void:
	var index := 0
	for setting_name in SETTINGS:
		var setting: Dictionary = SETTINGS[setting_name]
		
		var setting_default: Variant = setting.get(&"default")
		var setting_type: int = typeof(setting_default)
		var setting_hint := setting.get(&"hint")
		var setting_hint_string := setting.get(&"hint_string")
		var setting_flags: Dictionary = setting.get(&"flags", {})
		
		var info := {
			"name": setting_name,
			"type": setting_type,
		}
		
		if setting_hint:
			info["hint"] = setting_hint
			if setting_hint_string:
				info["hint_string"] = setting_hint_string
		
		if not ProjectSettings.has_setting(setting_name):
			ProjectSettings.set_setting(setting_name, setting_default)
		# setting info
		ProjectSettings.set_order(setting_name, index)
		ProjectSettings.set_initial_value(setting_name, setting_default)
		ProjectSettings.add_property_info(info)
		# feature flag overrides
		for flag in setting_flags:
			var flag_value: Variant = setting_flags[flag]
			var full_setting_name := str(setting_name,".",flag)
			if not ProjectSettings.has_setting(full_setting_name):
				ProjectSettings.set_setting(full_setting_name, flag_value)
			ProjectSettings.set_order(full_setting_name, index)
			ProjectSettings.set_initial_value(full_setting_name, flag_value)
		
		index += 1


static func get_setting(setting_name: StringName) -> Variant:
	if not ProjectSettings.has_setting(setting_name):
		var setting: Dictionary = SETTINGS.get(setting_name)
		var setting_flags: Dictionary = setting.get("flags", {})
		for flag in setting_flags:
			if OS.has_feature(flag):
				return setting_flags[flag]
		return setting.get(&"default")
	return ProjectSettings.get_setting_with_override(setting_name)
