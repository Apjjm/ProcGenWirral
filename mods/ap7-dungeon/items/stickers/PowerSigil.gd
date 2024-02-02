extends BattleMove

func notify(fighter, id:String, args):
	if id == "move_ending" && args.fighter == fighter:
		var amount = min(1, fighter.status.max_ap - fighter.status.ap)
		if amount > 0:
			fighter.status.change_ap(amount, name)
			fighter.battle.queue_status_update(fighter)
		
	return .notify(fighter, id, args)
