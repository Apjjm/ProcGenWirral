extends Action

const FloorTags = preload("../../FloorTags.gd")
const DungeonInfo = preload("../../DungeonInfo.gd")
const PlayerData = preload("../../globals/PlayerData.gd")
const DungeonData = preload("../../globals/DungeonData.gd")
const MemorySigil = preload("../../items/stickers/MemorySigil.gd")

const FusedMaterial = preload("res://data/items/fused_material.tres")

export(bool) var defeated = false
export(bool) var completed = false

func _run():
	var player_data = PlayerData.get_global()
	var dungeon_data = DungeonData.get_global()
	var dungeon_info = dungeon_data.get_current_dungeon()
	var floor_info = dungeon_info.get_current_floor() if dungeon_info != null else DungeonData.get_fallback_floor()
	var target_scene = FloorTags.SCENE_LOOKUP[FloorTags.FT_SCENE_EXTERIROR]
	print("[ExitDungeonAction] preparing to leaving dungeon from floor ", floor_info.floor_number(), " -> ", FloorTags.FT_SCENE_EXTERIROR)

	var tapes = _get_keepable_tapes()
	var args = { 
		"dungeon_defeated": self.defeated, 
		"dungeon_completed": self.completed,
		"dungeon_tapes": tapes.keep,
		"dungeon_items": _get_keepable_items(floor_info.floor_number(), dungeon_info.get_level_multiplier()),
		"dungeon_stickers": _get_keepable_stickers(floor_info.floor_number(), dungeon_info.get_level_multiplier(), tapes.drop),
		"dungeon_floor": floor_info.floor_number(),
	}

	player_data.pop_dungeon_player()
	dungeon_data.clear_dungeon()
	SaveState.party.heal()

	SceneManager.clear_stack()
	WorldSystem.reset_flags()
	SceneManager.transition = SceneManager.TransitionKind.TRANSITION_SLOW_FADE
	WorldSystem.warp(target_scene, null, "ExitDungeon", args)
	return true

func _get_keepable_tapes() -> Dictionary:
	var saved_tapes = []
	var unsaved_tapes = []
	for tape in SaveState.party.get_tapes():
		var saved = false

		for i in range(tape.get_max_stickers()):
			var sticker = tape.get_sticker(i)
			if sticker != null && sticker.battle_move is MemorySigil:
				saved_tapes.push_back(tape)
				saved = true
				break

		if !saved:
			unsaved_tapes.push_back(tape)

	# Remove dungeon only stickers - this also helps keep saves compatible.
	_prepare_tapes_for_exit(saved_tapes)
	_prepare_tapes_for_exit(unsaved_tapes)
	
	return {"keep": saved_tapes, "drop": unsaved_tapes }

func _get_keepable_items(floor_number: int, scaling: float) -> Array:
	var result = []
	var mul = (0.2 if self.defeated else 0.4) * scaling
	if floor_number > 2:
		result.push_back({"item": FusedMaterial, "amount": int(floor_number * floor_number * mul)})

	for item_node in SaveState.inventory.get_category("resources").get_children():
		var quantity = int(item_node.amount * mul)
		if quantity > 0:
			result.push_back({"item": item_node.item, "amount": quantity})

	return result

func _get_keepable_stickers(floor_number: int, scaling: float, tapes: Array) -> Array:
	var stickers = []
	var to_keep = int(floor_number*scaling*0.75)

	for item_node in SaveState.inventory.get_category("stickers").get_children():
		if item_node.amount > 0 && item_node.item is StickerItem && item_node.item.rarity == BaseItem.Rarity.RARITY_RARE:
			stickers.push_back(item_node.item)

	for tape in tapes:
		for i in range(tape.get_max_stickers()):
			var sticker = tape.get_sticker(i)
			if sticker != null && sticker.rarity == BaseItem.Rarity.RARITY_RARE:
				stickers.push_back(sticker)

	stickers.shuffle()
	if stickers.size() > to_keep:
		stickers.resize(to_keep)

	return stickers

func _prepare_tapes_for_exit(tapes: Array):
	for tape in tapes:
		for i in range(tape.get_max_stickers()):
			var sticker = tape.get_sticker(i)
			if sticker != null && ("sigil" in sticker.battle_move.tags || "sigil_rare" in sticker.battle_move.tags):
				tape.favorite = false
				tape.peel_sticker(i, true)
