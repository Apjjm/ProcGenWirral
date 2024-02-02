extends "res://battle/ai/WeightedAI.gd"

const DurationExtender = preload("res://data/battle_move_scripts/DurationExtender.gd")
const GambitStatus = preload("res://data/status_effects/gambit.tres")

func get_ap_system()->int:
	return Character.APSystem.ACCUMULATE


func choose_best_order(valid_moves:Array, exclude_orders:Array):
	var usable_moves = []
	for move in valid_moves:
		if move is DurationExtender:
			# Do I need to avoid getting killed by gambit this turn (but don't get stuck in a loop trying to use it forever)
			var gambitStatus = fighter.status.get_effect_node(GambitStatus)
			var gambitDuration = gambitStatus.get_duration() if gambitStatus != null else -1
			if gambitDuration == 2 || (gambitDuration == 3 && fighter.status.get_ap() < 10):
				var order = configure_move(move)
				if order:
					print("[AI] Dog years - gambit duration was: ", gambitDuration)
					return order
		elif move.cost >= 10:
			var order = configure_move(move)
			if order:
				return order
		else:
			usable_moves.push_back(move)

	return .choose_best_order(usable_moves, exclude_orders)
