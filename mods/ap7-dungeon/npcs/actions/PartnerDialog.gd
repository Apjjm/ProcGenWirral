extends Action

export (Array, String) var kayleigh_messages:Array = []
export (Array, String) var meredith_messages:Array = []
export (Array, String) var felix_messages:Array = []
export (Array, String) var eugene_messages:Array = []
export (Array, String) var viola_messages:Array = []
export (Array, String) var dog_messages:Array = []

export (Texture) var kayleigh_portrait:Texture = null
export (Texture) var meredith_portrait:Texture = null
export (Texture) var felix_portrait:Texture = null
export (Texture) var eugene_portrait:Texture = null
export (Texture) var viola_portrait:Texture = null
export (Texture) var dog_portrait:Texture = null

export (AudioStream) var kayleigh_audio:AudioStream = null
export (AudioStream) var meredith_audio:AudioStream = null
export (AudioStream) var felix_audio:AudioStream = null
export (AudioStream) var eugene_audio:AudioStream = null
export (AudioStream) var viola_audio:AudioStream = null
export (AudioStream) var dog_audio:AudioStream = null

export (String) var one_time_flag = ""
export (bool) var wait_for_confirm:bool = true
export (bool) var close_after:bool = true
export (bool) var passive_dialog:bool = false
export (bool) var dog_is_narrated:bool = false

func _run():
	var messages = _get_messages()
	if messages.size() == 0:
		return true

	var onceflag = _get_onetime_flag()
	if onceflag != "":
		if SaveState.has_flag(onceflag):
			return true
		else:
			SaveState.set_flag(onceflag, true)

	var variant = randi()
	var subs = MessageDialogAction.create_subs(self)
	var speaker = Loc.trvf(_get_title(), variant, subs)

	if passive_dialog:
		for i in range(messages.size()):
			var text = Loc.trvf(messages[i], variant, subs)
			text = Loc.substitute_mfn(text, SaveState.party.player.pronouns)
			yield (GlobalMessageDialog.passive_message.show_message(text, speaker), "completed")
	else:
		var dlg = GlobalMessageDialog.message_dialog
		dlg.portrait = _get_portrait()
		dlg.portrait_position = 0
		dlg.audio = _get_audio()
		dlg.type_sounds = null
		dlg.font = null
		dlg.title = speaker
		GlobalMessageDialog.layer = 64
	
		for i in range(messages.size()):
			var text = Loc.trvf(messages[i], variant, subs)
			text = Loc.substitute_mfn(text, SaveState.party.player.pronouns)
			yield (GlobalMessageDialog.show_message(text, false, wait_for_confirm or i < messages.size() - 1), "completed")
			dlg.audio = null

	return true

func _exit_action(_result):
	if close_after && !passive_dialog:
		return GlobalMessageDialog.hide()

func _get_title() -> String:
	match SaveState.party.partner.partner_id:
		"kayleigh": return "KAYLEIGH_NAME"
		"meredith": return "MEREDITH_NAME"
		"felix": return "FELIX_NAME"
		"eugene": return "EUGENE_NAME"
		"viola": return "VIOLA_NAME"
		"dog": return "" if dog_is_narrated else "DOG_NAME" 
		_: return ""

func _get_messages() -> Array:
	match SaveState.party.partner.partner_id:
		"kayleigh": return kayleigh_messages
		"meredith": return meredith_messages
		"felix": return felix_messages
		"eugene": return eugene_messages
		"viola": return viola_messages
		"dog": return dog_messages
		_: return []

func _get_portrait() -> Texture:
	match SaveState.party.partner.partner_id:
		"kayleigh": return kayleigh_portrait
		"meredith": return meredith_portrait
		"felix": return felix_portrait
		"eugene": return eugene_portrait
		"viola": return viola_portrait
		"dog": return dog_portrait
		_: return null

func _get_audio() -> AudioStream:
	match SaveState.party.partner.partner_id:
		"kayleigh": return kayleigh_audio
		"meredith": return meredith_audio
		"felix": return felix_audio
		"eugene": return eugene_audio
		"viola": return viola_audio
		"dog": return dog_audio
		_: return null

func _get_onetime_flag() -> String:
	if one_time_flag == "":
		return ""
	
	match SaveState.party.partner.partner_id:
		"kayleigh": return one_time_flag + "_KAYLEIGH"
		"meredith": return one_time_flag + "_MEREDITH"
		"felix": return one_time_flag + "_FELIX"
		"eugene": return one_time_flag + "_EUGENE"
		"viola": return one_time_flag + "_VIOLA"
		"dog": return one_time_flag + "_DOG"
		_: return ""
	
