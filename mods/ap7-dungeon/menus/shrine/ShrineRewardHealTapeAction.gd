extends "ShrineRewardBaseAction.gd"

func _run():
    var tape = get_bb("shrine_tape")
    if tape != null:
        SaveState.party.heal_tape(tape)

    return true