extends BaseItem

const MENU_SCENE = preload("res://mods/ap7-dungeon/menus/TapeRerecordMenu.tscn")

func get_rarity():
	return Rarity.RARITY_RARE

func get_use_options(_node, _context_kind:int, _context)->Array:
	return [{"label":"AP7_DUNGEON_ITEM_OPTS_RERECORD", "arg": {}}]

func custom_use_menu(_node, _context_kind:int, _context, arg = null):
	var menu = MENU_SCENE.instance()
	MenuHelper.add_child(menu)
	var result = yield (menu.run_menu(), "completed")
	menu.queue_free()
	#print("[Rerecord] Menu closed with result: ", result)
	
	return arg if result == true else null # Null indicates a cancel

func _use_in_world(_node, _context, _arg):
	return true
