extends Spatial

var themes = []
var used_themes = []
var current_theme = null

func _ready():
	add_to_group("ap7_dungeon_tf_anim", false)
	for i in range(get_child_count()):
		var node = get_child(i)
		if i == 0:
			self.current_theme = node
			self.used_themes.push_back(node)
			node.visible = true
		else:
			self.themes.push_back(node)
			node.visible = false

	# We save a counter so on subsequent fights you can see a different backdrop
	var to_skip = get_counter() % self.themes.size()
	while self.themes.size() > 0 && to_skip > 0:
		self.used_themes.push_back(self.themes.pop_front())
		to_skip -= 1

func on_tf_begin(_mat: Material):
	pass

func on_tf_change():
	if self.themes.size() == 0:
		self.themes.append_array(used_themes)
		self.used_themes.clear()

	if self.current_theme != null:
		self.current_theme.visible = false
	
	self.current_theme = self.themes.pop_front()
	self.current_theme.visible = true
	self.used_themes.push_back(self.current_theme)
	inc_counter()

func on_tf_end():
	pass

func get_counter():
	if SaveState.counters.has("ap7_dungeon_tf_counter"):
		return SaveState.counters.get("ap7_dungeon_tf_counter")
	else:
		return 0

func inc_counter():
	if SaveState.counters.has("ap7_dungeon_tf_counter"):
		SaveState.counters["ap7_dungeon_tf_counter"] = (SaveState.counters["ap7_dungeon_tf_counter"] + 1) % get_child_count()
	else:
		SaveState.counters["ap7_dungeon_tf_counter"] = 1
