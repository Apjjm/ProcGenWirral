extends Action

const DungeonData = preload("../../globals/DungeonData.gd")
const PlayerData = preload("../../globals/PlayerData.gd")

func _run():
	var player_data = PlayerData.get_global()

	var di = DungeonData.get_global().get_current_dungeon()
	if di == null:
		push_warning("[SecretFloorAction] No dungeon active, skipping warp")
		return false

	var cfi = di.get_current_floor_or_default()
	var nfi = di.move_to_secret_floor(cfi.secret_floor_key())
	if nfi == null:
		push_warning("[SecretFloorAction] No next floor available, skipping warp")
		return false

	if !SceneManager.transitioned_out:
		SceneManager.transition = SceneManager.TransitionKind.TRANSITION_FADE
		yield (SceneManager.transition_out(), "completed")

	WorldSystem.pop_flags()
	player_data.push_inner_player()
	nfi.warp_to()
	return true
