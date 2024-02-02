extends Action

const KunekoSigil = preload("../../items/stickers/KunekoSigil.gd")

func _run():
	for tape in SaveState.party.get_tapes():
		for i in range(tape.get_max_stickers()):
			var sticker = tape.get_sticker(i)
			if sticker != null && sticker.battle_move is KunekoSigil:
				tape.peel_sticker(i, false)
				return true

	return false
