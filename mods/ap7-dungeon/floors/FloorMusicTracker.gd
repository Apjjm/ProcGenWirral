extends Node

const FloorLevelNode = preload("../floorgen/FloorLevelNode.gd")

var flr : FloorLevelNode
var zone : String

var _zone_resources = null

func _enter_tree():
	self.flr = get_parent()
	self.flr.connect("active_rooms_changed", self, "_on_active_rooms_changed")
	UserSettings.connect("settings_changed", self, "_update_music")
	_update_music()

func _exit_tree():
	self.flr = get_parent()
	self.flr.disconnect("active_rooms_changed", self, "_on_active_rooms_changed")
	UserSettings.disconnect("settings_changed", self, "_update_music")

func _on_active_rooms_changed(rooms: Array):
	if rooms.size() == 0:
		return

	var new_zone = ""
	for id in rooms:
		var room_zone = self.flr.floor_data.zones.get_zone(id)
		if room_zone != new_zone:
			if new_zone == "":
				new_zone = room_zone
			else:
				return
	
	if self.zone != new_zone:
		self.zone = new_zone
		self._zone_resources = self.flr.floor_data.zones.get_resources(new_zone)
		_update_music()

func _update_music():
	if SceneManager.transitioning && SceneManager.transitioned_out:
		yield (Co.safe_yield(self, SceneManager, "scene_change_ending"), "completed")

	if !is_inside_tree():
		return

	var music = null
	if self._zone_resources != null: 
		music = self._zone_resources.music_vox if UserSettings.audio_vocals else self._zone_resources.music_novox

	var scene = SceneManager.current_scene
	if music != null && scene != null && scene is LevelMap && scene.music_override != music:
		scene.music_override = music
