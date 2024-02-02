extends "res://data/battle_move_scripts/GenericAttack.gd"

const TerraformSlotBlock = preload("../move_vfx/TerraformSlotBlock.gd")
const TerraformHammerAnim = preload("../move_vfx/TerraformHammerAnim.tscn")
const VolatileStatus = preload("res://mods/ap7-dungeon/items/status/VolatileStatus.tres")

export(String) var winddown_anim = "";

func _execute(battle: Battle, user, argument, attack_params):
	for fighter in attack_params.targets:
		_add_slot_block(fighter)
		_add_volatile(fighter)
		if !_is_ignored_fighter(fighter):
			_jumble_form(battle, fighter)
		
		battle.queue_status_update(fighter)

	._execute(battle, user, argument, attack_params)

func _animate_attack_vfx(battle: Battle, user, target_slots: Array, vfx_params: Dictionary):
	# Rather unfortunately, because we want to interleave the transform animation we can't use the handy vfx nodes :(
	var tfroot = _get_hammer_anim(battle)
	var colist = [._animate_attack_vfx(battle, user, target_slots, vfx_params), tfroot.play_anim()]
	
	yield (tfroot, "do_transform")
	colist.push_back(_show_user(user))
	for target_slot in target_slots:
		var fighter = target_slot.get_fighter()
		if !_is_ignored_fighter(fighter):
			var bind = fighter.generate_transform_animation()
			colist.push_back(bind.call_func())

	yield (Co.join(colist), "completed")

func _show_user(user):
	yield (Co.wait(0.9), "completed")
	yield (user.slot.play_animation(self.winddown_anim), "completed")

func _is_ignored_fighter(fighter: FighterNode):
	return !fighter.is_transformed() || fighter.get_character_kind() < 0

func _add_slot_block(fighter: FighterNode):
	if !fighter.slot.has_node("ap7_tf_slot"):
		var node = TerraformSlotBlock.new()
		node.name = "ap7_tf_slot"
		fighter.slot.add_child(node)

func _jumble_form(battle: Battle, fighter: FighterNode):
	for character in fighter.get_characters():
		var tape = character.copying_tape if character.copying_tape != null else character.active_tape
		var types = tape.form.elemental_types if tape.type_override.size() == 0 else tape.type_override
		tape.form = _get_valid_form(battle)
		tape.type_override = types

		if character.copying_tape != null:
			character.set_copying_tape(tape)
		else:
			character.set_active_tape(tape)

func _add_volatile(fighter: FighterNode):
	if !fighter.status.has_effect(VolatileStatus):
		apply_status_effect(fighter, VolatileStatus, 1)

# Optimisation hackery #
func _get_valid_form(battle: Battle):
	if battle.background.has_node("TerraformSpritesPreloader"):
		return battle.background.get_node("TerraformSpritesPreloader").next_terraform_form()
	else:
		push_warning("[Terraform] Couldn't find preloaded forms. Getting next form will be slow.")
		var available = []
		for form in MonsterForms.basic_forms.values():
			if form.require_dlc == "" || DLC.has_dlc(form.require_dlc):
				available.push_back(form)

		return battle.rand.choice(available)

# Optimisation hackery #
func _get_hammer_anim(battle: Battle):
	if battle.background.has_node("TerraformSpritesPreloader"):
		return battle.background.get_node("TerraformSpritesPreloader/HammerAnim")
	elif battle.background.has_node("Ap7TerraformHammerAnim"):
		return battle.background.get_node("Ap7TerraformHammerAnim")
	else:
		push_warning("[Terraform] Couldn't find preloaded anim")
		var tfroot = TerraformHammerAnim.instance()
		tfroot.name = "Ap7TerraformHammerAnim"
		battle.background.add_child(tfroot)
		return tfroot
