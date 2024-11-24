const FloorTags = preload("../../FloorTags.gd")

const DEFAULT_EXP_MONSTER = 40
const DEFAULT_EXP_MONSTER_ENCOUNTER = 80

const DEFAULT_EXP_RANGER = 100
const DEFAULT_EXP_RANGER_ENCOUNTER = 120

static func calc_exp_multiplier(floor_number: int, boost: float):
	return ((floor_number*0.07)+0.6)*boost

static func calc_bootleg(floor_number: int, element_tag: String, is_fusion: bool, scaling: float, rng: Random) -> Array:
	var chance = (floor_number * 0.01 if is_fusion else floor_number * 0.003) * scaling
	if element_tag == "":
		return [] if rng.rand_float() > chance else [ BattleSetupUtil.random_type(rng) ]
	else:
		return [] if rng.rand_float() > (0.10+chance) else [ get_element_for_tag(element_tag, rng) ]

static func calc_level(floor_number: int, offset: int, underlevel: int, overlevel: int, scaling: float, rng: Random):
	var lvl = rng.rand_range_int(-underlevel,overlevel) + (floor_number+offset) * scaling
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