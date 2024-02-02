extends StatusEffect

func get_stackability(other):
	if other is get_script():
		return Stackability.PREVENT_NEW
	return Stackability.NONE

func notify(node, id:String, args):
	if id == "death_starting" && args.fighter == node.fighter && node.amount > 0:
		node.fighter.status.hp = 1
		return true
	elif id == "death_ending" && args.fighter == node.fighter:
		node.remove()

	return .notify(node, id, args)

func drained(node):
	if node.amount <= 0:
		if node.fighter.is_transformed():
			node.battle.queue_camera_set_state("effect", [node.fighter.slot])
			
			#var toast = node.battle.create_toast()
			#toast.setup_text("AP7_DUNGEON_MOVE_TOAST_AWAKENING_OVER")
			#node.battle.queue_play_toast(toast, node.fighter.slot)
			
			node.fighter.status.hp = 0
			node.fighter.get_controller().die()
		else :
			node.set_amount(1)
