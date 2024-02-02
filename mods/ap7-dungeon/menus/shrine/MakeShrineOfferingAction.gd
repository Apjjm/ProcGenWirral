extends Action

export (String) var confirm_message:String = "AP7_DUNGEON_MENU_SHRINE_CONFIRM"

func _run():
	var tapes = SaveState.party.get_tapes()
	var tape = yield (MenuHelper.show_choose_tape_menu(tapes, Bind.new(self, "_tape_filter")), "completed")
	if !tape:
		return false

	var msg = Loc.trf(confirm_message, {tape = tape.get_name()})
	if !yield (MenuHelper.confirm(msg), "completed"):
		return false

	# Lots of actions are going to look at this, so avoid copying this everywhere
	var sigils = []
	for move in tape.get_moves():
		#print("Move tags:", move.tags)
		if move != null && ("sigil" in move.tags || "sigil_rare" in move.tags):
			sigils.push_back(move)

	set_bb("shrine_tape", tape)
	set_bb("shrine_sigils", sigils)
	return true

func _tape_filter(tape:MonsterTape):
	return SaveState.party.player.tapes.find(tape) != 0 && SaveState.party.partner.tapes.find(tape) != 0
