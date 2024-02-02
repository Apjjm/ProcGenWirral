extends ConfirmDialogAction

const MemorySigil = preload("res://mods/ap7-dungeon/items/stickers/MemorySigil.gd")

export(String) var message_no_memory_sigils = ""
export(String) var message_used_memory_sigils = ""
export(String) var message_unused_memory_sigils = ""

func _run():
	if _has_unused_sigils():
		self.message = self.message_unused_memory_sigils
	elif _has_used_sigils():
		self.message = self.message_used_memory_sigils
	else:
		self.message = self.message_no_memory_sigils

	return ._run()

func _has_unused_sigils():
	for item_node in SaveState.inventory.get_category("stickers").get_children():
		if item_node.amount > 0 && item_node.item is StickerItem && item_node.item.battle_move is MemorySigil:
			return true

	return false

func _has_used_sigils():
	for tape in SaveState.party.get_tapes():
		for i in range(tape.get_max_stickers()):
			var sticker = tape.get_sticker(i)
			if sticker != null && sticker.battle_move is MemorySigil:
				return true

	return false
