extends Action

func run():
	var args = SceneManager.args
	var stickers = args.dungeon_stickers if args.has("dungeon_stickers") else []
	var items = args.dungeon_items if args.has("dungeon_items") else []
	var tapes = args.dungeon_tapes if args.has("dungeon_tapes") else []

	if items.size() > 0:
		var loot = get_loot(items, stickers)
		yield (MenuHelper.give_items(loot), "completed")

	for tape in tapes:
		yield (MenuHelper.give_tape(tape, false), "completed")
		
	return true

func get_loot(items: Array, stickers: Array) -> Array:
	var loot = []
	loot.append_array(items)

	for sticker in stickers:
		loot.push_back({ "item": sticker, "amount": 1 })

	return loot