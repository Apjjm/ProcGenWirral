extends Node

# Fork of path controller from the base game extended to only advance by the multiplier on the player motion tracker

const FALL_PREVENTION_DECELERATION:float = 64.0
const FALL_PREVENTION_STOP_THRESHOLD:float = 0.125
const PlayerMotionTracker = preload("../../player/PlayerMotionTracker.gd")

signal arrived(success)
signal target_reached
signal failed

const PLANE_XZ:Vector3 = Vector3(1, 0, 1)

class Params:
	var can_fly:bool = true
	var can_jump:bool = true
	var can_glide:bool = true
	var can_fall:bool = true
	var can_warp:bool = false
	var can_be_blocked:bool = false
	var pause_controls_on_arrive:bool = true
	var ignore_ending_y:bool = false
	var max_distance:float = -1.0
	var min_distance:float = 0.0
	var max_ticks: int = - 1
	var target_node:NodePath
	var target_pos:Vector3

export (int, "Approach", "Flee") var mode:int = 0
var params:Params = Params.new() setget set_params
var enabled:bool = true setget set_enabled

var pawn_id:int
var pawn:NPC setget set_pawn
var _ceiling_counter:int = 0
var force_fly:bool = false
var warping:bool = false

var _initial_speed_mul = 1.0
var _motion_tracker : WeakRef = null
var _wait_promise : Promise = null

func _ready():
	if pawn == null and get_parent() is NPC:
		set_pawn(get_parent())
		set_enabled(enabled)

func _enter_tree():
	if !instance_from_id(pawn_id):
		pawn = null

func _exit_tree():
	if is_instance_valid(pawn) and enabled:
		pawn.controls.reset()

func set_pawn(value:NPC):
	var old_pawn = instance_from_id(pawn_id)
	if old_pawn:
		old_pawn.disconnect("paused", self, "_on_pawn_paused")
		old_pawn.disconnect("resumed", self, "_on_pawn_resumed")
	pawn = value
	pawn_id = 0
	if pawn:
		pawn_id = pawn.get_instance_id()
		pawn.connect("paused", self, "_on_pawn_paused")
		pawn.connect("resumed", self, "_on_pawn_resumed")
		self._initial_speed_mul = pawn.controls.speed_multiplier
	set_enabled(enabled)

func set_enabled(value:bool):
	if enabled and not value and is_instance_valid(pawn):
		_pause_controls()
	
	enabled = value
	set_process(value and is_instance_valid(pawn) and not pawn.paused)

func reset_promises():
	if self._wait_promise != null:
		self._wait_promise.disconnect("fulfilled", self, "_on_timeout")
		self._wait_promise = null

func _on_timeout(_ticks):
	if !is_inside_tree() || !is_instance_valid(pawn) || !pawn.is_inside_tree() || !enabled:
		return
	arrive(false)

func _on_pawn_paused():
	set_enabled(enabled)

func _on_pawn_resumed():
	set_enabled(enabled)

func set_params(value):
	if params != value:
		params = value

func arrive(success:bool):
	reset_promises()
	if params.pause_controls_on_arrive:
		_pause_controls()
		
	if success:
		emit_signal("target_reached")
	else :
		emit_signal("failed")
	emit_signal("arrived", success)

func _process(delta):
	if !is_instance_valid(pawn) || !pawn.is_inside_tree():
		return
	
	###
	var mt = self._motion_tracker.get_ref() if self._motion_tracker != null else null
	if mt == null:
		self._motion_tracker = weakref(PlayerMotionTracker.find_motion_tracker())
		mt = self._motion_tracker.get_ref()
		if mt == null:
			return

	if self._wait_promise == null && self.params.max_ticks > 0:
		self._wait_promise = mt.add_wait_timer(self.params.max_ticks)
		self._wait_promise.connect("fulfilled", self, "_on_timeout")
	
	var dt = delta * mt.player_speed_mul
	pawn.controls.speed_multiplier = self._initial_speed_mul * mt.player_speed_mul
	control_movement(dt)
	###

func get_target()->Vector3:
	if params.target_node.is_empty():
		return params.target_pos
	assert (has_node(params.target_node))
	if not has_node(params.target_node):
		return params.target_pos
	var node = get_node(params.target_node)
	if not is_instance_valid(node) or not (node is Spatial):
		return params.target_pos
	return node.global_transform.origin

func _pause_controls():
	if not pawn.controls:
		return 
	pawn.controls.direction = Vector2()
	if params.can_jump:
		pawn.controls.jump = false
	force_fly = false
	if params.can_fly:
		pawn.controls.force_fly = false
	if params.can_glide:
		pawn.controls.glide = true

func _warp_to_target():
	if warping:return 
	warping = true
	var target = get_target()
	var fade = pawn.global_transform.origin.distance_squared_to(target) > 0.25
	var co = null
	if params.min_distance > 1.0:
		co = pawn.warp_near(target, fade, params.min_distance)
	else :
		co = pawn.warp_to(target, fade)
	if co is GDScriptFunctionState:
		yield (Co.safe_yield(self, co), "completed")
	warping = false

func warp_or_fail():
	if mode == 1:
		arrive(false)
	elif params.can_warp:
		_warp_to_target()
		arrive(true)
	else :
		arrive(false)

func control_movement(delta):
	var cur_pos = pawn.global_transform.origin
	
	var target = get_target()
	var min_xz_distance = sqrt(0.125 * 0.125 * 2)
	
	if params.max_distance > 0.0 and cur_pos.distance_to(target) > params.max_distance:
		if params.can_warp:
			_warp_to_target()
			arrive(true)
		else :
			arrive(false)
		return 
	
	
	var moving_xz = false
	var disp_xz = (target - cur_pos) * PLANE_XZ
	if mode == 1:
		disp_xz *= - 1
	var heading = disp_xz.normalized()
	var t = Transform.translated(Vector3(0, 0.2625, 0)) * pawn.global_transform
	
	if disp_xz.length() > (pawn.velocity * PLANE_XZ).length() * delta and disp_xz.length() > min_xz_distance:
		pawn.controls.direction = Vector2(heading.x, heading.z)
		moving_xz = true
	else :
		pawn.controls.direction = Vector2()
		if pawn.controls.infinite_deceleration:
			pawn.velocity.x = 0.0
			pawn.velocity.z = 0.0
	
	if not params.can_fall:
		var next_t = Transform.translated(heading * 2.0 * pawn.scale) * t
		if not pawn.test_move(next_t, Vector3.DOWN * 1.5, pawn.infinite_inertia):
			_pause_controls()
			if not pawn.controls.infinite_deceleration and (pawn.velocity * PLANE_XZ).length() > FALL_PREVENTION_STOP_THRESHOLD:
				pawn.velocity.x = _decelerate(pawn.velocity.x, FALL_PREVENTION_DECELERATION, delta)
				pawn.velocity.z = _decelerate(pawn.velocity.z, FALL_PREVENTION_DECELERATION, delta)
			else :
				pawn.velocity.x = 0.0
				pawn.velocity.z = 0.0
				if !params.can_be_blocked:
					warp_or_fail()
			return 
	
	
	var dist_y = target.y - cur_pos.y if mode != 1 else 0.0
	var target_is_up = dist_y >= 0.125
	var target_is_down = dist_y <= - 0.125
	var avoid_down = pawn.floor_ray.is_npc_avoid()
	var forwards = disp_xz.normalized()

	if disp_xz.length() < params.min_distance:
		pawn.direction = pawn.controls.direction
		_pause_controls()
		arrive(true)
		return 

	if params.can_glide:
		pawn.controls.glide = true
	
	if pawn.on_ceiling:
		_ceiling_counter += 1
	else :
		_ceiling_counter = 0
	
	var collides_forwards = (moving_xz and pawn.test_move(t, forwards * 0.15, pawn.infinite_inertia))
	if collides_forwards or ( not moving_xz and target_is_up) or avoid_down or (dist_y >= 10.0 and params.can_fly):
		if pawn.controls.climb and _ceiling_counter < 3:
			if target_is_up:
				pawn.controls.direction = pawn.direction
			if not target_is_down:
				pawn.controls.jump = true
		else :
			if collides_forwards:
				pawn.controls.direction = Vector2()
			
			if (pawn.controls.jump and pawn.velocity.y < - 5.0) or pawn.get_state() == "Gliding":
				if params.can_fly:
					pawn.controls.force_fly = true
					force_fly = true
					pawn.controls.climb = false
				else :
					if !params.can_be_blocked:
						warp_or_fail()
					return 
			if params.can_jump:
				pawn.controls.jump = true
				if _ceiling_counter >= 3:	
					if !params.can_be_blocked:	
						warp_or_fail()
					return 
			else :
				if !params.can_be_blocked:
					warp_or_fail()
				return 
	else :
		if pawn.controls.force_fly:
			if params.can_fly:
				
				if target_is_up and pawn.velocity.y < 0.0:
					pawn.controls.jump = true
				else :
					pawn.controls.jump = false
					if pawn.on_floor or pawn.in_water:
						pawn.controls.force_fly = false
						force_fly = false
		else :
			
			pawn.controls.jump = false
	
	if not moving_xz:
		if mode == 1:
			arrive(false)
			return 
		if params.ignore_ending_y:
			_pause_controls()
			arrive(true)
			return 
		if pawn.on_floor and target.y <= cur_pos.y - 0.125:
			warp_or_fail()
			return 
		if abs(target.y - cur_pos.y) <= 0.125:
			_pause_controls()
			pawn.global_transform.origin = target
			pawn.move_and_collide(Vector3(), false)
			arrive(true)

func _decelerate(v:float, decel:float, delta:float)->float:
	var s = sign(v)
	var a = abs(v)
	a = max(0.0, a - decel * delta)
	return s * a
