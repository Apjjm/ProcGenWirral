extends Resource

enum ConstraintType { CT_CELL, CT_REQUIRE_WALL, CT_UNUSED }

export(int, 0, 10) var first_x = 0
export(int, 0, 10) var first_y = 0
export(int, 0, 10) var width = 0
export(int, 0, 10) var height = 0
export(int, 0, 100) var size = 0
export(Array, int) var rules = []
export(String) var shape_id = "" 

func rule_x(i: int) -> int:
	return i%self.width

func rule_y(i: int) -> int:
	return i/self.width

func is_cell(i: int) -> int:
	return rules[i] == ConstraintType.CT_CELL

func is_forced_wall(i: int) -> int:
	return rules[i] == ConstraintType.CT_REQUIRE_WALL

func count_cells() -> int:
	var count = 0
	for rule in rules:
		if rule == ConstraintType.CT_CELL:
			count += 1
	return count

func draw_shape(canvas: CanvasItem, position: Vector2, scale: Vector2, fill: Color, draw_constraints: bool = false):
	var pos = Vector2(floor(position.x), floor(position.y))
	var sf = Vector2(floor(scale.x), floor(scale.y))
		
	var i=0
	while i < rules.size():
		var offset = Vector2(rule_x(i), rule_y(i)) * sf
		if rules[i] == ConstraintType.CT_CELL:
			canvas.draw_rect(Rect2(pos + offset, sf), fill)
		if draw_constraints:
			if rules[i] == ConstraintType.CT_REQUIRE_WALL && draw_constraints:
				canvas.draw_circle(pos + offset + sf * 0.5, sf.x * 0.1, Color.red)
			if rules[i] == ConstraintType.CT_UNUSED && draw_constraints:
				canvas.draw_circle(pos + offset + sf * 0.5, sf.x * 0.1, Color.green)
			if i%width == first_x && i/width == first_y:
				canvas.draw_circle(pos + offset + sf * 0.5, sf.x * 0.05, Color.white)
		i+=1
