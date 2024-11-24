extends Spatial

const DungeonData = preload("../globals/DungeonData.gd")

var _outside = null
var _dungeon = null
var _djinn = null
var _warp_region = null

func _notification(what):
	# Because this scene can live on outside the tree in the scene manager...
	if !Engine.editor_hint && what == NOTIFICATION_PREDELETE:
		if self._outside != null && is_instance_valid(self._outside):
			self._outside.queue_free()
		self._outside = null
		
		if self._dungeon != null && is_instance_valid(self._dungeon):
			self._dungeon.queue_free()
		self._dungeon = null

		if self._djinn != null && is_instance_valid(self._djinn):
			self._djinn.queue_free()
		self._djinn = null

func _enter_tree():
	self._outside = self._outside if self._outside != null else get_node("Outside")
	self._dungeon = self._dungeon if self._dungeon != null else get_node("Dungeon")
	self._djinn = self._djinn if self._djinn != null else get_node("Djinn")
	self._warp_region = self._warp_region if self._warp_region != null else get_node("WarpRegion")
	
	var dd = DungeonData.get_global()
	if dd != null && dd.get_current_dungeon() != null:
		if self._outside.get_parent() != null: remove_child(self._outside)
		if self._djinn.get_parent() != null: remove_child(self._djinn)
		if self._dungeon.get_parent() == null: add_child(self._dungeon)
		self._warp_region.disabled = true
	else:
		if self._outside.get_parent() == null: add_child(self._outside)
		if self._djinn.get_parent() == null: add_child(self._djinn)
		if self._dungeon.get_parent() != null: remove_child(self._dungeon)
		self._warp_region.disabled = false

func _ready():
	var dd = DungeonData.get_global()
	dd.connect("dungeon_started", self, "_on_dungeon_started")
	dd.connect("dungeon_exited", self, "_on_dungeon_exited")

	WorldSystem.connect("flags_changed", self, "_update_flags")

func _update_flags():
	# We need to defer removing the npc we're talking to until the cutscene ends, otherwise we get softlocked
	if WorldSystem.is_physics_enabled() && self._djinn != null && is_instance_valid(self._djinn) && self._djinn.get_parent() != null && !self._djinn.visible:
		remove_child(self._djinn)

func _on_dungeon_started():
	self._warp_region.disabled = true
	if self._dungeon != null && is_instance_valid(self._dungeon) && self._dungeon.get_parent() == null:
		add_child(self._dungeon)
		
	if self._outside != null && is_instance_valid(self._outside) && self._outside.get_parent() != null:
		remove_child(self._outside)

	if self._djinn != null && is_instance_valid(self._djinn) && self._djinn.get_parent() != null:
		self._djinn.visible = false

func _on_dungeon_exited():
	self._warp_region.disabled = false

	if self._dungeon != null && is_instance_valid(self._dungeon) && self._dungeon.get_parent() != null:
		remove_child(self._dungeon)
		
	if self._outside != null && is_instance_valid(self._outside) && self._outside.get_parent() == null:
		add_child(self._outside)
	
	if self._djinn != null && is_instance_valid(self._djinn) && self._djinn.get_parent() == null:
		add_child(self._djinn)
		self._djinn.visible = true

