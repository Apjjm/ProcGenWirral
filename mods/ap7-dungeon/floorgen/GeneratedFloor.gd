extends Reference

const PlotLayout = preload("./plotting/PlotLayout.gd")
const ZoneOverlay = preload("./zoning/ZoneOverlay.gd")
const ParcelOverlay = preload("./parcelling/ParcelOverlay.gd")
const EncountersOverlay = preload("./encounters/EncountersOverlay.gd")
const TreasureOverlay = preload("./treasure/TreasureOverlay.gd")
const DungeonMapMetadata = preload("./mapping/DungeonMapMetadata.gd")

var initial_seed: int
var number: int
var world_cell_size: Vector2
var world_interior_cell_size: Vector2
var layout: PlotLayout
var zones: ZoneOverlay
var parcels: ParcelOverlay
var encounters: EncountersOverlay
var treasure: TreasureOverlay
var map: DungeonMapMetadata
var region_settings: RegionSettings
var entrance_key: int
var treasure_room: int
var active_tags: Array = []

func num_rooms() -> int:
	return parcels.rooms.size()
