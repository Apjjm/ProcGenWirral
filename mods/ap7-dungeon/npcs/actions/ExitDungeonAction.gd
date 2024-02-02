extends Action

const FloorTags = preload("../../FloorTags.gd")
const PlayerData = preload("../../globals/PlayerData.gd")
const DungeonData = preload("../../globals/DungeonData.gd")
const MemorySigil = preload("../../items/stickers/MemorySigil.gd")

const FusedMaterial = preload("res://data/items/fused_material.tres")

export(bool) var defeated = false
export(bool) var completed = false

func _run():
	var player_data = PlayerData.get_global()
	var dungeon_data = DungeonData.get_global()
	var floor_info = dungeon_data.get_current_floor_or_default()
	var target_scene = FloorTags.SCENE_LOOKUP[FloorTags.FT_SCENE_EXTERIROR]
	print("[ExitDungeonAction] preparing to leaving dungeon from floor ", floor_info.floor_number(), " -> ", FloorTags.FT_SCENE_EXTERIROR)

	var args = { 
		"dungeon_defeated": self.defeated, 
		"dungeon_completed": self.completed,
		"dungeon_tapes": _get_keepable_tapes(),
		"dungeon_items": _get_keepable_items(floor_info.floor_number()),
		"dungeon_floor": floor_info.floor_number(),
	}

	dungeon_data.clear_dungeon()
	player_data.pop_dungeon_player()

	SceneManager.clear_stack()
	WorldSystem.reset_flags()
	SceneManager.transition = SceneManager.TransitionKind.TRANSITION_SLOW_FADE
	WorldSystem.warp(target_scene, null, "ExitDungeon", args)
	return true

func _get_keepable_tapes() -> Array:
	var saved_tapes = []
	for tape in SaveState.party.get_tapes():
		for i in range(tape.get_max_stickers()):
			var sticker = tape.get_sticker(i)
			if sticker != null && sticker.battle_move is MemorySigil:
				saved_tapes.push_back(tape)

	# Remove dungeon only stickers - this also helps keep saves compatible.
	for tape in saved_tapes:
		for i in range(tape.get_max_stickers()):
			var sticker = tape.get_sticker(i)
			if sticker != null && ("sigil" in sticker.battle_move.tags || "sigil_rare" in sticker.battle_move.tags):
				tape.favorite = false
				tape.peel_sticker(i, true)

	return saved_tapes

func _get_keepable_items(floor_number: int) -> Array:
	var result = []
	var mul = 0.5 if self.defeated else 1.0
	if floor_number > 2:
		result.push_back({"item": FusedMaterial, "amount": int(floor_number * mul * 0.5)})

	for item_node in SaveState.inventory.get_all_items():
		var quantity = int(item_node.amount * mul)
		if item_node.get_category() == "resources" && quantity > 0:
			result.push_back({"item": item_node.item, "amount": quantity})

	return result