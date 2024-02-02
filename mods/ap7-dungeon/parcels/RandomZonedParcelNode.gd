tool
extends Spatial
class_name RandomZonedParcelNode

const RoomRootNode = preload("../floorgen/RoomRootNode.gd")

# ResourceList of parcels for all zones which this node might find itself in / wants to handle.
# If a zone does not match any parcel, then no prop is spawned. This is intentionally _NOT_ an error!
export(Resource) var parcel_sets = null setget set_parcelsets
export(int) var preview_index = 0 setget set_preview_index
export(String) var preview_zone = "*" setget set_preview_zone

var _realised = false

func set_parcelsets(new_val):
	parcel_sets = new_val
	if Engine.editor_hint:
		_update_editor_preview()

func set_preview_index(new_val):
	preview_index = new_val
	if Engine.editor_hint:
		_update_editor_preview()

func set_preview_zone(new_val):
	preview_zone = new_val
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
	
	var scene = null
	var offset = Vector3.ZERO
	if rr != null:
		var set = _find_set_for_zone(rr.floor_data.zones.get_zone(rr.plot_id))
		if set != null:
			scene = set.get_random_parcel(rr.prop_rng)
			offset = set.offset
	else:
		push_warning("[RandomZonedParcelNode] could not find a root, using preview zone & index")
		var set = _find_set_for_zone(self.preview_zone)
		scene = set.get_parcel(self.preview_index)
		offset = set.offset

	if scene != null:
		var node = scene.instance()
		node.name = "CREATED_PARCEL_" + node.name
		node.translate(offset)
		add_child(node)

func _exit_tree():
	if Engine.editor_hint:
		self._clear_nodes()

func _update_editor_preview():
	self._clear_nodes()

	var set = _find_set_for_zone(self.preview_zone)
	var scene = set.get_parcel(self.preview_index) if set != null else null
	if scene != null:
		var node = scene.instance()
		node.name = "CREATED_PARCEL_" + node.name
		add_child(node)

func _clear_nodes():
	for c in get_children():
		if c.name.begins_with("CREATED_PARCEL_"):
			c.queue_free()

func _find_set_for_zone(zone: String):
	for p in self.parcel_sets.resources:
		if p.has_zone(zone):
			return p

	return null
