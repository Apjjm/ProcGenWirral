extends "res://data/battle_move_scripts/PureStatus.gd"

func apply_statuses(user, target, attack_params = {}, toast_message:String = ""):
	.apply_statuses(user, target, attack_params, toast_message)

	var debuffs = _get_debuffs(target)
	for debuff in debuffs:
		if _is_ritual_effect(debuff):
			# Hacky workaround for the status not being normally cleansable
			debuff.set_amount(0)
			debuff.remove()
		else:
			debuff.remove()

func _get_debuffs(fighter)->Array:
	var result = []
	for status in fighter.status.get_effects():
		if status.effect.is_debuff && status.effect.is_removable:
			result.push_back(status)
		elif _is_ritual_effect(status):
			result.push_back(status)
	return result

func _is_ritual_effect(status):
	return "resurrected" in status.effect.get_tags()
