extends Reference

var mat_lut: Dictionary = {}
var cull_mat_lut: Dictionary = {}
var mats : Array = []
var sprites: Array = []
var opacity : float = 1.0

func add_mat(mat: Material, force_backface_cull: bool = false) -> Material:
	if mat is SpatialMaterial:
		if force_backface_cull:
			var m = self.cull_mat_lut.get(mat)
			if m != null: return m;
		else:
			var m = self.mat_lut.get(mat)
			if m != null: return m;

		var copy = mat.duplicate()
		copy.flags_transparent = true
		copy.params_depth_draw_mode = SpatialMaterial.DEPTH_DRAW_ALPHA_OPAQUE_PREPASS
		copy.albedo_color.a = self.opacity
		if force_backface_cull:
			copy.params_cull_mode = SpatialMaterial.CULL_BACK
			self.cull_mat_lut[mat] = copy
		else:
			self.mat_lut[mat] = copy
		
		self.mats.push_back(copy)
		return copy

	return mat

func add_sprite(spr: Sprite3D):
	if spr.material_override != null && spr.material_override is SpatialMaterial: # For sprites with emission
		var m2 = add_mat(spr.material_override, false)
		spr.material_override = m2
	else:
		spr.transparent = true
		spr.alpha_cut = SpriteBase3D.ALPHA_CUT_OPAQUE_PREPASS
		spr.opacity = self.opacity
		self.sprites.push_back(spr)

func add_node_root(node: Spatial, force_backface_cull: bool = false):
	var to_visit = node.get_children()
	while to_visit.size() > 0:
		var next = to_visit.pop_back()
		if next.get_child_count() > 0:
			to_visit.append_array(next.get_children())

		if next is MeshInstance:
			if next.material_override != null:
				var m2 = add_mat(next.material_override, force_backface_cull)
				next.material_override = m2
			elif next.get_surface_material_count() > 0:
				for i in range(0, next.get_surface_material_count()):
					var m2 = add_mat(next.get_active_material(i), force_backface_cull)
					next.set_surface_material(i, m2)
		elif next is MultiMeshInstance:
			if next.material_override != null:
				var m2 = add_mat(next.material_override, force_backface_cull)
				next.material_override = m2
			elif next.multimesh.mesh.get_surface_count() == 1:
				var m2 = add_mat(next.multimesh.mesh.surface_get_material(0), force_backface_cull)
				next.material_override = m2
			else:
				push_error("[VisibilityBatch] Multimesh node with surface count " + str(next.multimesh.mesh.get_surface_count()) + ": " + str(node.get_path()))
		elif next is Sprite3D:
			add_sprite(next)

func set_opacity(opacity: float):
	if self.opacity<0.001 && opacity<0.001:
		return

	self.opacity = opacity

	for mat in self.mats:
		mat.albedo_color.a = opacity

	for spr in self.sprites:
		spr.opacity = opacity
