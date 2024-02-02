extends Reference

const LayoutGrid = preload("LayoutGrid.gd")
const PlotDefinition = preload("PlotDefinition.gd")
enum DoorwayDirection { DIR_N = 0, DIR_E = 1, DIR_S = 2, DIR_W = 3 };
enum PlotType { PT_NONE = 0, PT_EXIT = 1, PT_SECRET = 2 };

var plots : Array = []
var doors : Array = []
var virtual_doors : Array = []
var grid:LayoutGrid

class Plot:
	extends Reference
	
	var id: int
	var x: int # Top left corner of the plot in grid space
	var y: int # Top left corner of the plot in grid space
	var plot_type: int
	var definition: Resource

	func _init(id, x, y, definition):
		self.id = id
		self.x = x
		self.y = y
		self.definition = definition
		self.plot_type = PlotType.PT_NONE

	func is_normal():
		return plot_type == PlotType.PT_NONE

	func is_exit():
		return plot_type == PlotType.PT_EXIT

	func is_secret():
		return plot_type == PlotType.PT_SECRET

class Doorway:
	extends Reference
	var id1: int
	var id2: int
	var x1: int # Positions are in grid space
	var y1: int
	var x2: int
	var y2: int
	var dir1: int
	var dir2: int
	var door_id: int
	
	func _init(id1, id2, x1, y1, x2, y2, dir1, dir2):
		self.id1 = id1 
		self.id2 = id2 
		self.x1 = x1 
		self.y1 = y1 
		self.x2 = x2 
		self.y2 = y2 
		self.dir1 = dir1 
		self.dir2 = dir2 

	func has_plot(plot_id: int) -> bool:
		return plot_id == id1 || plot_id == id2

	func plot_x(plot_id: int) -> int:
		return x1 if plot_id == id1 else x2

	func plot_y(plot_id: int) -> int:
		return y1 if plot_id == id1 else y2

	func plot_dir(plot_id: int) -> int:
		return dir1 if plot_id == id1 else dir2

	func other_plot(plot_id: int) -> int:
		return id2 if plot_id == id1 else id1

	func matches(other: Doorway) -> bool:
		return self.id1 == other.id1 && self.id2 == other.id2 && self.x1 == other.x1 && self.y1 == other.y1 && self.dir1 == other.dir1

	func _to_string():
		return "("+str(self.x1)+","+str(self.y1)+") <--"+str(self.dir1)+"--> ("+str(self.x2)+","+str(self.y2)+") ["+str(self.id1)+","+str(self.id2)+"]"

	static func sort_door(a, b):
		return ((a.id1 << 32) | (a.id2 << 16) | (a.y1 << 8) | a.x1) < ((b.id1 << 32) | (b.id2 << 16) | (b.y1 << 8) | b.x1)

# Adds a plot definition to the plots array, returning the plot
func add_plot(definition: PlotDefinition, x: int, y: int) -> Plot:
	var plot = Plot.new(self.plots.size(), x, y, definition)
	self.plots.push_back(plot)
	return plot

# Returns the most recently added plot
func last_plot() -> Plot:
	return self.plots.back()

# Adds a door to the doors array, returning it.
# Doors, by convention, always start in the lowest indexed plot, so from and to may swap if needed.
func add_door(from: int, to: int, x1: int, y1: int, direction: int) -> Doorway:
	var door
	if from < to:
		match direction:
			DoorwayDirection.DIR_N: door = Doorway.new(from, to, x1, y1, x1, y1-1, DoorwayDirection.DIR_N, DoorwayDirection.DIR_S)
			DoorwayDirection.DIR_E: door = Doorway.new(from, to, x1, y1, x1+1, y1, DoorwayDirection.DIR_E, DoorwayDirection.DIR_W)
			DoorwayDirection.DIR_S: door = Doorway.new(from, to, x1, y1, x1, y1+1, DoorwayDirection.DIR_S, DoorwayDirection.DIR_N)
			DoorwayDirection.DIR_W: door = Doorway.new(from, to, x1, y1, x1-1, y1, DoorwayDirection.DIR_W, DoorwayDirection.DIR_E)
			_: return null
	else:
		match direction:
			DoorwayDirection.DIR_N: door = Doorway.new(to, from, x1, y1-1, x1, y1, DoorwayDirection.DIR_S, DoorwayDirection.DIR_N)
			DoorwayDirection.DIR_E: door = Doorway.new(to, from, x1+1, y1, x1, y1, DoorwayDirection.DIR_W, DoorwayDirection.DIR_E)
			DoorwayDirection.DIR_S: door = Doorway.new(to, from, x1, y1+1, x1, y1, DoorwayDirection.DIR_N, DoorwayDirection.DIR_S)
			DoorwayDirection.DIR_W: door = Doorway.new(to, from, x1-1, y1, x1, y1, DoorwayDirection.DIR_E, DoorwayDirection.DIR_W)
			_: return null
	self.doors.push_back(door)
	return door

# Makes an existing door a "virtual door"
# Virtual doors are doorways which we could choose to add, but aren't part of the fundamental level layout
# These can be used with zoning so we might know that we neighbour a zone of a different type, and adjust our edges to look believable
func make_door_virtual(index: int) -> void:
	var door = self.doors[index]
	self.doors.remove(index)
	self.virtual_doors.push_back(door)

# Find all the doors on a given plot id
func find_doors(plot_id: int) -> Array:
	var result = []
	for door in self.doors:
		if door.has_plot(plot_id):
			result.push_back(door)

	return result

# Count all the doors on a given plot id
func count_doors(plot_id: int) -> int:
	var count = 0
	for door in self.doors:
		if door.has_plot(plot_id):
			count+=1

	return count

# Find a door by a position and a direction
func find_door_by_spot(pos_x: int, pos_y: int, dir: int) -> Doorway:
	for door in self.doors:
		if door.x1 == pos_x && door.y1 == pos_y && door.dir1 == dir:
			return door
		if door.x2 == pos_x && door.y2 == pos_y && door.dir2 == dir:
			return door
	
	return null

# Find all the virtual doors on a given plot id
func find_virtual_doors(plot_id: int) -> Array:
	var result = []
	for door in self.virtual_doors:
		if door.has_plot(plot_id):
			result.push_back(door)
	
	return result

# Find a virtual door by a position and a direction
func find_virtual_door_by_spot(pos_x: int, pos_y: int, dir: int) -> Doorway:
	for door in self.virtual_doors:
		if door.x1 == pos_x && door.y1 == pos_y && door.dir1 == dir:
			return door
		if door.x2 == pos_x && door.y2 == pos_y && door.dir2 == dir:
			return door
	
	return null

# Return an array of all plots in order of top->bottom when traversing the grid, then left->right
func find_plots_by_column() -> Array:
	var result = []
	for x in range(0, self.grid.width):
		var col = PoolIntArray()
		var current_plot = LayoutGrid.PlotValues.PV_CLEAR
		
		for y in range(0, self.grid.height):
			var plot = self.grid.get_plot(LayoutGrid.cell_from_coord(x, y))
			if plot != LayoutGrid.PlotValues.PV_CLEAR && plot != LayoutGrid.PlotValues.PV_BAD_CELL && plot != current_plot:
				col.push_back(plot)
				current_plot = plot

		result.push_back(col)

	return result

# Sorts doors array such that all doors between cell pairs are adjacent in the array. 
# Additionally, doors themselves will be then ordered by x and y.
func sort_doors() -> void:
	self.doors.sort_custom(Doorway, "sort_door")

# See sort_door
func sort_virtual_doors() -> void:
	self.virtual_doors.sort_custom(Doorway, "sort_door")

# Estimate the area of all the plots
func estimate_floor_area() -> int:
	var total = 0
	for p in self.plots:
		total += p.definition.count_cells()
	return total

func debug_draw(canvas: CanvasItem, scale: Vector2, plot_colors: Array, draw_doors: bool = true, draw_virtual_doors: bool = true):
	for plot in self.plots:
		var pos = Vector2(plot.x, plot.y) * scale
		var col = plot_colors[plot.id % plot_colors.size()]
		plot.definition.draw_shape(canvas, pos, scale, col, false)

		if plot.is_exit():
			canvas.draw_circle(pos + 0.5 * scale, scale.x * 0.1, Color.black)

	if draw_doors:
		for door in self.doors:
			var pos1 = Vector2(door.x1 + 0.5, door.y1 + 0.5) * scale
			var pos2 = Vector2(door.x2 + 0.5, door.y2 + 0.5) * scale
			var mid = (pos1 + pos2) * 0.5
			canvas.draw_line((pos1 + mid) * 0.5, (pos2 + mid) * 0.5, Color.mediumslateblue)
	
	if draw_virtual_doors:
		for door in self.virtual_doors:
			var pos1 = Vector2(door.x1 + 0.5, door.y1 + 0.5) * scale
			var pos2 = Vector2(door.x2 + 0.5, door.y2 + 0.5) * scale
			var mid = (pos1 + pos2) * 0.5
			canvas.draw_line((pos1 + mid) * 0.5, (pos2 + mid) * 0.5, Color.crimson)
