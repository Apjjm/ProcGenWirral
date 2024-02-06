# Floor tags to indicate which floor type it is.
# Since we have this info to hand anyway, we use it to stop a bunch of hard coded paths sprawling all over the code and just have a scene table here.
const FT_SCENE_MALL             = "mall"
const FT_SCENE_CAVE             = "cave"
const FT_SCENE_TOWN             = "town"
const FT_SCENE_STATION          = "station"
const FT_SCENE_FINAL            = "final"
const FT_SCENE_INN              = "inn.scene"
const FT_SCENE_KUNEKO           = "kunkeo.scene"
const FT_SCENE_LANDKEEPER       = "landkeeper.scene"
const FT_SCENE_RANGER_AIR       = "ranger.air"
const FT_SCENE_RANGER_ASTRAL    = "ranger.astral"
const FT_SCENE_RANGER_BEAST     = "ranger.beast"
const FT_SCENE_RANGER_EARTH     = "ranger.earth"
const FT_SCENE_RANGER_FIRE      = "ranger.fire"
const FT_SCENE_RANGER_GLASS     = "ranger.glass"
const FT_SCENE_RANGER_ICE       = "ranger.ice"
const FT_SCENE_RANGER_LIGHTNING = "ranger.lightning"
const FT_SCENE_RANGER_METAL     = "ranger.metal"
const FT_SCENE_RANGER_PLANT     = "ranger.plant"
const FT_SCENE_RANGER_PLASTIC   = "ranger.plastic"
const FT_SCENE_RANGER_POISON    = "ranger.posion"
const FT_SCENE_RANGER_WATER     = "ranger.water"
const FT_SCENE_INTRO_MALL       = "intro.mall"
const FT_SCENE_INTRO_CAVE       = "intro.cave"
const FT_SCENE_INTRO_TOWN       = "intro.town"
const FT_SCENE_INTRO_STATION    = "intro.station"
const FT_SCENE_EXTERIROR        = "dungeon.exterior"

# Floor modifiers
const FT_NOCOMBAT   = "nc"          # Floor has no combat (i.e. is a rest area)
const FT_TREASURE   = "treasure"    # Floor has a "treasure" room containing heavy enemy & loot presence
const FT_SWARMING   = "swarming"    # Floor has more enemies
const FT_SPRAWLING  = "sprawling"   # Floor is larger
const FT_AIR        = "air"         # Floor has higher chance of bootlegs of this element
const FT_ASTRAL     = "astral"      # Floor has higher chance of bootlegs of this element
const FT_BEAST      = "beast"       # Floor has higher chance of bootlegs of this element
const FT_EARTH      = "earth"       # Floor has higher chance of bootlegs of this element
const FT_FIRE       = "fire"        # Floor has higher chance of bootlegs of this element
const FT_GLASS      = "glass"       # Floor has higher chance of bootlegs of this element
const FT_GLITTER    = "glitter"     # Floor has higher chance of bootlegs of this element
const FT_ICE        = "ice"         # Floor has higher chance of bootlegs of this element
const FT_LIGHTNING  = "lightning"   # Floor has higher chance of bootlegs of this element
const FT_METAL      = "metal"       # Floor has higher chance of bootlegs of this element
const FT_PLANT      = "plant"       # Floor has higher chance of bootlegs of this element
const FT_PLASTIC    = "plastic"     # Floor has higher chance of bootlegs of this element
const FT_POISON     = "posion"      # Floor has higher chance of bootlegs of this element
const FT_WATER      = "water"       # Floor has higher chance of bootlegs of this element
const FT_CHAOS      = "chaos"       # Floor can spawn any enemies from any floor, some restrictions on v. early floors
const FT_MEMORY     = "memorysigil" # Floor may contain a memory sigil - used for rest areas

# Special Overlays
const FT_SHOP               = "shop"             # Floor will have a merchant appear in a random room
const FT_SHRINE             = "shrine"           # Floor will have a shrine of power appear in a random room
const FT_KUNEKO             = "kuneko"           # Floor will spawn the kuneko quest NPC
const FT_INN_KEY            = "inn.key"          # Floor will spawn the key to get into inn area
const FT_RANGER_KEY         = "ranger.key"       # Floor will spawn the key to get into a ranger room (see FT_RANGER_*)

# Doors linking to secret rooms
const FT_INN_DOOR           = "inn.door"         # Floor will spawn the door to get into inn area
const FT_LANDKEEPER_DOOR    = "landkeeper.door"  # Floor will spawn the door to get into landkeeper area (no key required)
const FT_RANGER_DOOR        = "ranger.door"      # Floor will spawn the door to get into a ranger room (see FT_RANGER_*)

# All floor modifier elemental types collected up - useful for doing a random choice
const ALL_ELEMENT_TAGS = [
	FT_AIR,
	FT_ASTRAL,
	FT_BEAST,
	FT_EARTH,
	FT_FIRE,
	FT_GLASS,
	FT_GLITTER,
	FT_ICE,
	FT_LIGHTNING,
	FT_METAL,
	FT_PLANT,
	FT_PLASTIC,
	FT_POISON,
	FT_WATER
]

# All ranger types collected up - useful for doing a random choice
const ALL_RANGER_ELEMENT_TAGS = [
	FT_SCENE_RANGER_AIR,
	FT_SCENE_RANGER_ASTRAL,
	FT_SCENE_RANGER_BEAST,
	FT_SCENE_RANGER_EARTH,
	FT_SCENE_RANGER_FIRE,
	FT_SCENE_RANGER_GLASS,
	FT_SCENE_RANGER_ICE,
	FT_SCENE_RANGER_LIGHTNING,
	FT_SCENE_RANGER_METAL,
	FT_SCENE_RANGER_PLANT,
	FT_SCENE_RANGER_PLASTIC,
	FT_SCENE_RANGER_POISON,
	FT_SCENE_RANGER_WATER
]

# All tags that require generation of an extra secret room. Max 1 per floor.
const ALL_SECRET_ROOM_TAGS = [
	FT_INN_DOOR,
	FT_LANDKEEPER_DOOR,
	FT_RANGER_DOOR
]

# These are adjectives that will appear on the floor name when you enter the floor e.g. "Sprawling mall 1"
const TAG_FLOOR_ADJECTIVES = {
	FT_TREASURE: "AP7_DUNGEON_FLOOR_ADJ_TREASURE",
	FT_SWARMING: "AP7_DUNGEON_FLOOR_ADJ_SWARMING",
	FT_SPRAWLING: "AP7_DUNGEON_FLOOR_ADJ_SPRAWLING",
	FT_AIR: "AP7_DUNGEON_FLOOR_ADJ_AIR",
	FT_ASTRAL: "AP7_DUNGEON_FLOOR_ADJ_ASTRAL",
	FT_BEAST: "AP7_DUNGEON_FLOOR_ADJ_BEAST",
	FT_EARTH: "AP7_DUNGEON_FLOOR_ADJ_EARTH",
	FT_FIRE: "AP7_DUNGEON_FLOOR_ADJ_FIRE",
	FT_GLASS: "AP7_DUNGEON_FLOOR_ADJ_GLASS",
	FT_GLITTER: "AP7_DUNGEON_FLOOR_ADJ_GLITTER",
	FT_ICE: "AP7_DUNGEON_FLOOR_ADJ_ICE",
	FT_LIGHTNING: "AP7_DUNGEON_FLOOR_ADJ_LIGHTNING",
	FT_METAL: "AP7_DUNGEON_FLOOR_ADJ_METAL",
	FT_PLANT: "AP7_DUNGEON_FLOOR_ADJ_PLANT",
	FT_PLASTIC: "AP7_DUNGEON_FLOOR_ADJ_PLASTIC",
	FT_POISON: "AP7_DUNGEON_FLOOR_ADJ_POISON",
	FT_WATER: "AP7_DUNGEON_FLOOR_ADJ_WATER",
	FT_CHAOS: "AP7_DUNGEON_FLOOR_ADJ_CHAOS",
}

# Scenes associated with generated areas
const SCENE_LOOKUP = {
	FT_SCENE_EXTERIROR: "res://mods/ap7-dungeon/floors/Djinntermission.tscn",
	FT_SCENE_MALL: "res://mods/ap7-dungeon/floors/DungeonFloor_Mall.tscn",
	FT_SCENE_CAVE: "res://mods/ap7-dungeon/floors/DungeonFloor_Cave.tscn",
	FT_SCENE_TOWN: "res://mods/ap7-dungeon/floors/DungeonFloor_Town.tscn",
	FT_SCENE_STATION: "res://mods/ap7-dungeon/floors/DungeonFloor_Station.tscn",
	FT_SCENE_FINAL: "res://mods/ap7-dungeon/floors/DungeonFloor_Final.tscn",
	FT_SCENE_INN: "res://mods/ap7-dungeon/floors/special/Special_AllieInn.tscn",
	FT_SCENE_KUNEKO: "res://mods/ap7-dungeon/floors/special/Special_Kuneko.tscn",
	FT_SCENE_LANDKEEPER: "res://mods/ap7-dungeon/floors/special/Special_Landkeeper.tscn",
	FT_SCENE_RANGER_AIR: "res://mods/ap7-dungeon/floors/special/Special_RangerAir.tscn",
	FT_SCENE_RANGER_ASTRAL: "res://mods/ap7-dungeon/floors/special/Special_RangerAstral.tscn",
	FT_SCENE_RANGER_BEAST: "res://mods/ap7-dungeon/floors/special/Special_RangerBeast.tscn",
	FT_SCENE_RANGER_EARTH: "res://mods/ap7-dungeon/floors/special/Special_RangerEarth.tscn",
	FT_SCENE_RANGER_FIRE: "res://mods/ap7-dungeon/floors/special/Special_RangerFire.tscn",
	FT_SCENE_RANGER_GLASS: "res://mods/ap7-dungeon/floors/special/Special_RangerGlass.tscn",
	FT_SCENE_RANGER_ICE: "res://mods/ap7-dungeon/floors/special/Special_RangerIce.tscn",
	FT_SCENE_RANGER_LIGHTNING: "res://mods/ap7-dungeon/floors/special/Special_RangerLightning.tscn",
	FT_SCENE_RANGER_METAL: "res://mods/ap7-dungeon/floors/special/Special_RangerMetal.tscn",
	FT_SCENE_RANGER_PLANT: "res://mods/ap7-dungeon/floors/special/Special_RangerGrass.tscn",
	FT_SCENE_RANGER_PLASTIC: "res://mods/ap7-dungeon/floors/special/Special_RangerPlastic.tscn",
	FT_SCENE_RANGER_POISON: "res://mods/ap7-dungeon/floors/special/Special_RangerPoison.tscn",
	FT_SCENE_RANGER_WATER: "res://mods/ap7-dungeon/floors/special/Special_RangerWater.tscn",
	FT_SCENE_INTRO_MALL: "res://mods/ap7-dungeon/floors/intro/Intro_Town.tscn", # TODO
	FT_SCENE_INTRO_CAVE: "res://mods/ap7-dungeon/floors/intro/Intro_Caves.tscn",
	FT_SCENE_INTRO_TOWN: "res://mods/ap7-dungeon/floors/intro/Intro_Town.tscn",
	FT_SCENE_INTRO_STATION: "res://mods/ap7-dungeon/floors/intro/Intro_Station.tscn",
}

# List of the main procedurally generated areas in default order
const MAIN_AREAS_IN_ORDER = [ 
	FT_SCENE_MALL, 
	FT_SCENE_CAVE, 
	FT_SCENE_TOWN, 
	FT_SCENE_STATION
]

# Associated intro areas for each procedural area
const INTRO_AREA_LOOKUP = {
	FT_SCENE_MALL: FT_SCENE_INTRO_MALL,
	FT_SCENE_CAVE: FT_SCENE_INTRO_CAVE,
	FT_SCENE_TOWN: FT_SCENE_INTRO_TOWN,
	FT_SCENE_STATION: FT_SCENE_INTRO_STATION,
}

# Key item lookup - used for forcing loot into chests for secret areas
const KEY_ITEM_LOOKUP = {
	FT_INN_KEY: "res://data/items/ap7_key_secret_inn.tres",
	FT_RANGER_KEY: "res://data/items/ap7_key_secret_ranger.tres"
}

static func tags_intersect(tagsA: Array, tagsB: Array) -> bool:
	for tag in tagsA:
		if tag in tagsB:
			return true

	return false

static func first_tag_matching(tagsSet: Array, matching: Array) -> String:
	for tag in tagsSet:
		if tag in matching:
			return tag

	return ""