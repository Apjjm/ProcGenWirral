extends Node

const FloorTags = preload("../../FloorTags.gd")
const PlotLayout = preload("PlotLayout.gd")
const PlotDefinition = preload("PlotDefinition.gd")
const LayoutGrid = preload("LayoutGrid.gd")

export(int) var width = 14
export(int) var height = 14
export(int, 1, 100) var border = 2
export(int) var total_rooms = 10
export(int) var edge_rooms = 2
export(float) var p_bad_block = 0.2
export(Array, Resource) var seed_plots = []
export(Array, Resource) var standard_plots = []
export(Array, Resource) var edge_plots = []
export(Array, Resource) var exit_plots = []

func generate_plots(rng: Random, floor_tags: Array = []) -> PlotLayout:
	var ratio_width = int(max(self.width, self.height*2))
	var raio_height = int(max(ceil(self.width*0.5), self.height))

	var layout = PlotLayout.new()
	var grid = LayoutGrid.new(ratio_width, raio_height, LayoutGrid.WallFlags.WF_ALL)
	
	# Phase 1 - make the grid a bit more interesting with a light sprinkling of cells to completely avoid
	_place_avoid_cells(grid, self.border+(ratio_width-self.width)/2, self.border+(raio_height-self.height)/2, rng)
	
	# Phase 2 - fill out the grid with some plots by building out from the center
	# We will start with one of of our high prioity seed plots (if it fits & we have one)
	# Then after that we will place standard and a few leafs at the end.
	# There will be a natural bias towards joining stuff up because the next_cells can have duplicates.
	var next_cells = []
	var num_rooms = int(self.total_rooms * 1.5) if FloorTags.FT_SPRAWLING in floor_tags else self.total_rooms
	var origin = LayoutGrid.cell_from_coord(grid.width / 2, grid.height / 2)
	if _try_place_seed_plot(grid, origin, layout, next_cells, rng):
		num_rooms -= 1
	else:
		next_cells = [ origin ]

	var available_plots = self.standard_plots.duplicate()
	while num_rooms > self.edge_rooms && next_cells.size() > 0 && available_plots.size() > 0:
		if _try_place_standard_plot(grid, next_cells, available_plots, layout, rng):
			num_rooms -= 1
	
	num_rooms = self.edge_rooms if num_rooms > self.edge_rooms else num_rooms
	available_plots = self.edge_plots.duplicate()
	while num_rooms > 0 && next_cells.size() > 0 && available_plots.size() > 0:
		if _try_place_standard_plot(grid, next_cells, available_plots, layout, rng):
			num_rooms -= 1

	# Phase 3 - keep track of where the plots join together.
	# This is basically 2 division - actual doors and virtual doors
	# Actual doors are what it says on tin - doors that really do link the spaces together.
	# Virtual doors are places that could have been doors, but we already have a door so we chose not to place one there
	# Virtual doors are useful, as we might want to put stuff like windows there instead, as we know two areas are adjacent
	_add_all_doors(layout, grid)
	_dedupe_doors(layout, grid, rng)

	# Add some special plots. These can bypass the "avoid" areas so we know we always have room for them.
	# Additionally, they will we will enforce one entry door, unlike all the other "normal" plots
	_clear_avoid_cells(grid)
	if !_try_place_special_plot(layout, grid, rng, PlotLayout.PlotType.PT_EXIT):
		push_error("Exit plot was not placed / connected to a cell. The floor is probably not completable. Fix: use console dfnext")

	if FloorTags.tags_intersect(FloorTags.ALL_SECRET_ROOM_TAGS, floor_tags):
		if !_try_place_special_plot(layout, grid, rng, PlotLayout.PlotType.PT_SECRET):
			push_error("Special plot was not placed / connected to a cell.")

	# DEBUG: lets check that the grid seems reasonable (i.e. we're fully connected)
	assert(grid.test_full_connectivity(), "Grid is not fully connected. It is likely that some rooms are unreachable. Fix: use console dfnext")

	layout.grid = grid
	print("[PlottingPass] Plots generated: ", layout.plots.size(), " Doors: ", layout.doors.size(), " Virtuals: ", layout.virtual_doors.size())
	return layout

func _place_avoid_cells(grid: LayoutGrid, border_x: int, border_y: int, rng: Random) -> void:
	for x in range(0, border_x):
		for y in range(0, grid.height):
			grid.set_plot(LayoutGrid.cell_from_coord(x,y), LayoutGrid.PlotValues.PV_BAD_CELL)
			grid.set_plot(LayoutGrid.cell_from_coord(grid.width-x,y), LayoutGrid.PlotValues.PV_BAD_CELL)

	for x in range(0, grid.width):
		for y in range(0, border_y):
			grid.set_plot(LayoutGrid.cell_from_coord(x,y), LayoutGrid.PlotValues.PV_BAD_CELL)
			grid.set_plot(LayoutGrid.cell_from_coord(x,grid.height-y), LayoutGrid.PlotValues.PV_BAD_CELL)
	
	for x in range(border_x, grid.width-border_x):
		for y in range(border_y, grid.height-border_y):
			if rng.rand_float() > self.p_bad_block:
				continue
			if x-1>grid.width/2 || x+1<grid.width/2 || y-1>grid.height/2 || y+1<grid.height/2:
				grid.set_plot(LayoutGrid.cell_from_coord(x,y), LayoutGrid.PlotValues.PV_BAD_CELL)

func _clear_avoid_cells(grid: LayoutGrid):
	for x in range(0, grid.width):
		for y in range(0, grid.height):
			var cell = LayoutGrid.cell_from_coord(x, y)
			if grid.get_plot(cell) == LayoutGrid.PlotValues.PV_BAD_CELL:
				grid.set_plot(cell, LayoutGrid.PlotValues.PV_CLEAR)

func _try_place_standard_plot(grid: LayoutGrid, cells: Array, plots: Array, layout: PlotLayout, rng: Random) -> bool:
	rng.shuffle(cells)
	rng.shuffle(plots)
	while cells.size() > 0:
		var cell = cells.pop_back()
		for i in range(0, plots.size()):
			if _try_place_plot(grid, cell, plots[i], layout, cells, rng):
				plots.remove(i)
				return true
	return false

func _try_place_seed_plot(grid: LayoutGrid, cell: int, layout: PlotLayout, next_cells: Array, rng: Random) -> bool:
	var plots = self.seed_plots.duplicate()
	rng.shuffle(plots)
	
	for plot in plots:
		if _try_place_plot(grid, cell, plot, layout, next_cells, rng):
			return true

	return false

func _try_place_plot(grid: LayoutGrid, connector_cell: int, plot: PlotDefinition, layout: PlotLayout, next_cells: Array, rng: Random) -> bool:
	var connector_x = LayoutGrid.cell_get_x(connector_cell)
	var connector_y = LayoutGrid.cell_get_y(connector_cell)

	var i=0
	var possible_placements = []
	while i < plot.rules.size():
		if plot.is_cell(i):
			var start_x = connector_x - plot.rule_x(i)
			var start_y = connector_y - plot.rule_y(i)
			if start_x >= 0 && start_y >= 0 && (start_x + plot.width < grid.width) && (start_y + plot.height < grid.height):
				possible_placements.push_back(i)
		i+=1

	if possible_placements.size() > 0:
		rng.shuffle(possible_placements)
		for j in possible_placements:
			var start_x = connector_x - plot.rule_x(j)
			var start_y = connector_y - plot.rule_y(j)
			if _try_place_plot_at(grid, start_x, start_y, plot, layout, next_cells):
				return true

	return false

func _try_place_plot_at(grid: LayoutGrid, x: int, y: int, plot: PlotDefinition, layout: PlotLayout, next_cells: Array) -> bool:	
	var i=0
	while i < plot.rules.size():
		var rule_cell = LayoutGrid.cell_from_coord(x + plot.rule_x(i), y + plot.rule_y(i))
		if grid.has_plot(rule_cell):
			return false
		i+=1
	i=0
	
	var placement = layout.add_plot(plot, x, y)
	while i < plot.rules.size():
		var rule_cell = LayoutGrid.cell_from_coord(x + plot.rule_x(i), y + plot.rule_y(i))
		grid.set_plot(rule_cell, placement.id)
		if plot.is_cell(i):
			grid.remove_walls(rule_cell)
		i+=1
	i=0

	while i < plot.rules.size():
		if plot.is_cell(i):
			var c = LayoutGrid.cell_from_coord(x + plot.rule_x(i), y + plot.rule_y(i))
			var n = LayoutGrid.cell_north_of(c)
			var e = LayoutGrid.cell_east_of(c)
			var s = LayoutGrid.cell_south_of(c)
			var w = LayoutGrid.cell_west_of(c)

			if !grid.has_plot(n): next_cells.push_back(n)		
			if !grid.has_plot(e): next_cells.push_back(e)	
			if !grid.has_plot(s): next_cells.push_back(s)
			if !grid.has_plot(w): next_cells.push_back(w)
		i+=1
	
	return true

#Phase 3 - We want to keep track of doors between plots, so lets just walk all the used cells and inspect the neighbours
#We do this at the plot level because we can be a bit clever with the plot id's to prevent doubling up doors in both directions
func _add_all_doors(layout: PlotLayout, grid: LayoutGrid) -> void:
	for plot in layout.plots:
		var i = 0
		while i < plot.definition.rules.size():
			var cellx = plot.x + plot.definition.rule_x(i)
			var celly = plot.y + plot.definition.rule_y(i)
			var cell = LayoutGrid.cell_from_coord(cellx, celly)
			var plot_n = grid.get_plot(LayoutGrid.cell_north_of(cell))
			var plot_e = grid.get_plot(LayoutGrid.cell_east_of(cell))
			var plot_s = grid.get_plot(LayoutGrid.cell_south_of(cell))
			var plot_w = grid.get_plot(LayoutGrid.cell_west_of(cell))
			
			# Only add plots with a bigger id - that way we won't add doors twice
			if !grid.has_wall(cell, LayoutGrid.WallFlags.WF_N) && plot_n > plot.id && plot_n < LayoutGrid.PlotValues.PV_CLEAR:
				layout.add_door(plot.id, plot_n, cellx, celly, PlotLayout.DoorwayDirection.DIR_N)	
			if !grid.has_wall(cell, LayoutGrid.WallFlags.WF_E) && plot_e > plot.id && plot_e < LayoutGrid.PlotValues.PV_CLEAR:
				layout.add_door(plot.id, plot_e, cellx, celly, PlotLayout.DoorwayDirection.DIR_E)
			if !grid.has_wall(cell, LayoutGrid.WallFlags.WF_S) && plot_s > plot.id && plot_s < LayoutGrid.PlotValues.PV_CLEAR:
				layout.add_door(plot.id, plot_s, cellx, celly, PlotLayout.DoorwayDirection.DIR_S)
			if !grid.has_wall(cell, LayoutGrid.WallFlags.WF_W) && plot_w > plot.id && plot_w < LayoutGrid.PlotValues.PV_CLEAR:
				layout.add_door(plot.id, plot_w, cellx, celly, PlotLayout.DoorwayDirection.DIR_W)
			i+=1

# Two regions might touch on multiple edges.
# So lets, erode away all extra doors until only the middle door is left
func _dedupe_doors(layout: PlotLayout, grid: LayoutGrid, rng: Random) -> void:
	layout.sort_doors()
	
	var i = 0 
	var j = 1
	while j < layout.doors.size():
		if layout.doors[i].id1 != layout.doors[j].id1 || layout.doors[i].id2 != layout.doors[j].id2:
			while j - i > 2: 
				_replace_door_with_wall(layout, grid, j-1)
				_replace_door_with_wall(layout, grid, i)
				j -= 2
			if j - i == 2:
				_replace_door_with_wall(layout, grid, j-(1+rng.rand_int(2))) # So we don't always pick left/top
				j -= 1
			i = j
		j += 1

func _replace_door_with_wall(layout: PlotLayout, grid: LayoutGrid, index: int) -> void:
	var door = layout.doors[index]
	var cell = LayoutGrid.cell_from_coord(door.x1, door.y1)
	match door.dir1:
		PlotLayout.DoorwayDirection.DIR_N: grid.add_walls_n(cell)
		PlotLayout.DoorwayDirection.DIR_E: grid.add_walls_e(cell)
		PlotLayout.DoorwayDirection.DIR_S: grid.add_walls_s(cell)
		PlotLayout.DoorwayDirection.DIR_W: grid.add_walls_w(cell)
	layout.make_door_virtual(index)

func _try_place_special_plot(layout: PlotLayout, grid: LayoutGrid, rng: Random, type: int) -> bool:
	var available = []
	for plot in layout.plots:
		for i in range(0, plot.definition.rules.size()):
			if plot.is_normal() && plot.definition.is_cell(i):
				var c = LayoutGrid.cell_from_coord(plot.x + plot.definition.rule_x(i), plot.y + plot.definition.rule_y(i))
				var n = LayoutGrid.cell_north_of(c)
				var e = LayoutGrid.cell_east_of(c)
				var s = LayoutGrid.cell_south_of(c)
				var w = LayoutGrid.cell_west_of(c)
				if !grid.has_plot(n): available.push_back(n)
				if !grid.has_plot(e): available.push_back(e)
				if !grid.has_plot(s): available.push_back(s)
				if !grid.has_plot(w): available.push_back(w)

	var doors = []
	if _try_place_standard_plot(grid, available, self.exit_plots.duplicate(), layout, rng):
		var plot = layout.last_plot()
		plot.plot_type = type

		for i in range(0, plot.definition.rules.size()):
			var cellx = plot.x + plot.definition.rule_x(i)
			var celly = plot.y + plot.definition.rule_y(i)
			var cell = LayoutGrid.cell_from_coord(cellx, celly)
			var plot_n = grid.get_plot(LayoutGrid.cell_north_of(cell))
			var plot_e = grid.get_plot(LayoutGrid.cell_east_of(cell))
			var plot_s = grid.get_plot(LayoutGrid.cell_south_of(cell))
			var plot_w = grid.get_plot(LayoutGrid.cell_west_of(cell))

			# Have to handle some special logic when two secret areas are adjancent so their only door isn't into eachother...
			if !grid.has_wall(cell, LayoutGrid.WallFlags.WF_N) && plot.id > plot_n:
				if !layout.plots[plot_n].is_normal():
					grid.add_walls_n(cell)
				else:
					doors.push_back(layout.add_door(plot.id, plot_n, cellx, celly, PlotLayout.DoorwayDirection.DIR_N))

			if !grid.has_wall(cell, LayoutGrid.WallFlags.WF_E) && plot.id > plot_e:
				if !layout.plots[plot_e].is_normal():
					grid.add_walls_e(cell)
				else:
					doors.push_back(layout.add_door(plot.id, plot_e, cellx, celly, PlotLayout.DoorwayDirection.DIR_E))

			if !grid.has_wall(cell, LayoutGrid.WallFlags.WF_S) && plot.id > plot_s:
				if !layout.plots[plot_s].is_normal():
					grid.add_walls_s(cell)
				else:
					doors.push_back(layout.add_door(plot.id, plot_s, cellx, celly, PlotLayout.DoorwayDirection.DIR_S))

			if !grid.has_wall(cell, LayoutGrid.WallFlags.WF_W) && plot.id > plot_w:
				if !layout.plots[plot_w].is_normal():
					grid.add_walls_w(cell)
				else:
					doors.push_back(layout.add_door(plot.id, plot_w, cellx, celly, PlotLayout.DoorwayDirection.DIR_W))

	rng.shuffle(doors)
	for j in range(1, doors.size()):
		_replace_door_with_wall(layout, grid, layout.doors.find(doors[j]))

	return doors.size() > 0
