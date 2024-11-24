extends Node

const FloorTags = preload("../../FloorTags.gd")
const MonsterTable = preload("../../globals/MonsterTable.gd")
const PlotLayout = preload("../plotting/PlotLayout.gd")
const EncountersOverlay = preload("EncountersOverlay.gd")
const EncountersUtil = preload("EncountersUtil.gd")

export(float, 0, 10) var enemy_density = 1.4
export(int, 0, 10) var max_enemies_per_cell = 2
export(int, 0, 42) var exp_gradient = 5
export(int, 0, 9999) var exp_base_level = 0
export(int, 1, 100) var max_distinct_overworld = 5

func generate_encounters(floor_number: int, area_number: int, subfloor_number: int, floor_tags: Array, priority_room: int, wild: bool, scaling: float, expboost: float, layout: PlotLayout, rng: Random) -> EncountersOverlay:
	var element_tag = FloorTags.first_tag_matching(FloorTags.ALL_ELEMENT_TAGS, floor_tags)
	var extra_density = 1.25 if (FloorTags.FT_TREASURE in floor_tags || FloorTags.FT_SWARMING in floor_tags) else 1.0
	
	# Lets try to keep floors feeling a bit more distinct by not having every overworld monster on every floor
	var overworld_choices = get_overworld_monsters(floor_number, area_number, floor_tags, wild, rng)
	var backup_choices = get_backup_monsters(floor_number, subfloor_number, area_number, floor_tags, wild)
	var ranger_choices = get_backup_monsters(floor_number, subfloor_number, area_number, floor_tags, wild)
	print("[EncountersPass] choosing from ", overworld_choices.size(), "/", backup_choices.size(), "/", ranger_choices.size(), " monsters")

	var result = EncountersOverlay.new()
	var total_monsters = int(layout.plots.size() * self.enemy_density * extra_density)
	for _i in range(0, total_monsters):
		var monsters = select_monsters(overworld_choices, backup_choices, floor_number, rng)

		var is_fusion = EncountersUtil.calc_fusion(floor_number, rng)
		var encounter = result.add_monster_encounter()
		encounter.seed_value = rng.get_child_seed(encounter.id)
		encounter.overworld_form = monsters[0].overworld
		encounter.monsters = roll_tapes(floor_number, scaling, element_tag, monsters.size() > 2, is_fusion, monsters, rng)
		encounter.exp_multiplier = EncountersUtil.calc_exp_multiplier(floor_number, expboost)
		
		# If there is a fusion, it is always the last two monsters.
		if is_fusion && monsters.size() > 1:
			encounter.fusion = encounter.monsters.pop_back().tape

	# Allocate monsters to various spots on the map.
	# If we have a treasure room / priority room to pack them all in, place there first.
	var place_index = 0
	if priority_room >= 0:
		var plot_size = 1.5 * self.max_enemies_per_cell * layout.plots[priority_room].definition.count_cells()
		while place_index < plot_size && place_index < result.encounters.size():
			result.encounters[place_index].plot = priority_room
			place_index += 1

	for option in get_placement_options(layout, priority_room, rng):
		if place_index >= result.encounters.size():
			break
		result.encounters[place_index].plot = option
		place_index += 1

	if place_index < result.encounters.size():
		print("[EncountersPass] Couldn't place all monsters (", result.encounters.size(), ") dropping to: ", place_index)
		for _i in range(place_index, result.encounters.size()):
			result.encounters.pop_back()

	# Allocate a ranger to each room we want one. Currently this is just exit rooms.
	for plot in layout.plots:
		if !plot.is_exit():
			continue
		
		var ranger_monsters = select_ranger_monsters(ranger_choices, floor_number, area_number, rng)
		var partner_monsters = select_ranger_monsters(ranger_choices, floor_number, area_number, rng) if subfloor_number > 1 else []
		var encounter = result.add_ranger_encounter()
		encounter.seed_value = rng.get_child_seed(encounter.id)
		encounter.plot = plot.id
		encounter.ranger_tapes = roll_tapes(floor_number+1, scaling, element_tag, false, false, ranger_monsters, rng)
		encounter.partner_tapes = roll_tapes(floor_number+1, scaling, element_tag, false, false, partner_monsters, rng)
		encounter.exp_multiplier = EncountersUtil.calc_exp_multiplier(floor_number, expboost)

	print("[EncountersPass] Generated ", result.encounters.size(), " monsters, ", result.rangers.size(), " rangers")
	return result

func get_overworld_monsters(floor_number: int, area_number: int, tags: Array, wild: bool, rng: Random) -> Array:
	var mt = MonsterTable.get_global()
	if (wild || FloorTags.FT_CHAOS) in tags && floor_number > 2:
		return mt.get_overworld_subset_untiered(self.max_distinct_overworld, rng)
	else:
		var tier = min(4, max(1, area_number+1))
		return mt.get_overworld_subset(tier, self.max_distinct_overworld, rng)

func get_backup_monsters(floor_number: int, subfloor_number: int, area_number: int, tags: Array, wild: bool) -> Array:
	var mt = MonsterTable.get_global()
	if (wild || FloorTags.FT_CHAOS) in tags && floor_number > 6: # Don't make the floor & rangers brutal in the early game
		return mt.get_backup_untiered()
	else:
		var tier = min(4, max(1, area_number+1 if subfloor_number > 1 else area_number))
		return mt.get_backup(tier)

func select_monsters(overworld: Array, backup: Array, floor_number: int, rng: Random) -> Array:
	var result = [ rng.choice(overworld) ]

	# Reduce chances for duo/swarm fights in particular on very early floors
	if result[0].force_solo || floor_number <= 1 + rng.rand_int(2):
		return result
	
	var buddies = []
	for m in backup:
		if m.shares_tag_with(result[0]):
			buddies.push_back(m)
			
	if buddies.size() == 0:
		return result
	
	var num_buddies = 4 if EncountersUtil.calc_swarm(floor_number, rng) else 1
	if num_buddies == 4:
		var buddy = rng.choice(buddies)
		for _i in range(num_buddies):
			result.push_back(result[0] if rng.rand_float() < 0.5 else buddy)
	else:
		for _i in range(num_buddies):
			result.push_back(rng.choice(buddies))
	
	return result

func select_ranger_monsters(backup: Array, floor_number: int, area_number: int, rng: Random) -> Array:
	var result = [ rng.choice(backup), rng.choice(backup) ]
	if min(4, max(1, area_number+1)) > 3: result.push_back(rng.choice(backup))
	return result

func roll_tapes(floor_number: int, scaling: float, element_tag: String, is_swarm: bool, is_fusion: bool, monsters: Array, rng: Random) -> Array:
	var result = []
	var level_adj = (-1 if is_swarm else 0) + (1 if is_fusion else 0)
	for monster in monsters:
		var m = EncountersOverlay.EncounterTape.new()
		m.form = monster.form
		m.smartness = monster.smartness
		m.level = EncountersUtil.calc_level(floor_number, level_adj, monster.underlevel_max, monster.overlevel_max, scaling, rng)
		var xp = BattleFormulas.get_exp_to_level(m.level, self.exp_gradient, self.exp_base_level)
		
		m.tape = MonsterTape.new()
		m.tape.form = monster.form
		m.tape.seed_value = rng.rand_int()
		m.tape.type_override = EncountersUtil.calc_bootleg(floor_number, element_tag, is_fusion, scaling, rng)
		m.tape.assign_initial_stickers(true, rng)
		m.tape.apply_exp_points(xp, rng, MonsterTape.MAX_TAPE_GRADE)
		if m.tape.type_override.size() == 0:
			for move in monster.starter_stickers:
				if move is StickerItem:
					m.tape.stickers.push_front(move)
				elif move is BattleMove:
					m.tape.stickers.push_front(ItemFactory.create_sticker(move, rng))
		m.tape.fix_slot_overflow(true)
		result.push_back(m)

	return result

func get_placement_options(layout: PlotLayout, priority_room: int, rng: Random) -> Array:
	var result = []
	for plot in layout.plots:
		if plot.id != priority_room && plot.is_exit() != null:
			var n = plot.definition.count_cells() * self.max_enemies_per_cell
			while n > 0:
				result.push_back(plot.id)
				n -= 1
	
	rng.shuffle(result)
	return result
