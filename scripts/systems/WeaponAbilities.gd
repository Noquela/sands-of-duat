extends Node
class_name WeaponAbilities

# Advanced weapon ability system for special attacks and mastery bonuses

signal ability_upgraded(weapon_id: int, ability_name: String, upgrade_level: int)
signal mastery_milestone_reached(weapon_id: int, milestone: String)

@export_group("Mastery Settings")
@export var max_mastery_level: int = 10
@export var mastery_milestone_levels: Array[int] = [3, 5, 7, 10]
@export var ability_upgrade_intervals: int = 2  # Every 2 mastery levels

# Mastery bonuses per weapon type
var mastery_bonuses = {
	0: {  # WAS_SCEPTER
		"name": "Divine Mastery",
		"bonuses": {
			1: {"divine_damage": 10.0, "light_resistance": 5.0},
			2: {"ability_cooldown_reduction": 10.0},
			3: {"divine_explosion_radius": 20.0, "milestone": "Sacred Authority"},
			4: {"divine_damage": 20.0, "fire_damage": 15.0},
			5: {"ability_cooldown_reduction": 20.0, "milestone": "Radiant Power"},
			6: {"divine_damage": 30.0, "burn_chance": 25.0},
			7: {"divine_explosion_radius": 40.0, "milestone": "Solar Dominion"},
			8: {"divine_damage": 40.0, "ability_cooldown_reduction": 30.0},
			9: {"divine_explosion_radius": 60.0, "ultimate_unlock": true},
			10: {"milestone": "Avatar of Ra", "divine_mastery_complete": true}
		}
	},
	1: {  # KHOPESH
		"name": "Royal Combat Mastery",
		"bonuses": {
			1: {"combo_damage": 15.0, "attack_speed": 8.0},
			2: {"combo_extend_chance": 20.0},
			3: {"royal_fury_duration": 2.0, "milestone": "Pharaoh's Grace"},
			4: {"combo_damage": 25.0, "crit_chance": 10.0},
			5: {"combo_extend_chance": 35.0, "milestone": "Dynasty Warrior"},
			6: {"royal_fury_damage": 50.0, "cleave_range": 1.5},
			7: {"combo_finisher_unlock": true, "milestone": "King's Blade"},
			8: {"combo_damage": 40.0, "attack_speed": 15.0},
			9: {"infinite_combo_chance": 15.0, "ultimate_unlock": true},
			10: {"milestone": "Eternal Pharaoh", "royal_mastery_complete": true}
		}
	},
	2: {  # SPEAR_OF_RA
		"name": "Solar Spear Mastery", 
		"bonuses": {
			1: {"thrust_damage": 20.0, "pierce_chance": 25.0},
			2: {"solar_burn_duration": 1.0},
			3: {"thrust_range": 1.0, "milestone": "Sun Piercer"},
			4: {"thrust_damage": 35.0, "solar_explosion_chance": 20.0},
			5: {"pierce_chance": 50.0, "milestone": "Radiant Lancer"},
			6: {"thrust_range": 2.0, "solar_burn_damage": 30.0},
			7: {"solar_beam_unlock": true, "milestone": "Ra's Champion"},
			8: {"thrust_damage": 50.0, "pierce_chance": 75.0},
			9: {"solar_explosion_chance": 40.0, "ultimate_unlock": true},
			10: {"milestone": "Solar Avatar", "spear_mastery_complete": true}
		}
	},
	3: {  # STAFF_OF_THOTH
		"name": "Knowledge Mastery",
		"bonuses": {
			1: {"wisdom_damage": 25.0, "mana_efficiency": 15.0},
			2: {"knowledge_stun_duration": 0.5},
			3: {"wisdom_aoe_radius": 1.0, "milestone": "Sage's Wisdom"},
			4: {"wisdom_damage": 40.0, "spell_crit_chance": 20.0},
			5: {"mana_efficiency": 30.0, "milestone": "Thoth's Disciple"},
			6: {"knowledge_chain_targets": 2, "wisdom_aoe_radius": 2.0},
			7: {"arcane_mastery_unlock": true, "milestone": "Master Scribe"},
			8: {"wisdom_damage": 60.0, "spell_crit_multiplier": 0.5},
			9: {"knowledge_chain_targets": 4, "ultimate_unlock": true},
			10: {"milestone": "Avatar of Knowledge", "wisdom_mastery_complete": true}
		}
	},
	4: {  # BOW_OF_WINDS
		"name": "Wind Mastery",
		"bonuses": {
			1: {"arrow_damage": 18.0, "wind_speed": 20.0},
			2: {"arrow_pierce_count": 1},
			3: {"wind_volley_count": 2, "milestone": "Desert Storm"},
			4: {"arrow_damage": 30.0, "elemental_proc_chance": 25.0},
			5: {"arrow_pierce_count": 2, "milestone": "Wind Walker"},
			6: {"wind_volley_count": 3, "tornado_chance": 15.0},
			7: {"hurricane_arrow_unlock": true, "milestone": "Storm Master"},
			8: {"arrow_damage": 45.0, "elemental_proc_chance": 40.0},
			9: {"tornado_chance": 30.0, "ultimate_unlock": true},
			10: {"milestone": "Wind Avatar", "storm_mastery_complete": true}
		}
	}
}

# Ability upgrade data
var ability_upgrades = {
	0: {  # WAS_SCEPTER abilities
		"divine_authority": {
			1: {"explosion_radius": "+20%", "damage": "+15%"},
			2: {"burn_application": "25% chance", "cooldown": "-15%"},
			3: {"double_explosion": "50% chance", "damage": "+25%"},
			4: {"divine_mark": "Enemies take +30% damage", "cooldown": "-25%"},
			5: {"avatar_mode": "3s invulnerability + 100% damage", "cooldown": "-35%"}
		}
	},
	1: {  # KHOPESH abilities
		"royal_combo": {
			1: {"combo_length": "+1 hit", "damage": "+20%"},
			2: {"combo_healing": "5% max HP per hit", "speed": "+15%"},
			3: {"combo_finisher": "Devastating final strike", "damage": "+30%"},
			4: {"combo_rage": "Each hit reduces all cooldowns", "speed": "+25%"},
			5: {"eternal_combo": "15% chance to not end combo", "damage": "+50%"}
		}
	},
	2: {  # SPEAR_OF_RA abilities
		"solar_thrust": {
			1: {"pierce_count": "+2 enemies", "damage": "+25%"},
			2: {"solar_burn": "Pierced enemies burn for 5s", "range": "+20%"},
			3: {"thrust_beam": "Continuous solar beam", "damage": "+35%"},
			4: {"solar_explosion": "Explodes on final pierce", "range": "+30%"},
			5: {"ra_blessing": "Allies gain solar damage buff", "damage": "+60%"}
		}
	},
	3: {  # STAFF_OF_THOTH abilities  
		"wisdom_burst": {
			1: {"chain_targets": "+2 enemies", "damage": "+20%"},
			2: {"knowledge_stun": "2s stun on crit", "mana_cost": "-20%"},
			3: {"arcane_explosion": "Secondary blast", "damage": "+30%"},
			4: {"mind_control": "Convert enemy for 5s", "chain_targets": "+2"},
			5: {"omniscience": "Affects all visible enemies", "damage": "+70%"}
		}
	},
	4: {  # BOW_OF_WINDS abilities
		"wind_arrow_volley": {
			1: {"arrow_count": "+3 arrows", "damage": "+15%"},
			2: {"elemental_infusion": "Random element per arrow", "pierce": "Arrows pierce"},
			3: {"tornado_arrows": "25% chance to spawn tornado", "damage": "+25%"},
			4: {"hurricane_mode": "Continuous volley for 3s", "arrow_count": "+5"},
			5: {"storm_lord": "All arrows become tornadoes", "damage": "+80%"}
		}
	}
}

# References
var weapon_system: Node
var player: CharacterBody3D

func _ready():
	setup_weapon_abilities()

func setup_weapon_abilities():
	add_to_group("weapon_abilities")
	
	# Find weapon system
	weapon_system = get_tree().get_first_node_in_group("weapon_system")
	if not weapon_system:
		push_error("WeaponSystem not found - abilities system disabled")
		return
	
	# Connect to weapon system signals
	weapon_system.weapon_mastery_gained.connect(_on_mastery_gained)
	
	player = get_tree().get_first_node_in_group("player")
	
	print("Weapon Abilities system initialized")

func _on_mastery_gained(weapon_id: int, mastery_level: int):
	apply_mastery_bonuses(weapon_id, mastery_level)
	check_ability_upgrades(weapon_id, mastery_level)
	check_mastery_milestones(weapon_id, mastery_level)

func apply_mastery_bonuses(weapon_id: int, mastery_level: int):
	var weapon_bonuses = mastery_bonuses.get(weapon_id, {})
	var level_bonuses = weapon_bonuses.get("bonuses", {}).get(mastery_level, {})
	
	if level_bonuses.is_empty():
		return
	
	print("Applying mastery bonuses for weapon ", weapon_id, " level ", mastery_level)
	
	# Apply bonuses to player meta
	for bonus_type in level_bonuses:
		if bonus_type == "milestone" or bonus_type.ends_with("_unlock") or bonus_type.ends_with("_complete"):
			continue  # Skip special markers
		
		var bonus_value = level_bonuses[bonus_type]
		var current_value = player.get_meta("mastery_" + bonus_type, 0.0)
		player.set_meta("mastery_" + bonus_type, current_value + bonus_value)
		
		print("  ", bonus_type, ": +", bonus_value, " (total: ", current_value + bonus_value, ")")

func check_ability_upgrades(weapon_id: int, mastery_level: int):
	if mastery_level % ability_upgrade_intervals != 0:
		return  # Only upgrade every N levels
	
	var upgrade_tier = mastery_level / ability_upgrade_intervals
	var weapon_abilities = ability_upgrades.get(weapon_id, {})
	
	for ability_name in weapon_abilities:
		var ability_tiers = weapon_abilities[ability_name]
		var tier_data = ability_tiers.get(upgrade_tier, {})
		
		if not tier_data.is_empty():
			upgrade_ability(weapon_id, ability_name, upgrade_tier, tier_data)

func upgrade_ability(weapon_id: int, ability_name: String, upgrade_tier: int, upgrade_data: Dictionary):
	# Apply the upgrade to the weapon
	var upgrade_key = "ability_" + ability_name + "_tier"
	player.set_meta(upgrade_key, upgrade_tier)
	
	ability_upgraded.emit(weapon_id, ability_name, upgrade_tier)
	
	print("Ability upgraded: ", ability_name, " -> Tier ", upgrade_tier)
	for upgrade_type in upgrade_data:
		print("  ", upgrade_type, ": ", upgrade_data[upgrade_type])

func check_mastery_milestones(weapon_id: int, mastery_level: int):
	if mastery_level not in mastery_milestone_levels:
		return
	
	var weapon_bonuses = mastery_bonuses.get(weapon_id, {})
	var level_bonuses = weapon_bonuses.get("bonuses", {}).get(mastery_level, {})
	var milestone = level_bonuses.get("milestone", "")
	
	if milestone != "":
		mastery_milestone_reached.emit(weapon_id, milestone)
		print("Mastery Milestone Reached: ", milestone)
		
		# Special milestone effects
		apply_milestone_effects(weapon_id, milestone, mastery_level)

func apply_milestone_effects(weapon_id: int, milestone: String, level: int):
	# Special effects for major milestones
	match milestone:
		"Avatar of Ra", "Eternal Pharaoh", "Solar Avatar", "Avatar of Knowledge", "Wind Avatar":
			# Ultimate mastery - unlock weapon's true form
			player.set_meta("ultimate_mastery_" + str(weapon_id), true)
			print("Ultimate mastery unlocked for weapon ", weapon_id, "!")
		
		"Sacred Authority", "Pharaoh's Grace", "Sun Piercer", "Sage's Wisdom", "Desert Storm":
			# Mid-tier milestones - significant bonuses
			player.set_meta("milestone_bonus_" + str(weapon_id) + "_" + str(level), true)
			print("Major milestone bonus applied: ", milestone)

# Ability execution with mastery bonuses
func execute_enhanced_ability(weapon_id: int, base_ability_func: Callable) -> bool:
	# Apply mastery bonuses before ability execution
	apply_pre_ability_bonuses(weapon_id)
	
	# Execute the base ability
	var success = base_ability_func.call()
	
	if success:
		# Apply post-ability effects
		apply_post_ability_effects(weapon_id)
	
	return success

func apply_pre_ability_bonuses(weapon_id: int):
	# Apply mastery bonuses that affect ability execution
	var cooldown_reduction = player.get_meta("mastery_ability_cooldown_reduction", 0.0)
	if cooldown_reduction > 0:
		# This would modify the actual cooldown in WeaponSystem
		var reduction_multiplier = 1.0 - (cooldown_reduction / 100.0)
		player.set_meta("current_ability_cooldown_multiplier", reduction_multiplier)

func apply_post_ability_effects(weapon_id: int):
	# Apply effects that trigger after successful ability use
	var mana_efficiency = player.get_meta("mastery_mana_efficiency", 0.0)
	if mana_efficiency > 0:
		# Restore some mana based on efficiency mastery
		var mana_restore = mana_efficiency * 2.0
		# This would integrate with AbilitySystem if available
		print("Mastery mana efficiency restored ", mana_restore, " mana")

# Public API for getting mastery information
func get_weapon_mastery_info(weapon_id: int) -> Dictionary:
	var weapon_bonuses = mastery_bonuses.get(weapon_id, {})
	var mastery_name = weapon_bonuses.get("name", "Unknown Mastery")
	
	return {
		"name": mastery_name,
		"current_level": weapon_system.get_mastery_level(weapon_id) if weapon_system else 0,
		"progress": weapon_system.get_mastery_progress(weapon_id) if weapon_system else 0.0,
		"next_milestone": get_next_milestone(weapon_id),
		"active_bonuses": get_active_bonuses(weapon_id)
	}

func get_next_milestone(weapon_id: int) -> String:
	if not weapon_system:
		return ""
	
	var current_level = weapon_system.get_mastery_level(weapon_id)
	var weapon_bonuses = mastery_bonuses.get(weapon_id, {})
	var bonuses = weapon_bonuses.get("bonuses", {})
	
	# Find next level with milestone
	for level in range(current_level + 1, max_mastery_level + 1):
		var level_data = bonuses.get(level, {})
		if "milestone" in level_data:
			return level_data["milestone"]
	
	return "Max Level Reached"

func get_active_bonuses(weapon_id: int) -> Array:
	if not weapon_system:
		return []
	
	var current_level = weapon_system.get_mastery_level(weapon_id)
	var active_bonuses = []
	var weapon_bonuses = mastery_bonuses.get(weapon_id, {})
	var bonuses = weapon_bonuses.get("bonuses", {})
	
	# Collect all bonuses from level 1 to current level
	for level in range(1, current_level + 1):
		var level_bonuses = bonuses.get(level, {})
		for bonus_type in level_bonuses:
			if bonus_type != "milestone" and not bonus_type.ends_with("_unlock") and not bonus_type.ends_with("_complete"):
				active_bonuses.append({
					"type": bonus_type,
					"value": level_bonuses[bonus_type],
					"level": level
				})
	
	return active_bonuses

func get_ability_upgrade_info(weapon_id: int, ability_name: String) -> Dictionary:
	var weapon_abilities = ability_upgrades.get(weapon_id, {})
	var ability_tiers = weapon_abilities.get(ability_name, {})
	
	if not weapon_system:
		return {}
	
	var current_level = weapon_system.get_mastery_level(weapon_id)
	var current_tier = current_level / ability_upgrade_intervals
	var next_tier = current_tier + 1
	
	return {
		"current_tier": current_tier,
		"current_upgrades": ability_tiers.get(current_tier, {}),
		"next_tier": next_tier,
		"next_upgrades": ability_tiers.get(next_tier, {}),
		"max_tier": ability_tiers.keys().max() if not ability_tiers.is_empty() else 0
	}

# Helper function to check if player has specific mastery bonus
func has_mastery_bonus(bonus_type: String) -> bool:
	return player.has_meta("mastery_" + bonus_type) and player.get_meta("mastery_" + bonus_type) > 0

# Helper function to get mastery bonus value
func get_mastery_bonus_value(bonus_type: String) -> float:
	return player.get_meta("mastery_" + bonus_type, 0.0)