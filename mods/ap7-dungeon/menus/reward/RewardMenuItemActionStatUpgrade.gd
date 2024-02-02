extends "RewardMenuItemAction.gd"

export(String) var stat_key = ""
export(int) var boost = 1

func _run():
    SaveState.stats.get_stat("exchange_purchased").report_event(stat_key, 1)
    return true