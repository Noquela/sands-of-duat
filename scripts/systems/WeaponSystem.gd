extends Node
class_name WeaponManager

signal weapon_switched(weapon_id: int)
signal weapon_mastery_gained(weapon_id: int, mastery_level: int)
signal special_ability_used(weapon_id: int, ability_name: String)

enum WeaponType {
	WAS_SCEPTER = 0,    # Divine scepter - starting weapon
	KHOPESH = 1,        # Curved sword - balanced
	SPEAR_OF_RA = 2,    # Solar spear - range
	STAFF_OF_THOTH = 3, # Magic staff - AOE  
	BOW_OF_WINDS = 4    # Elemental bow - ranged
}

@export_group("Weapon System")
@export var starting_weapon: WeaponType = WeaponType.WAS_SCEPTER
@export var weapon_switch_speed: float = 0.3
@export var mastery_exp_per_hit: float = 5.0
@export var mastery_exp_per_kill: float = 25.0

# Current state
var current_weapon: WeaponType
var unlocked_weapons: Array[WeaponType] = []
var weapon_mastery: Dictionary = {} # weapon_id -> mastery_level
var weapon_experience: Dictionary = {} # weapon_id -> current_exp
var weapon_data: Dictionary = {}

# Special ability cooldowns
var ability_cooldowns: Dictionary = {}
var ability_ready: Dictionary = {}

# References
var player: CharacterBody3D
var combat_system: Node
var animation_player: AnimationPlayer

# Mastery requirements (exp needed for each level)
var mastery_requirements: Array[float] = [0, 100, 300, 600, 1000, 1500, 2200, 3000, 4000, 5500]

func _ready():
	setup_weapon_system()
	initialize_weapon_data()
	unlock_weapon(starting_weapon)
	# For testing - unlock all weapons
	unlock_weapon(WeaponType.KHOPESH)
	unlock_weapon(WeaponType.SPEAR_OF_RA) 
	unlock_weapon(WeaponType.STAFF_OF_THOTH)
	unlock_weapon(WeaponType.BOW_OF_WINDS)
	equip_weapon(starting_weapon)

func _process(delta):
	update_ability_cooldowns(delta)

func setup_weapon_system():
	add_to_group("weapon_system")
	player = get_parent()
	if not player or not player is CharacterBody3D:
		push_error("WeaponSystem must be child of CharacterBody3D (Player)")
		return
	
	# Find animation player
	animation_player = player.get_node_or_null("AnimationPlayer")
	if not animation_player:
		push_warning("AnimationPlayer not found - weapon animations disabled")
	
	print("Weapon System initialized")

func initialize_weapon_data():
	# Was Scepter of Ra - Divine authority starting weapon
	weapon_data[WeaponType.WAS_SCEPTER] = {
		"name": "Was Scepter of Ra",
		"description": "Divine scepter of royal authority, blessed with solar power",
		"base_damage": 35.0,
		"attack_speed": 1.2,
		"range": 2.5,
		"crit_chance": 15.0,
		"crit_multiplier": 2.0,
		"special_cooldown": 8.0,
		"special_ability": "Divine Authority",
		"element": "Light",
		"weapon_class": "Scepter",
		"boon_tags": ["divine", "authority", "light", "fire"]
	}
	
	# Khopesh of Pharaohs - Balanced royal combat
	weapon_data[WeaponType.KHOPESH] = {
		"name": "Khopesh of Pharaohs",
		"description": "Curved blade of ancient kings, perfect balance of power and speed",
		"base_damage": 45.0,
		"attack_speed": 1.5,
		"range": 2.0,
		"crit_chance": 20.0,
		"crit_multiplier": 2.2,
		"special_cooldown": 6.0,
		"special_ability": "Royal Combo",
		"element": "Physical",
		"weapon_class": "Blade",
		"boon_tags": ["royal", "balanced", "combo", "pharaoh"]
	}
	
	# Spear of Ra - Solar range weapon
	weapon_data[WeaponType.SPEAR_OF_RA] = {
		"name": "Spear of Ra",
		"description": "Long spear infused with the power of the sun god",
		"base_damage": 40.0,
		"attack_speed": 1.0,
		"range": 4.0,
		"crit_chance": 12.0,
		"crit_multiplier": 2.5,
		"special_cooldown": 10.0,
		"special_ability": "Solar Thrust",
		"element": "Solar",
		"weapon_class": "Spear",
		"boon_tags": ["solar", "range", "thrust", "ra"]
	}
	
	# Staff of Thoth - Knowledge magic AOE
	weapon_data[WeaponType.STAFF_OF_THOTH] = {
		"name": "Staff of Thoth",
		"description": "Ancient staff containing the wisdom of the god of knowledge",
		"base_damage": 30.0,
		"attack_speed": 0.8,
		"range": 3.5,
		"crit_chance": 25.0,
		"crit_multiplier": 1.8,
		"special_cooldown": 12.0,
		"special_ability": "Wisdom Burst",
		"element": "Magic",
		"weapon_class": "Staff",
		"boon_tags": ["magic", "knowledge", "aoe", "thoth"]
	}
	
	# Bow of the Winds - Elemental ranged
	weapon_data[WeaponType.BOW_OF_WINDS] = {
		"name": "Bow of the Winds",
		"description": "Mystical bow that channels the power of desert winds",
		"base_damage": 50.0,
		"attack_speed": 1.8,
		"range": 8.0,
		"crit_chance": 30.0,
		"crit_multiplier": 2.8,
		"special_cooldown": 15.0,
		"special_ability": "Wind Arrow Volley",
		"element": "Wind",
		"weapon_class": "Bow",
		"boon_tags": ["wind", "ranged", "elemental", "volley"]
	}
	
	# Initialize mastery and experience
	for weapon in WeaponType.values():
		weapon_mastery[weapon] = 0
		weapon_experience[weapon] = 0.0
		ability_ready[weapon] = true
		ability_cooldowns[weapon] = 0.0
	
	print("Weapon data initialized for 5 Egyptian weapons")

func equip_weapon(weapon_type: WeaponType):
	if weapon_type not in unlocked_weapons:
		print("Weapon ", get_weapon_name(weapon_type), " is locked")
		return false
	
	var previous_weapon = current_weapon
	current_weapon = weapon_type
	
	# Apply weapon stats to player
	apply_weapon_stats()
	
	# Change animations if available
	if animation_player:
		change_weapon_animation_set(weapon_type)
	
	# Visual weapon change (placeholder - would load actual weapon models)
	update_weapon_visual()
	
	weapon_switched.emit(weapon_type)
	print("Equipped ", get_weapon_name(weapon_type))
	
	return true

func apply_weapon_stats():
	var data = weapon_data[current_weapon]
	var mastery_level = weapon_mastery[current_weapon]
	
	# Base stats with mastery bonuses
	var damage_bonus = mastery_level * 5.0  # +5 damage per mastery level
	var speed_bonus = mastery_level * 0.05   # +5% speed per mastery level
	var crit_bonus = mastery_level * 2.0     # +2% crit per mastery level
	
	# Apply to player meta (other systems can read these)
	player.set_meta("weapon_damage", data.base_damage + damage_bonus)
	player.set_meta("weapon_speed", data.attack_speed + speed_bonus)
	player.set_meta("weapon_range", data.range)
	player.set_meta("weapon_crit_chance", data.crit_chance + crit_bonus)
	player.set_meta("weapon_crit_multiplier", data.crit_multiplier)
	player.set_meta("weapon_element", data.element)
	player.set_meta("weapon_class", data.weapon_class)
	player.set_meta("weapon_boon_tags", data.boon_tags)
	
	print("Applied stats for ", data.name, " with mastery level ", mastery_level)

func change_weapon_animation_set(weapon_type: WeaponType):
	# Each weapon would have different animation sets
	var anim_set = ""
	match weapon_type:
		WeaponType.WAS_SCEPTER:
			anim_set = "scepter_"
		WeaponType.KHOPESH:
			anim_set = "khopesh_"
		WeaponType.SPEAR_OF_RA:
			anim_set = "spear_"
		WeaponType.STAFF_OF_THOTH:
			anim_set = "staff_"
		WeaponType.BOW_OF_WINDS:
			anim_set = "bow_"
	
	# This would change animation library prefix
	# animation_player.set_animation_library(anim_set)
	print("Changed animation set to ", anim_set)

func update_weapon_visual():
	# Placeholder - would show/hide different weapon models
	var weapon_name = get_weapon_name(current_weapon)
	print("Visual update: ", weapon_name, " equipped")

func unlock_weapon(weapon_type: WeaponType):
	if weapon_type not in unlocked_weapons:
		unlocked_weapons.append(weapon_type)
		print("Unlocked weapon: ", get_weapon_name(weapon_type))

func gain_weapon_experience(weapon_type: WeaponType, exp_amount: float):
	if weapon_type not in unlocked_weapons:
		return
	
	weapon_experience[weapon_type] += exp_amount
	check_mastery_level_up(weapon_type)

func check_mastery_level_up(weapon_type: WeaponType):
	var current_level = weapon_mastery[weapon_type]
	var current_exp = weapon_experience[weapon_type]
	
	if current_level >= mastery_requirements.size() - 1:
		return  # Max level reached
	
	var required_exp = mastery_requirements[current_level + 1]
	
	if current_exp >= required_exp:
		weapon_mastery[weapon_type] += 1
		var new_level = weapon_mastery[weapon_type]
		
		# Reapply stats with new mastery
		if weapon_type == current_weapon:
			apply_weapon_stats()
		
		weapon_mastery_gained.emit(weapon_type, new_level)
		print(get_weapon_name(weapon_type), " mastery increased to level ", new_level)
		
		# Check for more level ups
		check_mastery_level_up(weapon_type)

func use_special_ability() -> bool:
	if not is_special_ability_ready():
		return false
	
	var data = weapon_data[current_weapon]
	var success = false
	
	match current_weapon:
		WeaponType.WAS_SCEPTER:
			success = use_divine_authority()
		WeaponType.KHOPESH:
			success = use_royal_combo()
		WeaponType.SPEAR_OF_RA:
			success = use_solar_thrust()
		WeaponType.STAFF_OF_THOTH:
			success = use_wisdom_burst()
		WeaponType.BOW_OF_WINDS:
			success = use_wind_arrow_volley()
	
	if success:
		ability_cooldowns[current_weapon] = data.special_cooldown
		ability_ready[current_weapon] = false
		special_ability_used.emit(current_weapon, data.special_ability)
		
		# Gain experience for using special ability
		gain_weapon_experience(current_weapon, 15.0)
	
	return success

# Special Ability Implementations

func use_divine_authority() -> bool:
	print("Divine Authority activated! - Solar explosion around player")
	
	# Area damage with light element
	var explosion_radius = 5.0
	var explosion_damage = get_weapon_stat("base_damage") * 1.5
	
	# Find enemies in range
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_count = 0
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = player.global_position.distance_to(enemy.global_position)
			if distance <= explosion_radius:
				if enemy.has_method("take_damage"):
					enemy.take_damage(explosion_damage, player)
					hit_count += 1
	
	# Visual effects (placeholder)
	create_divine_explosion_effect(player.global_position, explosion_radius)
	
	print("Divine Authority hit ", hit_count, " enemies for ", explosion_damage, " damage each")
	return true

func use_royal_combo() -> bool:
	print("Royal Combo activated! - Multi-hit combo sequence")
	
	# Placeholder for complex combo system
	var combo_hits = 5
	var base_damage = get_weapon_stat("base_damage")
	
	print("Executing ", combo_hits, "-hit royal combo with ", base_damage * 0.7, " damage per hit")
	
	# This would trigger animation sequence and multiple hit detections
	return true

func use_solar_thrust() -> bool:
	print("Solar Thrust activated! - Long-range piercing attack")
	
	# Long-range pierce through multiple enemies
	var thrust_range = 8.0
	var thrust_damage = get_weapon_stat("base_damage") * 2.0
	
	# Raycast implementation for piercing
	var space_state = player.get_world_3d().direct_space_state
	var forward = -player.global_transform.basis.z
	
	var query = PhysicsRayQueryParameters3D.create(
		player.global_position,
		player.global_position + forward * thrust_range
	)
	query.collision_mask = 2  # Enemies layer
	
	# This would be more complex with multiple hits
	print("Solar thrust pierces forward for ", thrust_damage, " damage")
	return true

func use_wisdom_burst() -> bool:
	print("Wisdom Burst activated! - AOE magical explosion")
	
	# Large AOE with magical damage
	var burst_radius = 7.0
	var burst_damage = get_weapon_stat("base_damage") * 1.3
	
	# Status effect application
	var status_system = get_tree().get_first_node_in_group("status_system")
	if status_system:
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if is_instance_valid(enemy):
				var distance = player.global_position.distance_to(enemy.global_position)
				if distance <= burst_radius:
					# Apply Shock status effect (3 = SHOCK enum value)
					status_system.apply_status_effect(enemy, 3, 5.0, 1.0, player)
	
	print("Wisdom Burst affects ", burst_radius, " unit radius with shock effects")
	return true

func use_wind_arrow_volley() -> bool:
	print("Wind Arrow Volley activated! - Multiple projectile barrage")
	
	# Multiple projectiles in spread pattern
	var arrow_count = 7
	var arrow_damage = get_weapon_stat("base_damage") * 0.8
	var spread_angle = 45.0
	
	print("Launching ", arrow_count, " wind arrows with ", arrow_damage, " damage each")
	
	# This would spawn actual projectile entities
	for i in arrow_count:
		var angle_offset = (i - arrow_count / 2.0) * (spread_angle / arrow_count)
		print("Arrow ", i + 1, " launched at ", angle_offset, " degree offset")
	
	return true

# Utility functions

func update_ability_cooldowns(delta: float):
	for weapon in ability_cooldowns.keys():
		if ability_cooldowns[weapon] > 0:
			ability_cooldowns[weapon] -= delta
			if ability_cooldowns[weapon] <= 0:
				ability_ready[weapon] = true

func is_special_ability_ready() -> bool:
	return ability_ready.get(current_weapon, false)

func get_special_cooldown_remaining() -> float:
	return max(0.0, ability_cooldowns.get(current_weapon, 0.0))

func get_weapon_stat(stat_name: String) -> float:
	var data = weapon_data.get(current_weapon, {})
	return data.get(stat_name, 0.0)

func get_weapon_name(weapon_type: WeaponType) -> String:
	var data = weapon_data.get(weapon_type, {})
	return data.get("name", "Unknown Weapon")

func get_weapon_description(weapon_type: WeaponType) -> String:
	var data = weapon_data.get(weapon_type, {})
	return data.get("description", "No description available")

func create_divine_explosion_effect(position: Vector3, radius: float):
	# Placeholder for divine light explosion
	print("Creating divine explosion VFX at ", position, " with radius ", radius)

# Input handling
func handle_weapon_switching():
	if Input.is_action_just_pressed("switch_weapon_1") and WeaponType.WAS_SCEPTER in unlocked_weapons:
		equip_weapon(WeaponType.WAS_SCEPTER)
	elif Input.is_action_just_pressed("switch_weapon_2") and WeaponType.KHOPESH in unlocked_weapons:
		equip_weapon(WeaponType.KHOPESH)
	elif Input.is_action_just_pressed("switch_weapon_3") and WeaponType.SPEAR_OF_RA in unlocked_weapons:
		equip_weapon(WeaponType.SPEAR_OF_RA)

# Public API
func get_current_weapon_data() -> Dictionary:
	return weapon_data.get(current_weapon, {})

func get_mastery_level(weapon_type: WeaponType) -> int:
	return weapon_mastery.get(weapon_type, 0)

func get_mastery_progress(weapon_type: WeaponType) -> float:
	var level = weapon_mastery.get(weapon_type, 0)
	var current_exp = weapon_experience.get(weapon_type, 0.0)
	
	if level >= mastery_requirements.size() - 1:
		return 1.0  # Max level
	
	var level_exp = mastery_requirements[level]
	var next_level_exp = mastery_requirements[level + 1]
	
	return (current_exp - level_exp) / (next_level_exp - level_exp)

func get_all_unlocked_weapons() -> Array[WeaponType]:
	return unlocked_weapons

func get_weapon_system_info() -> Dictionary:
	return {
		"current_weapon": get_weapon_name(current_weapon),
		"unlocked_count": unlocked_weapons.size(),
		"mastery_levels": weapon_mastery,
		"special_ready": is_special_ability_ready(),
		"cooldown_remaining": get_special_cooldown_remaining()
	}