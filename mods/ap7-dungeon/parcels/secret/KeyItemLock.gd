extends WiredInteraction

export(Resource) var key_item = null
export (bool) var remove_pawn_on_unlock:bool = true
onready var animation_player = $AnimationPlayer

func _ready():
	_refresh()

func _refresh():
	if state:
		set_disabled(true)
		if self.remove_pawn_on_unlock && get_pawn():
			get_pawn().queue_free()

func interact(player):
	if !state && (animation_player == null || !animation_player.is_playing()):
		if MenuHelper.consume_item(key_item):
			.interact(player)
			set_disabled(true)
			if animation_player != null:
				animation_player.play("press")
			else:
				set_state(true)
