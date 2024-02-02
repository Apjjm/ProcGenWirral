extends DecoratorAction

var _in_state:bool = false

func _enter_tree():
	set_paused(!self._in_state || !WorldSystem.is_ai_enabled())
	WorldSystem.connect("flags_changed", self, "_world_flags_changed")

func _exit_tree():
	set_paused(true)
	WorldSystem.disconnect("flags_changed", self, "_world_flags_changed")

func _enter_state():
	#print("ENTER STATE ", name, " NR: ", self.num_running)
	# Failsafe, maybe there is some ordering of tasks finished that
	# meant we somehow ended up completing the promise after setting to 0
	assert(self.num_running <= 0, "[MonsterBehaviour] Entered state "+name+" with unexpected num running: "+str(self.num_running))
	self.num_running = 0
	self._in_state = true
	set_paused(!WorldSystem.is_ai_enabled())
	blackboard.pawn = get_parent().pawn

func _exit_state():
	self._in_state = false
	call_deferred("_reset")
	# print("EXIT STATE ", name)

func _exit_action(result):
	if !result && !free_on_exit:
		get_parent().set_state("")

func _world_flags_changed():
	set_paused(!self._in_state || !WorldSystem.is_ai_enabled())

func update(_delta):
	if self._in_state && !is_running() && !is_paused():
		# print("RUN ", name)
		run()

func _reset():
	# print("RESET ", name, " running:", num_running)
	var new_actions = []
	for action in get_children():
		new_actions.push_back(action.duplicate())
		remove_child(action)
		action.queue_free()
	for action in new_actions:
		add_child(action)
	self.num_running = 0
	
