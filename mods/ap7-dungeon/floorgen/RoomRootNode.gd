extends Spatial

const CellRootNode = preload("CellRootNode.gd")
const GeneratedFloor = preload("GeneratedFloor.gd")

signal player_cell_entered(body, cell_x, cell_y, id)
signal player_cell_exited(body, cell_x, cell_y, id)

var plot_id: int
var floor_data: GeneratedFloor

# Vars used after realisation
var prop_rng: Random
var points_of_interest: Array = []

static func find_room_root(node: Node) -> Node:
	return node.find_parent("DF_ROOM_ROOT_*")

func _init(plot_id: int, floor_data: GeneratedFloor):
	self.plot_id = plot_id
	self.floor_data = floor_data
	self.name = "DF_ROOM_ROOT_" + str(plot_id)

func realise():
	var plot = self.floor_data.layout.plots[self.plot_id]
	var room = self.floor_data.parcels.get_room(self.plot_id)
	self.prop_rng = Random.new(room.interior_seed)
	self.translate(room.offset)
	
	for cell in room.cells:
		var cell_node = CellRootNode.new(plot.id, self.floor_data, cell.x, cell.y)
		var xz = (Vector2(cell.x, cell.y)-Vector2(plot.x, plot.y)) * self.floor_data.world_cell_size
		cell_node.translate(Vector3(xz.x, 0, xz.y))
		add_child(cell_node)

		cell_node.realise(cell)
		cell_node.connect("player_cell_entered", self, "_on_player_entered")
		cell_node.connect("player_cell_exited", self, "_on_player_exited")

func get_cell(cx: int, cy: int):
	return get_node("DF_CELL_" + str(cx) + "_" + str(cy))

func register_point_of_interest(node: Node):
	self.points_of_interest.push_back(node)

func is_player_in_room():
	return plot_id in get_parent().active_rooms

func _on_player_entered(body, cell_x, cell_y, id):
	emit_signal("player_cell_entered", body, cell_x, cell_y, id)

func _on_player_exited(body, cell_x, cell_y, id):
	emit_signal("player_cell_exited", body, cell_x, cell_y, id)
