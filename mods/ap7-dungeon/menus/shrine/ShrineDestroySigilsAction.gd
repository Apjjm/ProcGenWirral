extends Action

func get_requirement():
	return "AP7_DUNGEON_MENU_SHRINE_COST_SIGIL"

func _run():
	print("[ShrineDestroySigilsAction] Removing sigils")
	var tape = get_bb("shrine_tape")
	if tape != null:
		for i in range(tape.stickers.size()):
			var sticker = tape.get_sticker(i)
			if sticker != null && "sigil" in sticker.battle_move.tags:
				tape.peel_sticker(i, false)
		tape.fix_slot_overflow()

	return true