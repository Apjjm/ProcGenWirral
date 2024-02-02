extends Resource

export(Resource) var form = null
export(String, FILE, "*.tscn") var overworld = ""
export(Array, String) var buddy_tags = []
export(Array, Resource) var starter_stickers = []
export(int, 1, 4) var floor_tier = 1
export(int, 0, 10) var overlevel_max = 0
export(int, 0, 10) var underlevel_max = 1
export(bool) var force_solo = false
export(String, "monster", "monster_miniboss", "monster_boss_smart") var smartness = "monster"

func has_buddy_tags():
	return buddy_tags.size() > 0

func shares_tag_with(other):
	for tag in other.buddy_tags:
		if buddy_tags.has(tag):
			return true

	return false
