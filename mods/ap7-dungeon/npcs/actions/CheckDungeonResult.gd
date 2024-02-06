extends DecoratorAction

enum ExitType { Any, Victory, Defeat, Flee }

export(ExitType) var exit_type = ExitType.Any
export(bool) var require_item_found = false
export(int) var require_floor_min = -1
export(int) var require_floor_max = -1

func run():
	var args = SceneManager.args

	var was_completed = args.has("dungeon_completed") && args.dungeon_completed
	var was_defeated = args.has("dungeon_defeated") && args.dungeon_defeated
	var stickers = args.dungeon_stickers if args.has("dungeon_stickers") else []
	var items = args.dungeon_items if args.has("dungeon_items") else []
	var tapes = args.dungeon_tapes if args.has("dungeon_tapes") else []
	var flr = args.dungeon_floor if args.has("dungeon_floor") else 1

	if exit_type == ExitType.Victory && !was_completed:
		return false
	if exit_type == ExitType.Defeat && !was_defeated:
		return false
	if exit_type == ExitType.Flee && (was_completed || was_defeated):
		return false

	if require_item_found && items.size() == 0 && tapes.size() == 0 && stickers.size() == 0:
		return false

	if require_floor_min > 0 && flr < require_floor_min:
		return false
	if require_floor_max > 0 && flr > require_floor_max:
		return false

	return .run()
