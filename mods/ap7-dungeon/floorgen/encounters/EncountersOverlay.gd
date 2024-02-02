extends Reference

var encounters: Array = []
var rangers: Array = []

class MonsterEncounter:
    var id = -1
    var seed_value: int = -1
    var overworld_form: String = ""
    var monsters: Array = []
    var plot: int = -1
    var fusion: MonsterTape = null
    var exp_multiplier: float = 1.0

class RangerEncounter:
    var id = -1
    var seed_value: int = -1
    var plot: int = -1
    var ranger_tapes : Array = []
    var partner_tapes : Array = []
    var exp_multiplier: float = 1.0

class EncounterTape:
    var level : int
    var smartness: String = ""
    var form : MonsterForm = null
    var tape : MonsterTape = null

func add_ranger_encounter() -> RangerEncounter:
    var ranger = RangerEncounter.new()
    ranger.id = rangers.size()
    rangers.push_back(ranger)
    return ranger

func add_monster_encounter() -> MonsterEncounter:
    var encounter = MonsterEncounter.new()
    encounter.id = encounters.size()
    encounters.push_back(encounter)
    return encounter

func get_monster_encounter(id: int) -> MonsterEncounter:
    return encounters[id]

func get_monster_encounters() -> Array:
    return encounters

func get_ranger_encounter(id: int) -> RangerEncounter:
    return rangers[id]

func get_ranger_encounters() -> Array:
    return rangers