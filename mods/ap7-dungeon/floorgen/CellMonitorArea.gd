extends Area

func _init(mask: int, cell_size: Vector2, inner_cell_size: Vector2):
	self.monitoring = true
	self.monitorable = false
	self.collision_layer = mask
	self.collision_mask = mask

	var box = BoxShape.new()
	var overlap = (cell_size - inner_cell_size) * 0.45
	box.extents = Vector3(cell_size.x*0.5 + overlap.x, 30, cell_size.y*0.5 + overlap.y)

	var shape = CollisionShape.new()
	shape.translate(Vector3(cell_size.x * 0.5, 1, cell_size.y * 0.5))
	shape.shape = box
	add_child(shape)
