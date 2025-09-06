extends Node
class_name MemorySystem

signal memory_fragments_changed(new_amount: int)
signal memory_upgrade_purchased(upgrade_id: String, cost: int)
signal memory_upgrade_unlocked(upgrade_id: String)

@export_group("Memory Fragment Settings")
@export var base_fragments_per_run: int = 10
@export var fragments_per_floor: int = 2
@export var boss_fragment_bonus: int = 15
@export var perfect_run_multiplier: float = 1.5

@export_group("Save System")
@export var save_file_path: String = "user://memory_progress.save"

# Currency tracking - 4 types as per Sprint 12 spec
var total_memory_fragments: int = 0  # Meta progression currency
var lifetime_fragments_earned: int = 0
var current_run_fragments: int = 0

# Additional currencies from ROADMAP Sprint 12
var ankh_fragments: int = 0        # Common - Fragmentos de vida
var golden_scarabs: int = 0        # Rare - Proteção divina  
var heart_pieces: int = 0          # Boss - Essência emocional
var memory_shards: int = 0         # Meta - Lembranças importantes

# Memory upgrades database
var memory_upgrades: Dictionary = {}
var purchased_upgrades: Array[String] = []
var unlocked_upgrades: Array[String] = []

# References
var player: Node3D
var game_manager: Node

func _ready():
	setup_memory_system()
	initialize_memory_upgrades()
	load_memory_progress()
	find_system_references()

func _process(_delta):
	# Track current run performance
	update_run_tracking()

func setup_memory_system():
	add_to_group("memory_system")
	print("Memory System initialized - Pool of Memories")

func find_system_references():
	player = get_tree().get_first_node_in_group("player")
	game_manager = get_tree().get_first_node_in_group("game_manager")

func initialize_memory_upgrades():
	# Khenti's Past - Memory Upgrades based on his Egyptian mythology background
	
	# HEALTH & VITALITY MEMORIES
	memory_upgrades["memory_health_1"] = {
		"name": "Memories of Youth",
		"description": "Recall the vitality of youth. +25 Max Health.",
		"cost": 10,
		"category": "health",
		"tier": 1,
		"effects": {"max_health_bonus": 25},
		"prerequisites": []
	}
	
	memory_upgrades["memory_health_2"] = {
		"name": "Royal Bloodline",
		"description": "Remember noble heritage. +50 Max Health.",
		"cost": 25,
		"category": "health", 
		"tier": 2,
		"effects": {"max_health_bonus": 50},
		"prerequisites": ["memory_health_1"]
	}
	
	memory_upgrades["memory_health_3"] = {
		"name": "Divine Protection",
		"description": "Channel ancestral gods. +100 Max Health, 10% damage resistance.",
		"cost": 50,
		"category": "health",
		"tier": 3,
		"effects": {"max_health_bonus": 100, "damage_resistance": 0.1},
		"prerequisites": ["memory_health_2"]
	}
	
	# DAMAGE & COMBAT MEMORIES
	memory_upgrades["memory_damage_1"] = {
		"name": "Warrior Training",
		"description": "Recall combat lessons. +15% base damage.",
		"cost": 15,
		"category": "damage",
		"tier": 1,
		"effects": {"damage_multiplier": 1.15},
		"prerequisites": []
	}
	
	memory_upgrades["memory_damage_2"] = {
		"name": "Battle Scars", 
		"description": "Remember past victories. +25% base damage.",
		"cost": 30,
		"category": "damage",
		"tier": 2,
		"effects": {"damage_multiplier": 1.25},
		"prerequisites": ["memory_damage_1"]
	}
	
	memory_upgrades["memory_damage_3"] = {
		"name": "Pharaoh's Might",
		"description": "Channel royal authority. +40% base damage, crits heal 10 HP.",
		"cost": 60,
		"category": "damage",
		"tier": 3,
		"effects": {"damage_multiplier": 1.4, "crit_heal": 10},
		"prerequisites": ["memory_damage_2"]
	}
	
	# SPEED & MOBILITY MEMORIES
	memory_upgrades["memory_speed_1"] = {
		"name": "Fleet of Foot",
		"description": "Remember swift escapes. +20% movement speed.",
		"cost": 12,
		"category": "speed",
		"tier": 1,
		"effects": {"movement_speed_multiplier": 1.2},
		"prerequisites": []
	}
	
	memory_upgrades["memory_speed_2"] = {
		"name": "Desert Runner",
		"description": "Recall sand dune traversal. +35% movement speed.",
		"cost": 28,
		"category": "speed",
		"tier": 2,
		"effects": {"movement_speed_multiplier": 1.35},
		"prerequisites": ["memory_speed_1"]
	}
	
	memory_upgrades["memory_speed_3"] = {
		"name": "Wind Walker",
		"description": "Channel Shu's blessing. +50% movement speed, dash through enemies.",
		"cost": 55,
		"category": "speed",
		"tier": 3,
		"effects": {"movement_speed_multiplier": 1.5, "dash_through_enemies": true},
		"prerequisites": ["memory_speed_2"]
	}
	
	# BOON & DIVINE MEMORIES
	memory_upgrades["memory_boons_1"] = {
		"name": "Divine Favor",
		"description": "Recall god encounters. +1 boon choice per room.",
		"cost": 20,
		"category": "boons",
		"tier": 1,
		"effects": {"extra_boon_choices": 1},
		"prerequisites": []
	}
	
	memory_upgrades["memory_boons_2"] = {
		"name": "Sacred Offerings",
		"description": "Remember ritual knowledge. 25% higher boon rarity.",
		"cost": 40,
		"category": "boons",
		"tier": 2,
		"effects": {"boon_rarity_bonus": 0.25},
		"prerequisites": ["memory_boons_1"]
	}
	
	memory_upgrades["memory_boons_3"] = {
		"name": "Godly Communion",
		"description": "Channel divine connection. Legendary boons 50% more common.",
		"cost": 75,
		"category": "boons",
		"tier": 3,
		"effects": {"legendary_boon_chance": 0.5},
		"prerequisites": ["memory_boons_2"]
	}
	
	# WEALTH & RESOURCES MEMORIES
	memory_upgrades["memory_wealth_1"] = {
		"name": "Royal Treasury",
		"description": "Remember palace riches. +50% gold from all sources.",
		"cost": 18,
		"category": "wealth",
		"tier": 1,
		"effects": {"gold_multiplier": 1.5},
		"prerequisites": []
	}
	
	memory_upgrades["memory_wealth_2"] = {
		"name": "Trade Networks",
		"description": "Recall merchant contacts. Shop prices reduced 25%.",
		"cost": 35,
		"category": "wealth",
		"tier": 2,
		"effects": {"shop_discount": 0.25},
		"prerequisites": ["memory_wealth_1"]
	}
	
	memory_upgrades["memory_wealth_3"] = {
		"name": "Economic Mastery",
		"description": "Channel administrative wisdom. Double gold, free shop rerolls.",
		"cost": 65,
		"category": "wealth",
		"tier": 3,
		"effects": {"gold_multiplier": 2.0, "free_shop_rerolls": true},
		"prerequisites": ["memory_wealth_2"]
	}
	
	# SPECIAL ABILITY MEMORIES
	memory_upgrades["memory_special_1"] = {
		"name": "Ancient Knowledge",
		"description": "Recall scholarly pursuits. Identify all items automatically.",
		"cost": 22,
		"category": "special",
		"tier": 1,
		"effects": {"auto_identify": true},
		"prerequisites": []
	}
	
	memory_upgrades["memory_special_2"] = {
		"name": "Mummy's Resilience",
		"description": "Remember preservation magic. Survive death once per run.",
		"cost": 45,
		"category": "special",
		"tier": 2,
		"effects": {"death_save": 1},
		"prerequisites": ["memory_special_1"]
	}
	
	memory_upgrades["memory_special_3"] = {
		"name": "Pharaoh's Authority",
		"description": "Channel royal command. Enemies occasionally refuse to attack.",
		"cost": 80,
		"category": "special",
		"tier": 3,
		"effects": {"intimidation_chance": 0.15},
		"prerequisites": ["memory_special_2"]
	}
	
	# WEAPON MASTERY MEMORIES
	memory_upgrades["memory_weapons_1"] = {
		"name": "Weapon Familiarity",
		"description": "Recall training days. All weapons +10% damage.",
		"cost": 25,
		"category": "weapons",
		"tier": 1,
		"effects": {"weapon_damage_bonus": 0.1},
		"prerequisites": []
	}
	
	memory_upgrades["memory_weapons_2"] = {
		"name": "Combat Expertise",
		"description": "Remember battle experience. Weapon specials recharge 25% faster.",
		"cost": 50,
		"category": "weapons",
		"tier": 2,
		"effects": {"special_cooldown_reduction": 0.25},
		"prerequisites": ["memory_weapons_1"]
	}
	
	memory_upgrades["memory_weapons_3"] = {
		"name": "Master of Arms",
		"description": "Channel warrior spirit. All weapon attacks have 15% crit chance.",
		"cost": 90,
		"category": "weapons",
		"tier": 3,
		"effects": {"global_crit_chance": 0.15},
		"prerequisites": ["memory_weapons_2"]
	}
	
	# STATUS EFFECT MEMORIES  
	memory_upgrades["memory_status_1"] = {
		"name": "Poison Resistance",
		"description": "Recall desert survival. 50% less damage from poison/burn.",
		"cost": 30,
		"category": "status",
		"tier": 1,
		"effects": {"dot_resistance": 0.5},
		"prerequisites": []
	}
	
	memory_upgrades["memory_status_2"] = {
		"name": "Mental Fortitude", 
		"description": "Remember royal composure. Immunity to charm and fear.",
		"cost": 40,
		"category": "status",
		"tier": 2,
		"effects": {"mental_immunity": true},
		"prerequisites": ["memory_status_1"]
	}
	
	memory_upgrades["memory_status_3"] = {
		"name": "Divine Immunity",
		"description": "Channel godly protection. All debuffs 75% shorter duration.",
		"cost": 70,
		"category": "status",
		"tier": 3,
		"effects": {"debuff_duration_reduction": 0.75},
		"prerequisites": ["memory_status_2"]
	}
	
# ADDITIONAL MEMORY UPGRADES (Sprint 12 - reaching 30+ total)
	
	# COMBO & TECHNIQUE MEMORIES
	memory_upgrades["memory_combo_1"] = {
		"name": "Desert Fighting Style", 
		"description": "Recall training with Nubian warriors. Combo attacks are 20% faster.",
		"cost": 35,
		"category": "weapons",
		"tier": 2,
		"effects": {"combo_speed_bonus": 0.2},
		"prerequisites": ["memory_weapons_1"]
	}
	
	memory_upgrades["memory_combo_2"] = {
		"name": "Royal Combat Mastery",
		"description": "Remember palace sparring sessions. Perfect combos grant brief invincibility.",
		"cost": 60,
		"category": "weapons", 
		"tier": 3,
		"effects": {"perfect_combo_invincibility": 1.0},
		"prerequisites": ["memory_combo_1"]
	}
	
	# EXPLORATION & DISCOVERY MEMORIES
	memory_upgrades["memory_explore_1"] = {
		"name": "Tomb Raider's Instinct",
		"description": "Recall secret passage discoveries. See hidden treasures through walls.",
		"cost": 25,
		"category": "special",
		"tier": 1, 
		"effects": {"treasure_vision": true, "hidden_detection_range": 10.0},
		"prerequisites": []
	}
	
	memory_upgrades["memory_explore_2"] = {
		"name": "Archaeologist's Wisdom",
		"description": "Remember scholarly expeditions. All containers hold 50% more loot.",
		"cost": 45,
		"category": "wealth",
		"tier": 2,
		"effects": {"loot_quantity_bonus": 0.5},
		"prerequisites": ["memory_explore_1"]
	}
	
	# MAGICAL RESISTANCE MEMORIES  
	memory_upgrades["memory_magic_1"] = {
		"name": "Priest's Blessing",
		"description": "Recall temple consecrations. 30% resistance to magical damage.",
		"cost": 40,
		"category": "status",
		"tier": 2,
		"effects": {"magic_resistance": 0.3},
		"prerequisites": ["memory_status_1"]
	}
	
	memory_upgrades["memory_magic_2"] = {
		"name": "Divine Ward",
		"description": "Channel protective rituals. Reflect 25% of magical damage back to casters.", 
		"cost": 75,
		"category": "status",
		"tier": 3,
		"effects": {"spell_reflection": 0.25},
		"prerequisites": ["memory_magic_1"]
	}
	
	# SOCIAL & DIPLOMATIC MEMORIES
	memory_upgrades["memory_social_1"] = {
		"name": "Noble Bearing",
		"description": "Remember royal court etiquette. Merchants offer 15% better prices.",
		"cost": 30,
		"category": "wealth",
		"tier": 2,
		"effects": {"merchant_discount": 0.15},
		"prerequisites": ["memory_wealth_1"]
	}
	
	memory_upgrades["memory_social_2"] = {
		"name": "Diplomatic Immunity", 
		"description": "Recall peace negotiations. Some enemies refuse to attack you.",
		"cost": 65,
		"category": "special",
		"tier": 3,
		"effects": {"diplomacy_chance": 0.1, "enemy_hesitation": 0.2},
		"prerequisites": ["memory_social_1"]
	}
	
	print("Memory upgrade database initialized with ", memory_upgrades.size(), " upgrades")

func award_fragments_for_run_completion(floors_cleared: int, boss_defeated: bool, perfect_run: bool):
	var fragments_earned = base_fragments_per_run
	fragments_earned += floors_cleared * fragments_per_floor
	
	if boss_defeated:
		fragments_earned += boss_fragment_bonus
	
	if perfect_run:
		fragments_earned = int(fragments_earned * perfect_run_multiplier)
	
	add_memory_fragments(fragments_earned)
	current_run_fragments = fragments_earned
	
	print("Run completed! Earned ", fragments_earned, " Memory Fragments")
	return fragments_earned

func add_memory_fragments(amount: int):
	total_memory_fragments += amount
	lifetime_fragments_earned += amount
	memory_fragments_changed.emit(total_memory_fragments)
	
	# Check for newly unlocked upgrades
	check_upgrade_unlocks()

# Currency management functions for all 4 types
func add_ankh_fragments(amount: int):
	ankh_fragments += amount
	print("Gained ", amount, " Ankh Fragments! Total: ", ankh_fragments)

func add_golden_scarabs(amount: int):
	golden_scarabs += amount
	print("Gained ", amount, " Golden Scarabs! Total: ", golden_scarabs)

func add_heart_pieces(amount: int):
	heart_pieces += amount
	print("Gained ", amount, " Heart Pieces! Total: ", heart_pieces)

func add_memory_shards(amount: int):
	memory_shards += amount
	print("Gained ", amount, " Memory Shards! Total: ", memory_shards)

func spend_ankh_fragments(amount: int) -> bool:
	if ankh_fragments >= amount:
		ankh_fragments -= amount
		return true
	return false

func spend_golden_scarabs(amount: int) -> bool:
	if golden_scarabs >= amount:
		golden_scarabs -= amount
		return true
	return false

func spend_heart_pieces(amount: int) -> bool:
	if heart_pieces >= amount:
		heart_pieces -= amount
		return true
	return false

func spend_memory_shards(amount: int) -> bool:
	if memory_shards >= amount:
		memory_shards -= amount
		return true
	return false

func get_currency_totals() -> Dictionary:
	return {
		"memory_fragments": total_memory_fragments,
		"ankh_fragments": ankh_fragments,
		"golden_scarabs": golden_scarabs, 
		"heart_pieces": heart_pieces,
		"memory_shards": memory_shards
	}

func spend_memory_fragments(amount: int) -> bool:
	if total_memory_fragments >= amount:
		total_memory_fragments -= amount
		memory_fragments_changed.emit(total_memory_fragments)
		return true
	return false

func can_afford_upgrade(upgrade_id: String) -> bool:
	if not memory_upgrades.has(upgrade_id):
		return false
	
	var upgrade = memory_upgrades[upgrade_id]
	return total_memory_fragments >= upgrade.cost

func can_purchase_upgrade(upgrade_id: String) -> bool:
	if not memory_upgrades.has(upgrade_id):
		return false
	
	# Already purchased?
	if upgrade_id in purchased_upgrades:
		return false
	
	# Can afford?
	if not can_afford_upgrade(upgrade_id):
		return false
	
	# Prerequisites met?
	var upgrade = memory_upgrades[upgrade_id]
	for prereq in upgrade.prerequisites:
		if not prereq in purchased_upgrades:
			return false
	
	return true

func purchase_upgrade(upgrade_id: String) -> bool:
	if not can_purchase_upgrade(upgrade_id):
		return false
	
	var upgrade = memory_upgrades[upgrade_id]
	
	# Spend fragments
	if not spend_memory_fragments(upgrade.cost):
		return false
	
	# Add to purchased list
	purchased_upgrades.append(upgrade_id)
	
	# Apply upgrade effects
	apply_upgrade_effects(upgrade_id, upgrade.effects)
	
	memory_upgrade_purchased.emit(upgrade_id, upgrade.cost)
	print("Purchased memory upgrade: ", upgrade.name)
	
	# Save progress
	save_memory_progress()
	
	return true

func apply_upgrade_effects(upgrade_id: String, effects: Dictionary):
	if not player:
		return
	
	# Apply effects to player
	for effect_type in effects:
		var value = effects[effect_type]
		
		match effect_type:
			"max_health_bonus":
				if player.has_method("add_max_health_bonus"):
					player.add_max_health_bonus(value)
				elif player.has_meta("max_health_bonus"):
					var current = player.get_meta("max_health_bonus", 0)
					player.set_meta("max_health_bonus", current + value)
				else:
					player.set_meta("max_health_bonus", value)
			
			"damage_resistance":
				player.set_meta("damage_resistance_bonus", value)
			
			"damage_multiplier":
				if player.has_meta("damage_multiplier_bonus"):
					var current = player.get_meta("damage_multiplier_bonus", 1.0)
					player.set_meta("damage_multiplier_bonus", current * value)
				else:
					player.set_meta("damage_multiplier_bonus", value)
			
			"crit_heal":
				player.set_meta("crit_heal_amount", value)
			
			"movement_speed_multiplier":
				if player.has_meta("movement_speed_multiplier"):
					var current = player.get_meta("movement_speed_multiplier", 1.0)
					player.set_meta("movement_speed_multiplier", current * value)
				else:
					player.set_meta("movement_speed_multiplier", value)
			
			"dash_through_enemies":
				player.set_meta("dash_through_enemies", value)
			
			"extra_boon_choices":
				player.set_meta("extra_boon_choices", value)
			
			"boon_rarity_bonus":
				player.set_meta("boon_rarity_bonus", value)
			
			"legendary_boon_chance":
				player.set_meta("legendary_boon_chance", value)
			
			"gold_multiplier":
				if player.has_meta("gold_multiplier"):
					var current = player.get_meta("gold_multiplier", 1.0)
					player.set_meta("gold_multiplier", current * value)
				else:
					player.set_meta("gold_multiplier", value)
			
			"shop_discount":
				player.set_meta("shop_discount", value)
			
			"free_shop_rerolls":
				player.set_meta("free_shop_rerolls", value)
			
			_:
				# Generic meta application
				player.set_meta("memory_" + effect_type, value)

func check_upgrade_unlocks():
	for upgrade_id in memory_upgrades:
		if upgrade_id in unlocked_upgrades:
			continue
		
		var upgrade = memory_upgrades[upgrade_id]
		
		# Check if prerequisites are met
		var prereqs_met = true
		for prereq in upgrade.prerequisites:
			if not prereq in purchased_upgrades:
				prereqs_met = false
				break
		
		if prereqs_met:
			unlocked_upgrades.append(upgrade_id)
			memory_upgrade_unlocked.emit(upgrade_id)

func get_available_upgrades() -> Array:
	var available = []
	for upgrade_id in memory_upgrades:
		if upgrade_id in purchased_upgrades:
			continue
		if upgrade_id in unlocked_upgrades:
			available.append(upgrade_id)
		elif memory_upgrades[upgrade_id].prerequisites.is_empty():
			# No prerequisites = always available
			available.append(upgrade_id)
			if not upgrade_id in unlocked_upgrades:
				unlocked_upgrades.append(upgrade_id)
	
	return available

func get_upgrades_by_category(category: String) -> Array:
	var category_upgrades = []
	for upgrade_id in memory_upgrades:
		if memory_upgrades[upgrade_id].category == category:
			category_upgrades.append(upgrade_id)
	return category_upgrades

func get_upgrade_info(upgrade_id: String) -> Dictionary:
	if memory_upgrades.has(upgrade_id):
		var upgrade = memory_upgrades[upgrade_id].duplicate()
		upgrade["id"] = upgrade_id
		upgrade["purchased"] = upgrade_id in purchased_upgrades
		upgrade["can_purchase"] = can_purchase_upgrade(upgrade_id)
		upgrade["can_afford"] = can_afford_upgrade(upgrade_id)
		return upgrade
	return {}

func update_run_tracking():
	# This would track current run performance for fragment calculation
	pass

func save_memory_progress():
	var save_file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if save_file:
		var save_data = {
			"total_memory_fragments": total_memory_fragments,
			"lifetime_fragments_earned": lifetime_fragments_earned,
			"purchased_upgrades": purchased_upgrades,
			"unlocked_upgrades": unlocked_upgrades
		}
		save_file.store_string(JSON.stringify(save_data))
		save_file.close()
		print("Memory progress saved")

func load_memory_progress():
	if not FileAccess.file_exists(save_file_path):
		# First time - unlock base tier upgrades
		check_upgrade_unlocks()
		return
	
	var save_file = FileAccess.open(save_file_path, FileAccess.READ)
	if save_file:
		var json_string = save_file.get_as_text()
		save_file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		
		if parse_result == OK:
			var save_data = json.data
			total_memory_fragments = save_data.get("total_memory_fragments", 0)
			lifetime_fragments_earned = save_data.get("lifetime_fragments_earned", 0)
			purchased_upgrades = save_data.get("purchased_upgrades", [])
			unlocked_upgrades = save_data.get("unlocked_upgrades", [])
			
			# Reapply all purchased upgrades
			for upgrade_id in purchased_upgrades:
				if memory_upgrades.has(upgrade_id):
					apply_upgrade_effects(upgrade_id, memory_upgrades[upgrade_id].effects)
			
			print("Memory progress loaded: ", total_memory_fragments, " fragments, ", purchased_upgrades.size(), " upgrades")
		
		check_upgrade_unlocks()

# Public API
func get_memory_fragments() -> int:
	return total_memory_fragments

func get_lifetime_fragments() -> int:
	return lifetime_fragments_earned

func get_purchased_upgrades() -> Array:
	return purchased_upgrades.duplicate()

func is_upgrade_purchased(upgrade_id: String) -> bool:
	return upgrade_id in purchased_upgrades

func get_upgrade_categories() -> Array:
	var categories = []
	for upgrade in memory_upgrades.values():
		if not upgrade.category in categories:
			categories.append(upgrade.category)
	return categories

func get_total_upgrades() -> int:
	return memory_upgrades.size()

func get_completion_percentage() -> float:
	return float(purchased_upgrades.size()) / float(memory_upgrades.size()) * 100.0