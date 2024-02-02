extends MeshInstance

func _ready():
	add_to_group("ap7_dungeon_tf_anim", false)
	self.visible = false

func on_tf_begin(mat: Material):
	self.material_override = mat
	self.visible = true

func on_tf_change():
	pass

func on_tf_end():
	self.visible = false
