extends Interaction

export(float) var kill_depth
export(NodePath) var respawn_path

var respawn_point = null

func _ready():
	if !self.prop_path.is_empty() && has_node(self.prop_path):
		self.respawn_point = get_node(self.respawn_path)

func _physics_process(_delta):
	if !lifting && respawn_point != null && self.global_translation.y < kill_depth:
		self.global_translation = respawn_point.global_translation
