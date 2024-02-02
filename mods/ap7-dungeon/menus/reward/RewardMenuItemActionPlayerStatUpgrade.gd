extends "RewardMenuItemAction.gd"

enum Stat { HP, MDEF, MATK, RDEF, RATK, SPD };
enum StatDir { UP, DOWN }

export(Stat) var stat = 0
export(StatDir) var stat_dir = 0

func _run():
	var player = SaveState.party.get_player()
	var amt = 10 if stat_dir == StatDir.UP else -10
	if stat == Stat.HP:
		player.boost_max_hp += amt
	elif stat == Stat.MDEF:
		player.boost_melee_defense += amt
	elif stat == Stat.MATK:
		player.boost_melee_attack += amt
	elif stat == Stat.RDEF:
		player.boost_ranged_defense += amt
	elif stat == Stat.RATK:
		player.boost_ranged_attack += amt
	elif stat == Stat.SPD:
		player.boost_speed += amt

	return true
