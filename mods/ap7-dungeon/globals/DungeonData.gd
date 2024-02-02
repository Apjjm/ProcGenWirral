extends Node

const SAVE_KEY_NAME_DUNGEON = "ap7_dungeon_generated_v1"

const FloorInfo = preload("../FloorInfo.gd")
const DungeonInfo = preload("../DungeonInfo.gd")
const FloorTags = preload("../FloorTags.gd")

static func get_global() -> Node:
	return DLC.get_node("./Ap7Dungeon/DungeonData")

func _init():
	name = "DungeonData"

func clear_dungeon():
	if SaveState.other_data.has(SAVE_KEY_NAME_DUNGEON):
		SaveState.other_data.erase(SAVE_KEY_NAME_DUNGEON)

func get_current_dungeon() -> DungeonInfo:
	if SaveState.other_data.has(SAVE_KEY_NAME_DUNGEON):
		return DungeonInfo.new(SaveState.other_data[SAVE_KEY_NAME_DUNGEON])
	else:
		return null

func get_current_floor_or_default() -> FloorInfo:
	var di = get_current_dungeon()
	var fi = di.get_current_floor() if di != null else null
	if fi == null:
		push_warning("[DungeonData] no current dungeon/floor active. Assuming default floor for testing")
		fi = FloorInfo.new({})

	return fi

func generate_dungeon(s: int) -> DungeonInfo:
	var rng = Random.new(s)
	var di = DungeonInfo.new({})
	di.set_initial_seed(s)

	var combat_floor = 1
	for a in range(FloorTags.MAIN_AREAS_IN_ORDER.size()):
		var area = FloorTags.MAIN_AREAS_IN_ORDER[a]
		var intro = FloorTags.INTRO_AREA_LOOKUP[area]
		if a > 0:
			var fi = make_floor(intro, combat_floor, 0, rng)
			fi.add_tag(FloorTags.FT_NOCOMBAT)
			di.add_normal_floor(fi)

		for i in range(4):
			di.add_normal_floor(make_floor(area, combat_floor, 1+i, rng))
			combat_floor += 1
		
	add_shrines(di, rng)
	add_shops(di, rng)
	add_floor_modifiers(di, rng)
	add_secret_rooms(di, rng)
	di.add_normal_floor(make_floor(FloorTags.FT_SCENE_FINAL, combat_floor, 0, rng))
	
	#di.print_stats()
	#if OS.is_debug_build():
	di.print_spoilers()
	
	SaveState.other_data[SAVE_KEY_NAME_DUNGEON] = di.info
	return di

func add_shrines(di: DungeonInfo, rng: Random):
	# One shrine per set of non-rest areas floors
	for tag in FloorTags.MAIN_AREAS_IN_ORDER:
		var fi = rng.choice(di.get_floors_with_tag(tag))
		if fi != null:
			fi.add_tag(FloorTags.FT_SHRINE)

func add_shops(di: DungeonInfo, rng: Random):
	# One shop per set of non-rest areas floors. Won't appear before you have any stuff to spend.
	for tag in FloorTags.MAIN_AREAS_IN_ORDER:
		var fi = rng.choice(di.get_floors_with_tag(tag))
		if fi != null && fi.floor_number() > 2:
			fi.add_tag(FloorTags.FT_SHOP)

func add_floor_modifiers(di: DungeonInfo, rng: Random):
	# A floor has a chance of rolling a general modifier which might effect monsters/shape/size/loot
	for fi in di.get_floors():
		var roll = rng.rand_float()
		if roll < 0.14:
			fi.add_tag(rng.choice(FloorTags.ALL_ELEMENT_TAGS))
		elif roll < 0.17:
			fi.add_tag(FloorTags.FT_TREASURE)
		elif roll < 0.20:
			fi.add_tag(FloorTags.FT_SWARMING)
		elif roll < 0.22:
			fi.add_tag(FloorTags.FT_SPRAWLING)

func add_secret_rooms(di: DungeonInfo, rng: Random):
	# Some floors might be too hard on the first zone
	var early = [ "inn", "kuneko" ]
	var all = [ "inn", "ranger", "kuneko", "landkeeper" ]
	var used = []

	for area_tag in FloorTags.MAIN_AREAS_IN_ORDER:
		var floors = di.get_floors_with_tag(area_tag)
		var option = pick_secret_option(early, used, rng) if used.size() == 0 else pick_secret_option(all, used, rng)
		if option != "":
			used.push_back(option)
			match option:
				"inn": add_secret_inn(di, floors, rng)
				"kuneko": add_secret_kuneko(di, floors, rng)
				"landkeeper": add_secret_landkeeper(di, floors, rng)
				"ranger": add_secret_ranger(di, floors, rng)

func pick_secret_option(all: Array, used: Array, rng: Random) -> String:
	rng.shuffle(all)
	for item in all:
		if !(item in used):
			return item
	return ""

func add_secret_inn(di: DungeonInfo, floors: Array, rng: Random):
	var door_index = 1+rng.rand_int(floors.size()-1)
	var key_index = rng.rand_int(door_index+1)

	var kfi = floors[key_index]
	kfi.add_tag(FloorTags.FT_INN_KEY)
	
	var dfi = floors[door_index]
	dfi.add_tag(FloorTags.FT_INN_DOOR)
	dfi.set_secret_floor_key(FloorTags.FT_SCENE_INN)

	var sfi = make_floor(FloorTags.FT_SCENE_INN, dfi.floor_number(), 0, rng)
	di.add_secret_floor(FloorTags.FT_SCENE_INN, sfi)

func add_secret_kuneko(di: DungeonInfo, floors: Array, rng: Random):
	var before_shrine = []
	var after_shrine = []
	var on_shrine = null
	var current = before_shrine
	for fi in floors:
		if fi.has_tag(FloorTags.FT_SHRINE):
			current = after_shrine
			on_shrine = fi
		else:
			current.push_back(fi)
	
	if on_shrine != null:
		var f2 = null
		if before_shrine.size() > 0:
			var f1 = rng.choice(before_shrine)
			f1.add_tag(FloorTags.FT_KUNEKO)
			f2 = rng.choice(after_shrine) if after_shrine.size() > 0 else on_shrine
		else:
			f2 = on_shrine
			
		f2.add_tag(FloorTags.FT_KUNEKO)
		f2.set_secret_floor_key(FloorTags.FT_SCENE_KUNEKO)
		var sfi = make_floor(FloorTags.FT_SCENE_KUNEKO, f2.floor_number(), 0, rng)
		di.add_secret_floor(FloorTags.FT_SCENE_KUNEKO, sfi)

func add_secret_landkeeper(di: DungeonInfo, floors: Array, rng: Random):
	var index = 1+rng.rand_int(floors.size()-1)
	var npc_floor = floors[index]
	npc_floor.add_tag(FloorTags.FT_LANDKEEPER_DOOR)
	npc_floor.set_secret_floor_key(FloorTags.FT_SCENE_LANDKEEPER)
	
	var sfi = make_floor(FloorTags.FT_SCENE_LANDKEEPER, npc_floor.floor_number(), 0, rng)
	di.add_secret_floor(FloorTags.FT_SCENE_LANDKEEPER, sfi)

func add_secret_ranger(di: DungeonInfo, floors: Array, rng: Random):
	var door_index = 1+rng.rand_int(floors.size()-1)
	var key_index = rng.rand_int(door_index+1)
	var type = rng.choice(FloorTags.ALL_RANGER_ELEMENT_TAGS)

	var kfi = floors[key_index]
	kfi.add_tag(FloorTags.FT_RANGER_KEY)
	kfi.add_tag(type)
	
	var dfi = floors[door_index]
	dfi.add_tag(FloorTags.FT_RANGER_DOOR)
	dfi.add_tag(type)
	dfi.set_secret_floor_key(type)

	var sfi = make_floor(type, dfi.floor_number(), 0, rng)
	di.add_secret_floor(type, sfi)

func make_floor(tag: String, flr_num: int, sub_num: int, rng: Random, extra_tags = null):
	var fi = FloorInfo.new({})
	fi.set_number(flr_num)
	fi.set_subfloor_number(sub_num)
	fi.set_floor_scene(FloorTags.SCENE_LOOKUP[tag])
	fi.set_floor_seed(rng.get_child_seed(flr_num))
	fi.set_tags([tag])
	if extra_tags != null:
		for t in extra_tags:
			fi.add_tag(t)
	
	return fi
