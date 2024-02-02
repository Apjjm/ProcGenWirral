extends "res://battle/ai/WeightedAI.gd"

const PetrifiedStatus = preload("res://data/status_effects/petrified.tres")
const StoneworkMove = preload("res://mods/ap7-dungeon/items/moves/ap7_aa_dungeon_stonework.tres")
const SculptMove = preload("res://mods/ap7-dungeon/items/moves/ap7_aa_dungeon_sculpt.tres")
const AwakeningMove = preload("res://mods/ap7-dungeon/items/moves/ap7_aa_dungeon_awakening.tres")
const MeteorMove = preload("res://data/battle_moves/meteor_barrage.tres")

var tapes_backup = []

func _enter_tree():
	backup_player_party()

func _exit_tree():
	restore_player_party()

func _queue_animate_defeat():
	return battle.queue_animation(Bind.new(self, "animate_defeat_aahand"))

func choose_best_order(valid_moves:Array, exclude_orders:Array):
	var expensive = []
	for move in valid_moves:
		if move.cost >= 10:
			var order = configure_move(move)
			if order:
				return order
		elif move.cost >= 3:
			var order = configure_move(move)
			if order:
				expensive.push_back(order)

	if expensive.size() > 0:
		return battle.rand.choice(expensive)
	else:
		return .choose_best_order(valid_moves, exclude_orders)

func request_orders():
	var orders = .request_orders()
	if orders is GDScriptFunctionState:
		orders = yield (orders, "completed")
	elif orders == null:
		orders = []

	if fighter.status.ap < 6:
		var order = configure_move(SculptMove)
		if order != null:
			return [ order ]
	
	if fighter.status.ap < 3:
		var order = configure_move(StoneworkMove)
		if order != null:
			orders.insert(0, order)

	return orders

func get_valid_target_sets(move)->Array:
	var result = .get_valid_target_sets(move)
	if move == SculptMove:
		var new_result = []
		for target_set in result:
			for target in target_set:
				if target.status.has_effect(PetrifiedStatus):
					new_result.push_back(target_set)
		return new_result
	elif move == StoneworkMove:
		var new_result = []
		for target_set in result:
			for target in target_set:
				if !target.status.has_effect(PetrifiedStatus):
					new_result.push_back(target_set)
		return new_result
	else:
		return result

func animate_defeat_aahand():
	battle.camera_set_state("defeat", [fighter.slot])
	yield (Co.join([
		fighter.status_bubble.animate_death(true) if fighter.status_bubble else Co.pass(), 
		fighter.slot.play_animation("disappear")
	]), "completed")
	fighter.animate_leave_slot(fighter.slot)

func backup_player_party():
	print("[FinalBoss] Backing up prefight tapes")
	self.tapes_backup = []
	for i in range(SaveState.party.characters.size()):
		var character = SaveState.party.characters[i]
		var snap = []
		for tape in character.tapes:
			snap.push_back(tape.get_snapshot())
		
		self.tapes_backup.push_back(snap)

func restore_player_party():
	print("[FinalBoss] Restoring postfight tapes")
	for i in range(SaveState.party.characters.size()):
		var snap = self.tapes_backup[i]
		var character = SaveState.party.characters[i]
		for j in range(character.tapes.size()):
			character.tapes[j].set_snapshot(snap[j], SaveState.CURRENT_VERSION)
