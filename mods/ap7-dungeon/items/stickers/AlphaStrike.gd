extends "res://data/battle_move_scripts/GenericAttack.gd"

func contact(battle, user, target, damage, attack_params):
	.contact(battle, user, target, damage, attack_params)

	var ap_gain = min(user.status.max_ap - user.status.ap, 4)
	if ap_gain > 0 && battle.controller.round_num == 0:
		user.status.change_ap(ap_gain, "AP7_DUNGEON_MOVE_NAME_ALPHA_SIGIL")
		battle.queue_status_update(user)

func _create_attack_params(battle, user, targets:Array, argument)->Dictionary:
	var params = ._create_attack_params(battle, user, targets, argument)
	if battle.controller.round_num == 0:
		params.power = int(self.power * min(4, user.status.max_ap - user.status.ap) * 0.5)

	return params
