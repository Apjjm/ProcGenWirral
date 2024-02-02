extends BattleMove

const VolatileStatus = preload("res://mods/ap7-dungeon/items/status/VolatileStatus.tres")
const FLAG_OVERRIDE = false

# We give the AI a cost that the players don't get, and less damage

export(bool) var add_volatile = true
export(int) var min_cost = 0
export(float) var damage_mul = 2.0

func notify(fighter, id:String, args):
	if id == "fighter_starting" && self.add_volatile && args.fighter == fighter && !fighter.status.has_effect(VolatileStatus):
		fighter.battle.queue_turn_action(Bind.new(self, "_apply_status", [fighter]))
	elif id == "attack_starting":
		if "ap7_dungeon_oob" in args.attack_params.order_args && args.attack_params.order_args.ap7_dungeon_oob == self:
			# This is a rare sticker with random move selection and status drawback. Just having base 200 move would be disappointing.
			# The sticker should feel powerful given the cost - so we double up the power to make it better than just headshot spam.
			args.damage.damage = int(args.damage.damage * damage_mul)
	
	return .notify(fighter, id, args)

func _execute(battle, user, argument, _attack_params):
	var move = _pick_move(battle.rand)
	if move == null:
		battle.queue_animate_turn_failed()
		return
	
	var move_cost = int(max(self.min_cost, move.cost))
	var refund = (argument.cost - move_cost) if "cost" in argument else (self.cost - move_cost)
	if refund > 0:
		_ap_refund(user, refund)
		#user.battle.queue_turn_action(Bind.new(self, "_ap_refund", [user, refund]))
	
	var title = Loc.trf("MOVE_TITLE_MOVE_USING_MOVE", [get_title(), move.get_title()])
	user.battle.queue_animate_turn_start(user, title)
	user.get_controller().use_move(move, { "cost": 0 , "ap7_dungeon_oob": self })
	battle.queue_animate_turn_end()

func _apply_status(fighter):
	if !fighter.status.has_effect(VolatileStatus):
		apply_status_effect(fighter, VolatileStatus, 1, "AP7_DUNGEON_MOVE_BANR_OOB_SIGIL")
	
func _ap_refund(fighter, refund):
	var amount = min(refund, fighter.status.max_ap - fighter.status.ap)
	if amount > 0:
		fighter.status.change_ap(amount, name)
		fighter.battle.queue_status_update(fighter)

func _pick_move(rng: Random):
	var moves = [ 
		preload("res://data/archangel_moves/oldgante_coda_morgana.tres"), 
		preload("res://data/archangel_moves/oldgante_thrash.tres") ]
	
	if SaveState.has_flag("encounter_aa_lamento_mori") || FLAG_OVERRIDE:
		moves.push_back(preload("res://data/archangel_moves/lamento_mori_death_ray.tres"))

	if SaveState.has_flag("encounter_aa_mourningstar") || FLAG_OVERRIDE:
		moves.push_back(preload("res://data/archangel_moves/serpent_judgment.tres"))

	if SaveState.has_flag("encounter_aa_monarch") || FLAG_OVERRIDE:
		moves.push_back(preload("res://data/archangel_moves/monarch_tentacle.tres"))
		# moves.push_back(preload("res://data/archangel_moves/monarch_bomb_voyage.tres")) Breaks visuals :(

	if SaveState.has_flag("encounter_aa_alice") || FLAG_OVERRIDE:
		moves.push_back(preload("res://data/archangel_moves/alice_high_and_mighty.tres"))
		moves.push_back(preload("res://data/archangel_moves/alice_drink_me.tres"))
		moves.push_back(preload("res://data/archangel_moves/alice_eat_me.tres"))

	if SaveState.has_flag("encounter_aa_mammon") || FLAG_OVERRIDE:
		moves.push_back(preload("res://data/archangel_moves/mammon_market_crash.tres"))
		moves.push_back(preload("res://data/archangel_moves/mammon_loss_leader.tres"))
		
	if SaveState.has_flag("encounter_aa_cube") || FLAG_OVERRIDE:
		moves.push_back(preload("res://data/archangel_moves/cube_frustum_cull.tres"))

	if SaveState.has_flag("encounter_aa_puppet") || FLAG_OVERRIDE:
		moves.push_back(preload("res://data/archangel_moves/puppet_feedback.tres"))

	if SaveState.has_flag("encounter_aa_robin") || FLAG_OVERRIDE:
		moves.push_back(preload("res://data/archangel_moves/robin_fairy_horde.tres"))
		moves.push_back(preload("res://data/archangel_moves/robin_night_mare.tres"))

	if SaveState.has_flag("encounter_aa_tower") || FLAG_OVERRIDE:
		moves.push_back(preload("res://data/archangel_moves/tower_false_illumination.tres"))
		moves.push_back(preload("res://data/archangel_moves/tower_true_illumination.tres"))

	if SaveState.has_flag("encounter_aa_aleph_null") || FLAG_OVERRIDE:
		moves.push_back(preload("res://data/archangel_moves/aleph_death_by_1000_cuts.tres"))
		moves.push_back(preload("res://data/archangel_moves/aleph_death_by_10000_cuts.tres"))
	
	if SaveState.has_flag("encounter_aa_clown") || FLAG_OVERRIDE:
		moves.push_back(preload("res://data/archangel_moves/clown_topsy_turvy.tres"))
		
	if SaveState.has_flag("encounter_lenna") || FLAG_OVERRIDE:
		moves.push_back(preload("res://data/archangel_moves/lenna_power_of_truth.tres"))

	if SaveState.has_flag("ap7_dungeon_aa_hand_defeated") || FLAG_OVERRIDE:
		moves.push_back(preload("res://mods/ap7-dungeon/items/moves/ap7_aa_dungeon_awakening.tres"))

	#return moves[4]
	return rng.choice(moves)
