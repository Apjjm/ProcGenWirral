extends Action

const DungeonData = preload("../../globals/DungeonData.gd")
const PlayerData = preload("../../globals/PlayerData.gd")

func _run():
	var s = randi()
	DungeonData.get_global().generate_dungeon(s)
	PlayerData.get_global().push_dungeon_player(s)
	return true
