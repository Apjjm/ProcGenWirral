extends Action

enum CycleMode { CLOCKWISE, COUNTER_CLOCKWISE };

export(CycleMode) var cycle_mode = CycleMode.CLOCKWISE

func _run():
	var who = blackboard.pawn
	var direction = who.direction
	match self.cycle_mode:
		CycleMode.CLOCKWISE:
			var d = Direction.get_clockwise(Direction.get_nearest(direction))
			direction = Direction.get(d)
		CycleMode.COUNTER_CLOCKWISE:
			var d = Direction.get_anticlockwise(Direction.get_nearest(direction))
			direction = Direction.get(d)

	who.direction = direction
	return true
