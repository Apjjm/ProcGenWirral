extends Action

func get_requirement():
	return "AP7_DUNGEON_MENU_SHRINE_COST_TAPE"

func _run():
    print("[ShrineDestroyTapeAction] Removing tape")
    var tape = get_bb("shrine_tape")
    if tape != null:
        SaveState.party.remove_tape(tape)
        for i in range(tape.get_max_stickers()):
            var sticker = tape.peel_sticker(i)
            if sticker:
                var left_over = SaveState.inventory.add_item(sticker)
                if left_over > 0:
                    WorldSystem.drop_item(sticker, left_over)

    return true