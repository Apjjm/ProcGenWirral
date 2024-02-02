extends DecoratorAction

const PlayerMotionTracker = preload("../../player/PlayerMotionTracker.gd")
export(int) var cooldown_ticks = 2

const BLINK_TIME = 0.15

var sight_detector = null
var touch_detector = null
var interaction_detector = null

class AreaEnabledState:
	var monitoring: bool
	var monitorable: bool
	var disabled: bool
	var node: WeakRef

	func _init(node: Area):
		self.node = weakref(node)
		if node != null:
			self.monitoring = node.monitoring
			self.monitorable = node.monitorable
			self.disabled = node.disabled

	func disable():
		var ref = self.node.get_ref()
		if ref != null:
			ref.monitoring = false
			ref.monitorable = false
			ref.disabled = true

	func restore():
		var ref = self.node.get_ref()
		if ref != null:
			ref.monitoring = self.monitoring
			ref.monitorable = self.monitorable
			ref.disabled = self.disabled

func _enter_action():
	var who = blackboard.pawn
	print("[Interaction] Preparing overworld monster before battle")
	touch_detector = AreaEnabledState.new(who.get_node("PlayerTouchDetector"))
	sight_detector = AreaEnabledState.new(who.get_node("PlayerSightDetector"))
	interaction_detector = AreaEnabledState.new(who.get_node("Interaction"))
	
	touch_detector.disable()
	sight_detector.disable()
	interaction_detector.disable()
	
	# This should be cleaned up by the pursuit action anyway, but lets just make sure
	who.alert = false
	if who.emote_player != null:
		who.emote_player.stop()

func _exit_action(result):
	var who = blackboard.pawn
	if who == null:
		return
	
	print("[Interaction] Preparing overworld monster after battle")
	var sp = who.get_node("Sprite")

	var mt = PlayerMotionTracker.find_motion_tracker()
	if mt != null:
		var wt = mt.add_wait_timer(self.cooldown_ticks)
		var st = get_tree().create_timer(BLINK_TIME)
		
		while !wt.ready:
			yield(next_frame(), "completed")
			if st.time_left <= 0:
				st = get_tree().create_timer(max(0.01, BLINK_TIME + st.time_left), false)
				if sp != null:
					sp.visible = !sp.visible

	if sp != null:
		sp.visible = true

	yield(next_frame(), "completed")
	touch_detector.restore()
	sight_detector.restore()
	interaction_detector.restore()
	
	print("[Interaction] Overworld monster has recovered")
	return result
