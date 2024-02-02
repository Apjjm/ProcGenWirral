extends Reference
const PlotLayout = preload("../plotting/PlotLayout.gd")

var rooms : Array
var width : int
var height : int

enum CellWallFlags { CONN_L=1, CONN_R=2, CONN_LR=3 }

class CellOverlay:
	extends Reference
	
	var x: int # In grid space
	var y: int # In grid space
	var flr: PackedScene
	var cover: PackedScene
	var wall_n: PackedScene
	var wall_e: PackedScene
	var wall_s: PackedScene
	var wall_w: PackedScene
	var corner_nw: PackedScene
	var corner_ne: PackedScene
	var corner_sw: PackedScene
	var corner_se: PackedScene
	var wall_type_n: int
	var wall_type_e: int
	var wall_type_s: int
	var wall_type_w: int
	var has_special_cover: bool

class RoomOverlay:
	extends Reference

	var plot_id: int
	var interior_seed: int
	var cells: Array
	var offset: Vector3

	func find_cell(x: int, y: int):
		for cell in cells:
			if cell.x == x && cell.y == y:
				return cell
		return null

func _init(layout: PlotLayout):
	self.width = layout.grid.width
	self.height = layout.grid.height
	self.rooms = []
	self.rooms.resize(layout.plots.size())
	self.rooms.fill(null)

func add_room(plot_id: int, interior_seed: int) -> RoomOverlay:
	var result = RoomOverlay.new()
	result.plot_id = plot_id
	result.interior_seed = interior_seed
	result.cells = []
	self.rooms[plot_id] = result
	return result

func get_room(plot_id: int) -> RoomOverlay:
	return self.rooms[plot_id]
