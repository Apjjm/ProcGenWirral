extends "ShrineRewardBaseAction.gd"

const KunekoSigil = preload("../../items/stickers/KunekoSigil.gd")

func is_blocked() -> bool:
	return _find_sigil() == null

func has_priority() -> bool:
	return true

func _run():
	print("[ShrineRewardKunekoQuestAction] Selected")
	_find_sigil().apply_shrine_flag()
	return true

func _find_sigil() -> KunekoSigil:
	var sigils = get_bb("shrine_sigils")
	for move in sigils:
		if move is KunekoSigil:
			return move

	return null
