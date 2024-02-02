extends Spatial

const GeneratedFloor = preload("GeneratedFloor.gd")

var floor_data: GeneratedFloor

func realise():
	var starts = []
	var backup_starts = []
	for c in get_parent().get_children():
		if !c.name.begins_with("DF_ROOM_ROOT_"):
			continue

		for poi in c.points_of_interest:
			if poi.can_be_start() && !poi.is_allocated():
				if c.plot_id == floor_data.treasure_room:
					backup_starts.push_back(poi)
				else:
					starts.push_back(poi)

	if starts.size() > 0:
		var start = starts[floor_data.entrance_key % starts.size()]
		start.allocate_start()
		self.global_translate(start.global_translation)
	elif backup_starts.size() > 0:
		var start = backup_starts[floor_data.entrance_key % backup_starts.size()]
		start.allocate_start()
		self.global_translate(start.global_translation)
	else:
		push_error("[PlayerStartRootNode] No points of interest to spawn the player were found")
		return
	
	var start_node = get_parent().get_node("Start")
	if start_node == null:
		push_error("[PlayerStartRootNode] No 'Start' node found in scene")
		return

	start_node.transform = transform