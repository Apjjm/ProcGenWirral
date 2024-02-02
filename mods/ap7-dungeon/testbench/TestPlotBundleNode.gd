extends Node2D

const PlotDefinition = preload("../floorgen/plotting/PlotDefinition.gd")

export var padding : Vector2 = Vector2(10, 10)
export var scale_factor : Vector2 = Vector2(32, 32)
export var max_size : Vector2 = Vector2(4, 4)

var _groups = []

func _ready():	
	var dt = Datatables.load("res://mods/ap7-dungeon/plots").table
	for p in dt.values():
		var group = null
		for r in self._groups:
			if r[0].size == p.size:
				group = r
				break
		
		if group == null:
			self._groups.push_back([p])
		else:
			group.push_back(p)

	self._groups.sort_custom(GroupSorter, "sort_descending")	

func _process(_delta):
	update()

func _draw():	
	var pos = self.padding
	for plot_group in self._groups:
		for plot in plot_group:
			_draw_plot(plot, pos, Color.lightcoral)
			pos.x += padding.x + self.scale_factor.x * self.max_size.x
		
		pos.x = padding.x
		pos.y += padding.y + self.scale_factor.y * self.max_size.y

func _draw_plot(plot: PlotDefinition, pos: Vector2, color: Color):
	var plot_size = Vector2(plot.width, plot.height)
	draw_rect(Rect2(pos - self.padding * 0.25, self.max_size * self.scale_factor + self.padding * 0.5), Color.black, true)
	draw_rect(Rect2(pos - self.padding * 0.25, self.max_size * self.scale_factor + self.padding * 0.5), Color.white, false)
	draw_rect(Rect2(pos, plot_size), Color.darkgray, true)
	plot.draw_shape(self, pos, self.scale_factor, color, true)

class GroupSorter:
	static func sort_descending(a, b):
		return a[0].size > b[0].size
