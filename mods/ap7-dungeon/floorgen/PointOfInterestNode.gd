extends Position3D
class_name PointOfInterest

const RoomRootNode = preload("RoomRootNode.gd")

export(int, FLAGS, "Start", "Unused", "Enemy", "Treasure", "Ranger") var possible_types = 0x0F
var allocated_type = 0

func _enter_tree():
	var root = RoomRootNode.find_room_root(self)
	if root != null:
		root.register_point_of_interest(self)

func can_be_start() -> bool:
	return (possible_types & 1) > 0

#func can_be_exit() -> bool:
#	return (possible_types & 2) > 0

func can_be_enemy() -> bool:
	return (possible_types & 4) > 0

func can_be_treasure() -> bool:
	return (possible_types & 8) > 0

func can_be_ranger() -> bool:
	return (possible_types & 16) > 0

func is_allocated() -> bool:
	return allocated_type > 0

func is_start() -> bool:
	return (allocated_type & 1) > 0

#func is_exit() -> bool:
#	return (allocated_type & 2) > 0

func is_enemy() -> bool:
	return (allocated_type & 4) > 0

func is_treasure() -> bool:
	return (allocated_type & 8) > 0

func is_ranger() -> bool:
	return (allocated_type & 16) > 0

func allocate_start() -> void:
	allocated_type |= 1

#func allocate_exit() -> void:
#	allocated_type |= 2

func allocate_enemy() -> void:
	allocated_type |= 4

func allocate_treasure() -> void:
	allocated_type |= 8

func allocate_ranger() -> void:
	allocated_type |= 16
