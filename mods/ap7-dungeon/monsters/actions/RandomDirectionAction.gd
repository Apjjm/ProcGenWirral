extends "./RandomMonsterActionBase.gd"

export var exclude_current : bool = false

func _run():
	var who = blackboard.pawn
	
	var dir = who.direction
	if self.exclude_current:
		match Direction.get_nearest(dir):
			"left": 
				dir = self.rng.choice([ "right", "up", "down"])
			"right": 
				dir = self.rng.choice(["left", "up", "down"])
			"up": 
				dir = self.rng.choice(["left", "right", "down"])
			"down": 
				dir = self.rng.choice(["left", "right", "up"])
			_: 
				dir = self.rng.choice(["left", "right", "up", "down"])
	else:
		dir = self.rng.choice(["left", "right", "up", "down"])

	who.direction = Direction.get(dir)
	return true	
