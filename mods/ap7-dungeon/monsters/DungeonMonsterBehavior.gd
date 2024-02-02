extends "res://addons/misc_utils/StateMachine.gd"

export (bool) var repelable:bool = true
export (bool) var pursue_in_room_only:bool = true

const IDLE_NAME = "Idle"
const PURSUE_NAME = "Pursue"
const BATTLE_NAME = "Battle"
const RoomRootNode = preload("../floorgen/RoomRootNode.gd")

func _ready():
	yield (get_parent(), "ready")
	assert(get_parent() is NPC)

	assert(get_node(IDLE_NAME) != null, "no idle state present")
	assert(get_node(PURSUE_NAME) != null, "no pursue state present")
	assert(get_node(BATTLE_NAME) != null, "no battle state present")

	get_parent().connect("resumed", self, "set_paused", [false])
	get_parent().connect("paused", self, "set_paused", [true])

func idle():
	if state != BATTLE_NAME:
		set_state(IDLE_NAME)

func pursue(entity):
	if WorldSystem.no_aggro || (repelable && WorldSystem.reodorant_timer > 0.0):
		return
	
	if self.pursue_in_room_only:
		var room_root = RoomRootNode.find_room_root(self)
		if room_root != null && !room_root.is_player_in_room():
			return

	if state != BATTLE_NAME:
		if state != PURSUE_NAME:
			set_state(PURSUE_NAME)
		if state_node is ActionBase:
			state_node.blackboard["player"] = entity

func battle(_entity):
	if state != BATTLE_NAME:
		set_state(BATTLE_NAME)

