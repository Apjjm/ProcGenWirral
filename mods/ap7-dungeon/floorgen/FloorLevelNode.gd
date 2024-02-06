extends LevelMap

const GeneratedFloor = preload("GeneratedFloor.gd")
const RoomRootNode = preload("RoomRootNode.gd")
const EnemyRootNode = preload("EnemyRootNode.gd")
const RangerRootNode = preload("RangerRootNode.gd")
const TreasureRootNode = preload("TreasureRootNode.gd")
const PlayerStartRootNode = preload("PlayerStartRootNode.gd")
const PlayerMotionTracker = preload("../player/PlayerMotionTracker.gd")
const DungeonData = preload("../globals/DungeonData.gd")
const PlayerData = preload("../globals/PlayerData.gd")

signal active_rooms_changed(rooms)
signal active_cells_changed(cells)
signal floor_generated(floor_data)

class ActiveCellInfo:
	extends Reference
	var id : int
	var x : int
	var y : int

 # How many steps (parcel scene instantiations) can we take per frame when loading parcels?
export(int) var load_steps = 8

 # What foor seed should be forced if we didn't weren't given one? 0 = random.
export(int) var default_floor_seed = 0

var floor_data : GeneratedFloor = null
var active_rooms : Array = []
var active_cells : Array = []

var _load_promise : Promise = null
var _to_realise : Array = []
var _is_realised : bool = false

func get_room(plot_id: int):
	if has_node("DF_ROOM_ROOT_" + str(plot_id)):
		return get_node("DF_ROOM_ROOT_" + str(plot_id))
	return null

func _load_task()->Promise:
	._load_task()
	
	if self._is_realised: 
		return null # already loaded!

	assert(is_inside_tree())
	assert(SceneManager.loading)

	PlayerData.get_global().apply_inner_player() # The floor is remade from seed if we reload a save. So reset player to floor start. 
	
	var fi = DungeonData.get_global().get_current_floor_or_default()
	print("[Floor] Starting load for floor ", fi.floor_number())
	self.floor_data = get_node("FloorGenerator").generate_floor(fi)
	self.region_settings = self.floor_data.region_settings
	self.map_metadata = self.floor_data.map
	
	for node in get_children():
		if node.name.begins_with("DF_ROOM_ROOT_") || node.name.begins_with("DF_ENEMY_ROOT_") || node.name.begins_with("DF_LOOT_ROOT_"):
			node.queue_free()

	var parcels = self._rebuild_parcel_nodes()
	var transitions = self._rebuild_transition_nodes()
	var enemies = self._rebuild_enemy_nodes()
	var rangers = self._rebuild_ranger_nodes()
	var loot = self._rebuild_loot_nodes()
	var keys = self._rebuild_key_item_nodes()

	# Things added last get process first. We want to interleave enemies and loot as they are both competing for the same spots.
	self._to_realise.append_array(rangers)
	self._to_realise.append_array(transitions)
	self._to_realise.append_array(_interleave(enemies,loot))
	self._to_realise.append_array(keys)
	self._to_realise.append_array(parcels)

	emit_signal("floor_generated", self.floor_data)
	self._load_promise = Promise.new()
	self._load_promise.progress_max = self._to_realise.size()+1
	self.pause_mode = Node.PAUSE_MODE_PROCESS
	self.set_process(true)

	return self._load_promise

func _transition_into():
	._transition_into()

	if !PlayerMotionTracker.has_motion_tracker():
		var motion_tracker = PlayerMotionTracker.new()
		motion_tracker.attach_to_player()

func _process(_delta):
	if self._load_promise == null:
		return
	
	if self._to_realise.size() == 0:
		print("[Floor] Finishing loading floor")
		self._is_realised = true
		self._load_promise.progress = self._load_promise.progress_max
		self._load_promise.fulfill()
		self._load_promise = null
		self.pause_mode = Node.PAUSE_MODE_INHERIT
		self.set_process(false)
		return

	for _i in range(0, min(self._to_realise.size(), self.load_steps)):
		var child = self._to_realise.pop_back()
		child.realise()
		self._load_promise.progress += 1

func _rebuild_parcel_nodes() -> Array:
	var result = []
	
	for plot in self.floor_data.layout.plots:
		var room = RoomRootNode.new(plot.id, self.floor_data)
		room.translate(Vector3(plot.x * self.floor_data.world_cell_size.x, 0, plot.y * self.floor_data.world_cell_size.y))
		room.connect("player_cell_entered", self, "_on_player_cell_entered")
		room.connect("player_cell_exited", self, "_on_player_cell_exited")
		result.push_back(room)
		add_child(room)

	return result

func _rebuild_enemy_nodes() -> Array:
	var result = []
	if self.floor_data.encounters != null:
		for encounter in self.floor_data.encounters.get_monster_encounters():
			var node = EnemyRootNode.new()
			node.name = "DF_ENEMY_ROOT_" + str(encounter.id)
			node.encounter_id = encounter.id
			node.floor_data = self.floor_data
			result.push_back(node)
			get_room(encounter.plot).add_child(node)
	
	return result

func _rebuild_ranger_nodes() -> Array:
	var result = []
	if self.floor_data.encounters != null:
		for encounter in self.floor_data.encounters.get_ranger_encounters():
			var node = RangerRootNode.new()
			node.name = "DF_RANGER_ROOT_" + str(encounter.id)
			node.encounter_id = encounter.id
			node.floor_data = self.floor_data
			result.push_back(node)
			get_room(encounter.plot).add_child(node)
	
	return result

func _rebuild_loot_nodes() -> Array:
	var result = []
	if self.floor_data.treasure != null:
		for treasure in self.floor_data.treasure.get_treasures():
			var node = TreasureRootNode.new()
			node.name = "DF_TREASURE_ROOT_t" + str(treasure.id)
			node.treasure_id = treasure.id
			node.floor_data = self.floor_data
			result.push_back(node)
			get_room(treasure.plot).add_child(node)
		
	return result

func _rebuild_key_item_nodes() -> Array:
	var result = []
	if self.floor_data.treasure != null:
		for treasure in self.floor_data.treasure.get_key_items():
			var node = TreasureRootNode.new()
			node.name = "DF_TREASURE_ROOT_k" + str(treasure.id)
			node.key_item_id = treasure.id
			node.floor_data = self.floor_data
			result.push_back(node)
			get_room(treasure.plot).add_child(node)
		
	return result

func _rebuild_transition_nodes() -> Array:
	var start_node = PlayerStartRootNode.new()
	start_node.name="DF_PLAYER_START"
	start_node.floor_data = self.floor_data
	add_child(start_node)
	return [ start_node ]

func _interleave(arr1: Array, arr2: Array) -> Array:
	var result = []
	var i1 = 0
	var i2 = 0

	while i1 < arr1.size() || i2 < arr2.size():
		if i1 < arr1.size():
			result.push_back(arr1[i1])
			i1 += 1
		if i2 < arr2.size():
			result.push_back(arr2[i2])
			i2 += 1
	
	return result

func _select_parcel(definition: Resource, zone: String, key: int):
	for set in self.parcelsets:
		if set.plot == definition.shape_id && zone in set.zones:
			return set.get_parcel(key)

	assert(false, "No parcel found for definition " + str(definition.shape_id) + " with zone " + zone)

func _on_player_cell_entered(_body, cell_x, cell_y, id):
	var info = ActiveCellInfo.new()
	info.x = cell_x
	info.y = cell_y
	info.id = id

	self.active_cells.push_back(info)
	emit_signal("active_cells_changed", self.active_cells) 

	if !(id in self.active_rooms):
		self.active_rooms.push_back(id)
		#print("[FloorLevelNode] Rooms changed: ", self.active_rooms)
		emit_signal("active_rooms_changed", self.active_rooms) 

func _on_player_cell_exited(_body, cell_x, cell_y, _id):
	var new_rooms = []
	for i in range(self.active_cells.size()-1, -1, -1):
		if self.active_cells[i].x == cell_x && self.active_cells[i].y == cell_y:
			self.active_cells.remove(i)
		elif !(self.active_cells[i].id in new_rooms):
			new_rooms.push_back(self.active_cells[i].id)

	emit_signal("active_cells_changed", self.active_cells)
	if new_rooms.size() < self.active_rooms.size():
		#print("[FloorLevelNode] Rooms changed: ", new_rooms)
		self.active_rooms = new_rooms
		emit_signal("active_rooms_changed", self.active_rooms)
