tool
extends Spatial
class_name ParcelPlanner

export(int, 1, 10, 1) var x_size = 1 setget x_size_set
export(int, 1, 10, 1) var y_size = 1 setget y_size_set
export(int, 1, 40, 1) var height = 10 setget height_set
export(int, 1, 100, 2) var m_per_parcel = 24 setget m_per_parcel_set
export(int, 1, 100, 2) var m_per_interior_parcel = 20 setget m_per_interior_parcel_set

func _enter_tree():
	reset_geom()

func _exit_tree():
	if Engine.is_editor_hint():
		for child in get_children():
			if child.name.begins_with("EDITOR_MESH_"):
				child.queue_free()

func x_size_set(new_size):
	x_size = new_size
	reset_geom()

func y_size_set(new_size):
	y_size = new_size
	reset_geom()

func m_per_parcel_set(new_size):
	m_per_parcel = new_size
	reset_geom()
	
func m_per_interior_parcel_set(new_size):
	m_per_interior_parcel = new_size
	reset_geom()

func height_set(new_size):
	height = new_size
	reset_geom()

func reset_geom():
	if !Engine.is_editor_hint():
		return

	for child in get_children():
		if child.name.begins_with("EDITOR_MESH_"):
			child.queue_free()
	
	var thickness = 0.1
	for xc in range(x_size):
		for yc in range(y_size):
			var top_left = Vector3(xc, 0, yc) * m_per_parcel
			var instance1 = MeshInstance.new()
			var instance2 = MeshInstance.new()
			instance1.translate(top_left + Vector3(m_per_parcel, -thickness, m_per_parcel) * 0.5)
			instance1.name = "EDITOR_MESH_" + str(xc) + "_" + str(yc)
			add_child(instance1)
			
			instance2.translate(top_left + Vector3(m_per_parcel, -thickness, m_per_parcel) * 0.5)
			instance2.name = "EDITOR_MESH_I" + str(xc) + "_" + str(yc)
			add_child(instance2)

			var mesh1 = CubeMesh.new()
			mesh1.size = Vector3(m_per_parcel, thickness*0.25, m_per_parcel)
			instance1.mesh = mesh1

			var mesh2 = CubeMesh.new()
			mesh2.size = Vector3(m_per_interior_parcel, thickness, m_per_interior_parcel)
			instance2.mesh = mesh2

			var mat1 = SpatialMaterial.new()
			mat1.flags_unshaded = true
			mat1.flags_disable_ambient_light = true
			mat1.albedo_color = Color(0.4, 0.4, 0.4)
			instance1.material_override = mat1
			
			var mat2 = SpatialMaterial.new()
			mat2.flags_unshaded = true
			mat2.flags_disable_ambient_light = true
			mat2.albedo_color = Color(xc/(4.5*x_size), sqrt((x_size-xc)*(x_size-xc)+(y_size-yc)*(y_size-yc))/sqrt(x_size*x_size*16 + y_size*y_size*16),  yc/(4.5*y_size))
			instance2.material_override = mat2
