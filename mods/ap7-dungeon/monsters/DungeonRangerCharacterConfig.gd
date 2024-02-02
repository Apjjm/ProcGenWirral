extends "DungeonMonsterCharacterConfig.gd"

const blank_npc = preload("res://data/characters/generic_npc.tres")

export (int, 0, 10) var max_ap:int = 5
export (int, 0, 1000) var base_max_hp:int = Character.STAT_BASE
export (int, 0, 1000) var base_melee_attack:int = Character.STAT_BASE
export (int, 0, 1000) var base_melee_defense:int = Character.STAT_BASE
export (int, 0, 1000) var base_ranged_attack:int = Character.STAT_BASE
export (int, 0, 1000) var base_ranged_defense:int = Character.STAT_BASE

func _init():
	self.base_character = blank_npc

func generate_fighter(rand: Random, defeat_count: int):
	var f : FighterNode
	
	f = FighterNode.new()
	f.team = self.team

	var character = _create_character(rand, defeat_count)
	character.tapes = generate_tapes(rand, defeat_count, 0)
	character.max_ap = max(character.max_ap, self.max_ap)
	character.base_max_hp = max(character.base_max_hp, self.base_max_hp)
	character.base_melee_attack = max(character.base_melee_attack, self.base_melee_attack)
	character.base_melee_defense = max(character.base_melee_defense, self.base_melee_defense)
	character.base_ranged_attack = max(character.base_ranged_attack, self.base_ranged_attack)
	character.base_ranged_defense = max(character.base_ranged_defense, self.base_ranged_defense)
	
	var char_node = CharacterNode.new()
	char_node.character = character
	char_node.active_tape = character.tapes[0]
	f.add_child(char_node)

	var controller = generate_fighter_controller(rand)
	f.add_child(controller)
	controller.fighter = f
	
	return f
