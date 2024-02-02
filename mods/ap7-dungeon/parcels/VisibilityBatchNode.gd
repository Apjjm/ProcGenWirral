extends Spatial

const CellRootNode = preload("../floorgen/CellRootNode.gd")

# Some walls aren't always placed along the top edge of the room before rotation (e.g. corners)
# This indicates where north would be, if we rotated this element to be flat against the wall
# we would be looking at if we were looking from inside the cell out towards the north (z-) edge
export(Vector3) var north = Vector3.FORWARD

# Indicate that elements under this node should *never* do anything if it is on the south wall.
# This is intended to be used by decoration on the south wall the player will never see.
export(bool) var never_south = false
export(bool) var only_north = false

# Indicate that elements under this node should have backface culling set when adjusting transparency.
export(bool) var force_backface_cull = false

var _is_north : bool = false
var _is_south : bool = false

func _enter_tree():
	var bearing = global_transform.basis.xform(north)
	var northness = bearing.dot(Vector3.FORWARD)

	self._is_north = northness > 0.75
	self._is_south = northness < -0.75

	if (self._is_south && never_south) || (self.only_north && !self._is_north):
		for c in get_children():
			remove_child(c)
			c.queue_free()

func _ready():
	# We go over all the nodes in _ready() because random nodes can add/remove children during _enter_tree()
	if self._is_north:
		var cell_root = CellRootNode.find_cell_root(self)
		if cell_root != null:
			cell_root.visibility_batch_n.add_node_root(self, force_backface_cull)
	elif self._is_south:
		var cell_root = CellRootNode.find_cell_root(self)
		if cell_root != null:
			cell_root.visibility_batch_s.add_node_root(self, force_backface_cull)
