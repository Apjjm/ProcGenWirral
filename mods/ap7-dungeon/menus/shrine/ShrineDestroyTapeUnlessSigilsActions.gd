extends Action

func get_requirement():
	var sigils = get_bb("shrine_sigils")
	if sigils.size() > 0:
		return "AP7_DUNGEON_MENU_SHRINE_COST_SIGIL"
	else:
		return "AP7_DUNGEON_MENU_SHRINE_COST_TAPE"

func _run():
	print("[ShrineDestroyTapeUnlessSigilsAction] Removing sigils or tape")
	var tape = get_bb("shrine_tape")
	if tape != null:
		var sigils = get_bb("shrine_sigils")
		if sigils.size() > 0:
			for i in range(tape.stickers.size()):
				var sticker = tape.get_sticker(i)
				if sticker != null && "sigil" in sticker.battle_move.tags:
					tape.peel_sticker(i, false)
			tape.fix_slot_overflow()
		else:
			SaveState.party.remove_tape(tape)
			for i in range(tape.get_max_stickers()):
				var sticker = tape.peel_sticker(i)
				if sticker:
					var left_over = SaveState.inventory.add_item(sticker)
					if left_over > 0:
						WorldSystem.drop_item(sticker, left_over)

	return true