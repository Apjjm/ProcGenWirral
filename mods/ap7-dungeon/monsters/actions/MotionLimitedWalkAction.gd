extends Action

const MotionLimitedPathController = preload("MotionLimitedPathController.gd")

export var max_ticks:int = -1
export var max_distance:float = 10.0
export var always_succeed:bool = true

export var can_fly:bool = false
export var can_jump:bool = false
export var can_glide:bool = false
export var can_fall:bool = false
export var can_warp:bool = false
export var allow_block:bool = true
export var speed_multiplier:float = 1.0
export var strafe:bool = false
export var hide_avatars_if_cutscene:bool = true

var path_controller = null

func _run():
	if hide_avatars_if_cutscene and blackboard.get("is_cutscene"):
		WorldSystem.set_hide_net_avatars(true)
	
	var who = blackboard.pawn
	var start_pos = who.global_transform.origin
	
	var direction = who.direction
		
	if path_controller == null:
		path_controller = MotionLimitedPathController.new()
		add_child(path_controller)
		root.connect("paused", self, "_on_paused")
		root.connect("effectively_unpaused", self, "_on_unpaused")
	else:
		path_controller.reset_promises()
	
	path_controller.params.can_fly = can_fly
	path_controller.params.can_jump = can_jump
	path_controller.params.can_glide = can_glide
	path_controller.params.can_fall = can_fall
	path_controller.params.can_warp = can_warp
	path_controller.params.max_ticks = max_ticks
	path_controller.params.can_be_blocked = allow_block && max_ticks > 0
	path_controller.params.ignore_ending_y = true
	path_controller.params.target_pos = start_pos + Vector3(direction.x * max_distance, 0.0, direction.y * max_distance)
	
	who.controls.speed_multiplier = speed_multiplier
	who.controls.strafe = strafe

	path_controller.set_pawn(who)
	path_controller.enabled = true
	who.set_paused(false)
	
	var result = yield (wait_for_result(Co.listen(path_controller, "arrived")), "completed")
	path_controller.reset_promises()

	path_controller.enabled = false
	who.controls.speed_multiplier = 1.0
	who.controls.strafe = false
	
	return result or always_succeed

func _on_paused():
	assert (is_instance_valid(path_controller))
	path_controller.enabled = false

func _on_unpaused():
	assert (is_instance_valid(path_controller))
	path_controller.enabled = is_running()
