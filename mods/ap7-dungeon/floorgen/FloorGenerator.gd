extends Node

const GeneratedFloor = preload("GeneratedFloor.gd")
const FloorInfo = preload("../FloorInfo.gd")
const FloorTags = preload("../FloorTags.gd")

# Size of a world cell if it just floor and no walls
export var world_cell_size: Vector2 

# Size of a world cell if it is surrounded by walls
export var world_interior_cell_size: Vector2 

func generate_floor(info: FloorInfo) -> GeneratedFloor:
	var tags = info.tags()
	var result = GeneratedFloor.new()
	result.number = info.floor_number()
	result.initial_seed = info.floor_seed()
	result.active_tags.append_array(tags)
	result.world_cell_size = world_cell_size
	result.world_interior_cell_size = world_interior_cell_size

	var rng = Random.new(result.initial_seed)
	result.layout = get_node("Plotting").generate_plots(rng, result.active_tags)
	result.zones = get_node("Zoning").generate_zones(result.layout, rng)
	result.entrance_key = abs(rng.rand_int())

	result.treasure_room = select_treasure_room(result.layout, rng) if FloorTags.FT_TREASURE in result.active_tags else -1
	if result.treasure_room == -1 && FloorTags.FT_TREASURE in result.active_tags: 
		result.active_tags.erase(FloorTags.FT_TREASURE)

	if has_node("Parcelling"):
		result.parcels = get_node("Parcelling").generate_parcels(result.layout, result.zones, result.active_tags, rng)

	if has_node("Encounters"):
		result.encounters = get_node("Encounters").generate_encounters(result.number, info.subfloor_number(), result.active_tags, result.treasure_room, result.layout, rng)
	
	if has_node("Treasure"):
		result.treasure = get_node("Treasure").generate_treasure(result.number, result.active_tags, result.treasure_room, result.layout, rng)

	if has_node("Mapping"):
		result.map = get_node("Mapping").generate_map(info.subfloor_number(), result.active_tags, result.layout, result.world_cell_size)
	
	result.region_settings = create_region_settings(result.zones, result.map)
	return result

func select_treasure_room(layout: GeneratedFloor.PlotLayout, rng: Random) -> int:
	var available = []
	for plot in layout.plots:
		if plot.definition.count_cells() > 3:
			available.push_back(plot)

	return rng.choice(available).id if available.size() > 0 else -1

func create_region_settings(zones: GeneratedFloor.ZoneOverlay, map: GeneratedFloor.DungeonMapMetadata) -> RegionSettings:
	var rs = RegionSettings.new()
	rs.region_name = map.title if map != null else ""

	# We don't want a fade-out of the current music, if it is music that could play in this zone.
	var zr = zones.get_resources_by_music(MusicSystem.current_track)
	if zr != null:
		rs.music_day = zr.music_vox
		rs.music_night = zr.music_vox
		rs.music_no_vox = zr.music_novox

	return rs
