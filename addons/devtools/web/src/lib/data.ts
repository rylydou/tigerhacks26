export const dummyCommands = [
	{
		"id": "quit_app",
		"name": "Quit Application",
		"description": "Immediately terminate the application process."
	},
	{
		"id": "reload_scene",
		"name": "Reload Scene",
		"description": "Forces a reload of the current active game or UI scene."
	},
	{
		"id": "toggle_debug_ui",
		"name": "Toggle Debug UI",
		"description": "Shows or hides the internal debug overlay with statistics."
	},
	{
		"id": "spawn_item_1",
		"name": "Spawn Item: Health Potion",
		"description": "Adds a standard Health Potion to the player's inventory."
	},
	{
		"id": "god_mode_on",
		"name": "God Mode (On)",
		"description": "Enables invulnerability and infinite resources for the player."
	},
	{
		"id": "god_mode_off",
		"name": "God Mode (Off)",
		"description": "Disables invulnerability and returns the player to normal state."
	},
	{
		"id": "noclip_toggle",
		"name": "Toggle Noclip",
		"description": "Allows the camera/player to move freely through geometry."
	},
	{
		"id": "set_time_noon",
		"name": "Set Time: Noon",
		"description": "Sets the in-game time to 12:00 (midday)."
	},
	{
		"id": "add_currency_1000",
		"name": "Add Currency: 1000",
		"description": "Grants the player 1000 units of the primary in-game currency."
	},
	{
		"id": "teleport_hub",
		"name": "Teleport: Main Hub",
		"description": "Instantly moves the player character to the main city or hub location."
	},
	{
		"id": "log_memory_usage",
		"name": "Log Memory",
		"description": "Dumps the current application memory usage to the console."
	},
	{
		"id": "take_screenshot",
		"name": "Take Screenshot",
		"description": "Captures a high-resolution screenshot and saves it to a designated folder."
	},
	{
		"id": "skip_level",
		"name": "Skip Current Level",
		"description": "Immediately completes the current level/mission and loads the next one."
	},
	{
		"id": "clear_logs",
		"name": "Clear Console Logs",
		"description": "Wipes all messages from the in-game developer console."
	},
	{
		"id": "set_framerate_30",
		"name": "Cap FPS: 30",
		"description": "Sets the maximum rendering framerate to 30 frames per second for testing."
	},
	{
		"id": "toggle_collision_vis",
		"name": "Toggle Collision Visuals",
		"description": "Shows wireframe boxes for all physics collision shapes."
	},
	{
		"id": "damage_player_10",
		"name": "Damage Player (10 HP)",
		"description": "Reduces the player's health by a fixed amount (10 points)."
	},
	{
		"id": "reset_stats",
		"name": "Reset Player Stats",
		"description": "Clears all character progression, levels, and statistics."
	},
	{
		"id": "unlock_all_achievements",
		"name": "Unlock All Achievements",
		"description": "Marks all game achievements as completed."
	},
	{
		"id": "speed_up_time_2x",
		"name": "Time Scale: 2x",
		"description": "Doubles the speed of the game simulation."
	},
	{
		"id": "slow_down_time_0_5x",
		"name": "Time Scale: 0.5x",
		"description": "Halves the speed of the game simulation (slow motion)."
	},
	{
		"id": "show_pathfinding",
		"name": "Show Nav Mesh",
		"description": "Draws the AI navigation mesh on the screen."
	},
	{
		"id": "load_save_0",
		"name": "Load Save Slot 0",
		"description": "Loads the game state from the first automatic save slot."
	},
	{
		"id": "save_game_manual",
		"name": "Manual Save",
		"description": "Saves the current game state immediately."
	},
	{
		"id": "toggle_ai_freeze",
		"name": "Freeze AI",
		"description": "Stops all non-player character AI activity."
	},
	{
		"id": "give_weapon_rifle",
		"name": "Give Weapon: Rifle",
		"description": "Grants the player the standard assault rifle."
	},
	{
		"id": "mute_audio",
		"name": "Mute All Audio",
		"description": "Sets the master volume to zero."
	},
	{
		"id": "unmute_audio",
		"name": "Unmute All Audio",
		"description": "Restores the master volume to its previous level."
	},
	{
		"id": "test_connection_ping",
		"name": "Test Ping",
		"description": "Pings the game server to check network latency."
	},
	{
		"id": "recompile_shaders",
		"name": "Recompile Shaders",
		"description": "Forces all graphics shaders to recompile (slow operation)."
	},
	{
		"id": "toggle_wireframe",
		"name": "Toggle Wireframe View",
		"description": "Switches the rendering mode to show only polygon outlines."
	},
	{
		"id": "set_weather_rain",
		"name": "Set Weather: Rain",
		"description": "Changes the in-game environment to heavy rainfall."
	},
	{
		"id": "set_weather_clear",
		"name": "Set Weather: Clear",
		"description": "Changes the in-game environment to clear sky."
	},
	{
		"id": "spawn_enemy_weak",
		"name": "Spawn Enemy: Grunt",
		"description": "Spawns a basic, weak enemy unit near the player."
	},
	{
		"id": "destroy_all_enemies",
		"name": "Destroy All Enemies",
		"description": "Removes all active enemy NPCs from the scene."
	},
	{
		"id": "toggle_hud",
		"name": "Toggle Game HUD",
		"description": "Hides or shows the main player Heads-Up Display."
	},
	{
		"id": "log_position",
		"name": "Log Player Position",
		"description": "Prints the player's current X, Y, Z coordinates to the console."
	},
	{
		"id": "open_settings_menu",
		"name": "Open Settings Menu",
		"description": "Forces the game to open the primary settings configuration menu."
	},
	{
		"id": "reset_camera",
		"name": "Reset Camera Angle",
		"description": "Restores the in-game camera to its default orientation and zoom."
	},
	{
		"id": "run_performance_test",
		"name": "Run Performance Test",
		"description": "Starts an automated benchmark test suite."
	},
	{
		"id": "show_lighting_only",
		"name": "Show Lighting Pass",
		"description": "Switches to a view mode that only shows the light and shadow passes."
	},
	{
		"id": "dump_texture_cache",
		"name": "Dump Texture Cache",
		"description": "Writes information about loaded textures to a file."
	},
	{
		"id": "respawn_player",
		"name": "Respawn Player",
		"description": "Kills the player and restarts them at the last checkpoint."
	},
	{
		"id": "toggle_input_lock",
		"name": "Toggle Input Lock",
		"description": "Disables or enables all player keyboard and mouse/controller input."
	},
	{
		"id": "set_language_es",
		"name": "Set Language: Spanish",
		"description": "Forces the game's display language to Spanish (Español)."
	},
	{
		"id": "show_hitboxes",
		"name": "Show Hitboxes",
		"description": "Draws simple bounding boxes around objects for hit detection."
	},
	{
		"id": "teleport_last_death",
		"name": "Teleport: Last Death Spot",
		"description": "Moves the player back to the exact location of their last character death."
	},
	{
		"id": "fix_data_corruption",
		"name": "Fix Data Corruption",
		"description": "Attempts to repair minor inconsistencies in the save file data."
	},
	{
		"id": "enable_profiler",
		"name": "Enable Profiler",
		"description": "Starts the internal frame-time profiler for detailed performance analysis."
	},
	{
		"id": "disable_profiler",
		"name": "Disable Profiler",
		"description": "Stops the internal frame-time profiler and logs the results."
	}
];
