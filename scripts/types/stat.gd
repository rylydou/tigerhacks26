class_name Stat extends RefCounted
## A value that upgrades can modify. `compute()` is given the raw (base) value and returns the final value.
## Augments run in priority order (lowest first). `ctx['base_value']` holds the raw value so augments
## can add a percentage of the base without compounding.


## Flat or percent-of-base bonuses
const PRIORITY_ADD := 0
## Multipliers, applied after every additive bonus
const PRIORITY_MULTIPLY := 100


class Augmentation:
	var id: int
	var callback: Callable
	var priority: int


var next_id := 0
var augmentations: Array[Augmentation] = []


func augment(callback: Callable, priority := 0) -> int:
	next_id += 1
	
	var augmentation := Augmentation.new()
	augmentation.id = next_id
	augmentation.callback = callback
	augmentation.priority = priority
	
	# Inset augment after the last augment of same priority
	# 1 1 2 >2< 3
	var count := augmentations.size()
	for r_index in count:
		var index := (count - 1) - r_index
		var test := augmentations[index]
		if test.priority > priority: continue
		augmentations.insert(index + 1, augmentation)
		return next_id
	
	augmentations.push_front(augmentation)
	return next_id


func remove_augment(id: int) -> bool:
	for augmentation in augmentations:
		if augmentation.id != id: continue
		augmentations.erase(augmentation)
		return true
	return false


func compute(value: float, ctx: Dictionary) -> float:
	ctx['base_value'] = value
	for augmentation in augmentations:
		value = augmentation.callback.call(value, ctx)
	return value
