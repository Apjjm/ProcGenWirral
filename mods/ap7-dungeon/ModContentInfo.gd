extends ContentInfo

func init_content():
	.init_content()

	var globals = Node.new()
	globals.name = "Ap7Dungeon"
	DLC.add_child(globals)
	
	globals.add_child(load("res://mods/ap7-dungeon/globals/SigilMoves.gd").new())
	globals.add_child(load("res://mods/ap7-dungeon/globals/TreasureTable.gd").new())
	globals.add_child(load("res://mods/ap7-dungeon/globals/MonsterTable.gd").new())
	globals.add_child(load("res://mods/ap7-dungeon/globals/PlayerData.gd").new())
	globals.add_child(load("res://mods/ap7-dungeon/globals/DungeonData.gd").new())
	globals.add_child(load("res://mods/ap7-dungeon/globals/ModConsole.gd").new())

	ShaderCache.queue_shaders(load("res://mods/ap7-dungeon/shaders/PrecompileShaders.tscn"))
