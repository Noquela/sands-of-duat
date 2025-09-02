extends Resource
class_name WeaponData

enum WeaponType {
	STAFF,
	SWORD,
	SPEAR,
	BOW,
	MAGIC
}

@export var name: String = ""
@export var damage: float = 10.0
@export var attack_range: float = 2.0
@export var attack_speed: float = 1.0
@export var crit_chance: float = 0.05
@export var crit_multiplier: float = 1.5
@export var weapon_type: WeaponType = WeaponType.STAFF
@export var description: String = ""

func get_dps() -> float:
	var base_dps = damage * attack_speed
	var crit_bonus = base_dps * crit_chance * (crit_multiplier - 1.0)
	return base_dps + crit_bonus