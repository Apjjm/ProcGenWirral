const FloorTags = preload("../../FloorTags.gd")

const DEFAULT_EXP_MONSTER = 40
const DEFAULT_EXP_MONSTER_ENCOUNTER = 80

const DEFAULT_EXP_RANGER = 100
const DEFAULT_EXP_RANGER_ENCOUNTER = 120

static func calc_floor_tier(floor_number: int):
	if floor_number <= 4:
		return 1
	elif floor_number <= 8:
		return 2
	elif floor_number <= 12:
		return 3
	else:
		return 4

static func calc_exp_multiplier(floor_number: int):
	if floor_number <= 2: # First half of floor 1
		return 0.8
	elif floor_number <= 8:
		return 1.0
	elif floor_number <= 12: # Town encounters are significantly harder, you will take less of them at this pt.
		return 1.25
	else:
		return 1.50

static func calc_bootleg(floor_number: int, element_tag: String, is_fusion: bool, rng: Random) -> Array:
	var chance = floor_number * 0.01 if is_fusion else floor_number * 0.003
	if element_tag == "":
		return [] if rng.rand_float() > chance else [ BattleSetupUtil.random_type(rng) ]
	else:
		return [] if rng.rand_float() > (0.10+chance) else [ get_element_for_tag(element_tag, rng) ]

static func calc_level(floor_number: int, offset: int, underlevel: int, overlevel: int, rng: Random):
	var lvl = rng.rand_range_int(-underlevel,overlevel) + (floor_number+offset) * 1.5
	return 3 + int(max(0, lvl))

static func calc_fusion(floor_number: int, rng: Random) -> bool:
	return rng.rand_float() < clamp(floor_number*0.003, 0.01, 0.15)

static func calc_swarm(floor_number: int, rng: Random) -> bool:
	return rng.rand_float() < clamp(floor_number*0.005, 0.01, 0.05)

static func get_element_for_tag(tag: String, rng: Random) -> ElementalType:
	if FloorTags.FT_AIR == tag:
		return preload("res://data/elemental_types/air.tres");      
	if FloorTags.FT_ASTRAL == tag:
		return preload("res://data/elemental_types/astral.tres");   
	if FloorTags.FT_BEAST == tag:
		return preload("res://data/elemental_types/beast.tres");    
	if FloorTags.FT_EARTH == tag:
		return preload("res://data/elemental_types/earth.tres");    
	if FloorTags.FT_FIRE == tag:
		return preload("res://data/elemental_types/fire.tres");     
	if FloorTags.FT_GLASS == tag:
		return preload("res://data/elemental_types/glass.tres");    
	if FloorTags.FT_GLITTER == tag:
		return preload("res://data/elemental_types/glitter.tres");  
	if FloorTags.FT_ICE == tag:
		return preload("res://data/elemental_types/ice.tres");      
	if FloorTags.FT_LIGHTNING == tag:
		return preload("res://data/elemental_types/lightning.tres");
	if FloorTags.FT_METAL == tag:
		return preload("res://data/elemental_types/metal.tres");    
	if FloorTags.FT_PLANT == tag:
		return preload("res://data/elemental_types/plant.tres");    
	if FloorTags.FT_PLASTIC == tag:
		return preload("res://data/elemental_types/plastic.tres");  
	if FloorTags.FT_POISON == tag:
		return preload("res://data/elemental_types/poison.tres");   
	if FloorTags.FT_WATER == tag:
		return preload("res://data/elemental_types/water.tres");    
	
	return BattleSetupUtil.random_type(rng)