extends Node

# ! DANGER ! Here be dragons !
# It is remarkable that fading away some walls ends up more complex that all the damn floor generation 
# This is probably because we're a mod and can't extend all mats (especially with grid areas) to use a new shader + do some multi-pass hackery?
# (e.g. we could render parts of the active room out of order or use the stencil buffer or do an active rooms-only render pass and blend the final images)
# Any ideas i've had for doing this purely with shaders requires way too much in the way of base game changes to even consider. So instead...
# 
# It turns out, what "fade" feels reasonable to play is just really complicated. Simple approaches like "current room visible" looks janky.
# A quick summary of the approach here is as follows (note these cases generalise to N and fold together but this illustrates the logic)
#  A: Assume we are in exactly 1 room. Then the cells below all the cells in this room are potential occluders
#     We don't need to look at them all though, just a few cells (max_faded_under) as the rest will of camera. This should be transparent.
#  B: Assume we are walking between 2 cells N <--> S. We will have 2 active cells, one in the lower room, one in the upper room.
#     We can look at all the under cells again, and fade the under cells based on how far beneath that room the player is
#  C: Like case B but W<-->E, exactly the same logic applies - how far outside the cell are we?
#  From B & C we need to look at both X and Y for a given "active" cell. Choosing the biggest opacity constraint is telling us how far outside we are.
#  In reality, a player might be overlapping multiple active cells for a room (e.g. if two doors are side-by-side). Additionally, rooms might "fight" over a cell.
#  In this case, when multiple rooms (or active cells) want to set opacity on an under cell, the under cell just choses the least transparent.
#
#  There is some book-keeping we need to do. Getting all the under cells for a room would require a grid trawl every frame.
#  We also would need to know where the world position for all the active cells are.
#  We pre-compute this as much as posssible. At room generation we can cache all the under cells for a given room.
#  Whenever we move cells, we can update all the world positions for our active cells.
#
#  Final gotcha - what if the player leaves a cell really quickly? The opactiy might get stuck at 0.96 or something.
#  When we go through and update the list of cells we need to fade (because our active cells changed), we can look at any rooms we are about to clean up
#  because they are no longer active. Those rooms will conviently have a set of faded cells on them we can give full opacity back to.
#  In the case of fighting cells this maybe causes flickering depending on update ordering? dunno, seems rare enough that idgaf at this point.
# 
#  We will probably have to deal with some lighting BS at some point in the future from directional lights. But that can be dealt with out of here.

const LayoutGrid = preload("../floorgen/plotting/LayoutGrid.gd")
const FloorLevelNode = preload("../floorgen/FloorLevelNode.gd")
const GeneratedFloor = preload("../floorgen/GeneratedFloor.gd")

export(int, 1, 10) var max_faded_under = 3

var flr : FloorLevelNode
var room_lut : Array = []
var room_cells : Array = []
var faded_cells : Array  = []
var active_rooms : Array = []

var cell_size : Vector3
var interior_size : Vector3

class CellInfo:
	extends Reference

	var x: int = -1
	var y: int = -1
	var room: int = -1
	var vis_n: Reference = null
	var vis_s: Reference = null
	var pos : Vector3

class RoomInfo:
	extends Reference

	var id : int
	var active : Array = []

func _ready():
	self.flr = get_parent()
	self.flr.connect("active_cells_changed", self, "_on_active_cells_changed")
	if self.flr.floor_data != null:
		_on_floor_generated(self.flr.floor_data)
	else:
		self.flr.connect("floor_generated", self, "_on_floor_generated")

func _on_floor_generated(data: GeneratedFloor):
	self.cell_size = Vector3(data.world_cell_size.x, 1, data.world_cell_size.y)
	self.interior_size = Vector3(data.world_interior_cell_size.x, 1, data.world_interior_cell_size.y)
	
	self.room_lut = []
	for _p in data.layout.plots:
		self.room_lut.push_back([])
		self.room_cells.push_back([])
	
	var grid : LayoutGrid = data.layout.grid
	for x in range(0, grid.width):
		var y = 0
		while y < grid.height:
			# Find an actually used cell - this is our current room
			var room = -1
			var room_y = -1
			while y < grid.height:
				var cell = LayoutGrid.cell_from_coord(x, y)
				if !grid.has_wall(cell, LayoutGrid.WallFlags.WF_C):
					room = grid.get_plot(cell)
					room_y = y
					break
				y += 1

			# Find the last cell in this column from this room
			while y < grid.height:
				var cell = LayoutGrid.cell_from_coord(x, y)
				if grid.get_plot(cell) == room:
					if !grid.has_wall(cell, LayoutGrid.WallFlags.WF_C):
						var info = CellInfo.new()
						info.x = x
						info.y = y
						info.room = room
						self.room_cells[room].push_back(info)
				else:
					room_y = y-1
					break
				y += 1

			# Look at the nxt N cells, if these are real cells include them in our room's fade list
			while y < grid.height && y < room_y + max_faded_under:
				var cell = LayoutGrid.cell_from_coord(x, y)
				if !grid.has_wall(cell, LayoutGrid.WallFlags.WF_C):
					var info = CellInfo.new()
					info.x = x
					info.y = y
					info.room = grid.get_plot(cell)
					self.room_lut[room].push_back(info)
				y += 1
			
			if room_y != -1:
				y = room_y +1

func _on_active_cells_changed(cells: Array):
	for room in self.active_rooms:
		room.active.clear()
	
	for cell in cells:
		var room = _ensure_room(cell.id)
		room.active.push_back(Vector3(0.5 + cell.x, 0, 0.5 + cell.y) * cell_size)
		if room.active.size() == 1:
			for c in self.room_lut[room.id]:
				_ensure_vis(c)
			for c in self.room_cells[room.id]:
				_ensure_vis(c)

	for i in range(self.active_rooms.size()-1, -1, -1):
		if self.active_rooms[i].active.size() == 0:
			for c in self.room_lut[self.active_rooms[i].id]:
				c.vis_n.set_opacity(1.0)
				c.vis_s.set_opacity(1.0)
			self.active_rooms.remove(i)

func _process(_delta):
	var player = WorldSystem.get_player()
	if player == null:
		return

	# The maths here is really confusing. Basically, we want to know what the min opacity is for a given room.
	# For a given cell in a room, the opacity is the axis the player is furthest out on, and given by how much outside the active cell they are.
	# We use the maximum for the cell, because if they are coming in say, horziontally, then their vertical distance could be 0 already.
	var near = self.cell_size * 0.5
	var far = self.cell_size - (self.interior_size * 0.55)
	var pp = player.global_translation
	for room in self.active_rooms:
		var desired_opacity = 1.0
		for ap in room.active:
			var diff = ((ap-pp).abs()-near) / (far-near)
			var opacity = clamp(max(diff.x, diff.z), 0, 1)
			desired_opacity = min(opacity, desired_opacity)

		# Basically, souths of this room are like norths of the room below
		# So it seems we can just couple the opacity together and it works well enough.
		for cell in self.room_lut[room.id]:
			cell.vis_n.set_opacity(desired_opacity)
		
		for cell in self.room_cells[room.id]:
			cell.vis_s.set_opacity(desired_opacity)

func _ensure_vis(info: CellInfo):
	if info.vis_n == null:
		var cell = self.flr.get_room(info.room).get_cell(info.x, info.y)
		info.vis_n = cell.visibility_batch_n
		info.vis_s = cell.visibility_batch_s
	
func _ensure_room(id: int):
	for r in self.active_rooms:
		if r.id == id:
			return r
	
	var room = RoomInfo.new()
	room.id = id
	self.active_rooms.push_back(room)
	return room
