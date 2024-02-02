extends Area

const DungeonData = preload("../globals/DungeonData.gd")
const PlayerData = preload("../globals/PlayerData.gd")

export(bool) var secret_room_warp = false

func _ready():
	self.collision_layer = 0
	self.collision_mask = Collisions.MASK_PLAYER
	connect("body_entered", self, "_on_body_entered")

func _on_body_entered(_body):
	if WorldSystem.is_player_control_enabled():
		var di = DungeonData.get_global().get_current_dungeon()
		if di == null:
			push_warning("[NextFloorWarpArea] No dungeon active, skipping warp")
			return

		var cfi = di.get_current_floor_or_default()
		var nfi = di.move_to_secret_floor(cfi.secret_floor_key()) if self.secret_room_warp else di.move_to_next_normal_floor()
		if nfi == null:
			push_warning("[NextFloorWarpArea] No next floor available, skipping warp")
			return
		
		WorldSystem.push_flags(WorldSystem.WorldFlags.PHYSICS_ENABLED)
		for p in WorldSystem.get_players():
			if p is NPC:
				p.controls.reset()
				p.state_machine.state = "Falling"
		
		if !SceneManager.transitioned_out:
			SceneManager.transition = SceneManager.TransitionKind.TRANSITION_FADE
			yield (SceneManager.transition_out(), "completed")
		
		WorldSystem.pop_flags()
		PlayerData.get_global().push_inner_player()
		nfi.warp_to()
