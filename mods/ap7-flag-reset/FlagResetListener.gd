extends Node

var check_areas = [ WorldSystem.GAME_OVER_SCENE, WorldSystem.DEFAULT_SCENE ]

func _ready():
	SceneManager.connect("scene_changed", self, "_on_scene_changed")

func _on_scene_changed():
	var scn = SceneManager.current_scene
	if scn is LevelMap && scn.filename in self.check_areas:

		if SceneManager.transitioning && SceneManager.transitioned_out:
			yield (SceneManager, "scene_change_ending")

		yield(Co.next_frame(), "completed")
		while WorldSystem.get_flags() != WorldSystem.INITIAL_FLAGS:
			yield(Co.next_frame(), "completed")

		var choice = yield(_ask_about_flags(), "completed")
		if choice == 0:
			SaveState.flags["encounter_aa_oldgante"] = true
			SaveState.abilities["train_travel"] = true

func _ask_about_flags():
	WorldSystem.push_flags(WorldSystem.WorldFlags.PHYSICS_ENABLED)
	GlobalMessageDialog.clear_state()
	yield (GlobalMessageDialog.show_message("Do you want to Reset Fast Travel Flags?\nUninstall this mod after you confirm this works.", false, false), "completed")
	var choice = yield (GlobalMenuDialog.show_menu(["Yes", "No"], 0), "completed")
	yield (GlobalMessageDialog.hide(), "completed")
	WorldSystem.pop_flags()

	return choice
