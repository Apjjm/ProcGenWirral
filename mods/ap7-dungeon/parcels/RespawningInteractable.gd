extends Interaction

export(float) var kill_depth
export(Vector3) var respawn_point

func _physics_process(_delta):
	if self.global_translation.y < kill_depth:
		self.global_translation = self.respawn_point
