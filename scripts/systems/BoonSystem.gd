# BoonSystem.gd
# Egyptian god boon system - Hades-inspired divine blessings
# Sprint 7: Sistema de Recompensas Completo

extends Node

# Egyptian Gods providing boons
enum EgyptianGod {
	RA,       # Solar/Fire domain - Damage focused
	BASTET,   # Defense/Agility - Protection focused  
	THOTH,    # Magic/Utility - Knowledge focused
	ANUBIS    # Death/Justice - Execution focused
}

# Boon rarity levels
enum BoonRarity {
	COMMON,    # 70% chance
	RARE,      # 25% chance  
	EPIC,      # 4% chance
	LEGENDARY  # 1% chance
}

# Boon categories for synergy system
enum BoonTag {
	SOLAR,      # Ra's domain
	FIRE,       # Ra's domain
	DEFENSE,    # Bastet's domain
	AGILITY,    # Bastet's domain
	MAGIC,      # Thoth's domain
	UTILITY,    # Thoth's domain
	DEATH,      # Anubis' domain
	JUSTICE     # Anubis' domain
}

# God names for UI
var god_names = {
	EgyptianGod.RA: "Rá",
	EgyptianGod.BASTET: "Bastet", 
	EgyptianGod.THOTH: "Thoth",
	EgyptianGod.ANUBIS: "Anubis"
}

# Rarity names and colors
var rarity_data = {
	BoonRarity.COMMON: {"name": "Comum", "color": Color.WHITE},
	BoonRarity.RARE: {"name": "Rara", "color": Color.BLUE},
	BoonRarity.EPIC: {"name": "Épica", "color": Color.PURPLE},
	BoonRarity.LEGENDARY: {"name": "Lendária", "color": Color.GOLD}
}

# Active boons on player
var active_boons: Array[Dictionary] = []
var max_active_boons: int = 12

# Boon database - will be populated in _ready()
var available_boons: Dictionary = {}

# Selection system
var current_selection_options: Array[Dictionary] = []
var is_selection_active: bool = false

# References
var player: Node
var ui_manager: Node

signal boon_offered(boon_options: Array)
signal boon_selected(boon_data: Dictionary)
signal boon_applied(boon_data: Dictionary)

func _ready():
	print("🏺 BoonSystem: Initializing Egyptian divine blessings...")
	
	# Initialize boon database
	_initialize_boon_database()
	
	# Get references
	player = get_tree().get_first_node_in_group("player") if get_tree() else null
	
	print("🏺 BoonSystem: %d boons available from %d gods" % [_count_total_boons(), EgyptianGod.size()])

func _initialize_boon_database():
	"""Initialize all available boons from Egyptian gods"""
	available_boons = {}
	
	# Ra's Boons (Solar/Fire Domain)
	available_boons[EgyptianGod.RA] = [
		{
			"id": "ra_golden_flame",
			"name": "Chama Dourada",
			"description": "Seus ataques causam dano de fogo adicional",
			"tags": [BoonTag.SOLAR, BoonTag.FIRE],
			"type": "attack_modifier",
			"values": {
				BoonRarity.COMMON: {"fire_damage_percent": 15},
				BoonRarity.RARE: {"fire_damage_percent": 25},
				BoonRarity.EPIC: {"fire_damage_percent": 35},
				BoonRarity.LEGENDARY: {"fire_damage_percent": 50}
			}
		},
		{
			"id": "ra_purifying_light", 
			"name": "Luz Purificadora",
			"description": "Ataques cegam inimigos temporariamente",
			"tags": [BoonTag.SOLAR, BoonTag.UTILITY],
			"type": "debuff_applier",
			"values": {
				BoonRarity.COMMON: {"blind_duration": 1.5, "blind_chance": 25},
				BoonRarity.RARE: {"blind_duration": 2.0, "blind_chance": 35},
				BoonRarity.EPIC: {"blind_duration": 2.5, "blind_chance": 45},
				BoonRarity.LEGENDARY: {"blind_duration": 3.0, "blind_chance": 60}
			}
		},
		{
			"id": "ra_solar_eclipse",
			"name": "Eclipse Solar", 
			"description": "Explosão devastadora quando vida baixa",
			"tags": [BoonTag.SOLAR, BoonTag.FIRE],
			"type": "conditional_ability",
			"values": {
				BoonRarity.COMMON: {"trigger_health_percent": 25, "damage_multiplier": 200},
				BoonRarity.RARE: {"trigger_health_percent": 30, "damage_multiplier": 300},
				BoonRarity.EPIC: {"trigger_health_percent": 35, "damage_multiplier": 400},
				BoonRarity.LEGENDARY: {"trigger_health_percent": 40, "damage_multiplier": 500}
			}
		},
		{
			"id": "ra_dawn_spear",
			"name": "Lança do Amanhecer",
			"description": "Primeiro ataque em cada inimigo causa dano extra",
			"tags": [BoonTag.SOLAR],
			"type": "first_hit_bonus", 
			"values": {
				BoonRarity.COMMON: {"bonus_damage_percent": 50},
				BoonRarity.RARE: {"bonus_damage_percent": 75},
				BoonRarity.EPIC: {"bonus_damage_percent": 100},
				BoonRarity.LEGENDARY: {"bonus_damage_percent": 150}
			}
		},
		{
			"id": "ra_crown_of_fire",
			"name": "Coroa de Fogo",
			"description": "Aura de fogo ao redor do jogador",
			"tags": [BoonTag.FIRE, BoonTag.DEFENSE],
			"type": "aura_effect",
			"values": {
				BoonRarity.COMMON: {"aura_damage": 10, "aura_radius": 3.0},
				BoonRarity.RARE: {"aura_damage": 15, "aura_radius": 4.0},
				BoonRarity.EPIC: {"aura_damage": 20, "aura_radius": 5.0},
				BoonRarity.LEGENDARY: {"aura_damage": 30, "aura_radius": 6.0}
			}
		}
	]
	
	# Bastet's Boons (Defense/Agility Domain)
	available_boons[EgyptianGod.BASTET] = [
		{
			"id": "bastet_cat_reflexes",
			"name": "Reflexos Felinos", 
			"description": "Chance aumentada de esquivar ataques",
			"tags": [BoonTag.AGILITY, BoonTag.DEFENSE],
			"type": "dodge_bonus",
			"values": {
				BoonRarity.COMMON: {"dodge_chance_percent": 20},
				BoonRarity.RARE: {"dodge_chance_percent": 35},
				BoonRarity.EPIC: {"dodge_chance_percent": 50},
				BoonRarity.LEGENDARY: {"dodge_chance_percent": 70}
			}
		},
		{
			"id": "bastet_cat_leap",
			"name": "Salto da Gata",
			"description": "Dash mais longo e rápido",
			"tags": [BoonTag.AGILITY],
			"type": "movement_modifier",
			"values": {
				BoonRarity.COMMON: {"dash_distance_percent": 30, "dash_speed_percent": 20},
				BoonRarity.RARE: {"dash_distance_percent": 50, "dash_speed_percent": 35},
				BoonRarity.EPIC: {"dash_distance_percent": 70, "dash_speed_percent": 50},
				BoonRarity.LEGENDARY: {"dash_distance_percent": 100, "dash_speed_percent": 75}
			}
		},
		{
			"id": "bastet_sharp_claws",
			"name": "Garras Afiadas",
			"description": "Ataques têm chance de causar sangramento",
			"tags": [BoonTag.AGILITY],
			"type": "status_applier",
			"values": {
				BoonRarity.COMMON: {"bleed_chance": 30, "bleed_damage": 8, "bleed_duration": 3},
				BoonRarity.RARE: {"bleed_chance": 40, "bleed_damage": 12, "bleed_duration": 4},
				BoonRarity.EPIC: {"bleed_chance": 50, "bleed_damage": 16, "bleed_duration": 5},
				BoonRarity.LEGENDARY: {"bleed_chance": 65, "bleed_damage": 24, "bleed_duration": 6}
			}
		},
		{
			"id": "bastet_night_hunt",
			"name": "Caça Noturna",
			"description": "Velocidade aumentada em áreas escuras",
			"tags": [BoonTag.AGILITY],
			"type": "conditional_buff",
			"values": {
				BoonRarity.COMMON: {"speed_bonus_percent": 25},
				BoonRarity.RARE: {"speed_bonus_percent": 40},
				BoonRarity.EPIC: {"speed_bonus_percent": 55},
				BoonRarity.LEGENDARY: {"speed_bonus_percent": 75}
			}
		},
		{
			"id": "bastet_protective_mother",
			"name": "Mãe Protetora",
			"description": "Regenera vida ao matar inimigos",
			"tags": [BoonTag.DEFENSE],
			"type": "kill_heal",
			"values": {
				BoonRarity.COMMON: {"heal_amount": 10},
				BoonRarity.RARE: {"heal_amount": 15},
				BoonRarity.EPIC: {"heal_amount": 25},
				BoonRarity.LEGENDARY: {"heal_amount": 35}
			}
		}
	]
	
	# Thoth's Boons (Magic/Utility Domain)
	available_boons[EgyptianGod.THOTH] = [
		{
			"id": "thoth_ancient_tongue",
			"name": "Língua Antiga",
			"description": "Reduz tempo de recarga de habilidades",
			"tags": [BoonTag.MAGIC, BoonTag.UTILITY],
			"type": "cooldown_reduction",
			"values": {
				BoonRarity.COMMON: {"cooldown_reduction_percent": 25},
				BoonRarity.RARE: {"cooldown_reduction_percent": 35},
				BoonRarity.EPIC: {"cooldown_reduction_percent": 50},
				BoonRarity.LEGENDARY: {"cooldown_reduction_percent": 65}
			}
		},
		{
			"id": "thoth_sacred_writing",
			"name": "Escrita Sagrada",
			"description": "Ataques especiais fazem mais dano",
			"tags": [BoonTag.MAGIC],
			"type": "special_attack_boost", 
			"values": {
				BoonRarity.COMMON: {"special_damage_percent": 40},
				BoonRarity.RARE: {"special_damage_percent": 60},
				BoonRarity.EPIC: {"special_damage_percent": 80},
				BoonRarity.LEGENDARY: {"special_damage_percent": 120}
			}
		},
		{
			"id": "thoth_all_seeing_eye",
			"name": "Olho que Vê Tudo",
			"description": "Revela salas secretas e itens ocultos",
			"tags": [BoonTag.UTILITY],
			"type": "revelation",
			"values": {
				BoonRarity.COMMON: {"revelation_range": 1},
				BoonRarity.RARE: {"revelation_range": 2},
				BoonRarity.EPIC: {"revelation_range": 3},
				BoonRarity.LEGENDARY: {"revelation_range": 5}
			}
		},
		{
			"id": "thoth_forbidden_knowledge",
			"name": "Conhecimento Proibido",
			"description": "Ganha experiência extra de todas as fontes",
			"tags": [BoonTag.UTILITY],
			"type": "experience_multiplier",
			"values": {
				BoonRarity.COMMON: {"exp_multiplier": 1.25},
				BoonRarity.RARE: {"exp_multiplier": 1.4},
				BoonRarity.EPIC: {"exp_multiplier": 1.6},
				BoonRarity.LEGENDARY: {"exp_multiplier": 2.0}
			}
		},
		{
			"id": "thoth_word_of_power",
			"name": "Palavra de Poder",
			"description": "Magias atravessam inimigos",
			"tags": [BoonTag.MAGIC],
			"type": "projectile_pierce",
			"values": {
				BoonRarity.COMMON: {"pierce_count": 1},
				BoonRarity.RARE: {"pierce_count": 2},
				BoonRarity.EPIC: {"pierce_count": 3},
				BoonRarity.LEGENDARY: {"pierce_count": 5}
			}
		}
	]
	
	# Anubis' Boons (Death/Justice Domain)
	available_boons[EgyptianGod.ANUBIS] = [
		{
			"id": "anubis_heart_weighing",
			"name": "Pesagem do Coração",
			"description": "Executa inimigos com vida baixa",
			"tags": [BoonTag.DEATH, BoonTag.JUSTICE],
			"type": "execution_threshold",
			"values": {
				BoonRarity.COMMON: {"execution_threshold_percent": 30},
				BoonRarity.RARE: {"execution_threshold_percent": 35},
				BoonRarity.EPIC: {"execution_threshold_percent": 40},
				BoonRarity.LEGENDARY: {"execution_threshold_percent": 50}
			}
		},
		{
			"id": "anubis_guide_of_dead",
			"name": "Guia dos Mortos",
			"description": "Cura quando inimigos morrem",
			"tags": [BoonTag.DEATH],
			"type": "death_heal",
			"values": {
				BoonRarity.COMMON: {"heal_amount": 15},
				BoonRarity.RARE: {"heal_amount": 25},
				BoonRarity.EPIC: {"heal_amount": 35},
				BoonRarity.LEGENDARY: {"heal_amount": 50}
			}
		},
		{
			"id": "anubis_scales_of_truth",
			"name": "Balança da Verdade",
			"description": "Dano escala com nível de corrupção do inimigo",
			"tags": [BoonTag.JUSTICE],
			"type": "corruption_scaling",
			"values": {
				BoonRarity.COMMON: {"damage_per_corruption": 10},
				BoonRarity.RARE: {"damage_per_corruption": 15},
				BoonRarity.EPIC: {"damage_per_corruption": 20},
				BoonRarity.LEGENDARY: {"damage_per_corruption": 30}
			}
		},
		{
			"id": "anubis_final_judgment",
			"name": "Veredito Final",
			"description": "Critical hits têm chance de matar instantaneamente",
			"tags": [BoonTag.DEATH, BoonTag.JUSTICE],
			"type": "instant_kill",
			"values": {
				BoonRarity.COMMON: {"instant_kill_chance": 5},
				BoonRarity.RARE: {"instant_kill_chance": 8},
				BoonRarity.EPIC: {"instant_kill_chance": 12},
				BoonRarity.LEGENDARY: {"instant_kill_chance": 20}
			}
		},
		{
			"id": "anubis_royal_mummy",
			"name": "Múmia Real",
			"description": "Sobrevive à morte uma vez por sala",
			"tags": [BoonTag.DEATH],
			"type": "death_prevention",
			"values": {
				BoonRarity.COMMON: {"revive_health_percent": 25},
				BoonRarity.RARE: {"revive_health_percent": 40},
				BoonRarity.EPIC: {"revive_health_percent": 60},
				BoonRarity.LEGENDARY: {"revive_health_percent": 80}
			}
		}
	]

func _count_total_boons() -> int:
	"""Count total available boons across all gods"""
	var total = 0
	for god_boons in available_boons.values():
		total += god_boons.size()
	return total

func offer_boon_selection(rarity_boost: bool = false):
	"""Offer player 3 boons to choose from"""
	if is_selection_active:
		print("⚠️ BoonSystem: Selection already active!")
		return
	
	print("🏺 BoonSystem: Offering divine blessings...")
	
	# Generate 3 boon options
	current_selection_options = _generate_boon_selection(3, rarity_boost)
	is_selection_active = true
	
	# Emit signal for UI
	boon_offered.emit(current_selection_options)
	
	print("🏺 BoonSystem: 3 boons offered to player")

func _generate_boon_selection(count: int, rarity_boost: bool) -> Array[Dictionary]:
	"""Generate selection of random boons"""
	var selection: Array[Dictionary] = []
	var used_boons: Array[String] = []
	
	# Get available gods (could be filtered based on story progression)
	var available_gods = available_boons.keys()
	
	for i in range(count):
		# Select random god
		var god = available_gods.pick_random()
		var god_boons = available_boons[god]
		
		# Select random boon from god that isn't already used
		var attempts = 0
		var selected_boon = null
		
		while selected_boon == null and attempts < 20:
			var candidate_boon = god_boons.pick_random()
			if not used_boons.has(candidate_boon.id):
				selected_boon = candidate_boon
				used_boons.append(candidate_boon.id)
			attempts += 1
		
		if selected_boon == null:
			print("⚠️ BoonSystem: Could not find unique boon for selection!")
			continue
		
		# Determine rarity
		var rarity = _determine_boon_rarity(rarity_boost)
		
		# Create boon instance
		var boon_instance = _create_boon_instance(selected_boon, god, rarity)
		selection.append(boon_instance)
	
	return selection

func _determine_boon_rarity(rarity_boost: bool) -> BoonRarity:
	"""Determine boon rarity using Hades probabilities"""
	var rand = randf() * 100
	
	# Boost probabilities for elite rooms
	var common_chance = 70.0
	var rare_chance = 25.0
	var epic_chance = 4.0
	var legendary_chance = 1.0
	
	if rarity_boost:
		common_chance = 50.0
		rare_chance = 35.0
		epic_chance = 12.0
		legendary_chance = 3.0
	
	if rand < legendary_chance:
		return BoonRarity.LEGENDARY
	elif rand < legendary_chance + epic_chance:
		return BoonRarity.EPIC
	elif rand < legendary_chance + epic_chance + rare_chance:
		return BoonRarity.RARE
	else:
		return BoonRarity.COMMON

func _create_boon_instance(boon_template: Dictionary, god: EgyptianGod, rarity: BoonRarity) -> Dictionary:
	"""Create a boon instance with specific rarity values"""
	var instance = boon_template.duplicate(true)
	
	# Add runtime data
	instance["god"] = god
	instance["god_name"] = god_names[god]
	instance["rarity"] = rarity
	instance["rarity_data"] = rarity_data[rarity]
	instance["values"] = boon_template.values[rarity]
	instance["instance_id"] = _generate_boon_id()
	
	return instance

func _generate_boon_id() -> String:
	"""Generate unique instance ID for boon tracking"""
	return "boon_" + str(Time.get_unix_time_from_system()) + "_" + str(randi())

func select_boon(boon_instance: Dictionary):
	"""Player selects a boon from the offered options"""
	if not is_selection_active:
		print("⚠️ BoonSystem: No boon selection active!")
		return
	
	print("🏺 BoonSystem: Player selected %s from %s" % [boon_instance.name, boon_instance.god_name])
	
	# Apply boon to player
	_apply_boon_to_player(boon_instance)
	
	# Add to active boons
	active_boons.append(boon_instance)
	
	# Manage boon limit
	if active_boons.size() > max_active_boons:
		var removed_boon = active_boons.pop_front()
		print("🏺 BoonSystem: Removed oldest boon: %s" % removed_boon.name)
	
	# Clear selection
	current_selection_options.clear()
	is_selection_active = false
	
	# Emit signals
	boon_selected.emit(boon_instance)
	boon_applied.emit(boon_instance)
	
	print("✅ BoonSystem: %s applied successfully!" % boon_instance.name)

func _apply_boon_to_player(boon: Dictionary):
	"""Apply boon effects to the player"""
	if not player:
		print("⚠️ BoonSystem: No player found to apply boon!")
		return
	
	var boon_type = boon.get("type", "")
	var values = boon.get("values", {})
	
	# Apply based on boon type
	match boon_type:
		"attack_modifier":
			if player.has_method("add_attack_modifier"):
				player.add_attack_modifier(boon.id, values)
		
		"dodge_bonus":
			if player.has_method("add_dodge_bonus"):
				player.add_dodge_bonus(values.get("dodge_chance_percent", 0))
		
		"movement_modifier":
			if player.has_method("modify_movement"):
				player.modify_movement(values)
		
		"cooldown_reduction":
			if player.has_method("reduce_cooldowns"):
				player.reduce_cooldowns(values.get("cooldown_reduction_percent", 0))
		
		"execution_threshold":
			if player.has_method("set_execution_threshold"):
				player.set_execution_threshold(values.get("execution_threshold_percent", 0))
		
		_:
			print("⚠️ BoonSystem: Unknown boon type: %s" % boon_type)

# Utility functions
func get_active_boons() -> Array[Dictionary]:
	return active_boons.duplicate()

func has_boon_with_tag(tag: BoonTag) -> bool:
	for boon in active_boons:
		if boon.get("tags", []).has(tag):
			return true
	return false

func get_boons_with_tag(tag: BoonTag) -> Array[Dictionary]:
	var matching_boons: Array[Dictionary] = []
	for boon in active_boons:
		if boon.get("tags", []).has(tag):
			matching_boons.append(boon)
	return matching_boons

func clear_all_boons():
	"""Clear all active boons (for new run)"""
	active_boons.clear()
	current_selection_options.clear()
	is_selection_active = false
	print("🏺 BoonSystem: All boons cleared")

# Save/load support
func get_save_data() -> Dictionary:
	return {
		"active_boons": active_boons,
		"is_selection_active": is_selection_active
	}

func load_save_data(data: Dictionary):
	active_boons = data.get("active_boons", [])
	is_selection_active = data.get("is_selection_active", false)

# Public method for generating boon options (used by RoomSystem for physical drops)
func generate_boon_options(count: int = 3, rarity_boost: bool = false) -> Array[Dictionary]:
	"""Public method to generate boon options without starting selection"""
	return _generate_boon_selection(count, rarity_boost)

func show_boon_selection_with_options(boon_options: Array):
	"""Show boon selection UI with pre-generated options"""
	if is_selection_active:
		print("⚠️ BoonSystem: Selection already active!")
		return
	
	current_selection_options = boon_options
	is_selection_active = true
	
	# Emit signal for UI
	boon_offered.emit(current_selection_options)
	
	print("🏺 BoonSystem: Showing selection with %d pre-generated options" % boon_options.size())