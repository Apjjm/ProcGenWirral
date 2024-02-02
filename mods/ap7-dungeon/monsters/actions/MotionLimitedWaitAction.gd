extends Action

const PlayerMotionTracker = preload("../../player/PlayerMotionTracker.gd")

export var ticks:int = 1
export var stop_unit:bool = true

func _run():
	var pawn = blackboard.pawn
	var old_direction = pawn.controls.direction

	if self.stop_unit:
		pawn.controls.direction = Vector2.ZERO
		pawn.controls.jump = false
		pawn.controls.dash = false
		pawn.controls.glide = false

	var mt = PlayerMotionTracker.find_motion_tracker()
	if mt != null:
		yield(wait_for_result(mt.add_wait_timer(self.ticks).join()), "completed")

	pawn.controls.direction = old_direction
	return true