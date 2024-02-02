extends Spatial

const DungeonData = preload("../globals/DungeonData.gd")

var _outside = null
var _dungeon = null
var _warp_region = null
var _is_inside = false
var _dungeon_data = null

func _notification(what):
	# Because this scene can live on outside the tree in the scene manager...
	if !Engine.editor_hint && what == NOTIFICATION_PREDELETE:
		if self._outside != null && is_instance_valid(self._outside):
			self._outside.queue_free()
			self._outside = null
		if self._dungeon != null && is_instance_valid(self._dungeon):
			self._dungeon.queue_free()
			self._dungeon = null

func _enter_tree():
	self._dungeon_data = DungeonData.get_global()
	self._outside = self._outside if self._outside != null else get_node("Outside")
	self._dungeon = self._dungeon if self._dungeon != null else get_node("Dungeon")
	self._warp_region = self._warp_region if self._warp_region != null else get_node("WarpRegion")
	
	if _dungeon_data.get_current_dungeon() != null:
		self._is_inside = true
		if self._outside.get_parent() != null: remove_child(self._outside)
		if self._dungeon.get_parent() == null: add_child(self._dungeon)
		self._warp_region.disabled = true
	else:
		self._is_inside = false
		if self._outside.get_parent() == null: add_child(self._outside)
		if self._dungeon.get_parent() != null: remove_child(self._dungeon)
		self._warp_region.disabled = false

func _process(_delta):
	if WorldSystem.has_flag(WorldSystem.WorldFlags.PLAYER_CONTROL_ENABLED):
		var should_be_inside = _dungeon_data.get_current_dungeon() != null
		if should_be_inside && !self._is_inside:
			_is_inside = true
			_fade_in_dungeon()
		elif !should_be_inside && self._is_inside:
			_is_inside = false
			_fade_in_outside()
		
func _fade_in_dungeon():
	WorldSystem.push_flags(WorldSystem.WorldFlags.PHYSICS_ENABLED)
	if !SceneManager.transitioned_out:
		SceneManager.transition = SceneManager.TransitionKind.TRANSITION_SLOW_FADE
		yield (SceneManager.transition_out(), "completed")
	
	add_child(self._dungeon)
	remove_child(self._outside)
	self._warp_region.disabled = true
	
	if SceneManager.transitioned_out:
		SceneManager.transition = SceneManager.TransitionKind.TRANSITION_FADE
		yield (SceneManager.transition_in(), "completed")
	WorldSystem.pop_flags()
	
func _fade_in_outside():
	WorldSystem.push_flags(WorldSystem.WorldFlags.PHYSICS_ENABLED)
	if !SceneManager.transitioned_out:
		SceneManager.transition = SceneManager.TransitionKind.TRANSITION_SLOW_FADE
		yield (SceneManager.transition_out(), "completed")
	
	add_child(self._dungeon)
	remove_child(self._outside)
	self._warp_region.disabled = false
	
	if SceneManager.transitioned_out:
		SceneManager.transition = SceneManager.TransitionKind.TRANSITION_FADE
		yield (SceneManager.transition_in(), "completed")
	WorldSystem.pop_flags()
