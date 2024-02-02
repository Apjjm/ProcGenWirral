extends "TerraformTerrainBlock.gd"

onready var slot = get_parent()

func _ready():
	self.mesh = CubeMesh.new()

func _process(_delta):
	if self.slot != null && self.slot.has_sprite():
		var aabb = self.slot.sprite_container.get_aabb()
		if self.slot.decoy_container.scene != null:
			var decoy_aabb = self.slot.decoy_container.get_aabb()
			decoy_aabb.position = self.slot.decoy_container.transform.xform(decoy_aabb.position)
			aabb = aabb.merge(decoy_aabb)

		var scale = Vector3(aabb.size.x * 0.51, aabb.size.y, aabb.size.z * 0.75)
		set_scale(scale)
		set_translation(self.slot.sprite_container.translation)

func on_tf_end():
	queue_free()
