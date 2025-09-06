extends Node
class_name WeaponAspectSystem

signal aspect_unlocked(weapon_name: String, aspect_id: String)
signal aspect_equipped(weapon_name: String, aspect_id: String)

@export_group("Aspect Settings")
@export var aspects_unlock_cost: int = 50  # Memory fragments to unlock each aspect
@export var aspects_per_weapon: int = 4

# Weapon aspect definitions
var weapon_aspects: Dictionary = {}
var unlocked_aspects: Dictionary = {}  # weapon -> [aspect_ids]
var equipped_aspects: Dictionary = {}  # weapon -> aspect_id

# References
var memory_system: Node
var weapon_system: Node

func _ready():
	setup_aspect_system()
	initialize_weapon_aspects()
	find_system_references()
	load_aspect_progress()

func setup_aspect_system():
	add_to_group("weapon_aspect_system")
	print("Weapon Aspect System initialized")

func find_system_references():
	memory_system = get_tree().get_first_node_in_group("memory_system")
	weapon_system = get_tree().get_first_node_in_group("weapon_system")

func initialize_weapon_aspects():
	# KHOPESH - Pharaoh's Sword Aspects
	weapon_aspects["Khopesh"] = {
		"base": {
			"name": "Royal Khopesh",
			"description": "The classic curved blade of Egyptian royalty.",
			"unlocked": true,
			"effects": {}
		},
		"aspect_of_ra": {
			"name": "Aspect of Ra",
			"description": "Blessed by the sun god. Attacks burn enemies and heal allies in sunlight.",
			"unlocked": false,
			"effects": {
				"burn_on_hit": 0.3,
				"burn_damage": 15,
				"burn_duration": 5.0,
				"heal_allies_in_light": 5,
				"damage_multiplier_in_light": 1.25
			}
		},
		"aspect_of_khenti": {
			"name": "Aspect of Khenti-ka-es",
			"description": "Channeling Khenti's crocodile fury. Attacks have chance to grip and death roll enemies.",
			"unlocked": false,
			"effects": {
				"death_roll_chance": 0.2,
				"death_roll_damage": 50,
				"grip_duration": 2.0,
				"movement_speed_on_kill": 0.3,
				"damage_vs_gripped": 1.5
			}
		},
		"aspect_of_anubis": {
			"name": "Aspect of Anubis",
			"description": "Guided by the judge of the dead. Crits mark enemies for death, dealing % max health damage.",
			"unlocked": false,
			"effects": {
				"death_mark_on_crit": true,
				"death_mark_damage_percent": 0.15,
				"death_mark_duration": 8.0,
				"crit_chance_vs_low_health": 0.25,
				"execute_threshold": 0.2
			}
		},
		"aspect_of_set": {
			"name": "Aspect of Set",
			"description": "Chaos incarnate. Each enemy killed increases damage and speed, but reduces max health.",
			"unlocked": false,
			"effects": {
				"kill_stack_damage": 0.1,
				"kill_stack_speed": 0.05,
				"kill_stack_health_cost": 5,
				"max_kill_stacks": 20,
				"berserker_mode_threshold": 10
			}
		}
	}
	
	# STAFF OF WAS - Divine Staff Aspects
	weapon_aspects["Staff"] = {
		"base": {
			"name": "Staff of Was",
			"description": "A divine staff channeling the power of Egyptian gods.",
			"unlocked": true,
			"effects": {}
		},
		"aspect_of_thoth": {
			"name": "Aspect of Thoth",
			"description": "Blessed by wisdom. Spells have increased range and penetrate multiple enemies.",
			"unlocked": false,
			"effects": {
				"spell_range_multiplier": 1.5,
				"spell_penetration": 3,
				"wisdom_stacks_on_cast": 1,
				"wisdom_damage_per_stack": 5,
				"max_wisdom_stacks": 25
			}
		},
		"aspect_of_isis": {
			"name": "Aspect of Isis",
			"description": "Mother goddess's protection. Spells heal allies and create protective barriers.",
			"unlocked": false,
			"effects": {
				"heal_allies_on_cast": 20,
				"barrier_strength": 30,
				"barrier_duration": 10.0,
				"spell_cooldown_reduction": 0.25,
				"resurrect_chance": 0.1
			}
		},
		"aspect_of_ptah": {
			"name": "Aspect of Ptah",
			"description": "The creator's craft. Spells summon construct allies that fight alongside you.",
			"unlocked": false,
			"effects": {
				"construct_summon_chance": 0.4,
				"construct_health": 100,
				"construct_damage": 25,
				"construct_duration": 15.0,
				"max_constructs": 3
			}
		},
		"aspect_of_nut": {
			"name": "Aspect of Nut",
			"description": "Sky goddess's embrace. Spells rain down from above and control the battlefield.",
			"unlocked": false,
			"effects": {
				"aerial_spell_bonus": 0.5,
				"rain_spell_area": 2.0,
				"levitation_on_cast": 2.0,
				"storm_buildup_per_cast": 1,
				"storm_damage_threshold": 10
			}
		}
	}
	
	# BOW OF NEITH - Hunter's Bow Aspects
	weapon_aspects["Bow"] = {
		"base": {
			"name": "Bow of Neith",
			"description": "The huntress goddess's favored weapon.",
			"unlocked": true,
			"effects": {}
		},
		"aspect_of_neith": {
			"name": "Aspect of Neith",
			"description": "Perfect huntress aim. Arrows seek targets and multiply on precision shots.",
			"unlocked": false,
			"effects": {
				"seeking_arrows": true,
				"arrow_split_on_precision": 3,
				"precision_window": 0.2,
				"tracking_range": 8.0,
				"headshot_multiplier": 3.0
			}
		},
		"aspect_of_sobek": {
			"name": "Aspect of Sobek",
			"description": "Crocodile god's ferocity. Arrows pierce and drag enemies toward you.",
			"unlocked": false,
			"effects": {
				"arrow_piercing": 5,
				"pull_strength": 10.0,
				"pull_radius": 3.0,
				"damage_per_enemy_pierced": 0.1,
				"group_damage_bonus": 0.25
			}
		},
		"aspect_of_wadjet": {
			"name": "Aspect of Wadjet",
			"description": "Cobra goddess's venom. Arrows poison enemies and spread toxins on death.",
			"unlocked": false,
			"effects": {
				"poison_on_hit": true,
				"poison_damage": 20,
				"poison_duration": 8.0,
				"poison_spread_on_death": 5.0,
				"poison_stack_limit": 10
			}
		},
		"aspect_of_shu": {
			"name": "Aspect of Shu",
			"description": "Air god's blessing. Arrows control wind, pushing enemies and creating cyclones.",
			"unlocked": false,
			"effects": {
				"wind_push_force": 8.0,
				"cyclone_chance": 0.15,
				"cyclone_duration": 6.0,
				"cyclone_damage": 30,
				"aerial_mobility": 1.5
			}
		}
	}
	
	# BRONZE AXE - Warrior's Axe Aspects
	weapon_aspects["Axe"] = {
		"base": {
			"name": "Bronze War Axe",
			"description": "A heavy bronze axe forged for Egyptian warriors.",
			"unlocked": true,
			"effects": {}
		},
		"aspect_of_montu": {
			"name": "Aspect of Montu",
			"description": "War god's rage. Each kill increases damage and grants brief invincibility.",
			"unlocked": false,
			"effects": {
				"rage_stacks_per_kill": 1,
				"rage_damage_per_stack": 0.15,
				"rage_duration": 10.0,
				"invincibility_on_kill": 1.0,
				"berserker_threshold": 5
			}
		},
		"aspect_of_sekhmet": {
			"name": "Aspect of Sekhmet",
			"description": "Lioness goddess's fury. Low health increases damage exponentially and spreads plague.",
			"unlocked": false,
			"effects": {
				"low_health_damage_multiplier": 3.0,
				"low_health_threshold": 0.3,
				"plague_spread_chance": 0.25,
				"plague_damage": 25,
				"bloodlust_healing": 15
			}
		},
		"aspect_of_khnum": {
			"name": "Aspect of Khnum",
			"description": "Potter god's creation. Attacks shape the battlefield, creating walls and obstacles.",
			"unlocked": false,
			"effects": {
				"wall_creation_chance": 0.3,
				"wall_health": 200,
				"wall_duration": 20.0,
				"terrain_shaping": true,
				"construction_damage_bonus": 0.5
			}
		},
		"aspect_of_geb": {
			"name": "Aspect of Geb",
			"description": "Earth god's strength. Attacks cause earthquakes and pull power from the ground.",
			"unlocked": false,
			"effects": {
				"earthquake_chance": 0.2,
				"earthquake_radius": 6.0,
				"earthquake_damage": 40,
				"earth_power_stacks": 1,
				"damage_per_earth_stack": 8
			}
		}
	}
	
	# SPEAR OF HORUS - Divine Spear Aspects  
	weapon_aspects["Spear"] = {
		"base": {
			"name": "Spear of Horus",
			"description": "The falcon god's weapon of precision and speed.",
			"unlocked": true,
			"effects": {}
		},
		"aspect_of_horus": {
			"name": "Aspect of Horus",
			"description": "Sky god's sight. Perfect accuracy and attacks from impossible angles.",
			"unlocked": false,
			"effects": {
				"perfect_accuracy": true,
				"angle_independence": true,
				"falcon_dive_damage": 2.0,
				"height_damage_bonus": 0.1,
				"sky_vision_range": 15.0
			}
		},
		"aspect_of_min": {
			"name": "Aspect of Min",
			"description": "Fertility god's blessing. Attacks plant seeds that grow into damaging thorns.",
			"unlocked": false,
			"effects": {
				"seed_plant_chance": 0.4,
				"thorn_growth_time": 3.0,
				"thorn_damage": 35,
				"thorn_duration": 12.0,
				"nature_healing": 3
			}
		},
		"aspect_of_khenti_amentiu": {
			"name": "Aspect of Khenti-Amentiu",
			"description": "Lord of the West's judgment. Spear throws judge enemies, dealing damage based on their sins.",
			"unlocked": false,
			"effects": {
				"judgment_damage_multiplier": 2.5,
				"sin_stack_per_action": 1,
				"max_sin_stacks": 15,
				"divine_judgment_threshold": 10,
				"purification_healing": 25
			}
		},
		"aspect_of_wepwawet": {
			"name": "Aspect of Wepwawet",
			"description": "Opener of the Ways. Spear throws open portals, allowing tactical repositioning.",
			"unlocked": false,
			"effects": {
				"portal_creation": true,
				"portal_duration": 8.0,
				"portal_range": 12.0,
				"teleport_damage_bonus": 0.5,
				"path_finding_bonus": 1.0
			}
		}
	}
	
	print("Weapon aspects initialized: ", weapon_aspects.size(), " weapons with ", aspects_per_weapon, " aspects each")

func unlock_aspect(weapon_name: String, aspect_id: String) -> bool:
	if not weapon_aspects.has(weapon_name):
		return false
	
	if not weapon_aspects[weapon_name].has(aspect_id):
		return false
	
	# Check if already unlocked
	if is_aspect_unlocked(weapon_name, aspect_id):
		return false
	
	# Base aspect is always unlocked
	if aspect_id == "base":
		return false
	
	# Check if we can afford it
	if memory_system and not memory_system.spend_memory_fragments(aspects_unlock_cost):
		print("Not enough Memory Fragments to unlock aspect")
		return false
	
	# Unlock the aspect
	if not unlocked_aspects.has(weapon_name):
		unlocked_aspects[weapon_name] = []
	
	unlocked_aspects[weapon_name].append(aspect_id)
	weapon_aspects[weapon_name][aspect_id]["unlocked"] = true
	
	aspect_unlocked.emit(weapon_name, aspect_id)
	print("Unlocked aspect: ", weapon_aspects[weapon_name][aspect_id]["name"])
	
	save_aspect_progress()
	return true

func equip_aspect(weapon_name: String, aspect_id: String) -> bool:
	if not is_aspect_unlocked(weapon_name, aspect_id):
		return false
	
	# Unequip current aspect for this weapon
	if equipped_aspects.has(weapon_name):
		var old_aspect = equipped_aspects[weapon_name]
		if old_aspect != aspect_id:
			remove_aspect_effects(weapon_name, old_aspect)
	
	# Equip new aspect
	equipped_aspects[weapon_name] = aspect_id
	apply_aspect_effects(weapon_name, aspect_id)
	
	aspect_equipped.emit(weapon_name, aspect_id)
	print("Equipped aspect: ", get_aspect_name(weapon_name, aspect_id))
	
	save_aspect_progress()
	return true

func is_aspect_unlocked(weapon_name: String, aspect_id: String) -> bool:
	if aspect_id == "base":
		return true
	
	if not weapon_aspects.has(weapon_name):
		return false
	
	if not unlocked_aspects.has(weapon_name):
		return false
	
	return aspect_id in unlocked_aspects[weapon_name]

func get_equipped_aspect(weapon_name: String) -> String:
	return equipped_aspects.get(weapon_name, "base")

func get_aspect_info(weapon_name: String, aspect_id: String) -> Dictionary:
	if not weapon_aspects.has(weapon_name):
		return {}
	
	if not weapon_aspects[weapon_name].has(aspect_id):
		return {}
	
	var aspect = weapon_aspects[weapon_name][aspect_id].duplicate()
	aspect["weapon"] = weapon_name
	aspect["id"] = aspect_id
	aspect["unlocked"] = is_aspect_unlocked(weapon_name, aspect_id)
	aspect["equipped"] = get_equipped_aspect(weapon_name) == aspect_id
	aspect["unlock_cost"] = aspects_unlock_cost if aspect_id != "base" else 0
	
	return aspect

func get_aspect_name(weapon_name: String, aspect_id: String) -> String:
	var aspect_info = get_aspect_info(weapon_name, aspect_id)
	return aspect_info.get("name", "Unknown Aspect")

func get_weapon_aspects(weapon_name: String) -> Array:
	if not weapon_aspects.has(weapon_name):
		return []
	
	var aspects = []
	for aspect_id in weapon_aspects[weapon_name]:
		aspects.append(get_aspect_info(weapon_name, aspect_id))
	
	return aspects

func get_all_weapon_names() -> Array:
	return weapon_aspects.keys()

func apply_aspect_effects(weapon_name: String, aspect_id: String):
	if not weapon_system:
		return
	
	var aspect_info = get_aspect_info(weapon_name, aspect_id)
	if aspect_info.is_empty():
		return
	
	var effects = aspect_info.get("effects", {})
	
	# Apply effects to weapon system
	for effect_type in effects:
		var value = effects[effect_type]
		var meta_key = "aspect_" + effect_type
		
		# Set weapon-specific aspect effects
		if weapon_system.has_method("set_weapon_aspect_effect"):
			weapon_system.set_weapon_aspect_effect(weapon_name, effect_type, value)
		else:
			# Fallback: set as meta on weapon system
			weapon_system.set_meta(weapon_name.to_lower() + "_" + meta_key, value)

func remove_aspect_effects(weapon_name: String, aspect_id: String):
	if not weapon_system:
		return
	
	var aspect_info = get_aspect_info(weapon_name, aspect_id)
	if aspect_info.is_empty():
		return
	
	var effects = aspect_info.get("effects", {})
	
	# Remove effects from weapon system
	for effect_type in effects:
		var meta_key = "aspect_" + effect_type
		
		if weapon_system.has_method("remove_weapon_aspect_effect"):
			weapon_system.remove_weapon_aspect_effect(weapon_name, effect_type)
		else:
			# Fallback: remove meta
			weapon_system.remove_meta(weapon_name.to_lower() + "_" + meta_key)

func can_afford_aspect_unlock() -> bool:
	if not memory_system:
		return false
	return memory_system.get_memory_fragments() >= aspects_unlock_cost

func get_unlock_cost() -> int:
	return aspects_unlock_cost

func save_aspect_progress():
	var save_file = FileAccess.open("user://weapon_aspects.save", FileAccess.WRITE)
	if save_file:
		var save_data = {
			"unlocked_aspects": unlocked_aspects,
			"equipped_aspects": equipped_aspects
		}
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()

func load_aspect_progress():
	var save_path = "user://weapon_aspects.save"
	if not FileAccess.file_exists(save_path):
		# Default: equip base aspects for all weapons
		for weapon_name in weapon_aspects.keys():
			equipped_aspects[weapon_name] = "base"
		return
	
	var save_file = FileAccess.open(save_path, FileAccess.READ)
	if save_file:
		var json_string = save_file.get_as_text()
		save_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.data
			unlocked_aspects = save_data.get("unlocked_aspects", {})
			equipped_aspects = save_data.get("equipped_aspects", {})
			
			# Apply equipped aspects
			for weapon_name in equipped_aspects:
				var aspect_id = equipped_aspects[weapon_name]
				apply_aspect_effects(weapon_name, aspect_id)
			
			print("Weapon aspects loaded: ", unlocked_aspects.size(), " weapons unlocked")

# Public API for other systems
func get_aspect_effect_value(weapon_name: String, effect_type: String) -> Variant:
	var equipped_aspect = get_equipped_aspect(weapon_name)
	var aspect_info = get_aspect_info(weapon_name, equipped_aspect)
	
	if aspect_info.is_empty():
		return null
	
	var effects = aspect_info.get("effects", {})
	return effects.get(effect_type, null)

func has_aspect_effect(weapon_name: String, effect_type: String) -> bool:
	return get_aspect_effect_value(weapon_name, effect_type) != null

func get_total_unlocked_aspects() -> int:
	var total = 0
	for weapon_name in unlocked_aspects:
		total += unlocked_aspects[weapon_name].size()
	return total

func get_aspect_completion_percentage() -> float:
	var total_aspects = 0
	var unlocked_count = 0
	
	for weapon_name in weapon_aspects:
		var weapon_aspect_count = weapon_aspects[weapon_name].size() - 1  # Exclude base
		total_aspects += weapon_aspect_count
		
		if unlocked_aspects.has(weapon_name):
			unlocked_count += unlocked_aspects[weapon_name].size()
	
	if total_aspects == 0:
		return 0.0
	
	return float(unlocked_count) / float(total_aspects) * 100.0