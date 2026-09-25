extends RefCounted


static var stepped_ticks := 0


static func register_my_commands() -> void:
	var t := DevTools
	
	t.new_command("Reload Current Scene")\
			.describe("Reloads the current scene.")\
			.exec(func(): t.get_tree().reload_current_scene())
	
	t.new_command("Quit App")\
			.describe("Quits this application window.")\
			.exec(func(): t.get_tree().quit())
	
	t.new_command("Toggle Pause")\
			.describe("Toggles the scene tree's pause state on or off.")\
			.hkey("f5")\
			.exec(func():
			var tree := t.get_tree()
			tree.paused = not tree.paused
			stepped_ticks = 0
			if not tree.paused:
				DevTools.sticky_toast(&"Frame-by-Frame")
			)
	
	t.new_command("Pause")\
			.describe("Pauses the scene tree.")\
			.exec(func():
			t.get_tree().paused = true
			stepped_ticks = 0
			)
	
	t.new_command("Resume")\
			.describe("Resumes the scene tree.")\
			.exec(func():
			t.get_tree().paused = false
			stepped_ticks = 0
			DevTools.sticky_toast(&"Frame-by-Frame")
			)
	
	t.new_command("Step One Tick")\
			.describe("Advances by one physics process.")\
			.no_toast()\
			.no_sound()\
			.hkey("alt+tilde")\
			.exec(func():
			stepped_ticks += 1
			DevTools.sticky_toast(
					&"Frame-by-Frame",
					"Tick #%s\nAbout %.2fsec\n\nAlt+Tilde to advance\n" % [stepped_ticks, float(stepped_ticks) / Engine.physics_ticks_per_second],
					INF
			)
			var sound: AudioStreamPlayer = DevTools.tick_b_sound if stepped_ticks % 2 == 0 else DevTools.tick_a_sound
			sound.play()
			
			var tree := t.get_tree()
			tree.paused = false
			await tree.physics_frame
			await tree.physics_frame
			tree.paused = true
			)
	
	# t.new_command("Set Time Scale")\
	# 		.describe("Sets the engine time scale.")\
	# 		.params(["Time Scale|float|1.0"])\
	# 		.exec(func(time_scale: float): Engine.time_scale = time_scale)
	
	# t.new_command("Set Tick Rate")\
	# 		.describe("Sets the # of physics ticks per second.")\
	# 		.params(["Ticks per Second|int|60"])\
	# 		.exec(func(tick_rate: int): Engine.physics_ticks_per_second = tick_rate)
	
	# t.new_command("Set Max FPS")\
	# 		.describe("Sets the FPS cap.")\
	# 		.params(["Ticks per Second|int"])\
	# 		.exec(func(fps: int): Engine.max_fps = fps)
	
	t.new_command("Uncap Frame Rate")\
			.describe("Removes the FPS cap.")\
			.exec(func(): Engine.max_fps = 0)
	
	t.new_command("Set Physics Interpolation")\
			.describe("Enables or disables physics interpolation.")\
			.params(["State|toggle"])\
			.exec(func(state: float):
			t.get_tree().physics_interpolation = state
			t.get_tree().physics_jitter_fix = 0.0 if state else 1.0
			)
	
	t.new_command("Toggle Fullscreen")\
			.describe("Toggles fullscreen state on the window.")\
			.exec(func():
			var window := DevTools.get_window()
			if window.mode == Window.MODE_FULLSCREEN:
				go_windowed()
			else:
				window.mode = Window.MODE_FULLSCREEN
			)
	
	t.new_command("Go Fullscreen")\
			.describe("Make the current window fullscreen.")\
			.exec(func(): DevTools.get_window().mode = Window.MODE_FULLSCREEN)
	
	t.new_command("Go Windowed")\
			.describe("Make the current window windowed.")\
			.exec(go_windowed)
	
	return
	
	t.new_command("Disable Screen Space Antialiasing")\
		.exec(func(): DevTools.get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED)
	t.new_command("FXAA Screen Space Antialiasing")\
		.exec(func(): DevTools.get_viewport().screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA)
	t.new_command("Enable TAA")\
		.exec(func(): DevTools.get_viewport().use_taa = true)
	t.new_command("Disable TAA")\
		.exec(func(): DevTools.get_viewport().use_taa = true)
	
	for item in [
		["Disabled", Viewport.MSAA_DISABLED],
		["2x", Viewport.MSAA_2X],
		["4x", Viewport.MSAA_4X],
		["8x", Viewport.MSAA_8X],
	]:
		t.new_command("Set 2D MSAA to %s" % item[0])\
				.exec(func(): DevTools.get_viewport().msaa_2d = item[1])
	
		t.new_command("Set 3D MSAA to %s" % item[0])\
				.exec(func(): DevTools.get_viewport().msaa_3d = item[1])
	
	for render_mode in [
		["None", RenderingServer.VIEWPORT_DEBUG_DRAW_DISABLED],
		["Unshaded", RenderingServer.VIEWPORT_DEBUG_DRAW_UNSHADED],
		["Lighting", RenderingServer.VIEWPORT_DEBUG_DRAW_LIGHTING],
		["Overdraw", RenderingServer.VIEWPORT_DEBUG_DRAW_OVERDRAW],
		["Wireframe", RenderingServer.VIEWPORT_DEBUG_DRAW_WIREFRAME],
		["Normal Buffer", RenderingServer.VIEWPORT_DEBUG_DRAW_NORMAL_BUFFER],
		["Motion Vectors", RenderingServer.VIEWPORT_DEBUG_DRAW_MOTION_VECTORS],
		["Occluders", RenderingServer.VIEWPORT_DEBUG_DRAW_OCCLUDERS],
		["PSSM Splits", RenderingServer.VIEWPORT_DEBUG_DRAW_PSSM_SPLITS],
		["GI Buffer", RenderingServer.VIEWPORT_DEBUG_DRAW_GI_BUFFER],
		["SDF GI", RenderingServer.VIEWPORT_DEBUG_DRAW_SDFGI],
		["Internal Buffer", RenderingServer.VIEWPORT_DEBUG_DRAW_INTERNAL_BUFFER],
		["SSAO", RenderingServer.VIEWPORT_DEBUG_DRAW_SSAO],
		["SSIL", RenderingServer.VIEWPORT_DEBUG_DRAW_SSIL],
	]:
		t.new_command("Set Debug Draw to %s" % render_mode[0])\
				.exec(func(): DevTools.get_viewport().debug_draw = render_mode[1])


static func go_windowed() -> void:
	var window := DevTools.get_window()
	
	for count in 3:
		window.mode = Window.MODE_WINDOWED
		window.size = DEV_Util.get_default_window_size()
		window.move_to_center()
		window.move_to_foreground()
		window.grab_focus()
		await DevTools.get_tree().process_frame
