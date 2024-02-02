extends Action
export(Dictionary) var partner_songs = {}

var _current_index = 0
onready var _voice : AudioStreamPlayer = $Voice

func _run():
	var partner = SaveState.party.get_partner()
	var songs = [ SceneManager.current_scene.default_region_settings.music_day ]
	songs.append_array(self.partner_songs.get(partner.partner_id, []) if partner != null else [])

	self._current_index += 1
	var song = songs[self._current_index % songs.size()]
	MusicSystem.play(song)

	if self._voice:
		self._voice.play()

	return true
