extends Reference

# Cell coords: x+ is EAST, y+ is SOUTH
# Code in here does a lot of bit twiddling. 
# Unfortunately, gdscript is glacially slow so speed has been preferred over nicer language features

var width:int
var height:int
var walls:PoolByteArray
var plots:PoolByteArray

enum WallFlags { WF_N = 0x01, WF_E = 0x02, WF_S = 0x04, WF_W = 0x08, WF_C = 0x10, WF_EMPTY = 0, WF_ENCLOSED = 0x0F, WF_ALL = 0x1F, WF_BAD_CELL= 0xFF }
enum PlotValues { PV_CLEAR = 0xFE, PV_BAD_CELL= 0xFF }

static func cell_from_coord_safe(x: int, y: int) -> int:
	return ((y & 0x00FF) << 8) + (x & 0x00FF)

static func cell_from_coord(x: int, y: int) -> int:
	return (y << 8) + x

static func cell_from_offset(cell: int, x: int, y: int) -> int:
	return cell + (y << 8) + x

static func cell_get_x(cell: int) -> int:
	return cell & 0x00FF

static func cell_get_y(cell: int) -> int:
	return (cell >> 8) & 0x00FF

static func cell_north_of(cell: int) -> int:
	return (cell & 0x00FF) | ((cell - 0x0100) & 0xFF00)

static func cell_east_of(cell: int) -> int:
	return ((cell + 1) & 0x00FF) | (cell & 0xFF00)

static func cell_south_of(cell: int) -> int:
	return (cell & 0x00FF) | ((cell + 0x0100) & 0xFF00)
	
static func cell_west_of(cell: int) -> int:
	return ((cell - 1) & 0x00FF) | (cell & 0xFF00)

static func opposite_wall(wall: int) -> int:
	match wall:
		WallFlags.WF_N: return WallFlags.WF_S
		WallFlags.WF_E: return WallFlags.WF_W
		WallFlags.WF_S: return WallFlags.WF_N
		WallFlags.WF_W: return WallFlags.WF_E
		WallFlags.WF_C: return WallFlags.WF_C
		_: return wall

func _init(w: int, h: int, fill: int = WallFlags.WF_EMPTY):
	self.width=w
	self.height=h
	self.walls = PoolByteArray()
	self.plots = PoolByteArray()
	self.walls.resize(0x10000)
	self.plots.resize(0x10000)
	clear_cells(fill)

func set_from(other: Reference):
	self.width = other.width
	self.height = other.height
	self.walls = other.walls
	self.plots = other.plots

func add_walls_to_border() -> void:
	for x in range(0, self.width):
		self.walls[cell_from_coord(x, 0)] |= WallFlags.WF_N
		self.walls[cell_from_coord(x, self.height-1)] |= WallFlags.WF_S
	
	for y in range(0, self.height):
		self.walls[cell_from_coord(0, y)] |= WallFlags.WF_W
		self.walls[cell_from_coord(self.width-1, y)] |= WallFlags.WF_E

func add_walls(cell: int) -> void:
	var north = cell_north_of(cell)
	var east = cell_east_of(cell)
	var south = cell_south_of(cell)
	var west = cell_west_of(cell)
	self.walls[cell] |= WallFlags.WF_ALL
	self.walls[north] |= WallFlags.WF_S
	self.walls[east] |= WallFlags.WF_W
	self.walls[south] |= WallFlags.WF_N
	self.walls[west] |= WallFlags.WF_E
	fill_if_enclosed(north)
	fill_if_enclosed(east)
	fill_if_enclosed(south)
	fill_if_enclosed(west)

func add_walls_n(cell: int) -> void:
	var north = cell_north_of(cell)
	self.walls[cell] |= WallFlags.WF_N
	fill_if_enclosed(cell)
	if self.walls[north] != WallFlags.WF_BAD_CELL:
		self.walls[north] |= WallFlags.WF_S
		fill_if_enclosed(north)

func add_walls_e(cell: int) -> void:
	var east = cell_east_of(cell)
	self.walls[cell] |= WallFlags.WF_E
	fill_if_enclosed(cell)
	if self.walls[east] != WallFlags.WF_BAD_CELL:
		self.walls[east] |= WallFlags.WF_W
		fill_if_enclosed(east)

func add_walls_s(cell: int) -> void:
	var south = cell_south_of(cell)
	self.walls[cell] |= WallFlags.WF_S
	fill_if_enclosed(cell)
	if self.walls[south] != WallFlags.WF_BAD_CELL:
		self.walls[south] |= WallFlags.WF_N
		fill_if_enclosed(south)

func add_walls_w(cell: int) -> void:
	var west = cell_west_of(cell)
	self.walls[cell] |= WallFlags.WF_W
	fill_if_enclosed(cell)
	if self.walls[west] != WallFlags.WF_BAD_CELL:
		self.walls[west] |= WallFlags.WF_E
		fill_if_enclosed(west)

func count_walls(cell: int) -> int:
	return (1 if has_wall(cell, WallFlags.WF_N) else 0)\
		+ (1 if has_wall(cell, WallFlags.WF_E) else 0)\
		+ (1 if has_wall(cell, WallFlags.WF_S) else 0)\
		+ (1 if has_wall(cell, WallFlags.WF_W) else 0)

func fill_if_enclosed(cell: int) -> void:
	if self.walls[cell] == WallFlags.WF_ENCLOSED:
		self.walls[cell] = WallFlags.WF_ALL

func remove_walls(cell: int) -> void:
	var north = cell_north_of(cell)
	var east = cell_east_of(cell)
	var south = cell_south_of(cell)
	var west = cell_west_of(cell)
	
	self.walls[cell] &= (WallFlags.WF_ALL ^ WallFlags.WF_C)
	if self.walls[east] < WallFlags.WF_ALL:
		self.walls[cell] &= (WallFlags.WF_ALL ^ WallFlags.WF_E)
		self.walls[east] &= (WallFlags.WF_ALL ^ (WallFlags.WF_W | WallFlags.WF_C))

	if self.walls[west] < WallFlags.WF_ALL:
		self.walls[cell] &= (WallFlags.WF_ALL ^ WallFlags.WF_W)
		self.walls[west] &= (WallFlags.WF_ALL ^ (WallFlags.WF_E | WallFlags.WF_C))

	if self.walls[north] < WallFlags.WF_ALL:
		self.walls[cell] &= (WallFlags.WF_ALL ^ WallFlags.WF_N)
		self.walls[north] &= (WallFlags.WF_ALL ^ (WallFlags.WF_S | WallFlags.WF_C))

	if self.walls[south] < WallFlags.WF_ALL:
		self.walls[cell] &= (WallFlags.WF_ALL ^ WallFlags.WF_S)
		self.walls[south] &= (WallFlags.WF_ALL ^ (WallFlags.WF_N | WallFlags.WF_C))

func has_wall(cell: int, flags: int) -> bool:
	return (self.walls[cell] & flags) == flags 

func has_plot(cell: int) -> bool:
	return self.plots[cell] != PlotValues.PV_CLEAR

func get_plot(cell: int) -> int:
	return self.plots[cell]

func set_plot(cell: int, plot: int):
	self.plots[cell] = plot
	
func clear_cells(fill: int = WallFlags.WF_EMPTY) -> void:
	self.walls.fill(WallFlags.WF_BAD_CELL)
	self.plots.fill(PlotValues.PV_BAD_CELL)
	var x = 0
	while x < self.width:
		var y = 0
		while y < self.height:
			var cell = cell_from_coord(x,y)
			self.walls[cell] = fill
			self.plots[cell] = PlotValues.PV_CLEAR
			y += 1
		x += 1

func get_navigable_cells() -> Array:
	var result = []
	var x = 0
	while x < self.width:
		var y = 0
		while y < self.height:
			var cell = cell_from_coord(x,y)
			if self.walls[cell] < WallFlags.WF_ALL:
				result.push_back(cell)
			y += 1
		x += 1
	return result

func test_full_connectivity() -> bool:
	var visited = PoolByteArray()
	visited.resize(0x10000)
	visited.fill(0)

	var to_visit = PoolIntArray()
	to_visit.resize((self.width * self.height) >> 1)
	to_visit.fill(0)
	var head = 0

	var x = 0
	while x < self.width:
		var y = 0
		while y < self.height:
			var cell = cell_from_coord(x,y)
			if head == 0 && self.walls[cell] < WallFlags.WF_ALL:
				to_visit[head] = cell
				head = 1
				break
			y += 1
		x += 1
	
	while head > 0:
		head -= 1
		var n = cell_north_of(to_visit[head])
		var e = cell_east_of(to_visit[head])
		var s = cell_south_of(to_visit[head])
		var w = cell_west_of(to_visit[head])
		
		if visited[n] == 0 && self.walls[n] < WallFlags.WF_ALL:
			visited[n] = 1
			to_visit[head] = n
			head += 1
		if visited[e] == 0 && self.walls[e] < WallFlags.WF_ALL:
			visited[e] = 1
			to_visit[head] = e
			head += 1
		if visited[s] == 0 && self.walls[s] < WallFlags.WF_ALL:
			visited[s] = 1
			to_visit[head] = s
			head += 1
		if visited[w] == 0 && self.walls[w] < WallFlags.WF_ALL:
			visited[w] = 1
			to_visit[head] = w
			head += 1

	x = 0
	while x < self.width:
		var y = 0
		while y < self.height:
			var cell = cell_from_coord(x,y)
			if visited[cell] == 0 && self.walls[cell] < WallFlags.WF_ALL:
				return false
			y += 1
		x += 1
	
	return true

func debug_draw(canvas: CanvasItem, scale: Vector2, margin: float, color1: Color, color2: Color) -> void:
	var x = 0
	while x < self.width:
		var y = 0
		while y < self.height:
			var wall = self.walls[cell_from_coord(x,y)]
			var x0y0 = Vector2(x + margin, y + margin) * scale
			var x1y0 = Vector2(x + 1.0 - margin, y + margin) * scale
			var x0y1 = Vector2(x + margin, y + 1.0 - margin) * scale
			var x1y1 = Vector2(x + 1.0 - margin, y + 1.0 - margin) * scale
			canvas.draw_line(x0y0, x1y0, color1 if (wall & WallFlags.WF_N) > 0 else color2)
			canvas.draw_line(x1y0, x1y1, color1 if (wall & WallFlags.WF_E) > 0 else color2)
			canvas.draw_line(x0y1, x1y1, color1 if (wall & WallFlags.WF_S) > 0 else color2)
			canvas.draw_line(x0y0, x0y1, color1 if (wall & WallFlags.WF_W) > 0 else color2)
			canvas.draw_line(x0y0, x1y1, color1 if (wall & WallFlags.WF_C) > 0 else color2)
			y += 1
		x += 1
