extends Spatial

const RoomRootNode = preload("../floorgen/RoomRootNode.gd")
const RandomParcelRngRoot = preload("RandomParcelRngRoot.gd")

export(Vector3) var offset = Vector3(0,1,0)
export(float) var speed = 1.0

var _realised = false
var _offset_amount = 0.0
var _origin = Vector3(0,0,0)

func _enter_tree():
	if self._realised == false:
		self._realised = true
		self._origin = self.translation
		
		var rr = RoomRootNode.find_room_root(self)
		rr = rr if rr != null else RandomParcelRngRoot.find_rng_root(self)
		if rr != null:
			self._offset_amount = rr.prop_rng.rand_float()
		else:
			push_warning("[RandomFloatyNode] could not find a root to use as rng source")
			self._offset_amount = randf()

func _process(delta):
	self._offset_amount += delta * self.speed
	if self._offset_amount > 1.0:
		self._offset_amount -= 1.0
	
	self.translation = self._origin + self.offset * sin(self._offset_amount * TAU)
