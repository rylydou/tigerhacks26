@abstract
class_name MapStep
extends Resource
## One stage of the generation pipeline. Subclass and override apply().

@abstract func apply(ctx: MapContext) -> void


## Name of the snapshot taken after this step. Empty = none.
func label() -> String:
	return ""
