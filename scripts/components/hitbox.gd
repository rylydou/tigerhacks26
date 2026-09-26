class_name Hitbox extends Area2D


signal attacked(node: Node2D)


@export var auto_attack := false
@export var base_damage := 0
@export var damage_variation := 0.15
@export var knockback_strength := 0.0
@export var stun := 0.0
@export var always_attack := false
@export var remember_hits := true


var player: Player

var remembered_hits: Array[Node2D] = []


func _ready() -> void:
	if not is_instance_valid(player):
		if owner is Player:
			player = owner
		else:
			player = owner.player
	
	area_entered.connect(func(node: Node) -> void: if auto_attack: attack_node(node))
	body_entered.connect(func(node: Node) -> void: if auto_attack: attack_node(node))


func attack_overlap() -> void:
	var nodes := get_overlapping_bodies()
	nodes.append_array(get_overlapping_areas())
	for node in nodes:
		attack_node(node)


func attack_node(node: Node2D) -> bool:
	if remembered_hits.has(node): return false
	
	if is_instance_valid(player):
		if player.health <= 0 and not always_attack:
			return false
	
	# Compute damage
	var damage := base_damage
	damage *= Math.rand_var(1.0, damage_variation / 2.0)
	
	var has_hit := false
	
	if is_instance_valid(player):
		has_hit = player.try_attack(node, damage, knockback_strength)
	elif node.has_method(&"take_damage"):
		has_hit = node.take_damage(damage, knockback_strength)
	
	if not has_hit:
		return false
	
	if remember_hits:
		remembered_hits.append(node)
	
	_on_attacked(node)
	attacked.emit(node)
	
	# Inflict stun if the attack was successful and the target can be stunned
	if has_hit and stun > 0.0 and node.has_method(&'take_stun'):
		node.stun(stun)
	
	return has_hit


func _on_attacked(node: Node2D) -> void:
	pass
