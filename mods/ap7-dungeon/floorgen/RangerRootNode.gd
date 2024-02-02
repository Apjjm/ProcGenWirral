extends Node

const RangerNpcScene = preload("res://mods/ap7-dungeon/monsters/DungeonHumanNPC.tscn")
const BattleScene = preload("res://mods/ap7-dungeon/monsters/DungeonBattle.tscn")
const DungeonRangerCharacterConfig = preload("../monsters/DungeonRangerCharacterConfig.gd")
const GeneratedFloor = preload("GeneratedFloor.gd")
const EncountersUtil = preload("encounters/EncountersUtil.gd")

var encounter_id: int
var floor_data: GeneratedFloor

# Available after realisation
var enemy_rng: Random

static func find_ranger_root(node: Node) -> Node:
	return node.find_parent("DF_RANGER_ROOT_*")

func realise():
	# Decide where we should go in the room, if there is a spot..
	var encounter = self.floor_data.encounters.get_ranger_encounter(self.encounter_id)
	self.enemy_rng = Random.new(encounter.seed_value)
	
	var location = self._pick_location(self.enemy_rng)
	if location == null:
		print("[RangerRootNode] No space left for ranger, dropping it")
		self.queue_free()
		return
	
	location.allocate_ranger()

	# Create encounter config
	var name1 = "AP7_DUNGEON_RANGER_PRIMARY" + str(self.enemy_rng.rand_int(10))
	var name2 = "AP7_DUNGEON_RANGER_SIDEKICK" + str(self.enemy_rng.rand_int(10))
	var zone_info = self.floor_data.zones.get_resources_by_plot(get_parent().plot_id)
	var encounter_config = EncounterConfig.new()
	encounter_config.name = "EncounterConfig"
	encounter_config.seed_value = self.enemy_rng.get_child_seed(self.encounter_id)
	encounter_config.combine_with_player_seed = false
	encounter_config.background_override = zone_info.battle_background if zone_info != null else null
	encounter_config.music_override = zone_info.boss_novox if zone_info != null else null
	encounter_config.music_vox_override = zone_info.boss_vox if zone_info != null else null
	encounter_config.extra_exp_yield = int(encounter.exp_multiplier * EncountersUtil.DEFAULT_EXP_RANGER_ENCOUNTER)
	encounter_config.can_flee = false # Can't flee a ranger battle - so we don't need to do tape hackery
	encounter_config.enable_ai_fusion = encounter.ranger_tapes.size() > 1 && encounter.partner_tapes.size() > 1
	encounter_config.battle_override = BattleScene
	_add_character_config(name1, encounter_config, encounter.ranger_tapes, encounter.exp_multiplier, true)
	_add_character_config(name2, encounter_config, encounter.partner_tapes, encounter.exp_multiplier, false)

	if encounter_config.get_child_count() == 0:
		push_error("[RangerRootNode] Expected at least one character on ranger encounter, dropping it")
		self.queue_free()
		return

	# Create the overworld object
	var overworld = RangerNpcScene.instance()
	overworld.randomize_sprite(self.enemy_rng)
	overworld.name = "DF_RANGER"
	overworld.npc_name = name1
	overworld.initial_direction = Direction.get_nearest_xz(location.global_transform.basis.xform(Vector3.FORWARD))
	overworld.add_child(encounter_config)
	
	add_child(overworld)
	overworld.global_transform = location.global_transform

	# TODO: Add interaction behaviour
	
func _add_character_config(char_name: String, encounter_config: EncounterConfig, encounter_tapes: Array, exp_mul: float, is_primary: bool):
	if encounter_tapes.size() > 0:
		var tapes = []
		for tape in encounter_tapes:
			tapes.append(tape.tape)

		var character_config = DungeonRangerCharacterConfig.new()
		character_config.name = "Primary" if is_primary else "Sidekick"
		character_config.level_override = encounter_tapes[0].level
		character_config.level_scale_override_key = "npc_boss" if is_primary else "npc"
		character_config.tapes = tapes
		character_config.exp_yield = int(exp_mul * EncountersUtil.DEFAULT_EXP_RANGER)
		character_config.disable_overspill_damage = true
		character_config.character_kind = Character.CharacterKind.HUMAN
		character_config.randomize_human_sprite = !is_primary
		character_config.copy_human_sprite = NodePath("../..") if is_primary else NodePath("")
		character_config.character_name = char_name
		encounter_config.add_child(character_config)

func _pick_location(rng: Random) -> Spatial:
	var available = []
	for poi in get_parent().points_of_interest:
		if poi.can_be_ranger() && !poi.is_allocated():
			available.push_back(poi)
	
	return rng.choice(available)
