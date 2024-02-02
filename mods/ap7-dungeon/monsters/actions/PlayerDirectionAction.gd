extends "./RandomMonsterActionBase.gd"

enum DirectionModifier { Matching, Clockwise, CounterClockwise, Opposite };

export(DirectionModifier) var modifier = DirectionModifier.Opposite

func _run():
	var who = blackboard.pawn
	var player = WorldSystem.get_player()
	if player == null:
		return true
	
	var dir = Direction.get_nearest(player.direction)
	match modifier:
		DirectionModifier.Clockwise: 
			dir = Direction.get_clockwise(dir)
		DirectionModifier.CounterClockwise: 
			dir = Direction.get_anticlockwise(dir)
		DirectionModifier.Opposite: 
			dir = Direction.get_opposite(dir)

	who.direction = Direction.get(dir)
	return true	
