extends Action

const RoomRootNode = preload("../../floorgen/RoomRootNode.gd")
const RandomParcelRngRoot = preload("../../parcels/RandomParcelRngRoot.gd")
const RewardMenuScene = preload("RewardMenu.tscn")
const RewardMenu = preload("RewardMenu.gd")

export(String) var menu_title
export(Resource) var menu_open_sound
export(int, 0, 9) var num_items = 3

func _run_children(default_result):
	print("[RewardMenuAction] Showing reward menu")

	var low_priority = []
	var high_priority = []
	for c in get_children():
		if c.has_method("run") && c.has_method("has_priority") && !c.is_blocked():
			c.refresh()
			if c.has_priority():
				high_priority.push_back(c)
			else:
				low_priority.push_back(c)

	var rng = _get_rng()
	rng.shuffle(high_priority)
	rng.shuffle(low_priority)

	var menu_options = []
	menu_options.append_array(high_priority)
	menu_options.append_array(low_priority)
	menu_options.resize(int(min(menu_options.size(), self.num_items)))
	
	var menu = RewardMenuScene.instance()
	menu.title = self.menu_title
	menu.menu_open_sound = self.menu_open_sound
	menu.reward_items = menu_options

	MenuHelper.add_child(menu)
	var choice = yield (menu.run_menu(), "completed")
	menu.queue_free()

	return choice.run() if choice != null else default_result

func _get_rng():
	var rr = RoomRootNode.find_room_root(self)
	if rr == null:
		rr = RandomParcelRngRoot.find_rng_root(self)

	return rr.prop_rng if rr != null else Random.new()
