extends Node

const FloorTags = preload("../../FloorTags.gd")
const PlotLayout = preload("../plotting/PlotLayout.gd")
const LayoutGrid = preload("../plotting/LayoutGrid.gd")
const DungeonMapMetadata = preload("DungeonMapMetadata.gd")

export(Image) var wall_atlas
export(String) var floor_name

func generate_map(subfloor_number: int, floor_tags: Array, layout: PlotLayout, world_cell_size: Vector2) -> DungeonMapMetadata:
	var quad_size = wall_atlas.get_size() / Vector2(6, 4)
	var cell_size = quad_size * Vector2(2, 2)

	var img_texture = ImageTexture.new()
	var img = Image.new()
	img.create(int(layout.grid.width * cell_size.x), int(layout.grid.height * cell_size.y), false, self.wall_atlas.get_format())
	img.lock()

	for x in range(layout.grid.width):
		for y in range(layout.grid.height):
			var cell = LayoutGrid.cell_from_coord(x,y)
			var qnw = get_quadrant_nw(layout.grid, cell, quad_size)
			var qne = get_quadrant_ne(layout.grid, cell, quad_size)
			var qse = get_quadrant_se(layout.grid, cell, quad_size)
			var qsw = get_quadrant_sw(layout.grid, cell, quad_size)

			img.blit_rect(self.wall_atlas, qnw, Vector2(x * cell_size.x, y * cell_size.y))
			img.blit_rect(self.wall_atlas, qne, Vector2(x * cell_size.x + quad_size.x, y * cell_size.y))
			img.blit_rect(self.wall_atlas, qsw, Vector2(x * cell_size.x, y * cell_size.y + quad_size.y))
			img.blit_rect(self.wall_atlas, qse, Vector2(x * cell_size.x + quad_size.x, y * cell_size.y + quad_size.y))
	img_texture.create_from_image(img, 0)
	
	var block_texture = ImageTexture.new()
	var block_img = Image.new()
	block_img.create(int(quad_size.x), int(quad_size.y), false, self.wall_atlas.get_format())
	block_img.lock()
	block_img.blit_rect(wall_atlas, Rect2(Vector2.ZERO, quad_size), Vector2.ZERO)
	block_img.unlock()
	block_texture.create_from_image(img, Texture.FLAG_REPEAT)
	
	var grid_size = Vector2(layout.grid.width, layout.grid.height)
	var name = Loc.trf(self.floor_name, { floor_number=str(subfloor_number), floor_modifier=get_adj(floor_tags) })

	print("[MappingPass] Generated world map")
	return DungeonMapMetadata.new(name, img_texture, block_texture, grid_size, world_cell_size)

func get_quadrant_nw(grid: LayoutGrid, cell: int,  quad_size: Vector2) -> Rect2:
	var wall_c = grid.walls[cell]
	
	if (wall_c & LayoutGrid.WallFlags.WF_C) > 0:
		return Rect2(Vector2.ZERO, quad_size)
		
	var has_n = (wall_c & LayoutGrid.WallFlags.WF_N) > 0
	var has_w = (wall_c & LayoutGrid.WallFlags.WF_W) > 0
	if has_w && !has_n:
		return Rect2(Vector2(quad_size.x * 1, 0), quad_size)      
	if has_n && !has_w:
		return Rect2(Vector2(quad_size.x * 2, 0), quad_size)    
	if has_w && has_n:
		return Rect2(Vector2(quad_size.x * 3, 0), quad_size)
		
	var wall_n = grid.walls[LayoutGrid.cell_north_of(cell)]
	var wall_w = grid.walls[LayoutGrid.cell_west_of(cell)]
	if (wall_n & LayoutGrid.WallFlags.WF_W) | (wall_w & LayoutGrid.WallFlags.WF_N) > 0:
		return Rect2(Vector2(quad_size.x * 4, 0), quad_size)

	return Rect2(Vector2(quad_size.x * 5, 0), quad_size)

func get_quadrant_ne(grid: LayoutGrid, cell: int,  quad_size: Vector2) -> Rect2:
	var wall_c = grid.walls[cell]
	
	if (wall_c & LayoutGrid.WallFlags.WF_C) > 0:
		return Rect2(Vector2(0, quad_size.y * 1), quad_size)
		
	var has_n = (wall_c & LayoutGrid.WallFlags.WF_N) > 0
	var has_e = (wall_c & LayoutGrid.WallFlags.WF_E) > 0
	if !has_e && has_n:
		return Rect2(Vector2(quad_size.x * 1, quad_size.y * 1), quad_size)      
	if !has_n && has_e:
		return Rect2(Vector2(quad_size.x * 2, quad_size.y * 1), quad_size)    
	if has_e && has_n:
		return Rect2(Vector2(quad_size.x * 3, quad_size.y * 1), quad_size)
		
	var wall_n = grid.walls[LayoutGrid.cell_north_of(cell)]
	var wall_e = grid.walls[LayoutGrid.cell_east_of(cell)]
	if (wall_n & LayoutGrid.WallFlags.WF_E) | (wall_e & LayoutGrid.WallFlags.WF_N) > 0:
		return Rect2(Vector2(quad_size.x * 4, quad_size.y * 1), quad_size)

	return Rect2(Vector2(quad_size.x * 5, quad_size.y * 1), quad_size)


func get_quadrant_se(grid: LayoutGrid, cell: int,  quad_size: Vector2) -> Rect2:
	var wall_c = grid.walls[cell]
	
	if (wall_c & LayoutGrid.WallFlags.WF_C) > 0:
		return Rect2(Vector2(0, quad_size.y * 2), quad_size)
		
	var has_s = (wall_c & LayoutGrid.WallFlags.WF_S) > 0
	var has_e = (wall_c & LayoutGrid.WallFlags.WF_E) > 0
	if has_e && !has_s:
		return Rect2(Vector2(quad_size.x * 1, quad_size.y * 2), quad_size)      
	if has_s && !has_e:
		return Rect2(Vector2(quad_size.x * 2, quad_size.y * 2), quad_size)    
	if has_e && has_s:
		return Rect2(Vector2(quad_size.x * 3, quad_size.y * 2), quad_size)
		
	var wall_s = grid.walls[LayoutGrid.cell_south_of(cell)]
	var wall_e = grid.walls[LayoutGrid.cell_east_of(cell)]
	if (wall_s & LayoutGrid.WallFlags.WF_E) | (wall_e & LayoutGrid.WallFlags.WF_S) > 0:
		return Rect2(Vector2(quad_size.x * 4, quad_size.y * 2), quad_size)

	return Rect2(Vector2(quad_size.x * 5, quad_size.y * 2), quad_size)

func get_quadrant_sw(grid: LayoutGrid, cell: int, quad_size: Vector2) -> Rect2:
	var wall_c = grid.walls[cell]
	
	if (wall_c & LayoutGrid.WallFlags.WF_C) > 0:
		return Rect2(Vector2(0, quad_size.y * 3), quad_size)
		
	var has_s = (wall_c & LayoutGrid.WallFlags.WF_S) > 0
	var has_w = (wall_c & LayoutGrid.WallFlags.WF_W) > 0
	if !has_w && has_s:
		return Rect2(Vector2(quad_size.x * 1, quad_size.y * 3), quad_size)      
	if !has_s && has_w:
		return Rect2(Vector2(quad_size.x * 2, quad_size.y * 3), quad_size)    
	if has_w && has_s:
		return Rect2(Vector2(quad_size.x * 3, quad_size.y * 3), quad_size)
		
	var wall_s = grid.walls[LayoutGrid.cell_south_of(cell)]
	var wall_w = grid.walls[LayoutGrid.cell_west_of(cell)]
	if (wall_s & LayoutGrid.WallFlags.WF_W) | (wall_w & LayoutGrid.WallFlags.WF_S) > 0:
		return Rect2(Vector2(quad_size.x * 4, quad_size.y * 3), quad_size)

	return Rect2(Vector2(quad_size.x * 5, quad_size.y * 3), quad_size)

func get_adj(tags: Array) -> String:
	for tag in tags:
		if FloorTags.TAG_FLOOR_ADJECTIVES.has(tag):
			return FloorTags.TAG_FLOOR_ADJECTIVES[tag]
	
	return ""