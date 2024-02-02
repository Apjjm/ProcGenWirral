extends Spatial

const GlitchEffectShader = preload("res://mods/ap7-dungeon/shaders/GlitchEffect.gdshader")

export(float, 0.0, 1.0) var glitchyness = 1.0

# These parameters look nice
var threshold_min = Vector2(0.1, 0.2)
var threshold_max = Vector2(0.3, 0.6)
var scale_min = Vector3(0.4, 0.8, 0.05)
var scale_max = Vector3(0.4, 1.2, 0.05)
var power_min = 0.01
var power_max = 0.04
var ngonality_min = 0.85
var ngonality_max = 0.61
var speed = 2.0

# The effect was tuned for stuff about the size of sirenade & traffikrab
# really big or small sprites looks a bit rubbish if we don't scale the effect with size a bit.
var scale_mul = Vector3(1.0, 1.0, 1.0)

# Shader hackery to apply this effect only to the sprite -
# We decide if the thing behind is the battle slot sprite by looking at the depth buffer
# If the world space of the thing in the depth buffer is clsoe in z, it is probably our sprite.
# Unfortunately, because of billboarding, this "closeness" factor is something like 0.1
# The z-gap between battle slots is 5, and this number seems to handle tall stuff like artillerex
var clip_depth = 4.75

var created_mesh = null
var material = null

func _enter_tree():
	self.material = ShaderMaterial.new()
	self.material.shader = GlitchEffectShader

	self.created_mesh = MeshInstance.new()
	self.created_mesh.mesh = CubeMesh.new()
	self.created_mesh.material_override = self.material
	add_child(self.created_mesh)
	refresh_params()

func _exit_tree():
	if self.created_mesh != null:
		self.created_mesh.queue_free()
		self.created_mesh = null
		self.material = null

func _process(_delta: float) -> void:
	#set_glitchyness(0.9)
	#self.material.set_shader_param("clip_depth",self.clip_depth)

	var slot = get_parent()
	if slot != null && slot.sprite_container:
		var aabb = slot.sprite_container.get_aabb()
		var scale = Vector3(aabb.size.x * 0.5, aabb.size.y, 0.1)

		set_scale(scale)
		set_translation(slot.sprite_container.translation)
		update_scalemul(scale)

func set_glitchyness(value: float) -> void:
	self.glitchyness = min(1.0, value)
	refresh_params()

func refresh_params() -> void:
	if self.material != null:
		self.material.set_shader_param("clip_depth",self.clip_depth)
		self.material.set_shader_param("scale", lerp(self.scale_min, self.scale_max, self.glitchyness))
		self.material.set_shader_param("thresholds", lerp(self.threshold_min, self.threshold_max, self.glitchyness))
		self.material.set_shader_param("power", lerp(self.power_min, self.power_max, self.glitchyness) / self.scale_mul.x)
		self.material.set_shader_param("speed", self.speed)
		self.material.set_shader_param("ngonality", lerp(self.ngonality_min, self.ngonality_max, self.glitchyness))

func update_scalemul(scale: Vector3) -> void:
	self.scale_mul = Vector3(5.0 / max(1.0,scale.x), 4.0 / max(1.0,scale.y), 1.0)
	if self.material != null:
		self.material.set_shader_param("power", lerp(self.power_min, self.power_max, self.glitchyness) / self.scale_mul.x)
