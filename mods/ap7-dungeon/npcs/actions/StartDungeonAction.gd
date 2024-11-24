extends Action

const DungeonData = preload("../../globals/DungeonData.gd")
const PlayerData = preload("../../globals/PlayerData.gd")
const SetupMenu = preload("../../menus/setup/SetupMenu.tscn")

func _run():
	var menu = SetupMenu.instance()
	MenuHelper.add_child(menu)
	
	var gen_args = yield (Co.safe_yield(self, menu.run_menu()), "completed")
	menu.queue_free()

	return gen_args != null
