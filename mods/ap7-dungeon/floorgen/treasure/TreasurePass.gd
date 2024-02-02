extends Node

const FloorTags = preload("../../FloorTags.gd")
const TreasureTable = preload("../../globals/TreasureTable.gd")
const TreasureOverlay = preload("TreasureOverlay.gd")
const PlotLayout = preload("../plotting/PlotLayout.gd")

export(float, 0, 10) var treasure_density = 1.2
export(int, 0, 10) var max_treasure_per_cell = 2
export(PackedScene) var treasure_chest = null

func generate_treasure(floor_number: int, floor_tags: Array, priority_room: int, layout: PlotLayout, rng: Random) -> TreasureOverlay:
	var treasure_table = TreasureTable.get_global()
	var extra_density = 1.25 if FloorTags.FT_TREASURE in floor_tags else 1.0
	var total_treasures = int(layout.plots.size() * self.treasure_density * extra_density)
	
	var result = TreasureOverlay.new()
	var last_entry = null 
	for i in range(0, total_treasures):
		# Hack to avoid runs in close proximity, even if the the rng was perfect identical items nearyby doesn't feel random.
		var entry = last_entry
		while entry == last_entry:
			entry = roll_entry(treasure_table, rng)
		
		var t = result.add_treasure()
		t.plot = -1
		t.item = entry.roll_item(roll_rarity(floor_number, rng), rng)
		t.quantity = roll_quantity(floor_number, t.item.value, rng) if entry.multiple else 1
		t.scene = self.treasure_chest
		t.loot_seed = rng.get_child_seed(i)
		last_entry = entry

	var place_index = 0
	if priority_room >= 0:
		var plot_size = self.max_treasure_per_cell * layout.plots[priority_room].definition.count_cells()
		while place_index < plot_size && place_index < result.treasures.size():
			result.treasures[place_index].plot = priority_room
			place_index += 1

	for option in get_placement_options(layout, priority_room, rng):
		if place_index >= result.treasures.size():
			break
		result.treasures[place_index].plot = option
		place_index += 1
	
	if place_index < result.treasures.size():
		print("[TreasurePass] Couldn't allocate plot for all treasures (", result.treasures.size(), ") dropping count to: ", place_index)
		result.treasures.resize(place_index)

	for tag in floor_tags:
		if FloorTags.KEY_ITEM_LOOKUP.has(tag):
			var t = result.add_key_item()
			t.plot = rng.rand_int(layout.plots.size()) # This is only a suggestion! We will force a placement by evicting other treasure
			t.item = load(FloorTags.KEY_ITEM_LOOKUP[tag])
			t.quantity = 1
			t.scene = self.treasure_chest # TODO: Different kind of treasure chest for key items?
			t.loot_seed = rng.get_child_seed(tag)

	print("[TreasurePass] Generated ", result.treasures.size(), " treasures & ", result.key_items.size(), " key items. Density: ", self.treasure_density)
	return result

func roll_entry(treasure_table: TreasureTable, rng: Random) -> TreasureTable.ItemEntry:
	var cat = rng.rand_int(100)
	var subcat = rng.rand_int(100)

	if cat < 39:
		if subcat < 9:
			return rng.choice(treasure_table.move_sigil)
		elif subcat < 40:
			return rng.choice(treasure_table.move_passive)
		else:
			return rng.choice(treasure_table.move_active)
	elif cat < 46:
		if subcat < 75:
			return rng.choice(treasure_table.heal_common)
		else:
			return rng.choice(treasure_table.heal_rare)
	elif cat < 67:
		if subcat < 95:
			return rng.choice(treasure_table.tape_common)
		else:
			return rng.choice(treasure_table.tape_rare)
	elif cat < 80:
		if subcat < 75:
			return rng.choice(treasure_table.battle_common)
		else:
			return rng.choice(treasure_table.battle_rare)
	elif cat < 85:
		return rng.choice(treasure_table.stat_up)
	else:
		if subcat < 90:
			return rng.choice(treasure_table.resource_common)
		else:
			return rng.choice(treasure_table.resource_rare)

func roll_rarity(floor_number: int, rng: Random) -> int:
	# For reference bootleg rarity is approx 17% common, 66% uncommon  17% rare
	# FL1: 40% common, 50% uncommon, 10% rare -> FL16: 10% common, 50% uncommon, 40% rare
	var p = rng.rand_int(100) + 2*max(floor_number-1, 0)
	if p < 40:
		return BaseItem.Rarity.RARITY_COMMON
	elif p < 90:
		return BaseItem.Rarity.RARITY_UNCOMMON
	else:
		return BaseItem.Rarity.RARITY_RARE

func roll_quantity(floor_number: int, cost: int, rng: Random) -> int:
	var min_value = floor_number * 125
	var max_value = floor_number * 175
	var value = min_value + rng.rand_int(max_value - min_value)
	return int(max(value/cost, 1.0))

func get_placement_options(layout: PlotLayout, priority_room: int, rng: Random):
	var result = []
	for plot in layout.plots:
		if plot.id != priority_room && plot.is_normal():
			var n = plot.definition.count_cells() * self.max_treasure_per_cell
			while n > 0:
				result.push_back(plot.id)
				n -= 1
	
	rng.shuffle(result)
	return result
