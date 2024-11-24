extends Spatial

const DungeonData = preload("../globals/DungeonData.gd")
const FloorTag = preload("../FloorTags.gd")

export(String) var tag = ""

func _enter_tree():
	var dd = DungeonData.get_global()
	if dd != null:
		var di = dd.get_current_dungeon()
		var fi = di.get_current_floor() if di != null else DungeonData.get_fallback_floor()
		if tag != "" && !fi.has_tag(tag):
			for c in get_children():
				remove_child(c)
				c.queue_free()
