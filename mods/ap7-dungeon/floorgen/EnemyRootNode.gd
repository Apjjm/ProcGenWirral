extends Node

const BattleScene = preload("res://mods/ap7-dungeon/monsters/DungeonBattle.tscn")
const FusionScene = preload("res://mods/ap7-dungeon/monsters/MonsterAttachmentFusion.tscn")
const SwarmScene = preload("res://mods/ap7-dungeon/monsters/MonsterAttachmentSwarm.tscn")

const DungeonMonsterCharacterConfig = preload("../monsters/DungeonMonsterCharacterConfig.gd")
const GeneratedFloor = preload("GeneratedFloor.gd")
const EncountersUtil = preload("encounters/EncountersUtil.gd")

const FusionLootTable = preload("res://data/loot_tables/battle_rogue_fusion.tres")

var encounter_id: int
var floor_data: GeneratedFloor

# Available after realisation
var enemy_rng: Random

static func find_enemy_root(node: Node) -> Node:
	return node.find_parent("DF_ENEMY_ROOT_*")

func realise():
	# Decide where we should go in the room, if there is a spot..
	var encounter = self.floor_data.encounters.get_monster_encounter(self.encounter_id)
	self.enemy_rng = Random.new(encounter.seed_value)
	
	var location = self._pick_location(self.enemy_rng)
	if location == null:
		#print("[EnemyRootNode] No space left for an enemy, dropping it")
		self.queue_free()
		return
	
	location.allocate_enemy()

	# Create encounter config
	var zone_info = self.floor_data.zones.get_resources_by_plot(get_parent().plot_id)
	var encounter_config = EncounterConfig.new()
	encounter_config.name = "EncounterConfig"
	encounter_config.seed_value = self.enemy_rng.get_child_seed(self.encounter_id)
	encounter_config.combine_with_player_seed = false
	encounter_config.loot_table_override = FusionLootTable if encounter.fusion else null
	encounter_config.background_override = zone_info.battle_background if zone_info != null else null
	encounter_config.music_override = null
	encounter_config.music_vox_override = null
	encounter_config.extra_exp_yield = int(encounter.exp_multiplier * EncountersUtil.DEFAULT_EXP_MONSTER_ENCOUNTER)
	encounter_config.can_flee = true
	encounter_config.battle_override = BattleScene
	encounter_config.connect("battle_completed", self, "_on_battle_completed")

	# Create characters for each monster. If fusion is enabled, the last pair should be fused.
	var character_config = null
	for monster in encounter.monsters:
		character_config = DungeonMonsterCharacterConfig.new()
		character_config.name = "CharacterConfig"
		character_config.level_override = monster.level
		character_config.level_scale_override_key = monster.smartness
		character_config.tapes = [ monster.tape ]
		character_config.exp_yield = int(encounter.exp_multiplier * EncountersUtil.DEFAULT_EXP_MONSTER)
		encounter_config.add_child(character_config)
	
	if encounter.fusion:
		character_config.tapes.push_back(encounter.fusion)

	# Create overworld
	var overworld = load(encounter.overworld_form).instance()
	overworld.name = "DF_MONSTER"
	overworld.add_child(encounter_config)
	
	if encounter.fusion:
		var fusion_node = FusionScene.instance()
		fusion_node.name = "FusionAttachment"
		overworld.add_child(fusion_node)

	if encounter.monsters.size() > 3:
		var swarm_node = SwarmScene.instance()
		swarm_node.name = "SwarmAttachment"
		overworld.add_child(swarm_node)
	
	add_child(overworld)
	overworld.global_transform = location.global_transform

func _pick_location(rng: Random) -> Spatial:
	var available = []
	for poi in get_parent().points_of_interest:
		if poi.can_be_enemy() && !poi.is_allocated():
			available.push_back(poi)
	
	return rng.choice(available)

func _on_battle_completed():
	var overworld = get_node("DF_MONSTER")
	var encounter = overworld.get_node("EncounterConfig")

	var tapes_left = 0
	var has_fusion = false
	for c in encounter.get_children():
		var count = c.count_tapes()
		tapes_left += count
		has_fusion = count == 2 || has_fusion
		if count == 0:
			c.queue_free()

	print("[EnemyRootNode] Battle completed. Tapes: ", tapes_left, " Fusion: ", has_fusion)
	if overworld.has_node("FusionAttachment") && !has_fusion:
		overworld.get_node("FusionAttachment").queue_free()

	if overworld.has_node("SwarmAttachment") && tapes_left < 3:
		overworld.get_node("SwarmAttachment").queue_free()
