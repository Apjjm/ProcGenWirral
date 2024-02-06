extends Spatial

const DungeonData = preload("../globals/DungeonData.gd")
const FloorTag = preload("../FloorTags.gd")

export(String) var tag = ""

func _enter_tree():
	var dd = DungeonData.get_global()
	if dd != null && tag != "" && !dd.get_current_floor_or_default().has_tag(tag):
		for c in get_children():
			remove_child(c)
			c.queue_free()
