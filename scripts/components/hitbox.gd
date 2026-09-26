class_name Hitbox extends Area2D


enum DamageType {
	Generic,
	Melee,
	Bullet,
	Explosion,
	Crit,
}


signal attacked(node: Node2D)


@export var auto_attack := false
@export var base_damage := 0
@export var damage_variation := 0.15
@export var knockback_strength := 0.0
@export var damage_type := DamageType.Generic
@export var stun := 0.0
@export var always_attack := false


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
	if player.health <= 0 and not always_attack: return false
	var damage := base_damage
	damage *= Math.rand_var(1.0, damage_variation / 2.0)
	var has_hit := player.try_attack(node, damage, knockback_strength, damage_type)
	attacked.emit(node)
	if has_hit and stun > 0.0 and node.has_method(&'stun'):
		node.stun(stun)
	return has_hit
