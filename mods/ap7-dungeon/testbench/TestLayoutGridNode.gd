extends Node2D

const LayoutGrid = preload("../floorgen/plotting/LayoutGrid.gd")

export var rng_seed : String = ""
export var width: int = 8
export var height: int = 8
export var scale_factor : Vector2 = Vector2(30, 30)

var _rng : Random
var _grid1 : LayoutGrid
var _grid2 : LayoutGrid

func _ready():
	self._rng = Random.new(rng_seed) if rng_seed.length() > 0 else Random.new()
	self._grid1 = LayoutGrid.new(self.width, self.height)
	self._grid2 = LayoutGrid.new(self.width, self.height)
	
func _unhandled_input(event):
	if event.is_action("map_menu") || event.is_action_pressed("ui_accept"):
		if self._grid1.test_full_connectivity():
			self._grid2.set_from(self._grid1)
		else:
			self._grid1.set_from(self._grid2)
		
		var cell = LayoutGrid.cell_from_coord(self._rng.rand_int(self.width), self._rng.rand_int(self.height))
		if cell != null && self._grid1.has_wall(cell, LayoutGrid.WallFlags.WF_C):
			self._grid1.remove_walls(cell)
		elif cell != null:
			self._grid1.add_walls(cell)
		get_tree().set_input_as_handled()

func _process(_delta):
	update()

func _draw():
	self._grid2.debug_draw(self, self.scale_factor, 0.10, Color.red, Color.lightblue)
	self._grid1.debug_draw(self, self.scale_factor, 0.25, Color.orange, Color.aqua)
