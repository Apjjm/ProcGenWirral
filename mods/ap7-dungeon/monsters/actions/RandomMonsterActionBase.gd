extends Action

const EnemyRootNode = preload("../../floorgen/EnemyRootNode.gd")
const RangerRootNode = preload("../../floorgen/RangerRootNode.gd")
const RandomParcelRngRoot = preload("../../parcels/RandomParcelRngRoot.gd")

var rng = null

func _ready():
	var enemy_root = EnemyRootNode.find_enemy_root(self)
	if enemy_root != null:
		self.rng = Random.new(enemy_root.enemy_rng.rand_int())
		return

	var ranger_root = RangerRootNode.find_ranger_root(self)
	if ranger_root != null:
		self.rng = Random.new(ranger_root.enemy_rng.rand_int())
		return

	var rng_root = RandomParcelRngRoot.find_rng_root(self)
	if rng_root != null:
		self.rng = Random.new(rng_root.enemy_rng.rand_int())
		return

	print("[RandomMonsterAction] no root found, using unseeded fallback")
	self.rng = Random.new()
