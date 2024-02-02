tool
extends Resource
class_name ParcelSet

enum DirectionFlag { DIR_ANY = 0, DIR_N = 1, DIR_E = 2, DIR_S = 4, DIR_W = 8 };

# Zone tags for this parcel set, if applicable
export(Array, String) var zones = []

# Some parcels define a connection between zones, in this case they may have constraints about the other side of the link
export(Array, String) var target_zones = []

# Should this connection operate on NE/SW direction only (e.g. because it connects both sides)
export(int, FLAGS, "N", "E", "S", "W") var target_direction_only = 0

# are there walls that MUST be present in order for this parcel to be selected?
export(int, FLAGS, "N", "E", "S", "W") var require_occupied_wall_flags = 0

# are there walls that MUST NOT be present in order for this parcel to be selected?
export(int, FLAGS, "N", "E", "S", "W") var require_free_wall_flags = 0

# translation offset for this parcel
export(Vector3) var offset = Vector3(0,0,0)

# Collection of parcels for this set
export(Array, PackedScene) var parcels = []

func get_parcel(i: int) -> PackedScene:
	if self.parcels.size() > 0:
		return self.parcels[i % self.parcels.size()]
	
	return null

func get_random_parcel(rng: Random) -> PackedScene:
	if self.parcels.size() > 1:
		return self.parcels[rng.rand_int(self.parcels.size())]

	return self.parcels[0] if self.parcels.size() == 1 else null

func get_parcel_exact(i: int) -> PackedScene:
	return self.parcels[i]

func has_zone(zone: String) -> bool:
	return zones.size() == 0 || zone in zones || zone == "*"

func has_target_zone(zone: String) -> bool:
	return target_zones.size() == 0 || zone in target_zones || zone == "*"

func has_target_direction(dir_flag: int) -> bool:
	return target_direction_only == 0 || dir_flag == 0 || (dir_flag & target_direction_only > 0)

func has_permissable_wall_flags(dir_flags: int) -> bool:
	return ((dir_flags & self.require_occupied_wall_flags) == self.require_occupied_wall_flags) && ((dir_flags & self.require_free_wall_flags) == 0)

static func to_flags(wall_n: bool, wall_e: bool, wall_s: bool, wall_w: bool) -> int:
	return (1 if wall_n else 0) | (2 if wall_e else 0) | (4 if wall_s else 0) | (8 if wall_w else 0)