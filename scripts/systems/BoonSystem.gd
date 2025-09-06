extends Node
class_name BoonSystem

signal boon_selected(boon_data: Dictionary)
signal boon_applied(boon_data: Dictionary)
signal boon_stack_increased(boon_data: Dictionary, stack_count: int)
signal synergy_activated(synergy_data: Dictionary)

enum BoonRarity {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

enum BoonGod {
	RA,      # Fire/Light damage
	THOTH,   # Magic/Knowledge
	BASTET,  # Speed/Protection  
	SET      # Chaos/Corruption
}

enum BoonType {
	DAMAGE,
	DEFENSE,
	UTILITY,
	SPECIAL
}

@export_group("Boon Settings")
@export var max_boons_per_run: int = 12
@export var boon_selection_count: int = 3

@export_group("Rarity Settings")
@export var rarity_weights = {
	BoonRarity.COMMON: 60.0,
	BoonRarity.RARE: 30.0,
	BoonRarity.EPIC: 8.0,
	BoonRarity.LEGENDARY: 2.0
}

# Boon database
var boon_database: Array[Dictionary] = []
var active_boons: Array[Dictionary] = []
var boon_stacks: Dictionary = {}

# Synergy system
var synergy_database: Array[Dictionary] = []
var active_synergies: Array[Dictionary] = []

# References
var player: Node3D

func _ready():
	setup_boon_system()
	initialize_boon_database()
	initialize_synergy_database()
	player = get_tree().get_first_node_in_group("player")

func setup_boon_system():
	add_to_group("boon_system")
	print("Boon system initialized")

func initialize_boon_database():
	# Clear existing database
	boon_database.clear()
	
	# Add Ra (Fire/Light) boons
	add_ra_boons()
	
	# Add Thoth (Magic/Knowledge) boons  
	add_thoth_boons()
	
	# Add Bastet (Speed/Protection) boons
	add_bastet_boons()
	
	# Add Set (Chaos/Corruption) boons
	add_set_boons()
	
	print("Boon database initialized with ", boon_database.size(), " boons")

func initialize_synergy_database():
	# Clear existing synergies
	synergy_database.clear()
	
	# Ra synergies
	add_ra_synergies()
	
	# Thoth synergies
	add_thoth_synergies()
	
	# Bastet synergies
	add_bastet_synergies()
	
	# Set synergies
	add_set_synergies()
	
	# Cross-god synergies
	add_cross_god_synergies()
	
	print("Synergy database initialized with ", synergy_database.size(), " synergies")

func add_ra_synergies():
	# Ra internal synergies
	synergy_database.append({
		"id": "ra_solar_inferno",
		"name": "Solar Inferno",
		"description": "Golden Flame + Solar Wrath: Fire damage spreads to nearby enemies",
		"required_boons": ["ra_golden_flame", "ra_solar_wrath"],
		"effects": {
			"fire_spread_radius": 4.0,
			"spread_damage_multiplier": 0.75
		}
	})
	
	synergy_database.append({
		"id": "ra_phoenix_shield",
		"name": "Phoenix Shield", 
		"description": "Phoenix Rebirth + Solar Shield: Revival creates protective solar explosion",
		"required_boons": ["ra_phoenix_rebirth", "ra_solar_shield"],
		"effects": {
			"revival_explosion_damage": 100,
			"revival_explosion_radius": 8.0
		}
	})

func add_thoth_synergies():
	# Thoth internal synergies
	synergy_database.append({
		"id": "thoth_arcane_mastery",
		"name": "Arcane Mastery",
		"description": "Arcane Wisdom + Spell Echo: Echoed spells consume no mana",
		"required_boons": ["thoth_arcane_wisdom", "thoth_spell_echo"],
		"effects": {
			"echo_no_mana_cost": true,
			"echo_chance_bonus": 10
		}
	})
	
	synergy_database.append({
		"id": "thoth_knowledge_missiles", 
		"name": "Guided Missiles",
		"description": "Knowledge Seeker + Magic Missiles: Missiles home in on enemies",
		"required_boons": ["thoth_knowledge_seeker", "thoth_magic_missiles"],
		"effects": {
			"missile_homing": true,
			"missile_tracking_range": 10.0
		}
	})

func add_bastet_synergies():
	# Bastet internal synergies
	synergy_database.append({
		"id": "bastet_perfect_hunter",
		"name": "Perfect Hunter",
		"description": "Cat Reflexes + Hunter's Instinct: Dodging triggers execute bonus",
		"required_boons": ["bastet_cat_reflexes", "bastet_hunters_instinct"],
		"effects": {
			"dodge_execute_bonus": 25,
			"dodge_execute_duration": 3.0
		}
	})
	
	synergy_database.append({
		"id": "bastet_graceful_guardian",
		"name": "Graceful Guardian",
		"description": "Feline Grace + Protective Spirit: Speed increases shield strength",
		"required_boons": ["bastet_feline_grace", "bastet_protective_spirit"],
		"effects": {
			"speed_shield_multiplier": 0.5,
			"shield_speed_bonus": 15
		}
	})

func add_set_synergies():
	# Set internal synergies  
	synergy_database.append({
		"id": "set_chaos_harvest",
		"name": "Chaos Harvest",
		"description": "Chaos Strike + Soul Harvest: Chaos effects grant extra health/mana",
		"required_boons": ["set_chaos_strike", "set_soul_harvest"],
		"effects": {
			"chaos_heal_bonus": 5,
			"chaos_mana_bonus": 8
		}
	})
	
	synergy_database.append({
		"id": "set_dark_madness",
		"name": "Dark Madness",
		"description": "Dark Bargain + Madness: Low health triggers become even more powerful",
		"required_boons": ["set_dark_bargain", "set_madness"],
		"effects": {
			"enhanced_low_health_bonus": 1.5,
			"madness_damage_multiplier": 2.5
		}
	})

func add_cross_god_synergies():
	# Ra + Thoth synergies
	synergy_database.append({
		"id": "solar_wisdom",
		"name": "Solar Wisdom", 
		"description": "Ra + Thoth boons: Spells gain fire damage, fire gains spell effects",
		"required_boons": ["ra_golden_flame", "thoth_spell_echo"],
		"effects": {
			"spell_fire_damage": true,
			"fire_spell_chance": 25
		}
	})
	
	# Ra + Bastet synergies
	synergy_database.append({
		"id": "blazing_speed",
		"name": "Blazing Speed",
		"description": "Ra + Bastet boons: Movement creates fire trails, fire boosts speed",
		"required_boons": ["ra_burning_trail", "bastet_feline_grace"],
		"effects": {
			"movement_fire_trail": true,
			"fire_speed_bonus": 20
		}
	})
	
	# Thoth + Bastet synergies  
	synergy_database.append({
		"id": "tactical_knowledge",
		"name": "Tactical Knowledge",
		"description": "Thoth + Bastet boons: Dodging restores mana, abilities boost dodge chance",
		"required_boons": ["thoth_arcane_wisdom", "bastet_cat_reflexes"],
		"effects": {
			"dodge_mana_restore": 15,
			"ability_dodge_bonus": 10
		}
	})
	
	# Set + Other god synergies
	synergy_database.append({
		"id": "corrupted_power",
		"name": "Corrupted Power",
		"description": "Set + Any other god: Chaos effects can trigger other boon effects",
		"required_boons": ["set_chaos_strike"], # Plus any non-Set boon
		"special_requirement": "any_non_set_boon",
		"effects": {
			"chaos_triggers_other_boons": true,
			"cross_effect_chance": 20
		}
	})

func add_ra_boons():
	# Ra - Fire and Light damage boons
	boon_database.append({
		"id": "ra_golden_flame",
		"name": "Golden Flame",
		"description": "Your attacks burn with Ra's divine fire.",
		"god": BoonGod.RA,
		"type": BoonType.DAMAGE,
		"rarity": BoonRarity.COMMON,
		"max_stacks": 3,
		"effects": {
			"fire_damage_bonus": [10, 20, 30],  # Per stack
			"burn_chance": [15, 25, 35]
		},
		"icon": "res://icons/boons/ra_golden_flame.png"
	})
	
	boon_database.append({
		"id": "ra_solar_wrath",
		"name": "Solar Wrath", 
		"description": "Deal extra damage in sunlight areas.",
		"god": BoonGod.RA,
		"type": BoonType.DAMAGE,
		"rarity": BoonRarity.RARE,
		"max_stacks": 2,
		"effects": {
			"sunlight_damage_multiplier": [1.25, 1.5],
			"light_radius": [5, 8]
		},
		"icon": "res://icons/boons/ra_solar_wrath.png"
	})
	
	boon_database.append({
		"id": "ra_phoenix_rebirth",
		"name": "Phoenix Rebirth",
		"description": "Upon death, resurrect with full health once per room.",
		"god": BoonGod.RA,
		"type": BoonType.UTILITY,
		"rarity": BoonRarity.LEGENDARY,
		"max_stacks": 1,
		"effects": {
			"resurrect_on_death": [true],
			"resurrection_health": [100]
		},
		"icon": "res://icons/boons/ra_phoenix_rebirth.png"
	})
	
	boon_database.append({
		"id": "ra_solar_shield",
		"name": "Solar Shield",
		"description": "Blocking attacks releases solar energy that damages nearby enemies.",
		"god": BoonGod.RA,
		"type": BoonType.DEFENSE,
		"rarity": BoonRarity.EPIC,
		"max_stacks": 2,
		"effects": {
			"block_damage": [25, 40],
			"solar_radius": [4, 6]
		},
		"icon": "res://icons/boons/ra_solar_shield.png"
	})
	
	boon_database.append({
		"id": "ra_burning_trail",
		"name": "Burning Trail",
		"description": "Your dash leaves a trail of fire that damages enemies.",
		"god": BoonGod.RA,
		"type": BoonType.SPECIAL,
		"rarity": BoonRarity.RARE,
		"max_stacks": 3,
		"effects": {
			"trail_damage": [15, 25, 35],
			"trail_duration": [2, 3, 4]
		},
		"icon": "res://icons/boons/ra_burning_trail.png"
	})
	
	# NEW RA BOONS - EXPANSION
	boon_database.append({
		"id": "ra_solar_flare",
		"name": "Solar Flare",
		"description": "Critical hits create explosive solar bursts.",
		"god": BoonGod.RA,
		"type": BoonType.DAMAGE,
		"rarity": BoonRarity.EPIC,
		"max_stacks": 2,
		"effects": {
			"burst_damage": [40, 65],
			"burst_radius": [3, 4]
		},
		"icon": "res://icons/boons/ra_solar_flare.png"
	})
	
	boon_database.append({
		"id": "ra_sunlight_healing",
		"name": "Sunlight Healing",
		"description": "Standing in sunlight slowly restores health.",
		"god": BoonGod.RA,
		"type": BoonType.DEFENSE,
		"rarity": BoonRarity.COMMON,
		"max_stacks": 3,
		"effects": {
			"healing_per_second": [2, 4, 6],
			"sunlight_detection": [true]
		},
		"icon": "res://icons/boons/ra_sunlight_healing.png"
	})
	
	boon_database.append({
		"id": "ra_dawn_blessing",
		"name": "Dawn's Blessing",
		"description": "First attack each room deals massive fire damage.",
		"god": BoonGod.RA,
		"type": BoonType.DAMAGE,
		"rarity": BoonRarity.RARE,
		"max_stacks": 2,
		"effects": {
			"first_attack_multiplier": [2.0, 2.5],
			"fire_damage_bonus": [50, 75]
		},
		"icon": "res://icons/boons/ra_dawn_blessing.png"
	})
	
	boon_database.append({
		"id": "ra_solar_charge",
		"name": "Solar Charge",
		"description": "Abilities charge 25% faster in combat.",
		"god": BoonGod.RA,
		"type": BoonType.UTILITY,
		"rarity": BoonRarity.COMMON,
		"max_stacks": 4,
		"effects": {
			"ability_charge_speed": [1.25, 1.5, 1.75, 2.0],
			"combat_only": [true]
		},
		"icon": "res://icons/boons/ra_solar_charge.png"
	})
	
	boon_database.append({
		"id": "ra_pharaohs_crown",
		"name": "Pharaoh's Crown",
		"description": "Gain immunity to status effects while at full health.",
		"god": BoonGod.RA,
		"type": BoonType.DEFENSE,
		"rarity": BoonRarity.EPIC,
		"max_stacks": 1,
		"effects": {
			"status_immunity": [true],
			"full_health_required": [true]
		},
		"icon": "res://icons/boons/ra_pharaohs_crown.png"
	})
	
	boon_database.append({
		"id": "ra_divine_wrath",
		"name": "Divine Wrath",
		"description": "Taking damage increases fire damage for a short time.",
		"god": BoonGod.RA,
		"type": BoonType.DAMAGE,
		"rarity": BoonRarity.RARE,
		"max_stacks": 3,
		"effects": {
			"damage_bonus": [30, 50, 70],
			"duration": [5, 6, 7],
			"trigger_on_damage": [true]
		},
		"icon": "res://icons/boons/ra_divine_wrath.png"
	})
	
	boon_database.append({
		"id": "ra_solar_weapon",
		"name": "Solar Weapon",
		"description": "Weapon attacks have chance to blind enemies.",
		"god": BoonGod.RA,
		"type": BoonType.UTILITY,
		"rarity": BoonRarity.COMMON,
		"max_stacks": 3,
		"effects": {
			"blind_chance": [20, 30, 40],
			"blind_duration": [2, 3, 4]
		},
		"icon": "res://icons/boons/ra_solar_weapon.png"
	})
	
	boon_database.append({
		"id": "ra_eternal_flame",
		"name": "Eternal Flame",
		"description": "Fire effects never expire and stack infinitely.",
		"god": BoonGod.RA,
		"type": BoonType.SPECIAL,
		"rarity": BoonRarity.LEGENDARY,
		"max_stacks": 1,
		"effects": {
			"infinite_fire_stacks": [true],
			"permanent_burn": [true]
		},
		"icon": "res://icons/boons/ra_eternal_flame.png"
	})

func add_thoth_boons():
	# Thoth - Magic and Knowledge boons
	boon_database.append({
		"id": "thoth_arcane_wisdom",
		"name": "Arcane Wisdom",
		"description": "Increases maximum mana and mana regeneration.",
		"god": BoonGod.THOTH,
		"type": BoonType.UTILITY,
		"rarity": BoonRarity.COMMON,
		"max_stacks": 4,
		"effects": {
			"max_mana_bonus": [15, 25, 35, 50],
			"mana_regen_bonus": [2, 3, 4, 6]
		},
		"icon": "res://icons/boons/thoth_arcane_wisdom.png"
	})
	
	boon_database.append({
		"id": "thoth_spell_echo",
		"name": "Spell Echo",
		"description": "Your abilities have a chance to trigger twice.",
		"god": BoonGod.THOTH,
		"type": BoonType.SPECIAL,
		"rarity": BoonRarity.EPIC,
		"max_stacks": 2,
		"effects": {
			"echo_chance": [25, 40],
			"echo_damage": [0.75, 1.0]  # Damage multiplier for echo
		},
		"icon": "res://icons/boons/thoth_spell_echo.png"
	})
	
	boon_database.append({
		"id": "thoth_knowledge_seeker",
		"name": "Knowledge Seeker", 
		"description": "Gain extra boon choices and see boon rarities.",
		"god": BoonGod.THOTH,
		"type": BoonType.UTILITY,
		"rarity": BoonRarity.LEGENDARY,
		"max_stacks": 1,
		"effects": {
			"extra_boon_choices": [2],  # 5 total instead of 3
			"show_rarity_preview": [true]
		},
		"icon": "res://icons/boons/thoth_knowledge_seeker.png"
	})
	
	boon_database.append({
		"id": "thoth_magic_missiles",
		"name": "Magic Missiles",
		"description": "Your projectile attacks split into multiple smaller projectiles.",
		"god": BoonGod.THOTH,
		"type": BoonType.DAMAGE,
		"rarity": BoonRarity.RARE,
		"max_stacks": 3,
		"effects": {
			"missile_count": [2, 3, 4],
			"missile_damage": [0.6, 0.7, 0.8]  # Damage per missile
		},
		"icon": "res://icons/boons/thoth_magic_missiles.png"
	})
	
	boon_database.append({
		"id": "thoth_scroll_mastery",
		"name": "Scroll Mastery",
		"description": "Ability cooldowns reduced, cast speed increased.",
		"god": BoonGod.THOTH,
		"type": BoonType.UTILITY,
		"rarity": BoonRarity.COMMON,
		"max_stacks": 3,
		"effects": {
			"cooldown_reduction": [15, 25, 35],  # Percentage
			"cast_speed_bonus": [20, 35, 50]
		},
		"icon": "res://icons/boons/thoth_scroll_mastery.png"
	})
	
	# NEW THOTH BOONS - EXPANSION
	boon_database.append({
		"id": "thoth_mystical_shield",
		"name": "Mystical Shield",
		"description": "Absorbs damage and converts it into mana.",
		"god": BoonGod.THOTH,
		"type": BoonType.DEFENSE,
		"rarity": BoonRarity.RARE,
		"max_stacks": 3,
		"effects": {
			"shield_capacity": [100, 150, 200],
			"damage_to_mana_ratio": [0.5, 0.7, 1.0]
		},
		"icon": "res://icons/boons/thoth_mystical_shield.png"
	})
	
	boon_database.append({
		"id": "thoth_hieroglyph_power",
		"name": "Hieroglyph Power",
		"description": "Defeating enemies leaves magical symbols that boost damage.",
		"god": BoonGod.THOTH,
		"type": BoonType.DAMAGE,
		"rarity": BoonRarity.COMMON,
		"max_stacks": 4,
		"effects": {
			"symbol_damage_bonus": [5, 10, 15, 20],
			"symbol_duration": [8, 10, 12, 15],
			"max_symbols": [3, 4, 5, 6]
		},
		"icon": "res://icons/boons/thoth_hieroglyph_power.png"
	})
	
	boon_database.append({
		"id": "thoth_time_dilation",
		"name": "Time Dilation",
		"description": "Critical hits slow down time briefly.",
		"god": BoonGod.THOTH,
		"type": BoonType.SPECIAL,
		"rarity": BoonRarity.EPIC,
		"max_stacks": 2,
		"effects": {
			"slow_factor": [0.3, 0.2],  # Time scale
			"slow_duration": [1.5, 2.5]
		},
		"icon": "res://icons/boons/thoth_time_dilation.png"
	})
	
	boon_database.append({
		"id": "thoth_wisdom_barrier",
		"name": "Wisdom Barrier",
		"description": "High mana grants damage reduction.",
		"god": BoonGod.THOTH,
		"type": BoonType.DEFENSE,
		"rarity": BoonRarity.COMMON,
		"max_stacks": 3,
		"effects": {
			"mana_threshold": [75, 60, 50],  # Percentage of max mana
			"damage_reduction": [20, 30, 40]
		},
		"icon": "res://icons/boons/thoth_wisdom_barrier.png"
	})
	
	boon_database.append({
		"id": "thoth_spell_weaving",
		"name": "Spell Weaving",
		"description": "Using different abilities in sequence grants stacking damage.",
		"god": BoonGod.THOTH,
		"type": BoonType.DAMAGE,
		"rarity": BoonRarity.RARE,
		"max_stacks": 2,
		"effects": {
			"weave_damage_bonus": [15, 25],
			"max_weave_stacks": [4, 6],
			"sequence_window": [3, 4]
		},
		"icon": "res://icons/boons/thoth_spell_weaving.png"
	})
	
	boon_database.append({
		"id": "thoth_forbidden_knowledge",
		"name": "Forbidden Knowledge",
		"description": "See enemy health bars and attack patterns.",
		"god": BoonGod.THOTH,
		"type": BoonType.UTILITY,
		"rarity": BoonRarity.RARE,
		"max_stacks": 1,
		"effects": {
			"show_enemy_health": [true],
			"show_attack_telegraphs": [true],
			"prediction_time": [2.0]
		},
		"icon": "res://icons/boons/thoth_forbidden_knowledge.png"
	})
	
	boon_database.append({
		"id": "thoth_astral_projection",
		"name": "Astral Projection",
		"description": "Dash grants brief invincibility and phases through enemies.",
		"god": BoonGod.THOTH,
		"type": BoonType.UTILITY,
		"rarity": BoonRarity.EPIC,
		"max_stacks": 2,
		"effects": {
			"invincibility_duration": [0.5, 0.8],
			"phase_damage": [20, 35]
		},
		"icon": "res://icons/boons/thoth_astral_projection.png"
	})
	
	boon_database.append({
		"id": "thoth_infinite_wisdom",
		"name": "Infinite Wisdom",
		"description": "Abilities no longer consume mana, but have longer cooldowns.",
		"god": BoonGod.THOTH,
		"type": BoonType.SPECIAL,
		"rarity": BoonRarity.LEGENDARY,
		"max_stacks": 1,
		"effects": {
			"no_mana_cost": [true],
			"cooldown_penalty": [1.5]  # 50% longer cooldowns
		},
		"icon": "res://icons/boons/thoth_infinite_wisdom.png"
	})

func add_bastet_boons():
	# Bastet - Speed and Protection boons
	boon_database.append({
		"id": "bastet_feline_grace",
		"name": "Feline Grace",
		"description": "Increased movement speed and dash distance.", 
		"god": BoonGod.BASTET,
		"type": BoonType.UTILITY,
		"rarity": BoonRarity.COMMON,
		"max_stacks": 3,
		"effects": {
			"movement_speed_bonus": [15, 25, 40],  # Percentage
			"dash_distance_bonus": [1, 2, 3]      # Extra units
		},
		"icon": "res://icons/boons/bastet_feline_grace.png"
	})
	
	boon_database.append({
		"id": "bastet_protective_spirit",
		"name": "Protective Spirit",
		"description": "Gain temporary shields when taking damage.",
		"god": BoonGod.BASTET,
		"type": BoonType.DEFENSE,
		"rarity": BoonRarity.RARE,
		"max_stacks": 2,
		"effects": {
			"shield_amount": [30, 50],
			"shield_duration": [5, 8]
		},
		"icon": "res://icons/boons/bastet_protective_spirit.png"
	})
	
	boon_database.append({
		"id": "bastet_nine_lives",
		"name": "Nine Lives",
		"description": "Gain extra lives that prevent death.",
		"god": BoonGod.BASTET,
		"type": BoonType.DEFENSE,
		"rarity": BoonRarity.LEGENDARY,
		"max_stacks": 1,
		"effects": {
			"extra_lives": [2],
			"invulnerability_time": [3]  # Seconds after revival
		},
		"icon": "res://icons/boons/bastet_nine_lives.png"
	})
	
	boon_database.append({
		"id": "bastet_cat_reflexes",
		"name": "Cat Reflexes", 
		"description": "Chance to automatically dodge attacks.",
		"god": BoonGod.BASTET,
		"type": BoonType.DEFENSE,
		"rarity": BoonRarity.EPIC,
		"max_stacks": 3,
		"effects": {
			"dodge_chance": [15, 25, 35],
			"dodge_speed_bonus": [50, 75, 100]  # Speed boost after dodge
		},
		"icon": "res://icons/boons/bastet_cat_reflexes.png"
	})
	
	boon_database.append({
		"id": "bastet_hunters_instinct", 
		"name": "Hunter's Instinct",
		"description": "Deal more damage to low-health enemies.",
		"god": BoonGod.BASTET,
		"type": BoonType.DAMAGE,
		"rarity": BoonRarity.RARE,
		"max_stacks": 2,
		"effects": {
			"execute_threshold": [25, 35],       # Health percentage
			"execute_damage_bonus": [50, 100]   # Damage bonus percentage
		},
		"icon": "res://icons/boons/bastet_hunters_instinct.png"
	})
	
	# NEW BASTET BOONS - EXPANSION
	boon_database.append({
		"id": "bastet_shadow_step",
		"name": "Shadow Step",
		"description": "Dash makes you invisible and increases critical hit chance.",
		"god": BoonGod.BASTET,
		"type": BoonType.UTILITY,
		"rarity": BoonRarity.EPIC,
		"max_stacks": 2,
		"effects": {
			"invisibility_duration": [1.5, 2.5],
			"crit_chance_bonus": [30, 50]
		},
		"icon": "res://icons/boons/bastet_shadow_step.png"
	})
	
	boon_database.append({
		"id": "bastet_agility_training",
		"name": "Agility Training",
		"description": "Attack speed increases with consecutive hits.",
		"god": BoonGod.BASTET,
		"type": BoonType.DAMAGE,
		"rarity": BoonRarity.COMMON,
		"max_stacks": 4,
		"effects": {
			"attack_speed_per_hit": [8, 12, 16, 20],
			"max_speed_stacks": [5, 6, 7, 8],
			"stack_decay_time": [3, 4, 5, 6]
		},
		"icon": "res://icons/boons/bastet_agility_training.png"
	})
	
	boon_database.append({
		"id": "bastet_sacred_claws",
		"name": "Sacred Claws",
		"description": "Attacks apply bleeding that stacks infinitely.",
		"god": BoonGod.BASTET,
		"type": BoonType.DAMAGE,
		"rarity": BoonRarity.RARE,
		"max_stacks": 3,
		"effects": {
			"bleed_damage_per_stack": [3, 5, 7],
			"bleed_duration": [6, 8, 10],
			"application_chance": [60, 80, 100]
		},
		"icon": "res://icons/boons/bastet_sacred_claws.png"
	})
	
	boon_database.append({
		"id": "bastet_guardian_spirit",
		"name": "Guardian Spirit",
		"description": "Summons a cat spirit that fights alongside you.",
		"god": BoonGod.BASTET,
		"type": BoonType.SPECIAL,
		"rarity": BoonRarity.LEGENDARY,
		"max_stacks": 1,
		"effects": {
			"spirit_damage": [25],
			"spirit_health": [200],
			"spirit_speed": [1.5]
		},
		"icon": "res://icons/boons/bastet_guardian_spirit.png"
	})
	
	boon_database.append({
		"id": "bastet_perfect_balance",
		"name": "Perfect Balance",
		"description": "Cannot be knocked down or stunned.",
		"god": BoonGod.BASTET,
		"type": BoonType.DEFENSE,
		"rarity": BoonRarity.EPIC,
		"max_stacks": 1,
		"effects": {
			"knockdown_immunity": [true],
			"stun_immunity": [true],
			"stability_bonus": [100]
		},
		"icon": "res://icons/boons/bastet_perfect_balance.png"
	})
	
	boon_database.append({
		"id": "bastet_night_vision",
		"name": "Night Vision",
		"description": "See enemies through walls and detect traps.",
		"god": BoonGod.BASTET,
		"type": BoonType.UTILITY,
		"rarity": BoonRarity.COMMON,
		"max_stacks": 2,
		"effects": {
			"wall_vision_range": [10, 15],
			"trap_detection": [true],
			"enemy_outline": [true]
		},
		"icon": "res://icons/boons/bastet_night_vision.png"
	})
	
	boon_database.append({
		"id": "bastet_pounce_attack",
		"name": "Pounce Attack",
		"description": "Dash through enemies deals damage based on distance traveled.",
		"god": BoonGod.BASTET,
		"type": BoonType.DAMAGE,
		"rarity": BoonRarity.RARE,
		"max_stacks": 3,
		"effects": {
			"damage_per_unit": [8, 12, 16],
			"max_pounce_damage": [80, 120, 160],
			"stun_duration": [0.5, 0.7, 1.0]
		},
		"icon": "res://icons/boons/bastet_pounce_attack.png"
	})
	
	boon_database.append({
		"id": "bastet_territorial_instinct",
		"name": "Territorial Instinct",
		"description": "Deal more damage when staying in the same area.",
		"god": BoonGod.BASTET,
		"type": BoonType.DAMAGE,
		"rarity": BoonRarity.COMMON,
		"max_stacks": 4,
		"effects": {
			"territory_radius": [8, 10, 12, 15],
			"damage_bonus": [10, 20, 30, 40],
			"buildup_time": [3, 2.5, 2, 1.5]
		},
		"icon": "res://icons/boons/bastet_territorial_instinct.png"
	})

func add_set_boons():
	# Set - Chaos and Corruption boons
	boon_database.append({
		"id": "set_chaos_strike",
		"name": "Chaos Strike",
		"description": "Your attacks have unpredictable effects.",
		"god": BoonGod.SET,
		"type": BoonType.DAMAGE,
		"rarity": BoonRarity.COMMON,
		"max_stacks": 3,
		"effects": {
			"chaos_chance": [20, 30, 45],
			"chaos_effects": ["poison", "slow", "confusion", "fear"]
		},
		"icon": "res://icons/boons/set_chaos_strike.png"
	})
	
	boon_database.append({
		"id": "set_corruption_aura",
		"name": "Corruption Aura",
		"description": "Nearby enemies take damage over time.",
		"god": BoonGod.SET,
		"type": BoonType.SPECIAL,
		"rarity": BoonRarity.RARE,
		"max_stacks": 2,
		"effects": {
			"aura_damage": [8, 15],
			"aura_radius": [5, 8]
		},
		"icon": "res://icons/boons/set_corruption_aura.png"
	})
	
	boon_database.append({
		"id": "set_dark_bargain",
		"name": "Dark Bargain",
		"description": "Lose health but gain massive damage boost.",
		"god": BoonGod.SET,
		"type": BoonType.DAMAGE,
		"rarity": BoonRarity.EPIC,
		"max_stacks": 1,
		"effects": {
			"health_cost": [25],        # Percentage of max health
			"damage_bonus": [75]       # Percentage damage increase
		},
		"icon": "res://icons/boons/set_dark_bargain.png"
	})
	
	boon_database.append({
		"id": "set_madness",
		"name": "Madness",
		"description": "Lower health increases damage and speed dramatically.",
		"god": BoonGod.SET,
		"type": BoonType.SPECIAL,
		"rarity": BoonRarity.LEGENDARY, 
		"max_stacks": 1,
		"effects": {
			"low_health_threshold": [33],  # Health percentage
			"damage_multiplier": [2.0],    # 200% damage when low
			"speed_multiplier": [1.5]      # 150% speed when low
		},
		"icon": "res://icons/boons/set_madness.png"
	})
	
	boon_database.append({
		"id": "set_soul_harvest",
		"name": "Soul Harvest",
		"description": "Killing enemies restores health and mana.",
		"god": BoonGod.SET,
		"type": BoonType.UTILITY,
		"rarity": BoonRarity.RARE,
		"max_stacks": 3,
		"effects": {
			"health_per_kill": [10, 15, 25],
			"mana_per_kill": [15, 20, 30]
		},
		"icon": "res://icons/boons/set_soul_harvest.png"
	})
	
	# NEW SET BOONS - EXPANSION  
	boon_database.append({
		"id": "set_desert_storm",
		"name": "Desert Storm",
		"description": "Dash creates a sandstorm that blinds and damages enemies.",
		"god": BoonGod.SET,
		"type": BoonType.SPECIAL,
		"rarity": BoonRarity.EPIC,
		"max_stacks": 2,
		"effects": {
			"storm_damage": [15, 25],
			"storm_duration": [4, 6],
			"blind_duration": [3, 5]
		},
		"icon": "res://icons/boons/set_desert_storm.png"
	})
	
	boon_database.append({
		"id": "set_blood_for_power",
		"name": "Blood for Power",
		"description": "Sacrifice health to instantly refresh all ability cooldowns.",
		"god": BoonGod.SET,
		"type": BoonType.UTILITY,
		"rarity": BoonRarity.RARE,
		"max_stacks": 3,
		"effects": {
			"health_cost": [20, 15, 10],
			"cooldown_refresh": [true],
			"usage_limit": [2, 3, 4]  # Uses per room
		},
		"icon": "res://icons/boons/set_blood_for_power.png"
	})
	
	boon_database.append({
		"id": "set_plague_bearer",
		"name": "Plague Bearer",
		"description": "Poisoned enemies spread poison to nearby enemies on death.",
		"god": BoonGod.SET,
		"type": BoonType.DAMAGE,
		"rarity": BoonRarity.COMMON,
		"max_stacks": 3,
		"effects": {
			"spread_radius": [4, 6, 8],
			"spread_damage": [20, 35, 50],
			"spread_duration": [4, 5, 6]
		},
		"icon": "res://icons/boons/set_plague_bearer.png"
	})
	
	boon_database.append({
		"id": "set_cursed_weapons",
		"name": "Cursed Weapons",
		"description": "Weapons drain enemy health over time on hit.",
		"god": BoonGod.SET,
		"type": BoonType.DAMAGE,
		"rarity": BoonRarity.COMMON,
		"max_stacks": 4,
		"effects": {
			"curse_damage": [5, 8, 12, 16],
			"curse_duration": [6, 7, 8, 10],
			"curse_chance": [40, 60, 80, 100]
		},
		"icon": "res://icons/boons/set_cursed_weapons.png"
	})
	
	boon_database.append({
		"id": "set_shadow_clone",
		"name": "Shadow Clone",
		"description": "Create a dark copy that mimics your attacks.",
		"god": BoonGod.SET,
		"type": BoonType.SPECIAL,
		"rarity": BoonRarity.LEGENDARY,
		"max_stacks": 1,
		"effects": {
			"clone_damage": [0.75],
			"clone_duration": [30],
			"clone_health": [150]
		},
		"icon": "res://icons/boons/set_shadow_clone.png"
	})
	
	boon_database.append({
		"id": "set_vampiric_strikes",
		"name": "Vampiric Strikes",
		"description": "Heal for a percentage of damage dealt.",
		"god": BoonGod.SET,
		"type": BoonType.DEFENSE,
		"rarity": BoonRarity.RARE,
		"max_stacks": 3,
		"effects": {
			"lifesteal_percentage": [8, 15, 25],
			"max_heal_per_hit": [20, 35, 50]
		},
		"icon": "res://icons/boons/set_vampiric_strikes.png"
	})
	
	boon_database.append({
		"id": "set_chaos_magic",
		"name": "Chaos Magic",
		"description": "Abilities have random enhanced effects each use.",
		"god": BoonGod.SET,
		"type": BoonType.SPECIAL,
		"rarity": BoonRarity.EPIC,
		"max_stacks": 2,
		"effects": {
			"enhancement_chance": [50, 75],
			"possible_effects": ["double_damage", "no_cooldown", "area_boost", "free_cast"]
		},
		"icon": "res://icons/boons/set_chaos_magic.png"
	})
	
	boon_database.append({
		"id": "set_forbidden_ritual",
		"name": "Forbidden Ritual",
		"description": "Constantly lose health but gain powerful regeneration and damage.",
		"god": BoonGod.SET,
		"type": BoonType.SPECIAL,
		"rarity": BoonRarity.LEGENDARY,
		"max_stacks": 1,
		"effects": {
			"health_drain": [2],  # Per second
			"damage_bonus": [50],
			"regeneration": [8],  # Per second when not taking damage
			"regeneration_delay": [3]
		},
		"icon": "res://icons/boons/set_forbidden_ritual.png"
	})

# Boon selection and application
func generate_boon_choices(exclude_gods: Array[BoonGod] = []) -> Array[Dictionary]:
	var choices: Array[Dictionary] = []
	var available_boons = boon_database.filter(func(boon): return not exclude_gods.has(boon.god))
	
	# Get choice count (may be modified by Thoth boons)
	var choice_count = get_effective_choice_count()
	
	for i in range(choice_count):
		var selected_boon = select_random_boon(available_boons)
		if selected_boon and not choices.has(selected_boon):
			choices.append(selected_boon)
			# Remove to avoid duplicates
			available_boons.erase(selected_boon)
	
	return choices

func get_effective_choice_count() -> int:
	var base_count = boon_selection_count
	
	# Check for Thoth's Knowledge Seeker boon
	for boon in active_boons:
		if boon.id == "thoth_knowledge_seeker":
			base_count += boon.effects.extra_boon_choices[0]
			break
	
	return base_count

func select_random_boon(available_boons: Array) -> Dictionary:
	if available_boons.is_empty():
		return {}
	
	# First determine rarity based on weights
	var selected_rarity = select_rarity()
	
	# Filter boons by rarity  
	var rarity_boons = available_boons.filter(func(boon): return boon.rarity == selected_rarity)
	
	# Fallback to any rarity if none found
	if rarity_boons.is_empty():
		rarity_boons = available_boons
	
	# Select random boon from filtered list
	if rarity_boons.size() > 0:
		return rarity_boons[randi() % rarity_boons.size()]
	
	return {}

func select_rarity() -> BoonRarity:
	var total_weight = 0.0
	for weight in rarity_weights.values():
		total_weight += weight
	
	var random_value = randf() * total_weight
	var current_weight = 0.0
	
	for rarity in rarity_weights:
		current_weight += rarity_weights[rarity]
		if random_value <= current_weight:
			return rarity
	
	return BoonRarity.COMMON

func apply_boon(boon_data: Dictionary) -> bool:
	var boon_id = boon_data.id
	
	# Check if boon is already active
	var existing_boon = find_active_boon(boon_id)
	
	if existing_boon:
		# Stack the boon if possible
		if can_stack_boon(existing_boon):
			stack_boon(existing_boon)
			return true
		else:
			print("Boon ", boon_data.name, " is already at max stacks")
			return false
	else:
		# Add new boon
		var new_boon = boon_data.duplicate(true)
		new_boon["current_stacks"] = 1
		active_boons.append(new_boon)
		boon_stacks[boon_id] = 1
		
		# Apply boon effects
		apply_boon_effects(new_boon)
		boon_applied.emit(new_boon)
		
		# Check for new synergies
		check_and_activate_synergies()
		
		print("Applied boon: ", new_boon.name)
		return true

func find_active_boon(boon_id: String) -> Dictionary:
	for boon in active_boons:
		if boon.id == boon_id:
			return boon
	return {}

func can_stack_boon(boon_data: Dictionary) -> bool:
	return boon_data.current_stacks < boon_data.max_stacks

func stack_boon(boon_data: Dictionary):
	boon_data.current_stacks += 1
	boon_stacks[boon_data.id] = boon_data.current_stacks
	
	# Reapply effects with new stack count
	apply_boon_effects(boon_data)
	boon_stack_increased.emit(boon_data, boon_data.current_stacks)
	
	# Check for new synergies that might activate with higher stack count
	check_and_activate_synergies()
	
	print("Stacked boon: ", boon_data.name, " (", boon_data.current_stacks, "/", boon_data.max_stacks, ")")

func apply_boon_effects(boon_data: Dictionary):
	if not player:
		print("No player found to apply boon effects")
		return
	
	var stack_level = boon_data.current_stacks - 1  # 0-indexed for arrays
	
	# Apply effects based on boon ID
	match boon_data.id:
		"ra_golden_flame":
			apply_fire_damage_bonus(boon_data, stack_level)
		"thoth_arcane_wisdom":
			apply_mana_bonus(boon_data, stack_level)
		"bastet_feline_grace":
			apply_movement_bonus(boon_data, stack_level)
		"set_chaos_strike":
			apply_chaos_effects(boon_data, stack_level)
		_:
			print("Boon effect not implemented: ", boon_data.id)

func apply_fire_damage_bonus(boon_data: Dictionary, stack_level: int):
	# Apply fire damage bonus to player's combat system
	if player.has_method("get_node"):
		var combat_system = player.get_node_or_null("CombatSystem")
		if combat_system:
			var bonus = boon_data.effects.fire_damage_bonus[stack_level]
			combat_system.set_meta("fire_damage_bonus", bonus)
			print("Applied fire damage bonus: +", bonus, "%")

func apply_mana_bonus(boon_data: Dictionary, stack_level: int):
	# Apply mana bonus to player's ability system  
	if player.has_method("get_node"):
		var ability_system = player.get_node_or_null("AbilitySystem")
		if ability_system:
			var mana_bonus = boon_data.effects.max_mana_bonus[stack_level]
			var regen_bonus = boon_data.effects.mana_regen_bonus[stack_level]
			
			ability_system.max_mana += mana_bonus
			ability_system.mana_regeneration_rate += regen_bonus
			print("Applied mana bonus: +", mana_bonus, " max, +", regen_bonus, " regen")

func apply_movement_bonus(boon_data: Dictionary, stack_level: int):
	# Apply movement speed bonus
	var speed_bonus = boon_data.effects.movement_speed_bonus[stack_level]
	var dash_bonus = boon_data.effects.dash_distance_bonus[stack_level]
	
	# Store bonuses as meta on player
	player.set_meta("movement_speed_bonus", speed_bonus)
	player.set_meta("dash_distance_bonus", dash_bonus)
	print("Applied movement bonus: +", speed_bonus, "% speed, +", dash_bonus, " dash distance")

func apply_chaos_effects(boon_data: Dictionary, stack_level: int):
	# Apply chaos strike effects
	var chaos_chance = boon_data.effects.chaos_chance[stack_level]
	player.set_meta("chaos_strike_chance", chaos_chance)
	player.set_meta("chaos_effects", boon_data.effects.chaos_effects)
	print("Applied chaos effects: ", chaos_chance, "% chance")

# Synergy system functions
func check_and_activate_synergies():
	for synergy in synergy_database:
		if is_synergy_available(synergy) and not is_synergy_active(synergy.id):
			activate_synergy(synergy)

func is_synergy_available(synergy_data: Dictionary) -> bool:
	# Check if all required boons are active
	for required_boon_id in synergy_data.required_boons:
		if not has_boon(required_boon_id):
			return false
	
	# Check special requirements
	if synergy_data.has("special_requirement"):
		match synergy_data.special_requirement:
			"any_non_set_boon":
				return has_non_set_boon()
			_:
				return false
	
	return true

func has_non_set_boon() -> bool:
	for boon in active_boons:
		if boon.god != BoonGod.SET:
			return true
	return false

func is_synergy_active(synergy_id: String) -> bool:
	for synergy in active_synergies:
		if synergy.id == synergy_id:
			return true
	return false

func activate_synergy(synergy_data: Dictionary):
	# Add to active synergies
	active_synergies.append(synergy_data.duplicate(true))
	
	# Apply synergy effects
	apply_synergy_effects(synergy_data)
	
	# Emit signal
	synergy_activated.emit(synergy_data)
	
	print("Synergy activated: ", synergy_data.name, " - ", synergy_data.description)

func apply_synergy_effects(synergy_data: Dictionary):
	if not player:
		return
	
	# Apply effects based on synergy ID
	match synergy_data.id:
		"ra_solar_inferno":
			apply_solar_inferno_effects(synergy_data)
		"thoth_arcane_mastery":
			apply_arcane_mastery_effects(synergy_data)
		"bastet_perfect_hunter":
			apply_perfect_hunter_effects(synergy_data)
		"set_chaos_harvest":
			apply_chaos_harvest_effects(synergy_data)
		"solar_wisdom":
			apply_solar_wisdom_effects(synergy_data)
		"blazing_speed":
			apply_blazing_speed_effects(synergy_data)
		"tactical_knowledge":
			apply_tactical_knowledge_effects(synergy_data)
		"corrupted_power":
			apply_corrupted_power_effects(synergy_data)
		_:
			print("Synergy effect not implemented: ", synergy_data.id)

func apply_solar_inferno_effects(synergy_data: Dictionary):
	player.set_meta("fire_spread_radius", synergy_data.effects.fire_spread_radius)
	player.set_meta("spread_damage_multiplier", synergy_data.effects.spread_damage_multiplier)

func apply_arcane_mastery_effects(synergy_data: Dictionary):
	player.set_meta("echo_no_mana_cost", synergy_data.effects.echo_no_mana_cost)
	# Bonus to existing echo chance
	var current_echo_chance = player.get_meta("echo_chance", 0)
	player.set_meta("echo_chance", current_echo_chance + synergy_data.effects.echo_chance_bonus)

func apply_perfect_hunter_effects(synergy_data: Dictionary):
	player.set_meta("dodge_execute_bonus", synergy_data.effects.dodge_execute_bonus)
	player.set_meta("dodge_execute_duration", synergy_data.effects.dodge_execute_duration)

func apply_chaos_harvest_effects(synergy_data: Dictionary):
	player.set_meta("chaos_heal_bonus", synergy_data.effects.chaos_heal_bonus)
	player.set_meta("chaos_mana_bonus", synergy_data.effects.chaos_mana_bonus)

func apply_solar_wisdom_effects(synergy_data: Dictionary):
	player.set_meta("spell_fire_damage", synergy_data.effects.spell_fire_damage)
	player.set_meta("fire_spell_chance", synergy_data.effects.fire_spell_chance)

func apply_blazing_speed_effects(synergy_data: Dictionary):
	player.set_meta("movement_fire_trail", synergy_data.effects.movement_fire_trail)
	# Bonus to existing speed
	var current_speed_bonus = player.get_meta("movement_speed_bonus", 0)
	player.set_meta("movement_speed_bonus", current_speed_bonus + synergy_data.effects.fire_speed_bonus)

func apply_tactical_knowledge_effects(synergy_data: Dictionary):
	player.set_meta("dodge_mana_restore", synergy_data.effects.dodge_mana_restore)
	player.set_meta("ability_dodge_bonus", synergy_data.effects.ability_dodge_bonus)

func apply_corrupted_power_effects(synergy_data: Dictionary):
	player.set_meta("chaos_triggers_other_boons", synergy_data.effects.chaos_triggers_other_boons)
	player.set_meta("cross_effect_chance", synergy_data.effects.cross_effect_chance)

# Public API
func get_active_boons() -> Array[Dictionary]:
	return active_boons

func get_boon_count() -> int:
	return active_boons.size()

func has_boon(boon_id: String) -> bool:
	return not find_active_boon(boon_id).is_empty()

func get_boon_stack_count(boon_id: String) -> int:
	return boon_stacks.get(boon_id, 0)

func get_active_synergies() -> Array[Dictionary]:
	return active_synergies

func get_synergy_count() -> int:
	return active_synergies.size()

func has_synergy(synergy_id: String) -> bool:
	return is_synergy_active(synergy_id)

func get_synergy_info() -> Dictionary:
	return {
		"active_synergies": active_synergies.size(),
		"available_synergies": synergy_database.size(),
		"synergy_list": active_synergies
	}

func get_god_name(god: BoonGod) -> String:
	match god:
		BoonGod.RA:
			return "Ra"
		BoonGod.THOTH:
			return "Thoth"
		BoonGod.BASTET:
			return "Bastet"
		BoonGod.SET:
			return "Set"
		_:
			return "Unknown"

func get_rarity_name(rarity: BoonRarity) -> String:
	match rarity:
		BoonRarity.COMMON:
			return "Common"
		BoonRarity.RARE:
			return "Rare"
		BoonRarity.EPIC:
			return "Epic"  
		BoonRarity.LEGENDARY:
			return "Legendary"
		_:
			return "Unknown"

func get_rarity_color(rarity: BoonRarity) -> Color:
	match rarity:
		BoonRarity.COMMON:
			return Color.WHITE
		BoonRarity.RARE:
			return Color.CYAN
		BoonRarity.EPIC:
			return Color.MAGENTA
		BoonRarity.LEGENDARY:
			return Color.GOLD
		_:
			return Color.GRAY