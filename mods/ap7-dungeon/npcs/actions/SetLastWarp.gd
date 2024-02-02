extends Action

export(String, FILE, "*.tscn") var scene = ""
export(String) var target

func _run():
	SaveState.set_last_warp(self.scene, null, self.target)
	return true
