extends Node

export (String) var animation:String = "idle"
export (float) var max_y_speed:float = 12.0
export (float) var max_xz_speed:float = 6.0
export (float) var float_frequency:float = 0.25
export (float) var float_amplitude:float = 1.0
export (float) var sprite_wave_amplitude:float = 0.05
export (float) var sprite_wave_t_frequency:float = 12.0
export (float) var sprite_wave_v_frequency:float = 12.0
export (float) var hover_height_idle:float = 4.0
export (float) var hover_height_moving:float = 2.5

var t = 0.0
var floor_ray:RayCast
var ceiling_ray:RayCast

func _ready():
	# Hack: We don't want floaty things to spawn on the floor
	get_parent().get_parent().translate(Vector3.UP * min(hover_height_moving,hover_height_idle))

func _enter_state():
	var pawn = get_parent().pawn
	t = 0.0
	
	floor_ray = pawn.floor_ray
	ceiling_ray = pawn.get_node("CeilingRay") if pawn.has_node("CeilingRay") else null
	floor_ray.enabled = true
	if ceiling_ray:
		ceiling_ray.enabled = true

func _exit_state():
	var pawn = get_parent().pawn
	pawn.sprite.translation.y = 0.0
	
	floor_ray.enabled = false
	if ceiling_ray:
		ceiling_ray.enabled = false

func update(delta):
	var pawn = get_parent().pawn
	var is_physical = pawn.get_collision_mask_bit(Collisions.BIT_PHYSICAL)
	
	t += delta
	pawn.sprite.translation.y = float_amplitude * sin(float_frequency * t * 2 * PI)
	
	var dir = Vector3(pawn.controls.direction.x, 0, pawn.controls.direction.y)
	var hover_height = hover_height_idle

	if dir.length_squared() > 0.01:
		var vel_xz = dir.normalized() * max_xz_speed * pawn.controls.speed_multiplier
		pawn.velocity.x = vel_xz.x
		pawn.velocity.z = vel_xz.z
		hover_height = hover_height_moving
	
	if floor_ray.get_collision_distance() < hover_height || (!is_physical && ceiling_ray && ceiling_ray.is_colliding()) || pawn.controls.jump:
		pawn.velocity.y = max_y_speed * delta * pawn.controls.speed_multiplier
	else :
		pawn.velocity.y = -max_y_speed * delta * pawn.controls.speed_multiplier
	
	if abs(pawn.velocity.y) > max_y_speed:
		pawn.velocity.y = sign(pawn.velocity.y) * max_y_speed
	
	if !pawn.controls.strafe: pawn.direction = pawn.controls.direction
	
	pawn.sprite.loop_animation(animation)
	pawn.sprite.wave_amplitude = sprite_wave_amplitude
	pawn.sprite.wave_t_frequency = sprite_wave_t_frequency
	pawn.sprite.wave_v_frequency = sprite_wave_v_frequency
