class_name Group extends Step


var current_step: Step
var next_index := 0


func _start() -> int:
	if not is_instance_valid(enemy): return DONE
	if get_child_count() <= 0: return DONE
	
	next_index = 0
	return next()


func _tick(delta: float) -> int:
	if not is_instance_valid(enemy): return DONE
	if get_child_count() <= 0: return DONE
	
	if not current_step: return next()
	
	var code := current_step._tick(delta)
	if code == CONTINUE: return CONTINUE
	
	return next()


func next() -> int:
	for iteration in 50:
		if next_index >= get_child_count(): return DONE
		
		var step := get_child(next_index)
		next_index += 1
		
		if not step is Step:
			if step.has_method('trigger'):
				step.call('trigger')
			continue
		
		if not step.enabled: continue
		
		current_step = step
		
		var code := current_step._start()
		if code == CONTINUE: return CONTINUE
	
	assert(false, 'Too many loops in AI group! Potential Infinite Loop (very bad)!!!')
	return DONE
