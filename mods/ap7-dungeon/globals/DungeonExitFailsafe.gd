extends Node

const DungeonData = preload("DungeonData.gd")
const PlayerData = preload("PlayerData.gd")

var check_areas = [ WorldSystem.GAME_OVER_SCENE, WorldSystem.DEFAULT_SCENE, "res://world/maps/dungeon_mall/Mall.tscn" ]

func _ready():
	SceneManager.connect("scene_changed", self, "_on_scene_changed")

func _on_scene_changed():
	var scn = SceneManager.current_scene
	if scn is LevelMap && scn.filename in self.check_areas:
		var dd = DungeonData.get_global()
		var pd = PlayerData.get_global()
		if dd == null || pd == null || dd.get_current_dungeon() == null:
			return

		if pd.has_dungeon_player():
			print("[DungeonExitFailsafe] Possibly escaped dungeon area. Scene: ", scn.filename)
		else:
			print("[DungeonExitFailsafe] Possibly escaped dungeon area. No active player. Scene: ", scn.filename)

		if SceneManager.transitioning && SceneManager.transitioned_out:
			yield (SceneManager, "scene_change_ending")

		yield(Co.next_frame(), "completed") # Give cutscenes a chance to start
		while WorldSystem.get_flags() != WorldSystem.INITIAL_FLAGS:
			yield(Co.next_frame(), "completed")

		var choice = yield(_ask_about_warp(), "completed")
		if choice == 0:
			_warp_back_to_dungeon(dd, pd)
		elif choice == 1:
			_exit_in_place(dd, pd)

func _ask_about_warp():
	WorldSystem.push_flags(WorldSystem.WorldFlags.PHYSICS_ENABLED)
	GlobalMessageDialog.clear_state()
	yield (GlobalMessageDialog.show_message("AP7_DUNGEON_EXITED_FAILSAFE_MSG", false, false), "completed")
	var choice = yield (GlobalMenuDialog.show_menu(["AP7_DUNGEON_EXITED_FAILSAFE_WARP", "AP7_DUNGEON_EXITED_FAILSAFE_EXIT"], 0), "completed")
	yield (GlobalMessageDialog.hide(), "completed")
	WorldSystem.pop_flags()

	return choice

func _exit_in_place(dd, pd):
	print("[DungeonExitFailsafe] Performing exit in place")
	if pd.has_dungeon_player():
		pd.pop_dungeon_player()
	dd.clear_dungeon()

func _warp_back_to_dungeon(dd, pd):
	print("[DungeonExitFailsafe] Attempting warp back to dungeon")
	var di = dd.get_current_dungeon()
	if di.has_current_floor():
		di.get_current_floor().warp_to()
	else:
		_exit_in_place(dd, pd)
