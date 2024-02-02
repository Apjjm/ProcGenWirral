extends CharacterConfig

const blank_monster = preload("res://data/characters/blank_monster.tres")#
export(Array, Resource) var tapes = []
export(String) var required_flag = ""
export(String) var deny_flag = ""
export(Resource) var loot_table_override = null

func _init():
	self.base_character = blank_monster

# Used by fixed encounters. Only applied on tree enter - so set flags BEFORE the battle!
func has_required_flags():
	if self.deny_flag != "" && SaveState.has_flag(self.deny_flag):
		return false

	return self.required_flag == "" || SaveState.has_flag(self.required_flag)

# Used by fixed encounters. First one seen is used in the absence of one on the encounter.
func get_loot_table_override():
	return self.loot_table_override


# Overrides to force level scaling off.
# The whole point of the floors is that they get more dangerous the deeper you go
# If you can tune level scaling to whatever the dungeon loses a big gameplay difference.
func get_level(_rand: Random, _defeat_count: int)->int:
	return self.level_override

# We do a bit of magic here - we want K.O'd monsters to stay K.O'd
# The trick to this is to use the same tapes in each fight.
# We repair up HP, but if a tape was broken, just don't generate a fighter.
func generate_fighter(rand: Random, defeat_count: int):
	var f : FighterNode
	
	f = FighterNode.new()
	f.team = self.team

	for tape in generate_tapes(rand, defeat_count, 0):
		var char_node = CharacterNode.new()
		char_node.character = _create_character(rand, defeat_count)
		char_node.active_tape = tape
		f.add_child(char_node)

	var controller = generate_fighter_controller(rand)
	f.add_child(controller)
	controller.fighter = f
	
	return f

func generate_tapes(_rand: Random, _defeat_count: int, _exp_points: int)->Array:
	var filtered = []
	for tape in self.tapes:
		if !tape.is_broken():
			tape.hp.set_to(1, 1)
			filtered.push_back(tape)

	assert(filtered.size() > 0)
	return filtered

# Nope! No pesky warnings to worry about here :)
func _get_configuration_warning():
	return ""

func count_tapes() -> int:
	var count = 0
	for tape in self.tapes:
		if !tape.is_broken():
			count += 1

	return count
