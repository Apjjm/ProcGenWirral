extends BattleMove

export (Resource) var elemental_type:Resource

func notify(fighter, id:String, args):
	if id == "attack_starting" && args.fighter == fighter && args.damage.damage > 0 && elemental_type in args.damage.types:
		args.damage.damage = args.damage.damage * 1.10
		
	return .notify(fighter, id, args)
