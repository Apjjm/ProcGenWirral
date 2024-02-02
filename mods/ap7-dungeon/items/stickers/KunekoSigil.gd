extends BattleMove

export(Array, String) var descriptions = []

func get_description()->String:
	return descriptions[get_phase()]

func notify(fighter, id:String, args):
	if id == "damage_ending" && args.fighter.team != fighter.team && args.fighter.status.hp <= 0:
		apply_ko_flag()

func apply_shrine_flag():
	SaveState.set_flag("AP7_DUNGEON_KUNEKO_QUEST_SHRINE", true)

func apply_ko_flag():
	SaveState.set_flag("AP7_DUNGEON_KUNEKO_QUEST_KO", true)

func get_phase() -> int:
	var f1 = SaveState.has_flag("AP7_DUNGEON_KUNEKO_QUEST_SHRINE")
	var f2 = SaveState.has_flag("AP7_DUNGEON_KUNEKO_QUEST_KO")
	if f1 && f2:
		return 2
	elif f1 || f2:
		return 1
	else:
		return 0