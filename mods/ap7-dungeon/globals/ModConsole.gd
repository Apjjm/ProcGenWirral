extends Node

const DungeonData = preload("DungeonData.gd")
const PlayerData = preload("PlayerData.gd")
const SigilMoves = preload("SigilMoves.gd")
const MonsterTable = preload("MonsterTable.gd")

export(bool) var dev_commands = false

func _init():
	name = "ConsoleCommands"

func _ready():
	Console.register("dfgen", {
		"description":"Generate a fresh dungeon floor layout with given seed. dfgen 0 uses random seed.", 
		"args":[TYPE_INT], 
		"target":[self, "_console_df_gen"]
	})
	Console.register("dfset", {
		"description":"Set the seed of the current floor to the given value and reroll. dfset 0 uses random seed.", 
		"args":[TYPE_INT], 
		"target":[self, "_console_df_seed"]
	})
	Console.register("dftag", {
		"description":"Add a tag to the current floor and reroll", 
		"args":[TYPE_STRING], 
		"target":[self, "_console_df_tag"]
	})
	Console.register("dfnext", {
		"description":"Go to the dungeon next floor", 
		"args":[],
		"target":[self, "_console_df_next"]
	})
	Console.register("dflast", {
		"description":"Go to the last dungeon floor", 
		"args":[],
		"target":[self, "_console_df_last"]
	})
	Console.register("dfexit", {
		"description":"Exit the dungeon, and restore all player state. No loot is given.", 
		"args":[], 
		"target":[self, "_console_df_exit"]
	})
	
	if !dev_commands:
		return
		
	Console.register("dfitems", {
		"description":"Adds sigils & key items to the inventory. Not for use out of the dungeon.", 
		"args":[], 
		"target":[self, "_console_df_items"]
	})
	Console.register("dfmoncheck", {
		"description":"Checks all defined monster profiles can be seen as overworld / backup.", 
		"args":[], 
		"target":[self, "_console_df_moncheck"]
	})
	Console.register("dfkuneko", {
		"description":"Prints info about & advances the kuneko quest (if started).",
		"args":[],
		"target":[self, "_console_df_kuneko"]
	})
	Console.register("amt", {
		"description":"Attach tracker node to player", 
		"args":[], 
		"target":[self, "_console_add_playertracker"]
	})
	Console.register("rmt", {
		"description":"Remove tracker node from player", 
		"args":[], 
		"target":[self, "_console_remove_playertracker"]
	})
	Console.register("rrls", {
		"description":"Really reload the scene - don't just remount it", 
		"args":[], 
		"target":[self, "_console_reload_scene"]
	})

func _console_reload_scene():
	SceneManager.change_scene(SceneManager.current_scene.filename, { "disable_preservation": true, "disable_reentering": true })

func _console_add_playertracker():
	var PlayerMotionTracker = load("res://mods/ap7-dungeon/player/PlayerMotionTracker.gd")
	var pmt = PlayerMotionTracker.new()
	if pmt.attach_to_player():
		Console.writeLine("Attached a PlayerMotionTracker")

func _console_remove_playertracker():
	var PlayerMotionTracker = load("res://mods/ap7-dungeon/player/PlayerMotionTracker.gd")
	var pmt = PlayerMotionTracker.find_motion_tracker()
	if pmt != null:
		pmt.queue_free()
		Console.writeLine("Removed a PlayerMotionTracker")

func _console_df_gen(s: int):
	var dungeon_seed = randi() if s == 0 else s
	var pd = PlayerData.get_global()
	if !pd.has_dungeon_player():
		Console.writeLine("  pushing current player state...")
		pd.push_dungeon_player(dungeon_seed)

	Console.writeLine("  generating floors...")
	var di = DungeonData.get_global().generate_dungeon(dungeon_seed)
	
	Console.writeLine("  going to floor 1...")
	di.move_to_next_normal_floor().warp_to()

func _console_df_seed(s: int):
	var floor_seed = randi() if s == 0 else s
	var di = DungeonData.get_global().get_current_dungeon()
	if di != null && di.has_current_floor():
		if di != null && di.has_current_floor():
			var fi = di.get_current_floor()
			fi.set_floor_seed(floor_seed)
			fi.warp_to()
		else:
			Console.writeLine("no floor available")

func _console_df_tag(tag: String):
	var di = DungeonData.get_global().get_current_dungeon()
	if di != null && di.has_current_floor():
		var fi = di.get_current_floor()
		fi.add_tag(tag)
		fi.warp_to()
	else:
		Console.writeLine("no floor available")

func _console_df_next():
	var pd = PlayerData.get_global()
	var di = DungeonData.get_global().get_current_dungeon()
	var fi = di.move_to_next_normal_floor() if di != null else null
	if fi != null:
		pd.push_inner_player()
		Console.writeLine("floor " + str(fi.floor_number()) + " " + str(fi.tags()))
		fi.warp_to()
	else:
		Console.writeLine("no next floor available")

func _console_df_last():
	var pd = PlayerData.get_global()
	var di = DungeonData.get_global().get_current_dungeon()
	var fi = di.move_to_last_normal_floor() if di != null else null
	if fi != null:
		pd.push_inner_player()
		Console.writeLine("floor " + str(fi.floor_number()) + " - " + fi.floor_scene())
		fi.warp_to()
	else:
		Console.writeLine("no next floor available")

func _console_df_exit():
	var pd = PlayerData.get_global()
	if pd.has_dungeon_player():
		Console.writeLine("  restoring player state...")
		pd.pop_dungeon_player()
	
	DungeonData.get_global().clear_dungeon()	
	var args = { 
		"dungeon_defeated": false, 
		"dungeon_completed": false,
		"dungeon_tapes": [],
		"dungeon_items": [],
		"dungeon_floor": 1,
		"warp_target": { "name": "ExitDungeon", "chunk": null }
	} 
	SceneManager.change_scene("res://mods/ap7-dungeon/floors/Djinntermission.tscn", args)

func _console_df_moncheck():
	Console.writeLine("Enumerating unreachable monsters:")
	for monster in MonsterTable.get_global().get_unreachable_monsters():
		Console.writeLine(" - " + Loc.tr(monster.form.name))

func _console_df_items():
	var items = []
	for sigil in SigilMoves.get_global().all_sigils:
		items.push_back({ item=ItemFactory.create_sticker(sigil), amount=1 })

	items.push_back({ item=ItemFactory.generate_item(load("res://data/items/ap7_dungeon_rerecord.tres")), amount = 1 })
	items.push_back({ item=ItemFactory.generate_item(load("res://data/items/ap7_key_secret_ranger.tres")), amount = 1 })
	items.push_back({ item=ItemFactory.generate_item(load("res://data/items/ap7_key_secret_inn.tres")), amount = 1 })
	MenuHelper.give_items(items)

func _console_df_kuneko():
	var started = SaveState.has_flag("AP7_DUNGEON_KUNEKO_QUEST_STARTED")
	var shrine = SaveState.has_flag("AP7_DUNGEON_KUNEKO_QUEST_SHRINE")
	var ko = SaveState.has_flag("AP7_DUNGEON_KUNEKO_QUEST_KO")
	var completed = SaveState.has_flag("AP7_DUNGEON_KUNEKO_QUEST_COMPLETED")
	var state = "Started: " + str(started) + " Shrine: " + str(shrine) + " KO: " + str(ko) + " Completed: " + str(completed)
	Console.writeLine("Quest state - " + state)
	
	if started && !ko:
		Console.writeLine("Battle flag completed")
		SaveState.set_flag("AP7_DUNGEON_KUNEKO_QUEST_KO", true)
	elif started && !shrine:
		Console.writeLine("Shrine flag completed")
		SaveState.set_flag("AP7_DUNGEON_KUNEKO_QUEST_SHRINE", true)