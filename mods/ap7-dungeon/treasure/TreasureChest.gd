extends CollisionObject

export (Resource) var item:Resource
export (int) var quantity:int = 1
export (bool) var is_rare:bool = false

const MenuScene = preload("./GetTreasureMessage.tscn")
const TreasureRootNode = preload("../floorgen/TreasureRootNode.gd")

onready var animation_player = $AnimationPlayer
onready var interaction = $Interaction

var opened : bool = false
var rng : Random = null

func _ready():
	var rr = TreasureRootNode.find_treasure_root(self)
	
	self.opened = false
	self.rng = rr.loot_rng if rr != null else Random.new()
	interaction.disabled = self.opened

	animation_player.play_backwards("open")
	animation_player.seek(0, true)

func _interact(_player):
	if self.opened:
		return
	
	WorldSystem.push_flags(WorldSystem.WorldFlags.PHYSICS_ENABLED)
		
	animation_player.play("open")
	self.opened = true
	yield (animation_player, "animation_finished")
	interaction.disabled = true
	
	GlobalMessageDialog.clear_state()
	var menu = MenuScene.instance()
	var item = ItemFactory.generate_item(self.item, self.rng)
	var leftover = SaveState.inventory.add_new_item(item, self.quantity)
	if leftover > 0:
		WorldSystem.drop_item(item, leftover)
	
	yield(menu.run_oneshot_menu(item, self.quantity, self.is_rare), "completed")
	
	WorldSystem.pop_flags()
