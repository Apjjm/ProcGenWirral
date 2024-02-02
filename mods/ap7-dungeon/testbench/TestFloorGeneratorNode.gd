extends Node2D

const FloorInfo = preload("../FloorInfo.gd")
const FloorGenerator = preload("../floorgen/FloorGenerator.gd")
const GeneratedFloor = preload("../floorgen/GeneratedFloor.gd")

export var rng_seed : int = 0
export var scale_factor : Vector2 = Vector2(50,50)
export var draw_grid : bool = true
export var draw_map : bool = true

var _generator : FloorGenerator
var _result : GeneratedFloor
var _colors : Array

func _ready():
	self._generator = get_node("FloorGenerator")

	self._colors = []
	self._colors.push_back(Color.lightgray)
	self._colors.push_back(Color.lightsalmon)
	self._colors.push_back(Color.lemonchiffon)
	self._colors.push_back(Color.lightgreen)
	self._colors.push_back(Color.lightcyan)
	self._colors.push_back(Color.yellowgreen)
	self._colors.push_back(Color.lightblue)
	self._colors.push_back(Color.lightskyblue)
	self._colors.push_back(Color.limegreen)
	self._colors.push_back(Color.lightseagreen)
	self._colors.push_back(Color.lightyellow)
	self._colors.push_back(Color.cornsilk)
	self._colors.push_back(Color.lightgoldenrod)
	self._colors.push_back(Color.peachpuff)

	get_node("generate").connect("pressed", self, "_generate")

func _process(_delta):
	update()

func _unhandled_input(event):
	if event.is_action("ui_accept"):
		_generate()
		get_tree().set_input_as_handled()

func _generate():
	var info = { "floor_seed": randi() if self.rng_seed == 0 else self.rng_seed }
	self._result = self._generator.generate_floor(FloorInfo.new(info))

func _draw():
	if self._result != null:
		self.draw_set_transform(Vector2(50, 50), 0, Vector2.ONE)
		if self.draw_grid:
			self._result.layout.grid.debug_draw(self, scale_factor, 0.1, Color.orange, Color.aqua)
		elif self.draw_map && self._result.map != null:
			self.draw_texture(self._result.map.map_texture, Vector2.ZERO)
		else:
			var cols = []
			cols.resize(self._result.layout.plots.size())
			for plot in self._result.layout.plots:
				var zone = self._result.zones.get_zone(plot.id)
				cols[plot.id] = self._colors[zone.hash() % self._colors.size()]
			
			self._result.layout.debug_draw(self, scale_factor, cols)
			self.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
