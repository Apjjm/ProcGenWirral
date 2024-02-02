extends "./RandomMonsterActionBase.gd"

func _run_children(default_result):
	var inner_action = self.rng.choice(get_children())
	if inner_action != null:
		return inner_action.run()

	return default_result
