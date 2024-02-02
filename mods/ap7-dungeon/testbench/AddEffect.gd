extends Spatial

export(Resource) var status_effect = null
export(int) var amount = 1

func _ready():
	if self.visible:
		var battle = get_parent()
		if !battle.events:
			yield (battle, "ready")
		
		battle.events.connect("notified", self, "_battle_notified")

func _battle_notified(id, args):
	if id == "round_starting" && args.round_num == 0:
		for fighter in get_parent().get_fighters():
			if fighter.is_player_controlled():
				fighter.status.add_effect(status_effect, amount)
	
	return false
