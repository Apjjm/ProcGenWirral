extends MessageDialogAction

export(String) var morgante = ""
export(String) var lamento = ""
export(String) var cube = ""
export(String) var alice = ""
export(String) var puppetox = ""
export(String) var tower = ""
export(String) var helia = ""
export(String) var monarch = ""
export(String) var mammon = ""
export(String) var morningstar = ""
export(String) var robin = ""
export(String) var aleph = ""
export(String) var clown = ""

export(String) var counter_key = ""
export(bool) var advance_counter = false

func _run():
	var options = _get_possible_messages()
	var id = SaveState.get_counter(counter_key) % options.size()
	while options[id] == "":
		id = (1 + id)  % options.size()

	self.messages = [ options[id] ]

	if self.advance_counter:
		SaveState.set_counter(counter_key, (id + 1) % options.size())

	return ._run()

func _get_possible_messages() -> Array:
	var result = [ self.morgante ]

	result.push_back(self.cube if SaveState.has_flag("encounter_aa_cube") else "")
	result.push_back(self.alice if SaveState.has_flag("encounter_aa_alice") else "")
	result.push_back(self.monarch if SaveState.has_flag("encounter_aa_monarch") else "")
	result.push_back(self.puppetox if SaveState.has_flag("encounter_aa_puppet") else "")
	result.push_back(self.tower if SaveState.has_flag("encounter_aa_tower") else "")
	result.push_back(self.morningstar if SaveState.has_flag("encounter_aa_mourningstar") else "")
	result.push_back(self.mammon if SaveState.has_flag("encounter_aa_mammon") else "")
	result.push_back(self.robin if SaveState.has_flag("encounter_aa_robin") else "")
	result.push_back(self.lamento if SaveState.has_flag("encounter_aa_lamento_mori") else "")
	result.push_back(self.clown if SaveState.has_flag("encounter_aa_clown") else "")
	result.push_back(self.helia if SaveState.has_flag("encounter_aa_helia") else "")
	result.push_back(self.aleph if SaveState.has_flag("encounter_aa_aleph_null") else "")

	return result
