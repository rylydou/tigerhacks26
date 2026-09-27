class_name Cheats extends RefCounted
## DevTools cheat commands for testing the level loop and upgrades.
## Commands outlive scenes, so they look up GameLoop.current when run.


static func register() -> void:
	DevTools.new_command("Cheat: Win Level")\
			.describe("Clears the current level and opens the upgrade screen.")\
			.hkey("f6")\
			.exec(win_level)
	
	DevTools.new_command("Cheat: Add All Upgrades")\
			.describe("Gives one level of every upgrade that can still be taken.")\
			.exec(add_all_upgrades)
	
	for script in UpgradePool.UPGRADES:
		var upgrade_name := (script.new() as Upgrade).get_name()
		DevTools.new_command("Cheat: Add Upgrade: %s" % upgrade_name)\
				.describe("Gives the %s upgrade, or levels it up if you already have it." % upgrade_name)\
				.exec(add_upgrade.bind(script))


static func win_level() -> void:
	var loop := _get_loop()
	if not loop: return
	if loop.state != GameLoop.State.PLAYING:
		DevTools.toast("Can only win while playing")
		return
	loop._win_level()


static func add_all_upgrades() -> void:
	var loop := _get_loop()
	if not loop: return
	for script in UpgradePool.UPGRADES:
		if UpgradePool.can_offer(loop.player, script):
			loop.player.add_upgrade(script)
	DevTools.toast("Added all upgrades")


static func add_upgrade(script: Script) -> void:
	var loop := _get_loop()
	if not loop: return
	var owned := loop.player.get_upgrade(script)
	if owned and owned.is_maxed():
		DevTools.toast("%s is already max level" % owned.get_name())
		return
	# Cheats ignore mutual exclusivity (Panic/Focus) on purpose
	var upgrade := loop.player.add_upgrade(script)
	DevTools.toast("%s is now Lv %d" % [upgrade.get_name(), upgrade.level])


static func _get_loop() -> GameLoop:
	if not is_instance_valid(GameLoop.current) or not is_instance_valid(GameLoop.current.player):
		DevTools.toast("No level is running")
		return null
	return GameLoop.current
