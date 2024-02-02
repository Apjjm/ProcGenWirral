extends DecoratorAction

const KunekoSigil = preload("../../items/stickers/KunekoSigil.gd")

export(bool) var requires_tape = true
export(bool) var requires_ko = true
export(bool) var requires_shrine = true
export(bool) var requires_started = true

func run():
	if self.requires_ko && !SaveState.has_flag("AP7_DUNGEON_KUNEKO_QUEST_KO"):
		return false

	if self.requires_shrine && !SaveState.has_flag("AP7_DUNGEON_KUNEKO_QUEST_SHRINE"):
		return false

	if self.requires_started && !SaveState.has_flag("AP7_DUNGEON_KUNEKO_QUEST_STARTED"):
		return false

	if self.requires_tape:
		for tape in SaveState.party.get_tapes():
			for move in tape.get_moves():
				if move is KunekoSigil:
					return .run()
		return false
	else:
		return .run()