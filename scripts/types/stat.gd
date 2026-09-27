class_name Stat extends RefCounted


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
		augmentations.insert(index, augmentation)
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
