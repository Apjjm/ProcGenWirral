extends Node

func _ready():
	if DLC.network_multiplayer_compatible:
		print("[DungeonNetToggle] Mods are currently multiplayer compatible. Listening for active false wirral maps.")
		SceneManager.connect("scene_changed", self, "_on_scene_changed") # Handles loading saves into the dungeon & exiting to menu
		Net.connect("status_changed", self,"_on_status_changed") # Failsafe - Handles the user somehow finding a way to re-host a session
		_on_scene_changed()

func _on_scene_changed():
	if SceneManager.current_scene.filename.begins_with("res://mods/ap7-dungeon/floors"):
		if DLC.network_multiplayer_compatible:
			_end_multiplayer_sessions()
			DLC.network_multiplayer_compatible = false
	else:
		if !DLC.network_multiplayer_compatible:
			print("[DungeonNetToggle] Outside dungeon level. Enabling multiplayer")
			DLC.network_multiplayer_compatible = true

func _on_status_changed():
	if !Net.status_disconnected() && SceneManager.current_scene.filename.begins_with("res://mods/ap7-dungeon/floors"):
		_end_multiplayer_sessions()

func _end_multiplayer_sessions():
	if Net.status_disconnected():
		return
	
	GlobalMessageDialog.passive_message.show_message("AP7_DUNGEON_DISABLE_MULTIPLAYER_MESSAGE")
	Net.close_connection()
	
	if MenuHelper.hud.persistent_status_ui != null:
		var online_hud = MenuHelper.hud.persistent_status_ui.find_node("PersistentStatusElement_Online", true)
		if online_hud != null && online_hud.visible:
			online_hud.hide()