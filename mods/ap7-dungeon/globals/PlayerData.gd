extends Node

const SAVE_KEY_NAME_OUTER_PLAYER = "ap7_dungeon_outer_player"
const SAVE_KEY_NAME_INNER_PLAYER = "ap7_dungeon_inner_player"

const TapeBasic = preload("res://data/items/tape_basic.tres")
const TapeChrome = preload("res://data/items/tape_chrome.tres")
const Rewind = preload("res://data/items/rewind.tres")
const Respool = preload("res://data/items/respool.tres")
const Reodorant = preload("res://data/items/reodorant.tres")
const CureAll = preload("res://data/items/cure_all.tres")

static func get_global() -> Node:
	return DLC.get_node("./Ap7Dungeon/PlayerData")

func _init():
	name = "PlayerData"

func clear_info():
	SaveState.other_data.erase(SAVE_KEY_NAME_OUTER_PLAYER)

func has_dungeon_player():
	return SaveState.other_data.has(SAVE_KEY_NAME_OUTER_PLAYER)

func has_inner_player():
	return SaveState.other_data.has(SAVE_KEY_NAME_INNER_PLAYER)

func push_dungeon_player(initial_seed: String):
	if has_dungeon_player():
		push_error("[PlayerData] A dungeon player state is already pushed. Not pushing another.")
		return

	print("[PlayerData] Pushing outer player state")
	make_snapshot(SAVE_KEY_NAME_OUTER_PLAYER)
	
	var player = SaveState.party.get_player()
	var partner = SaveState.party.get_partner()

	var kept_items = _get_kept_items()
	SaveState.inventory.clear()
	SaveState.inventory.stack_limit_increases.clear()
	SaveState.tape_collection.clear()
	SaveState.flags["encounter_aa_oldgante"] = false # Hack: Block ability unlocks & fast-travel-flee
	SaveState.abilities["train_travel"] = false

	# Reset multi-floor dungeon quests
	SaveState.flags["AP7_DUNGEON_KUNEKO_QUEST_SHRINE"] = false 
	SaveState.flags["AP7_DUNGEON_KUNEKO_QUEST_KO"] = false
	SaveState.flags["AP7_DUNGEON_KUNEKO_QUEST_STARTED"] = false
	SaveState.flags["AP7_DUNGEON_KUNEKO_QUEST_COMPLETED"] = false
	SaveState.flags["AP7_DUNGEON_LK_INTRO1"] = false
	SaveState.flags["AP7_DUNGEON_LK_INTRO2"] = false
	SaveState.flags["AP7_VOLATILE_RANGER_DEFEATED"] = false
	SaveState.flags["AP7_DUNGEON_MIDPOINT_SIGIL"] = false
	SaveState.stats.get_stat("exchange_purchased").clear()

	player.set_level(5)
	player.exp_points = 0
	player.hp.set_to(1,1)
	player.tapes.clear()
	player.boost_max_hp = 0
	player.boost_melee_attack = 0
	player.boost_melee_defense = 0
	player.boost_ranged_attack = 0
	player.boost_ranged_defense = 0
	player.boost_speed = 0
	
	partner.set_level(5)
	partner.exp_points = 0
	partner.hp.set_to(1,1)
	partner.tapes.clear()
	
	var rng = Random.new(initial_seed)
	var forms = get_starter_forms(rng)
	player.tapes.push_back(make_starter_tape(forms.pop_back()))
	partner.tapes.push_back(make_starter_tape(forms.pop_back()))

	SaveState.inventory.add_item(TapeBasic, 5)
	SaveState.inventory.add_item(TapeChrome, 1)
	SaveState.inventory.add_item(Rewind, 5)
	SaveState.inventory.add_item(Respool, 1)
	SaveState.inventory.add_item(Reodorant, 1)
	SaveState.inventory.add_item(CureAll, 1)
	for item_def in kept_items:
		SaveState.inventory.add_item(item_def.item, item_def.amount)

	make_snapshot(SAVE_KEY_NAME_INNER_PLAYER)

func pop_dungeon_player():
	if !has_dungeon_player():
		push_error("[PlayerData] A dungeon player state is not pushed. Not restoring player state.")
		return

	print("[PlayerData] Apply outer player state (restoring dungeon start player)")
	restore_snapshot(SAVE_KEY_NAME_OUTER_PLAYER)
	SaveState.other_data.erase(SAVE_KEY_NAME_OUTER_PLAYER)
	SaveState.other_data.erase(SAVE_KEY_NAME_INNER_PLAYER)

# We also keep track of the state of the player at the start of each floor.
# We can't (easily) save the state of the floor perfectly, so instead we can just treat loading as a save from the floor start.
# To do that, we need to keep hold of a snapshot of the player state when they enter the floor so we can re-apply it on load.
func push_inner_player():
	print("[PlayerData] Pushing inner player state")
	make_snapshot(SAVE_KEY_NAME_INNER_PLAYER)

func apply_inner_player():
	if SaveState.other_data.has(SAVE_KEY_NAME_INNER_PLAYER):
		print("[PlayerData] Apply inner player state (restoring floor start player)")
		restore_snapshot(SAVE_KEY_NAME_INNER_PLAYER)

func make_snapshot(key: String):
	var player = SaveState.party.get_player()
	var partner = SaveState.party.get_partner()

	SaveState.other_data[key] = {
		"mod_version": 1,
		"game_version": SaveState.CURRENT_VERSION,
		"inventory": SaveState.inventory.get_snapshot(),
		"tape_collection": SaveState.tape_collection.get_snapshot(),
		"abilities": SaveState.abilities.duplicate(),
		"flags": SaveState.flags.duplicate(),
		"player": make_char_snapshot(player),
		"partner": make_char_snapshot(partner),
		"exchange_purchased": SaveState.stats.get_stat("exchange_purchased").get_snapshot()
	}

func restore_snapshot(key: String):
	var snap = SaveState.other_data[key]
	if snap.mod_version > 1:
		push_error("[PlayerData] Future version could not be loaded")
		return

	var player = SaveState.party.get_player()
	var partner = SaveState.party.get_partner_by_id(snap.partner.partner_id)
	if partner == null:
		push_error("[PlayerData] Error finding partner by id. Assuming current partner is who was pushed.")
		partner = SaveState.party.get_partner()

	if !SaveState.inventory.set_snapshot(snap.inventory, snap.game_version):
		push_error("[PlayerData] Incompatibility restoring inventory")

	if !SaveState.tape_collection.set_snapshot(snap.tape_collection, snap.game_version):
		push_error("[PlayerData] Incompatibility restoring tape collection")

	if !SaveState.stats.get_stat("exchange_purchased").set_snapshot(snap.exchange_purchased, snap.game_version):
		push_error("[PlayerData] Incompatibility restoring exchanges purchased")

	SaveState.flags["encounter_aa_oldgante"] = snap.flags.get("encounter_aa_oldgante", false)
	SaveState.abilities["train_travel"] = snap.abilities.get("train_travel", false)
	
	SaveState.flags["AP7_DUNGEON_KUNEKO_QUEST_SHRINE"] = snap.flags.get("AP7_DUNGEON_KUNEKO_QUEST_SHRINE", false)
	SaveState.flags["AP7_DUNGEON_KUNEKO_QUEST_KO"] = snap.flags.get("AP7_DUNGEON_KUNEKO_QUEST_KO", false)
	SaveState.flags["AP7_DUNGEON_KUNEKO_QUEST_STARTED"] = snap.flags.get("AP7_DUNGEON_KUNEKO_QUEST_STARTED", false)
	SaveState.flags["AP7_DUNGEON_KUNEKO_QUEST_COMPLETED"] = snap.flags.get("AP7_DUNGEON_KUNEKO_QUEST_COMPLETED", false)
	SaveState.flags["AP7_DUNGEON_LK_INTRO1"] = snap.flags.get("AP7_DUNGEON_LK_INTRO1", false)
	SaveState.flags["AP7_DUNGEON_LK_INTRO2"] = snap.flags.get("AP7_DUNGEON_LK_INTRO2", false)
	SaveState.flags["AP7_VOLATILE_RANGER_DEFEATED"] = snap.flags.get("AP7_VOLATILE_RANGER_DEFEATED", false)
	SaveState.flags["AP7_DUNGEON_MIDPOINT_SIGIL"] = snap.flags.get("AP7_DUNGEON_MIDPOINT_SIGIL", false)
	
	set_char_snapshot(player, snap.player, snap.game_version)
	set_char_snapshot(partner, snap.partner, snap.game_version)

func make_char_snapshot(c: Character) -> Dictionary:
	var tapes = []
	for tape in c.tapes:
		tapes.push_back(tape.get_snapshot())

	return { "level": c.level, "exp_points": c.exp_points, "tapes": tapes, "partner_id": c.partner_id, "boost_max_hp": c.boost_max_hp, "boost_melee_attack": c.boost_melee_attack, "boost_melee_defense": c.boost_melee_defense, "boost_ranged_attack": c.boost_ranged_attack, "boost_ranged_defense": c.boost_ranged_defense, "boost_speed": c.boost_speed  }

func set_char_snapshot(c: Character, s: Dictionary, v: int):
	c.level = int(s.level)
	c.exp_points = int(s.exp_points)
	c.boost_max_hp = int(s.get("boost_max_hp", 0))
	c.boost_melee_attack = int(s.get("boost_melee_attack", 0))
	c.boost_melee_defense = int(s.get("boost_melee_defense", 0))
	c.boost_ranged_attack = int(s.get("boost_ranged_attack", 0))
	c.boost_ranged_defense = int(s.get("boost_ranged_defense", 0))
	c.boost_speed = int(s.get("boost_speed", 0))
	c.tapes.clear()
	for tape_snap in s.tapes:
		var tape = MonsterTape.new()
		if tape.set_snapshot(tape_snap, v):
			c.tapes.push_back(tape)
		else:
			push_error("[PlayerData] Incompatibility restoring character tape")

func get_starter_forms(rng: Random) -> MonsterTape:
	var available = []
	for form in MonsterForms.basic_forms.values():
		if form.require_dlc != "" && !DLC.has_dlc(form.require_dlc):
			continue
			
		if !MonsterForms.pre_evolution.has(form) && SaveState.species_collection.has_seen_species(form):
			available.push_back(form)

	rng.shuffle(available)
	return available

func make_starter_tape(form) -> MonsterTape:
	var tape = MonsterTape.new()
	tape.form = form
	tape.favorite = true
	tape.assign_initial_stickers(true)
	return tape

func _get_kept_items() -> Array:
	var result = []
	for item_node in SaveState.inventory.get_all_items():
		if item_node.get_category() == "misc":
			result.push_back({"item": item_node.item, "amount": item_node.amount })
	
	return result
