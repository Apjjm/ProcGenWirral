extends Spatial

const ParcelOverlay = preload("./parcelling/ParcelOverlay.gd")
const GeneratedFloor = preload("GeneratedFloor.gd")
const VisibilityBatch = preload("VisibilityBatch.gd")
const CellMonitorArea = preload("CellMonitorArea.gd")

signal player_cell_entered(body, cell_x, cell_y, id)
signal player_cell_exited(body, cell_x, cell_y, id)

var plot_id: int
var cell_x : int
var cell_y : int
var floor_data: GeneratedFloor
var visibility_batch_n: VisibilityBatch
var visibility_batch_s: VisibilityBatch

static func find_cell_root(node: Node) -> Node:
	return node.find_parent("DF_CELL_*")

func _init(plot_id, floor_data, cell_x: int, cell_y: int):
	self.plot_id = plot_id
	self.cell_x = cell_x
	self.cell_y = cell_y
	self.floor_data = floor_data
	self.name = "DF_CELL_" + str(self.cell_x) + "_" + str(self.cell_y)
	self.visibility_batch_s = VisibilityBatch.new()
	self.visibility_batch_n = VisibilityBatch.new()

func realise(cell: ParcelOverlay.CellOverlay):
	var monitor = CellMonitorArea.new(Collisions.MASK_PLAYER, self.floor_data.world_cell_size, self.floor_data.world_interior_cell_size)
	monitor.connect("body_entered", self, "_on_player_entered")
	monitor.connect("body_exited", self, "_on_player_exited")
	add_child(monitor)

	var floor_tags = _get_floor_tags(cell)
	_place_floor(cell, floor_tags)
	_place_cover(cell, floor_tags)
	_place_walls(cell)
	_place_corners(cell)

func _place_floor(cell: ParcelOverlay.CellOverlay, floor_tags: Array):
	if cell.flr != null:
		var flr = cell.flr.instance()
		flr.name = "FLOOR"
		_remove_floor_tags(flr, floor_tags)
		add_child(flr)

func _place_cover(cell: ParcelOverlay.CellOverlay, floor_tags: Array):
	if cell.cover != null:
		var cover = cell.cover.instance()
		cover.name = "COVER"
		_remove_floor_tags(cover, floor_tags)
		add_child(cover)

func _place_walls(cell: ParcelOverlay.CellOverlay):
	# By convention wall origins (and, indeed, any room node parcels) are in the cell origin - the top left corner
	# This means any rotations happen about there, so translation don't need to move centres about.
	if cell.wall_n != null:
		var wall = cell.wall_n.instance()
		wall.name = "WALL_N"
		_remove_wall_tags(wall, cell.wall_type_n)
		add_child(wall)

	if cell.wall_e != null:
		var wall = cell.wall_e.instance()
		wall.name = "WALL_E"
		_remove_wall_tags(wall, cell.wall_type_e)
		wall.translate(Vector3(self.floor_data.world_cell_size.x, 0, 0))
		wall.rotate(Vector3.UP, PI * -0.5)
		add_child(wall)

	if cell.wall_s != null:
		var wall = cell.wall_s.instance()
		wall.name = "WALL_S"
		_remove_wall_tags(wall, cell.wall_type_s)
		wall.translate(Vector3(self.floor_data.world_cell_size.x, 0, self.floor_data.world_cell_size.y))
		wall.rotate(Vector3.UP, PI)
		add_child(wall)

	if cell.wall_w != null:
		var wall = cell.wall_w.instance()
		wall.name = "WALL_W"
		_remove_wall_tags(wall, cell.wall_type_w)
		wall.translate(Vector3(0, 0, self.floor_data.world_cell_size.y))
		wall.rotate(Vector3.UP, PI * -1.5)
		add_child(wall)

func _place_corners(cell: ParcelOverlay.CellOverlay):
	# Corners are very similar to walls in placement approach
	# Corners may be interior or exterior corners, but that is already factored in by the scene selected by this point
	if cell.corner_nw != null:
		var corner = cell.corner_nw.instance()
		corner.name = "CORNER_NW"
		add_child(corner)
	
	if cell.corner_ne != null:
		var corner = cell.corner_ne.instance()
		corner.name = "CORNER_NE"
		corner.translate(Vector3(self.floor_data.world_cell_size.x, 0, 0))
		corner.rotate(Vector3.UP, PI * -0.5)
		add_child(corner)
	
	if cell.corner_se != null:
		var corner = cell.corner_se.instance()
		corner.name = "CORNER_SE"
		corner.translate(Vector3(self.floor_data.world_cell_size.x, 0, self.floor_data.world_cell_size.y))
		corner.rotate(Vector3.UP, PI)
		add_child(corner)

	if cell.corner_sw != null:
		var corner = cell.corner_sw.instance()
		corner.name = "CORNER_SW"
		corner.translate(Vector3(0, 0, self.floor_data.world_cell_size.y))
		corner.rotate(Vector3.UP, PI * -1.5)
		add_child(corner)

func _get_floor_tags(cell: ParcelOverlay.CellOverlay) -> Array:
	# Floors are a 9-patch-like structure, we need to toggle on the edges
	var valid_tags = [ "Patch_C"]
	if cell.corner_ne == null && cell.wall_n == null && cell.wall_e == null: valid_tags.push_back("Patch_NE")
	if cell.corner_nw == null && cell.wall_n == null && cell.wall_w == null: valid_tags.push_back("Patch_NW")
	if cell.corner_se == null && cell.wall_s == null && cell.wall_e == null: valid_tags.push_back("Patch_SE")
	if cell.corner_sw == null && cell.wall_s == null && cell.wall_w == null: valid_tags.push_back("Patch_SW")
	if cell.wall_n == null: valid_tags.push_back("Patch_N")
	if cell.wall_e == null: valid_tags.push_back("Patch_E")
	if cell.wall_s == null: valid_tags.push_back("Patch_S")
	if cell.wall_w == null: valid_tags.push_back("Patch_W")
	return valid_tags

func _remove_floor_tags(node: Node, floor_tags: Array):
	for n in node.get_children():
		if n.name.begins_with("Patch_") && !(n.name in floor_tags):
			node.remove_child(n)
			n.queue_free()
		else:
			n.visible = true

func _remove_wall_tags(node: Node, flags: int):
	# When modelling the walls it is easier to think more about them "joining" the cell at e.g. the left,
	# rather than saying the left is occupied by a connection, and therefore should be shorter.
	# This means the conditions invert here, because we are talking about sides being free instead.
	var conn_tag = "Wall_S"
	if (flags & ParcelOverlay.CellWallFlags.CONN_LR) == 0:
		conn_tag = "Wall_LR"
	elif (flags & ParcelOverlay.CellWallFlags.CONN_L) == 0:
		conn_tag = "Wall_L"
	elif (flags & ParcelOverlay.CellWallFlags.CONN_R) == 0:
		conn_tag = "Wall_R"

	for c in node.get_children():
		if c.name.begins_with("Wall_"):
			if c.name == conn_tag:
				c.visible = true # We might toggle things on/off in editor and forget about it
			else:
				node.remove_child(c)
				c.queue_free()

func _on_player_entered(body):
	emit_signal("player_cell_entered", body, self.cell_x, self.cell_y, self.plot_id)

func _on_player_exited(body):
	emit_signal("player_cell_exited", body, self.cell_x, self.cell_y, self.plot_id)
