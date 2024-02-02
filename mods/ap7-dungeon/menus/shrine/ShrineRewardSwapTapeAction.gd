extends "ShrineRewardBaseAction.gd"

func _run():
	var tape = get_bb("shrine_tape")
	
	if tape != null:
		var rng = get_rng()
		var new_tape = MonsterTape.new()
		new_tape.form = get_new_form(rng)
		new_tape.favorite = tape.favorite
		new_tape.assign_initial_stickers(true)
		new_tape.apply_exp_points(tape.exp_points, rng)
		new_tape.fix_slot_overflow()
		
		print("[ShrineSwapTapeAction] Swapping tape ", tape.get_name(), " to ", new_tape.get_name())
		SaveState.party.remove_tape(tape)
		SaveState.party.add_tape(new_tape)

	return true

func get_new_form(rng: Random):
	var available = []
	for form in MonsterForms.basic_forms.values():
		if form.require_dlc != "" && !DLC.has_dlc(form.require_dlc):
			continue
			
		if SaveState.species_collection.has_seen_species(form):
			available.push_back(form)

	return rng.choice(available)