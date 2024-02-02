extends Spatial

signal do_transform()

var _tfn = []
func play_anim():
	_tfn = get_tree().get_nodes_in_group("ap7_dungeon_tf_anim")

	var mat = get_node("tfmain").get_surface_material(0)
	var epicenter = get_node("shockwaves").global_translation
	mat.set_shader_param("fade_origin", epicenter)
	
	for node in _tfn:
		node.on_tf_begin(mat)
	
	var ap = get_node("tfanim")
	ap.play("tf_in")
	yield(ap, "animation_finished")

	for node in _tfn:
		node.on_tf_end()

	_tfn = []

func _do_transform():
	emit_signal("do_transform")
	for node in _tfn:
		node.on_tf_change()
