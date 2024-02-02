extends Spatial

const FloorInfo = preload("../FloorInfo.gd")
const DungeonData = preload("../globals/DungeonData.gd")
const EncountersUtil = preload("../floorgen/encounters/EncountersUtil.gd")
const RandomParcelRngRoot = preload("../parcels/RandomParcelRngRoot.gd")
const BattleScene = preload("DungeonBattle.tscn")
const DungeonRangerCharacterConfig = preload("DungeonRangerCharacterConfig.gd")
const DungeonMonsterCharacterConfig = preload("DungeonMonsterCharacterConfig.gd")

export(bool) var randomize_npc_sprite = false
export(Resource) var battle_background = null
export(Resource) var music_novox = null
export(Resource) var music_vox = null
export(bool) var enable_fusion = false
export(bool) var can_flee = false
export(int) var encounter_exp = EncountersUtil.DEFAULT_EXP_RANGER
export(Resource) var title_banner = null
export(bool) var copy_human_sprite = false
export(int) var max_tapes_per_char = -1;
export(Resource) var loot_table_override = null
export(int,-99,99) var floor_level_offset = 0
export(int,0,99) var floor_level_underlevel = 0
export(int,0,99) var floor_level_overlevel = 1

func _ready():
	if self.randomize_npc_sprite:
		var pawn = get_pawn()
		var rng = get_rng()
		if pawn.has_method("randomize_sprite"):
			pawn.randomize_sprite(rng)

func _enter_tree():
	refresh_encounters()

func refresh_encounters():
	var rng = get_rng()
	var pawn = get_pawn()
	var dd = DungeonData.get_global() # Workaround for init from editor
	var fi = dd.get_current_floor_or_default() if dd != null else FloorInfo.new({})
	var exp_mul = EncountersUtil.calc_exp_multiplier(fi.floor_number())

	for c in pawn.get_children():
		if c is EncounterConfig:
			pawn.remove_child(c)
			c.queue_free()

	var encounter_config = EncounterConfig.new()
	encounter_config.name = "EncounterConfig"
	encounter_config.seed_value = rng.rand_int()
	encounter_config.combine_with_player_seed = false
	encounter_config.background_override = self.battle_background
	encounter_config.music_override = self.music_novox
	encounter_config.music_vox_override = self.music_vox
	encounter_config.extra_exp_yield = int(self.encounter_exp * exp_mul)
	encounter_config.can_flee = self.can_flee
	encounter_config.enable_ai_fusion = self.enable_fusion
	encounter_config.battle_override = BattleScene
	encounter_config.title_banner = title_banner
	encounter_config.loot_table_override = loot_table_override
	pawn.add_child(encounter_config)

	var should_copy_sprite = self.copy_human_sprite
	for old_config in get_configs(rng):
		var config = old_config.duplicate()
		encounter_config.add_child(config)
		
		config.tapes = []
		config.level_override = EncountersUtil.calc_level(fi.floor_number(), self.floor_level_offset, self.floor_level_underlevel, self.floor_level_overlevel, rng)
		config.exp_yield = int(self.encounter_exp * exp_mul)
		if should_copy_sprite:
			config.copy_human_sprite = config.get_path_to(pawn)
		elif !config.copy_human_sprite.is_empty():
			config.copy_human_sprite = config.get_path_to(pawn.get_node(config.copy_human_sprite))
		should_copy_sprite = false
		
		for t in old_config.tapes:
			config.tapes.push_back(t.duplicate())
		
		if encounter_config.loot_table_override == null && config.has_method("get_loot_table_override"):
			encounter_config.loot_table_override = config.get_loot_table_override()


func get_pawn() -> NPC:
	for n in get_children():
		if n is NPC:
			return n

	return null

func get_configs(rng: Random) -> Array:
	var result = []
	for n in get_children():
		if n is DungeonMonsterCharacterConfig && !n.has_required_flags():
			continue

		if n is DungeonRangerCharacterConfig:
			var copy = n.duplicate()
			copy.tapes = get_tape_copies(n.tapes)
			rng.shuffle(copy.tapes)
			if self.max_tapes_per_char > 0 && self.max_tapes_per_char < copy.tapes.size():
				copy.tapes.resize(self.max_tapes_per_char)
			result.push_back(copy)
		elif n is CharacterConfig:
			var copy = n.duplicate()
			copy.tapes = get_tape_copies(n.tapes)
			result.push_back(copy)

	return result


func get_tape_copies(tapes: Array) -> Array:
	var result = []
	for tape in tapes:
		result.push_back(tape.duplicate())

	return result

func get_rng() -> Random:
	var root = RandomParcelRngRoot.find_rng_root(self)
	return root.enemy_rng.get_child(self.name)
