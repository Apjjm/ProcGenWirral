extends Node

var backup_all = []
var overworld_all = []
var monsters_by_tier = [[], [], [], [], [], []]
var backup_by_tier = [[], [], [], [], [], []]
var overworld_by_tier = [[], [], [], [], [], []]
var _setup = false

static func get_global() -> Node:
	var node = DLC.get_node("./Ap7Dungeon/MonsterTable")
	if !node._setup:
		node.setup()
		node._setup = true

	return node

func _init():
	name = "MonsterTable"

func setup():
	print(["[MonsterTable] Setup"])
	for monster in Datatables.load("res://mods/ap7-dungeon/monsters/configs/").table.values():
		if monster.form.require_dlc != "" && !DLC.has_dlc(monster.form.require_dlc): 
			continue

		monsters_by_tier[monster.floor_tier].push_back(monster)

		if !monster.force_solo: 
			backup_by_tier[monster.floor_tier].push_back(monster);
			backup_all.push_back(monster)
		
		if monster.overworld != "": 
			overworld_by_tier[monster.floor_tier].push_back(monster)
			overworld_all.push_back(monster)

func get_monsters(tier: int) -> Array:
	return monsters_by_tier[tier]

func get_backup(tier: int) -> Array:
	return backup_by_tier[tier]

func get_backup_untiered() -> Array:
	return backup_all

func get_overworld(tier: int) -> Array:
	return overworld_by_tier[tier]

func get_overworld_subset(tier: int, size: int, rng: Random) -> Array:
	var all = overworld_by_tier[tier].duplicate()
	if all.size() > size:
		rng.shuffle(all)
		all.resize(size)
	
	return all

func get_overworld_subset_untiered(size: int, rng: Random) -> Array:
	var all = overworld_all.duplicate()
	if all.size() > size:
		rng.shuffle(all)
		all.resize(size)
	
	return all

func get_unreachable_monsters() -> Array:
	var result = []
	for i in range(backup_by_tier.size()):
		for backup in backup_by_tier[i]:
			var found = false
			for overworld in overworld_by_tier[i]:
				if overworld.shares_tag_with(backup):
					found = true
					break

			if !found:
				result.push_back(backup)

	return result