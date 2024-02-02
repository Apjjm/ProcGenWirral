extends "ShrineRewardBaseAction.gd"

func _run():
    var tape = get_bb("shrine_tape")
    if tape != null:
        print("[ShrineRewardTapeLevelAction] Selected")
        yield (MenuHelper.level_up(tape), "completed")

    return true
