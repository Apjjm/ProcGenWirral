extends MessageDialogAction

export (String) var message_loc_key:String = ""
export (String) var counter_key:String = ""
export (int, 1, 999) var message_count:int = 1
export (bool) var advance_counter:bool = false

func _run():
	var id = 1 + (SaveState.get_counter(counter_key) % self.message_count)
	self.messages = [ message_loc_key + str(id) ]

	if self.advance_counter:
		SaveState.set_counter(counter_key, (SaveState.get_counter(counter_key) + 1) % self.message_count)

	return ._run()
