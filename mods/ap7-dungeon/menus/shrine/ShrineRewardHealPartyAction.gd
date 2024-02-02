extends "ShrineRewardBaseAction.gd"

func _run():
    SaveState.party.heal()
    return true