extends "./RandomMonsterActionBase.gd"

func _run():
	var who = blackboard.pawn
	who.direction = self.rng.rand_unit_vec2()
	return true	
