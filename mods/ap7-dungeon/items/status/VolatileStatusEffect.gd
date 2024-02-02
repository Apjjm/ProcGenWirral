extends StatusEffect

const GlitchEffectOrb = preload("GlitchEffectOrb.gd");

export(float) var volatile_damage_frac = 0.3
export(Array, Resource) var hit_vfx:Array

func enter_tree(node: StatusEffectNode):
	.enter_tree(node)
	if node.fighter.slot != null:
		node.battle.queue_animation(Bind.new(self, "start_effects", [node, node.fighter.slot]))

func exit_tree(node: StatusEffectNode):
	if node.fighter.slot != null and not node.fighter.status.dead:
		node.battle.queue_animation(Bind.new(self, "stop_effects", [node, node.fighter.slot]))
	.exit_tree(node)

func enter_slot(node: StatusEffectNode, slot: BattleSlot):
	start_effects(node, slot)
	.enter_slot(node, slot)

func leave_slot(node: StatusEffectNode, slot: BattleSlot):
	stop_effects(node, slot)
	.leave_slot(node, slot)

func notify(node: StatusEffectNode, id:String, args: Dictionary):
	if id == "status_effect_add_starting" && args.fighter == node.fighter && args.status_effect.effect is get_script():
		stacks_changed(node, node.fighter.slot)
	elif id == "attack_damage_ending" && args.target == node.fighter && !("ap7_volatile" in args.damage.tags):
		add_volatile(node, args.damage.damage * args.damage.hits)
	elif id == "attack_contact_starting" && args.target == node.fighter:
		stacks_changed(node, node.fighter.slot)
	elif id == "turn_ending" && args.fighter == node.fighter:
		stacks_changed(node, node.fighter.slot)
		turn_ending(node)
	
	return false

func turn_ending(node: StatusEffectNode):
	var amt = int(get_volatile(node) * self.volatile_damage_frac)
	if amt > 0 && node.fighter.status.hp > 0:
		node.battle.queue_camera_set_state("normal", [node.fighter.slot])

		var damage = Damage.new()
		damage.damage = min(node.fighter.status.hp, amt)
		damage.physicality = 0
		damage.types = []
		damage.tags = ["ap7_volatile"]
		damage.ignores_walls = true
		damage.hit_vfx = hit_vfx
		damage.toast_message = name
		node.fighter.get_controller().take_damage(damage)

func stacks_changed(node: StatusEffectNode, slot: BattleSlot):
	if slot.has_node("AP7_STATUS_GLITCH_EFFECT"):
		var fxNode = slot.get_node("AP7_STATUS_GLITCH_EFFECT")
		var amount = get_volatile(node)
		var limit = float(node.fighter.status.max_hp if node.fighter.status.max_hp > 0 else node.fighter.status.max_backing_hp)
		var frac = clamp(amount/max(1.0, 0.6 * limit), 0.0, 1.0)
		fxNode.set_glitchyness(frac)

func start_effects(node: StatusEffectNode, slot: BattleSlot):
	#print("[E] start effects")
	if !slot.has_node("AP7_STATUS_GLITCH_EFFECT"):
		var fxNode = GlitchEffectOrb.new()
		fxNode.name = "AP7_STATUS_GLITCH_EFFECT"
		slot.add_child(fxNode)
		stacks_changed(node, slot)

func stop_effects(_node: StatusEffectNode, slot: BattleSlot):
	#print("[E] stop effects")
	if slot.has_node("AP7_STATUS_GLITCH_EFFECT"):
		var fxNode = slot.get_node("AP7_STATUS_GLITCH_EFFECT")
		fxNode.queue_free()

func add_volatile(node: StatusEffectNode, amount: float):
	if "ap7_volatile" in node.custom_data:
		node.custom_data["ap7_volatile"] = amount + node.custom_data["ap7_volatile"]
		print("Added: ", node.custom_data["ap7_volatile"])
	else:
		node.custom_data["ap7_volatile"] = amount

func get_volatile(node: StatusEffectNode) -> float:
	var min_amount = node.fighter.status.max_hp * 0.1
	if "ap7_volatile" in node.custom_data:
		return max(min_amount, node.custom_data["ap7_volatile"])
	else:
		return min_amount

func unfuse(node, new_fighter):
	var new_status = node.duplicate()
	if "ap7_volatile" in node.custom_data:
		var amt = node.custom_data["ap7_volatile"]
		node.custom_data["ap7_volatile"] = amt * 0.5
		new_status.custom_data["ap7_volatile"] = amt * 0.5
	
	new_fighter.status.add_child(new_status)
