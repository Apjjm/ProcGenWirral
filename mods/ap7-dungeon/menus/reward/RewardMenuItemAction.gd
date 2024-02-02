extends Action

enum RewardQuality { RQ_GOOD = 1, RQ_NEUTRAL = 0, RQ_BAD = -1 }

export(String) var title
export(String) var description
export(String) var requirement
export(RewardQuality) var quality
export(Resource) var icon
export(Resource) var selected_sound

func has_priority() -> bool:
	return false

func is_blocked() -> bool:
	return false

func refresh() -> void:
	pass
