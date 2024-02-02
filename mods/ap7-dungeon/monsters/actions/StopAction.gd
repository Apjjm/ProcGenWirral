extends Action

func _run():
	yield (Co.next_frame(), "completed")
	var pawn = blackboard.pawn
	pawn.controls.direction = Vector2.ZERO
	return true
