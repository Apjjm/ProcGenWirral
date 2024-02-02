const FloorTags = preload("../FloorTags.gd")

# Special zones that can go anywhere are called 'overlay' zones - so this should be all zones for normal parcels
export(Array, String) var required_overlay_zones = []
export(Array, PackedScene) var overlay_shrine_parcels = []
export(Array, PackedScene) var overlay_shop_parcels = []
export(Array, PackedScene) var overlay_kuneko_parcels = []

# Some special zones need a dedicated secret room. These are 'room' zones.
# We make these by using the same walls and layout as another zone normal zone
# but then swapping out some of the parts as needed to make it have the special contents.
# e.g. we might want to swap out the floor to put in a new exit hatch
# This is a bit hacky, but the alternative is way more config & having it all here makes it easy to see what we've missed.
export(Array, PackedScene) var room_cover_ranger_parcels = []
export(Array, PackedScene) var room_cover_inn_parcels = []
export(Array, PackedScene) var room_cover_landkeeper_parcels = []

export(Array, PackedScene) var room_floor_ranger_parcels = []
export(Array, PackedScene) var room_floor_inn_parcels = []
export(Array, PackedScene) var room_floor_landkeeper_parcels = []


func get_available_overlay_covers(tags: Array):
	var result = []
	if FloorTags.FT_SHRINE in tags:
		result.push_back(self.overlay_shrine_parcels)
	if FloorTags.FT_SHOP in tags:
		result.push_back(self.overlay_shop_parcels)
	if FloorTags.FT_KUNEKO in tags:
		result.push_back(self.overlay_kuneko_parcels)

	return result

func get_available_room_covers(tags: Array):
	if FloorTags.FT_RANGER_DOOR in tags:
		return self.room_cover_ranger_parcels
	if FloorTags.FT_INN_DOOR in  tags:
		return self.room_cover_inn_parcels
	if FloorTags.FT_LANDKEEPER_DOOR in  tags:
		return self.room_cover_landkeeper_parcels

	return []

func get_available_room_floors(tags: Array):
	if FloorTags.FT_RANGER_DOOR in tags:
		return self.room_floor_ranger_parcels
	if FloorTags.FT_INN_DOOR in  tags:
		return self.room_floor_inn_parcels
	if FloorTags.FT_LANDKEEPER_DOOR in  tags:
		return self.room_floor_landkeeper_parcels

	return []