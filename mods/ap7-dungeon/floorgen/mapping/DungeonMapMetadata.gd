extends MapMetadata

var _world_units_per_cell : Vector2
var _texels_per_cell : Vector2
var _grid_size : Vector2

func _init(floor_name: String, image: Texture, block: Texture, grid_size: Vector2, world_units_per_cell: Vector2):
	self.title = floor_name
	self.map_texture = image
	self.map_obscure = block
	self.map_background = block
	self.minimap_scale = Vector2(1.5,1.5)
	self.chunk_layout = Rect2(Vector2.ZERO, Vector2.ONE)
	self.texels_per_world_unit = image.get_size() / (world_units_per_cell * grid_size)
	self.default_chunk_metadata = MapChunkMetadata.new()
	self.default_chunk_metadata.title = floor_name

	# HACK: When saving Mapping.gd wants a real path to a MapMetadata - but we're procedurally generated.
	# So instead, we have a dummy file which will at least do something valid...
	take_over_path("res://mods/ap7-dungeon/floorgen/mapping/DummyMapMetadata.tres")
	
func world_pos_to_chunk_pos(pos: Vector3)->Vector2:
	return Vector2(pos.x, pos.z) / world_units_per_chunk()

func chunk_pos_to_world_pos(chunk_pos: Vector2, y: float)->Vector3:
	var pos = chunk_pos * world_units_per_chunk()
	return Vector3(pos.x, y, pos.y)