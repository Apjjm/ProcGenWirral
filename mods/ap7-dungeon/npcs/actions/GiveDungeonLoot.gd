extends Action

func run():
	var args = SceneManager.args
	var items = args.dungeon_items if args.has("dungeon_items") else []
	var tapes = args.dungeon_tapes if args.has("dungeon_tapes") else []

	if items.size() > 0:
		yield (MenuHelper.give_items(items), "completed")

	for tape in tapes:
		yield (MenuHelper.give_tape(tape, false), "completed")
		
	return true
