extends ContentInfo

func init_content():
	.init_content()
	DLC.add_child(load("res://mods/ap7-flag-reset/FlagResetListener.gd").new())

