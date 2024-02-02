extends Spatial

const MIN_TIME_UNIT = 0.25

# Raw player speeds
var player_speed : float = 0
var player_speed_prev : float = 0

# Adjusted player speeds, as a proportion of the players max walking speed. Clamped to at most 2x.
var player_speed_mul : float = 0
var player_speed_mul_prev : float = 0

# Over time we expect monster actions to "drift" and them to all move independantly - this isn't great for predictability.
# Instead we will only process monster timers every X ticks against this global clock so that they can synchronise again
var wait_tick_time = 0

var _unit_xz_speed = 8
var _physics_velocity : Vector3 = Vector3.ZERO
var _timers = []

class TimerState:
	var ticks: int
	var promise: Promise

static func find_motion_tracker() -> Spatial:
	var player = WorldSystem.get_player()
	if player != null && player.has_node("PlayerMotionTracker"):
		return player.get_node("PlayerMotionTracker")

	return null

static func has_motion_tracker():
	var player = WorldSystem.get_player()
	return player != null && player.has_node("PlayerMotionTracker")

func add_wait_timer(ticks: int) -> Promise:
	var ts = TimerState.new()
	ts.ticks = ticks
	ts.promise = Promise.new()
	self._timers.push_back(ts)
	return ts.promise

func attach_to_player() -> bool:
	if get_parent() != null:
		get_parent().remove_child(self)

	var player = WorldSystem.get_player()
	if player != null:
		if player.has_node("PlayerMotionTracker"):
			print("[PlayerMotionTracker] already exists on ", player.get_path())
		else:
			player.add_child(self)

			var state_machine = player.get_node("StateMachine")
			assert(state_machine != null, "no StateMachine on player " + player.get_path())
		
			var walknode = state_machine.get_node("Walking")
			assert(walknode != null, "no Walking state on player " + player.get_path())
			self._unit_xz_speed = walknode.max_walk_speed
			assert(self._unit_xz_speed > 0.01, "bad max_walk_speed: " + str(walknode.max_walk_speed))

			# We need to run *BEFORE* player if we want to grab the velocity set by the input system
			self.process_priority = player.process_priority - 1000
			self.name = "PlayerMotionTracker"
			return true

	return false

func _process(delta):
	# The player's controls only update on process, so it is only fair our enemies do too, i guess.
	# It makes the enemy logic a bit less consistent under lag, maybe? But it should still be dt scaled so not too bad?
	# even if we correctly update AI on every physics update, input lag for the player still makes it inconsistent anyway.
	self.player_speed_prev = self.player_speed
	self.player_speed_mul_prev = self.player_speed_mul
	if WorldSystem.is_player_control_enabled():
		self.player_speed = sqrt(self._physics_velocity.x*self._physics_velocity.x + self._physics_velocity.z*self._physics_velocity.z)
		self.player_speed_mul = min(2.0, self.player_speed / self._unit_xz_speed)
		self.wait_tick_time += delta * self.player_speed_mul

		if self.wait_tick_time > MIN_TIME_UNIT:
			var num_ticks = floor(self.wait_tick_time / MIN_TIME_UNIT)
			self.wait_tick_time -= num_ticks * MIN_TIME_UNIT
			
			for i in range(self._timers.size()-1, -1, -1):
				self._timers[i].ticks -= num_ticks # Under really heavy lag this doesn't quite behave the same, but doing a while loop wouldn't anyway.
				if self._timers[i].ticks <= 0:
					self._timers[i].promise.fulfill(self._timers[i].ticks)
					self._timers.remove(i)

	else:
		self.player_speed = 0
		self.player_speed_mul = 0


func _physics_process(_delta):
	var pawn = get_parent()
	if pawn == null || pawn.paused:
		self._physics_velocity = Vector3.ZERO
	else:
		self._physics_velocity = pawn.velocity
