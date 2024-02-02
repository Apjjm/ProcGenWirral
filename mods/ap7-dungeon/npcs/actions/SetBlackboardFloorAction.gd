extends Action

const FloorTags = preload("../../FloorTags.gd")
const DungeonData = preload("../../globals/DungeonData.gd")

export(String) var bb_key = ""

func _run():
	var tag = _get_id_tag()
	if tag != "" && self.bb_key != "":
		set_bb(self.bb_key, tag)
		
	return true

func _get_id_tag() -> String:
	var cfi = DungeonData.get_global().get_current_floor_or_default()
	for tag in FloorTags.SCENE_LOOKUP.keys():
		if cfi.has_tag(tag):
			return tag

	return ""
