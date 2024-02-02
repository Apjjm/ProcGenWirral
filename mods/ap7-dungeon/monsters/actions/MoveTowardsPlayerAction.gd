extends "./RandomMonsterActionBase.gd"

const MotionLimitedPathController = preload("MotionLimitedPathController.gd")
const RoomRootNode = preload("../../floorgen/RoomRootNode.gd")

enum MotionType { X_ONLY, Z_ONLY, RANDOM_XZ_ONLY, LARGEST_XZ_ONLY, DIRECT };

export var max_ticks:int = -1
export var always_succeed:bool = true
export(MotionType) var motion_type = MotionType.DIRECT

export var can_fly:bool = false
export var can_jump:bool = false
export var can_glide:bool = false
export var can_fall:bool = false
export var can_warp:bool = false
export var allow_block:bool = false
export var pause_controls_on_arrive:bool = true
export var speed_multiplier:float = 1.0
export var strafe:bool = false
export var hide_avatars_if_cutscene:bool = true
export var only_in_room:bool = true

var path_controller = null
var room_root = null

func _ready():
	self.room_root = RoomRootNode.find_room_root(self)

func _run():
	if self.room_root != null:
		if self.only_in_room && !self.room_root.is_player_in_room():
			yield(Co.next_frame(), "completed")
			return always_succeed

	if hide_avatars_if_cutscene and blackboard.get("is_cutscene"):
		WorldSystem.set_hide_net_avatars(true)
	
	var who = blackboard.pawn
	var start_pos = who.global_transform.origin

	var player = WorldSystem.get_player()
	if player == null:
		yield(Co.next_frame(), "completed")
		return always_succeed
		
	var end_pos = start_pos
	var player_pos = player.global_translation

	match motion_type:
		MotionType.X_ONLY: end_pos.x = player_pos.x
		MotionType.Z_ONLY: end_pos.z = player_pos.z
		MotionType.RANDOM_XZ_ONLY: 
			if self.rng.rand_bool():
				end_pos.z = player_pos.z
			else:
				end_pos.x = player_pos.x
		MotionType.LARGEST_XZ_ONLY:
			if abs(end_pos.z - player_pos.z) > abs(end_pos.x - player_pos.x):
				end_pos.z = player_pos.z
			else:
				end_pos.x = player_pos.x
		MotionType.DIRECT:
				end_pos = player_pos
	
	if path_controller == null:
		path_controller = MotionLimitedPathController.new()
		add_child(path_controller)
		root.connect("paused", self, "_on_paused")
		root.connect("effectively_unpaused", self, "_on_unpaused")
	path_controller.params.can_fly = can_fly
	path_controller.params.can_jump = can_jump
	path_controller.params.can_glide = can_glide
	path_controller.params.can_fall = can_fall
	path_controller.params.can_warp = can_warp
	path_controller.params.max_ticks = max_ticks
	path_controller.params.can_be_blocked = allow_block
	path_controller.params.ignore_ending_y = true
	path_controller.params.pause_controls_on_arrive = pause_controls_on_arrive
	path_controller.params.target_node = player.get_path() if motion_type == MotionType.DIRECT else NodePath("")
	path_controller.params.target_pos = end_pos
	
	who.controls.speed_multiplier = speed_multiplier
	who.controls.strafe = strafe

	path_controller.set_pawn(who)
	path_controller.enabled = true
	who.set_paused(false)
	var result = yield (wait_for_result(Co.listen(path_controller, "arrived")), "completed")

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
