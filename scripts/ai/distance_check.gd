class_name DistanceCheck extends Group


enum Condition {
	CloserThan,
	FurtherThan,
}


@export var condition := Condition.CloserThan
@export var distance := 0.0


@onready var distance_sqr := (distance * 16) ** 2


func _start() -> int:
	if not is_instance_valid(enemy.aggro): return DONE
	
	var distance_to_aggro := enemy.global_position.distance_squared_to(enemy.aggro.global_position)
	match condition:
		Condition.CloserThan:
			if distance_to_aggro <= distance_sqr:
				return super._start()
		Condition.FurtherThan:
			if distance_to_aggro >= distance_sqr:
				return super._start()
	return DONE
