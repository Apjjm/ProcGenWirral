tool
extends Spatial
class_name RandomParcelNode

const RoomRootNode = preload("../floorgen/RoomRootNode.gd")
const RandomParcelRngRoot = preload("RandomParcelRngRoot.gd")

export(Resource) var parcel_set = null setget set_parcelset
export(int) var preview_index = 0 setget set_preview_index

var _realised = false

func set_parcelset(new_val):
	parcel_set = new_val
	if Engine.editor_hint:
		_update_editor_preview()

func set_preview_index(new_val):
	preview_index = new_val
	if Engine.editor_hint:
		_update_editor_preview()

func _enter_tree():
	if Engine.editor_hint:
		_update_editor_preview()
		return
	
	if self._realised:
		return
	
	self._realised = true
	var rr = RoomRootNode.find_room_root(self)
	if rr == null:
		rr = RandomParcelRngRoot.find_rng_root(self)
	
	var scene = null
	if rr != null && self.parcel_set != null:
		scene = self.parcel_set.get_random_parcel(rr.prop_rng)
	elif rr == null && self.parcel_set != null:
		push_warning("[RandomParcelNode] could not find a root, using preview zone")
		scene = self.parcel_set.get_parcel(self.preview_index)	

	if scene != null:
		var node = scene.instance()
		node.name = "CREATED_PARCEL_" + node.name
		node.translate(self.parcel_set.offset)
		add_child(node)

func _exit_tree():
	if Engine.editor_hint:
		self._clear_nodes()

func _update_editor_preview():
	self._clear_nodes()

	var scene = self.parcel_set.get_parcel(self.preview_index) if self.parcel_set != null else null
	if scene != null:
		var node = scene.instance()
		node.name = "CREATED_PARCEL_" + node.name
		add_child(node)

func _clear_nodes():
	for c in get_children():
		if c.name.begins_with("CREATED_PARCEL_"):
			c.queue_free()
