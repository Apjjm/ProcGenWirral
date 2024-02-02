extends Spatial

const RoomRootNode = preload("../floorgen/RoomRootNode.gd")
const RandomParcelRngRoot = preload("RandomParcelRngRoot.gd")

export(float, -360, 360, 5) var y_min = -45.0
export(float, -360, 360, 5) var y_max = 45.0
export(int, "X", "Y", "Z", "XYZ") var axis = 1

var _realised = false

func _enter_tree():
	if self._realised:
		return

	self._realised = true
	var rr = RoomRootNode.find_room_root(self)
	if rr == null:
		rr = RandomParcelRngRoot.find_rng_root(self)

	if rr != null:
		var y0 = deg2rad(min(y_min, y_max))
		var y1 = deg2rad(max(y_min, y_max))
		var dy = y0 + (rr.prop_rng.rand_float() * (y1-y0))
		if axis != 3:
			rotate(_get_axis(), dy)
		else:
			var dx = y0 + (rr.prop_rng.rand_float() * (y1-y0))
			var dz = y0 + (rr.prop_rng.rand_float() * (y1-y0))
			rotate(Vector3(1,0,0), dx)
			rotate(Vector3(0,1,0), dy)
			rotate(Vector3(0,0,1), dz)

func _get_axis() -> Vector3:
	match self.axis:
		0: return Vector3(1,0,0)
		1: return Vector3(0,1,0)
		2: return Vector3(0,0,1)
		_: return Vector3(0,1,0)
