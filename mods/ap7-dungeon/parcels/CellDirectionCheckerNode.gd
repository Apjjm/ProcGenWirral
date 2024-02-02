extends Spatial

export(int, "None", "Flip", "Destroy") var behavior_on_south = 0
export(int, "None", "Flip", "Destroy") var behavior_on_east_west = 0
export(int, "None", "Flip", "Destroy") var behavior_on_north = 0

func _enter_tree():
	var bearing = global_transform.basis.xform(Vector3.FORWARD)
	var northness = bearing.dot(Vector3.FORWARD)

	if northness < -0.75:
		match self.behavior_on_south:
			1: _handle_flip()
			2: _handle_destroy()
			_: pass
	elif northness < 0.75:
		match self.behavior_on_east_west:
			1: _handle_flip()
			2: _handle_destroy()
			_: pass
	else:
		match self.behavior_on_north:
			1: _handle_flip()
			2: _handle_destroy()
			_: pass

func _handle_destroy():
	for c in get_children():
		remove_child(c)
		c.queue_free()

func _handle_flip():
	for c in get_children():
		if c is Spatial:
			c.rotate(Vector3.UP, PI)