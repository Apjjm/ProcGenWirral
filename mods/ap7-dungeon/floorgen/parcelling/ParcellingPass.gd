extends Node

const FloorTags = preload("../../FloorTags.gd")
const ParcelSet = preload("../../parcels/ParcelSet.gd")
const SpecialCoverParcelSet = preload("../../parcels/SpecialCoverParcelSet.gd")
const LayoutGrid = preload("../plotting/LayoutGrid.gd")
const PlotDefinition = preload("../plotting/PlotDefinition.gd")
const PlotLayout = preload("../plotting/PlotLayout.gd")
const ZoneOverlay = preload("../zoning/ZoneOverlay.gd")
const ParcelOverlay = preload("ParcelOverlay.gd")

export(Array, Resource) var floor_parcels = []
export(Array, Resource) var wall_parcels = []
export(Array, Resource) var interior_corner_parcels = []
export(Array, Resource) var exterior_corner_parcels = []
export(Array, Resource) var door_parcels = []
export(Array, Resource) var virtual_parcels = []
export(Array, Resource) var cover_parcels = []
export(Resource) var special_parcels = null

# Convention: The "default" cover is the first permissable cover in the cover parcels sets.
# This means that when filling out the cover_parcels array put the most generic stuff first.
# We could have a whole bunch of extra properties for this but it is a bit tedious to re-specify everything.
export(float, 0, 1) var default_cover_chance = 0.5

# By default we might want the same floor tile to cover a whole room (e.g. the mall)
# But in other settings, we want to randomise it per cell instead where the visible room deliniation is a bit weaker (e.g. caves)
export(bool) var match_floor_to_room = true

# Parcelling is about using the zoning information on a plot/doorway etc and picking out the scenes to associate with the doors & plots.
# Within each parcel, some things might want to do some extra randomisation of bits of deco, so we hold and interior rng instance for that too
func generate_parcels(layout: PlotLayout, zones: ZoneOverlay, tags: Array, rng: Random) -> ParcelOverlay:
	assert(self.floor_parcels.size(), "Floors are required")
	assert(self.wall_parcels.size(), "Walls are required")
	var result = ParcelOverlay.new(layout)

	# First pass - setup information that doesn't depend on looking over boundries
	for plot in layout.plots:
		var overlay = result.add_room(plot.id, rng.get_child_seed(plot.id))
		var zone = zones.get_zone(plot.id)
		var floors = matching_parcels(zone, self.floor_parcels)
		var room_floor = floors.get_random_parcel(rng)
		overlay.offset = floors.offset

		for i in range(0, plot.definition.rules.size()):
			if plot.definition.is_cell(i):
				var c = ParcelOverlay.CellOverlay.new()
				c.x = plot.definition.rule_x(i) + plot.x
				c.y = plot.definition.rule_y(i) + plot.y
				c.flr = room_floor if self.match_floor_to_room else floors.get_random_parcel(rng)
				choose_walls(c, layout.grid, zone, rng)
				overlay.cells.push_back(c)

	# Apply doors - each side of the cell will give us half of the door
	if self.door_parcels.size() > 0:
		for door in layout.doors:
			var zone1 = zones.get_zone(door.id1)
			var zone2 = zones.get_zone(door.id2)
			var cell1 = result.get_room(door.id1).find_cell(door.x1, door.y1)
			var cell2 = result.get_room(door.id2).find_cell(door.x2, door.y2)
			choose_door(cell1, door.dir1, zone1, zone2, self.door_parcels, rng)
			choose_door(cell2, door.dir2, zone2, zone1, self.door_parcels, rng)

	# Apply virtual doors. again these are like real doors but don't actually "join" up the rooms in a meaningful way.
	if self.virtual_parcels.size() > 0:
		for door in layout.virtual_doors:
			var zone1 = zones.get_zone(door.id1)
			var zone2 = zones.get_zone(door.id2)
			var cell1 = result.get_room(door.id1).find_cell(door.x1, door.y1)
			var cell2 = result.get_room(door.id2).find_cell(door.x2, door.y2)
			choose_door(cell1, door.dir1, zone1, zone2, self.virtual_parcels, rng)
			choose_door(cell2, door.dir2, zone2, zone1, self.virtual_parcels, rng)

	# Apply covers - these might have rules about not going infront of doors and such so want to run last
	for room in result.rooms:
		var zone = zones.get_zone(room.plot_id)
		for cell in room.cells:
			choose_cover(cell, zone, rng)

	# We might have some single use covers (e.g. shrine, special npcs / treasures), these should get inserted last
	if self.special_parcels != null:
		var room_floor_parcel = rng.choice(self.special_parcels.get_available_room_floors(tags))
		var room_cover_parcel = rng.choice(self.special_parcels.get_available_room_covers(tags))
		
		if room_floor_parcel != null || room_cover_parcel != null:
			var room = rng.choice(matching_rooms_for_secret_room(result.rooms, layout))
			if room != null:
				print("[ParcellingPass] applying special cover to room", room.plot_id)
				for cell in room.cells:
					cell.flr = room_floor_parcel if room_floor_parcel != null else cell.flr
					cell.cover = room_cover_parcel # Floor isn't optional, cover is.
					cell.has_special_cover = true

		var overlay_cells = matching_cells_for_special_overlay(self.special_parcels, result.rooms, layout, zones, rng)
		for cover_set in self.special_parcels.get_available_overlay_covers(tags):
			if cover_set.size() == 0 || overlay_cells.size() == 0:
				continue
			
			var cell = overlay_cells.pop_back()
			print("[ParcellingPass] applying special cover to cell ", cell.x, ",", cell.y)
			cell.cover = rng.choice(cover_set)
			cell.has_special_cover = true

	print("[ParcellingPass] Allocated ", result.rooms.size(), " parcels")
	return result

func choose_walls(cell: ParcelOverlay.CellOverlay, grid: LayoutGrid, zone: String, rng: Random):
	var c = LayoutGrid.cell_from_coord(cell.x, cell.y)
	var cn = LayoutGrid.cell_north_of(c)
	var ce = LayoutGrid.cell_east_of(c)
	var cs = LayoutGrid.cell_south_of(c)
	var cw = LayoutGrid.cell_west_of(c)
	
	var walls = matching_parcels(zone, self.wall_parcels)
	if grid.has_wall(c, LayoutGrid.WallFlags.WF_N):
		cell.wall_n = walls.get_random_parcel(rng) 
		cell.wall_type_w |= ParcelOverlay.CellWallFlags.CONN_R
		cell.wall_type_e |= ParcelOverlay.CellWallFlags.CONN_L
	
	if grid.has_wall(c, LayoutGrid.WallFlags.WF_E):
		cell.wall_e = walls.get_random_parcel(rng) 
		cell.wall_type_n |= ParcelOverlay.CellWallFlags.CONN_R
		cell.wall_type_s |= ParcelOverlay.CellWallFlags.CONN_L

	if grid.has_wall(c, LayoutGrid.WallFlags.WF_S):
		cell.wall_s = walls.get_random_parcel(rng) 
		cell.wall_type_e |= ParcelOverlay.CellWallFlags.CONN_R
		cell.wall_type_w |= ParcelOverlay.CellWallFlags.CONN_L

	if grid.has_wall(c, LayoutGrid.WallFlags.WF_W):
		cell.wall_w = walls.get_random_parcel(rng) 
		cell.wall_type_s |= ParcelOverlay.CellWallFlags.CONN_R
		cell.wall_type_n |= ParcelOverlay.CellWallFlags.CONN_L

	if self.interior_corner_parcels.size() > 0:
		var icorners = matching_parcels(zone, self.interior_corner_parcels)
		if cell.wall_n != null && cell.wall_e != null:
			cell.corner_ne = icorners.get_random_parcel(rng)
		if cell.wall_n != null && cell.wall_w != null:
			cell.corner_nw = icorners.get_random_parcel(rng)
		if cell.wall_s != null && cell.wall_e != null:
			cell.corner_se = icorners.get_random_parcel(rng)
		if cell.wall_s != null && cell.wall_w != null:
			cell.corner_sw = icorners.get_random_parcel(rng)
	
	if self.exterior_corner_parcels.size() > 0:
		var ecorners = matching_parcels(zone, self.exterior_corner_parcels)
		if cell.wall_n == null && cell.wall_e == null && (grid.has_wall(cn, LayoutGrid.WallFlags.WF_E) || grid.has_wall(ce, LayoutGrid.WallFlags.WF_N)):
			cell.corner_ne = ecorners.get_random_parcel(rng)
		if cell.wall_n == null && cell.wall_w == null && (grid.has_wall(cn, LayoutGrid.WallFlags.WF_W) || grid.has_wall(cw, LayoutGrid.WallFlags.WF_N)):
			cell.corner_nw = ecorners.get_random_parcel(rng)
		if cell.wall_s == null && cell.wall_e == null && (grid.has_wall(cs, LayoutGrid.WallFlags.WF_E) || grid.has_wall(ce, LayoutGrid.WallFlags.WF_S)):
			cell.corner_se = ecorners.get_random_parcel(rng)
		if cell.wall_s == null && cell.wall_w == null && (grid.has_wall(cs, LayoutGrid.WallFlags.WF_W) || grid.has_wall(cw, LayoutGrid.WallFlags.WF_S)):
			cell.corner_sw = ecorners.get_random_parcel(rng)

func choose_cover(cell: ParcelOverlay.CellOverlay, zone: String, rng: Random):
	var cover_flags = ParcelSet.to_flags(cell.wall_n != null, cell.wall_e != null, cell.wall_s != null, cell.wall_w != null)
	var parcels = matching_cover_parcels(zone, cover_flags)
	if parcels.size() > 0:
		if rng.rand_float() < self.default_cover_chance:
			cell.cover = parcels[0]
		else:
			cell.cover = rng.choice(parcels)

func choose_door(cell: ParcelOverlay.CellOverlay, dir: int, zone1: String, zone2: String, parcels: Array, rng: Random):	
	if dir == PlotLayout.DoorwayDirection.DIR_N:
		var doors = matching_door_parcels(zone1, zone2, ParcelSet.DirectionFlag.DIR_N, parcels)
		if doors == null: return false
		
		cell.wall_n = doors.get_random_parcel(rng)
		cell.wall_type_w |= ParcelOverlay.CellWallFlags.CONN_R
		cell.wall_type_e |= ParcelOverlay.CellWallFlags.CONN_L
		cell.corner_ne = null # We do need to clear these because of exterior corners
		cell.corner_nw = null
	elif dir == PlotLayout.DoorwayDirection.DIR_E:
		var doors = matching_door_parcels(zone1, zone2, ParcelSet.DirectionFlag.DIR_E, parcels)
		if doors == null:
			return false
		
		cell.wall_e = doors.get_random_parcel(rng)
		cell.wall_type_n |= ParcelOverlay.CellWallFlags.CONN_R
		cell.wall_type_s |= ParcelOverlay.CellWallFlags.CONN_L
		cell.corner_ne = null 
		cell.corner_se = null
	elif dir == PlotLayout.DoorwayDirection.DIR_S:
		var doors = matching_door_parcels(zone1, zone2, ParcelSet.DirectionFlag.DIR_S, parcels)
		if doors == null:
			return false
		
		cell.wall_s = doors.get_random_parcel(rng)
		cell.wall_type_e |= ParcelOverlay.CellWallFlags.CONN_R
		cell.wall_type_w |= ParcelOverlay.CellWallFlags.CONN_L
		cell.corner_se = null 
		cell.corner_sw = null
	elif dir == PlotLayout.DoorwayDirection.DIR_W:
		var doors = matching_door_parcels(zone1, zone2, ParcelSet.DirectionFlag.DIR_W, parcels)
		if doors == null:
			return false
		
		cell.wall_w = doors.get_random_parcel(rng)
		cell.wall_type_s |= ParcelOverlay.CellWallFlags.CONN_R
		cell.wall_type_n |= ParcelOverlay.CellWallFlags.CONN_L
		cell.corner_nw = null 
		cell.corner_sw = null

	if self.interior_corner_parcels.size() > 0:
		var icorners = matching_parcels(zone1, self.interior_corner_parcels)
		if cell.wall_n != null && cell.wall_e != null:
			cell.corner_ne = icorners.get_random_parcel(rng)
		if cell.wall_n != null && cell.wall_w != null:
			cell.corner_nw = icorners.get_random_parcel(rng)
		if cell.wall_s != null && cell.wall_e != null:
			cell.corner_se = icorners.get_random_parcel(rng)
		if cell.wall_s != null && cell.wall_w != null:
			cell.corner_sw = icorners.get_random_parcel(rng)

	return true

func matching_parcels(zone: String, parcelsets: Array) -> ParcelSet:
	for p in parcelsets:
		if p.has_zone(zone):
			return p

	assert(false, "Unable to find parcels for zone: " + zone)
	return parcelsets[0]

func matching_door_parcels(zone1: String, zone2: String, dir: int, parcelsets: Array) -> ParcelSet:
	for p in parcelsets:
		if p.has_zone(zone1) && p.has_target_zone(zone2) && p.has_target_direction(dir):
			return p
	
	return null

func matching_cover_parcels(zone: String, flags: int) -> Array:
	var result = []
	for p in self.cover_parcels:
		if p.has_zone(zone) && p.has_permissable_wall_flags(flags):
			result.append_array(p.parcels)

	return result

func matching_rooms_for_secret_room(rooms: Array, layout: PlotLayout) -> Array:
	var possible_rooms = []
	for r in rooms:
		if layout.plots[r.plot_id].is_secret():
			possible_rooms.push_back(r)

	return possible_rooms

func matching_cells_for_special_overlay(p: SpecialCoverParcelSet, rooms: Array, layout: PlotLayout, zones: ZoneOverlay, rng: Random) -> Array:
	var possible_cells = []
	var priority_cells = [] # Prefer placing special overlays in leaf areas rather than ontop of coridoors/doors

	for r in rooms:
		if layout.plots[r.plot_id].is_normal() && zones.get_zone(r.plot_id) in p.required_overlay_zones:
			for c in r.cells:
				if !c.has_special_cover:
					var cell_id = LayoutGrid.cell_from_coord(c.x, c.y)
					if layout.grid.count_walls(cell_id) > 2:
						priority_cells.push_back(c)
					else:
						possible_cells.push_back(c)

	rng.shuffle(possible_cells)
	rng.shuffle(priority_cells)
	possible_cells.append_array(priority_cells)

	#print("[ParcellingPass] special cover cells: ", priority_cells.size(), " /  ", possible_cells.size(), " total")
	return possible_cells
