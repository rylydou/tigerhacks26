class_name SetAggro extends Step


enum TargetMode {
	None,
	Random,
	LastAttackedBy,
	Closest,
	Furthest,
}


@export var target_mode := TargetMode.Random


func _start() -> int:
	set_aggro()
	return DONE


func set_aggro() -> void:
	if target_mode == TargetMode.None:
		enemy.aggro = null
		return
	
	enemy.set_aggro(Player.instance)
	
	# var players: Array[Player] = []
	# players.assign(Game.players.filter(func(p: Player) -> bool: return is_instance_valid(p) and p.health > 0))
	# match target_mode:
	# 	TargetMode.Random:
	# 		if players.size() > 0:
	# 			enemy.set_aggro(players.pick_random())
	# 	TargetMode.Closest:
	# 		var closest_player: Player
	# 		var closest_distance_sqr := INF
	# 		for player in players:
	# 			var distance_sqr := player.global_position.distance_squared_to(enemy.global_position)
	# 			if distance_sqr > closest_distance_sqr: continue
	# 			closest_player = player
	# 		enemy.set_aggro(closest_player)
	# 	TargetMode.Furthest:
	# 		var furthest_player: Player
	# 		var furthest_distance_sqr := -INF
	# 		for player in players:
	# 			var distance_sqr := player.global_position.distance_squared_to(enemy.global_position)
	# 			if distance_sqr < furthest_distance_sqr: continue
	# 			furthest_player = player
	# 		enemy.set_aggro(furthest_player)
