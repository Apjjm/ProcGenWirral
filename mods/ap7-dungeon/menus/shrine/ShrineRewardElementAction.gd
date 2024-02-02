extends "ShrineRewardBaseAction.gd"

const FloorTags = preload("../../FloorTags.gd")
const DungeonData = preload("../../globals/DungeonData.gd")
const ElementalSigil = preload("../../items/stickers/ElementalSigil.gd")

export(Resource) var element_type

func has_priority() -> bool:
	var sigils = get_bb("shrine_sigils")
	for move in sigils:
		if move is ElementalSigil && element_type == move.elemental_type:
			return true

	return false

func _run():
	print("[ShrineRewardTapeLevelAction] Selected with element ", element_type.id)

	var di = DungeonData.get_global().get_current_dungeon()
	var fi = di.get_next_normal_floor_without_tag(FloorTags.FT_NOCOMBAT) if di != null else null
	if fi != null:
		var new_tags = [element_type.id]
		var elemental_types = Datatables.load("res://data/elemental_types/").table.values()	
		for tag in fi.tags():
			if !is_elemental_tag(tag, elemental_types):
				new_tags.push_back(tag)

		fi.set_tags(new_tags)

	return true

func is_elemental_tag(tag: String, elemental_types: Array):
	for type in elemental_types:
		if tag == type.id:
			return true

	return false
