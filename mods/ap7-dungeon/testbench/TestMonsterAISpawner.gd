extends Node

const PlayerMotionTracker = preload("../player/PlayerMotionTracker.gd")
const DungeonMonsterCharacterConfig = preload("../monsters/DungeonMonsterCharacterConfig.gd")

var overworld_monsters = []
var spawn_button = null
var monsters_list = null

func _ready():
	spawn_button = find_node("SpawnButton")
	monsters_list = find_node("MonsterList")
	spawn_button.connect("pressed", self, "_on_spawn_pressed")

	var all_monster_configs = Datatables.load("res://mods/ap7-dungeon/monsters/configs").table
	var all_keys = all_monster_configs.keys()
	all_keys.sort()

	for key in all_keys:
		var monster = all_monster_configs[key]
		if monster.form.require_dlc != "" && !DLC.has_dlc(monster.form.require_dlc):
			continue
			
		if monster.overworld != "":
			var parts = key.replace(".tres", "").split("/")
			self.monsters_list.add_item(parts[parts.size()-1])
			self.overworld_monsters.push_back(monster)

func _on_spawn_pressed():
	if !PlayerMotionTracker.has_motion_tracker():
		print("[Floor] attaching player motion tracker")
		var motion_tracker = PlayerMotionTracker.new()
		motion_tracker.attach_to_player()
		
	var x = 0.0
	for index in self.monsters_list.get_selected_items():
		_spawn_monster(self.overworld_monsters[index], Vector3(x, 0, 0))
		x += 2

func _spawn_monster(monster, pos):
	print("spawning: " + monster.form.name)

	var monster_tape = MonsterTape.new()
	monster_tape.form = monster.form
	monster_tape.assign_initial_stickers(true)

	var encounter_config = EncounterConfig.new()
	encounter_config.name = "EncounterConfig"
	encounter_config.can_flee = true

	var character_config = DungeonMonsterCharacterConfig.new()
	character_config.name = "CharacterConfig"
	character_config.level_override = 5
	character_config.tapes = [ monster_tape ]
	encounter_config.add_child(character_config)

	var overworld = load(monster.overworld).instance()
	overworld.name = "SPAWNED_MONSTER"
	overworld.translation = pos
	overworld.add_child(encounter_config)
	add_child(overworld)
