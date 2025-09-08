# BoonSynergySystem.gd
# Advanced boon synergy and combination system
# Sprint 7: Sistema de Recompensas Completo

extends Node

# Synergy definitions - combinations that create special effects
var synergy_combinations: Array[Dictionary] = []

# Active synergies currently in effect
var active_synergies: Array[Dictionary] = []

# References
var boon_system: Node
var player: Node

signal synergy_activated(synergy_data: Dictionary)
signal synergy_deactivated(synergy_data: Dictionary)

func _ready():
	print("🔮 BoonSynergySystem: Initializing Egyptian divine synergies...")
	
	# Get references
	boon_system = get_node("/root/BoonSystem") if get_node_or_null("/root/BoonSystem") else null
	player = get_tree().get_first_node_in_group("player") if get_tree() else null
	
	# Initialize synergy combinations
	_initialize_synergy_combinations()
	
	# Connect to boon system
	if boon_system:
		boon_system.boon_applied.connect(_on_boon_applied)
		print("🔗 BoonSynergySystem connected to BoonSystem")
	
	print("🔮 BoonSynergySystem: %d synergy combinations available" % synergy_combinations.size())

func _initialize_synergy_combinations():
	"""Initialize all possible boon synergies"""
	synergy_combinations = [
		# Ra + Bastet Synergies (Fire + Defense)
		{
			"id": "divine_fire_shield",
			"name": "Escudo de Fogo Divino",
			"description": "Chama Dourada + Mãe Protetora = Aura de fogo que cura",
			"required_boons": ["ra_golden_flame", "bastet_protective_mother"],
			"required_tags": [BoonSystem.BoonTag.FIRE, BoonSystem.BoonTag.DEFENSE],
			"effects": {
				"aura_heal": 5,
				"aura_damage": 15,
				"aura_radius": 4.0
			}
		},
		{
			"id": "solar_reflexes", 
			"name": "Reflexos Solares",
			"description": "Luz Purificadora + Reflexos Felinos = Esquiva cega inimigos",
			"required_boons": ["ra_purifying_light", "bastet_cat_reflexes"],
			"required_tags": [BoonSystem.BoonTag.SOLAR, BoonSystem.BoonTag.AGILITY],
			"effects": {
				"dodge_blind": true,
				"blind_duration": 2.0,
				"blind_radius": 3.0
			}
		},
		
		# Ra + Thoth Synergies (Fire + Magic)
		{
			"id": "solar_knowledge",
			"name": "Conhecimento Solar",
			"description": "Eclipse Solar + Conhecimento Proibido = Eclipse mais frequente",
			"required_boons": ["ra_solar_eclipse", "thoth_forbidden_knowledge"],
			"required_tags": [BoonSystem.BoonTag.SOLAR, BoonSystem.BoonTag.UTILITY],
			"effects": {
				"eclipse_cooldown_reduction": 50,
				"exp_from_eclipse": 25
			}
		},
		{
			"id": "flaming_word",
			"name": "Palavra Flamejante",
			"description": "Coroa de Fogo + Palavra de Poder = Magias atravessam e queimam",
			"required_boons": ["ra_crown_of_fire", "thoth_word_of_power"],
			"required_tags": [BoonSystem.BoonTag.FIRE, BoonSystem.BoonTag.MAGIC],
			"effects": {
				"spell_burn_damage": 20,
				"spell_burn_duration": 4.0,
				"pierce_burn": true
			}
		},
		
		# Ra + Anubis Synergies (Fire + Death)
		{
			"id": "judgmental_flames",
			"name": "Chamas do Julgamento",
			"description": "Lança do Amanhecer + Pesagem do Coração = Primeiros ataques executam",
			"required_boons": ["ra_dawn_spear", "anubis_heart_weighing"],
			"required_tags": [BoonSystem.BoonTag.SOLAR, BoonSystem.BoonTag.DEATH],
			"effects": {
				"first_hit_execution_chance": 25,
				"execution_threshold_bonus": 10
			}
		},
		{
			"id": "phoenix_rebirth",
			"name": "Renascimento da Fênix",
			"description": "Eclipse Solar + Múmia Real = Revive com explosão de fogo",
			"required_boons": ["ra_solar_eclipse", "anubis_royal_mummy"],
			"required_tags": [BoonSystem.BoonTag.FIRE, BoonSystem.BoonTag.DEATH],
			"effects": {
				"revive_explosion_damage": 300,
				"revive_explosion_radius": 8.0,
				"revive_fire_immunity": 5.0
			}
		},
		
		# Bastet + Thoth Synergies (Agility + Magic)
		{
			"id": "wise_hunter",
			"name": "Caçadora Sábia",
			"description": "Caça Noturna + Olho que Vê Tudo = Revela inimigos e aumenta velocidade",
			"required_boons": ["bastet_night_hunt", "thoth_all_seeing_eye"],
			"required_tags": [BoonSystem.BoonTag.AGILITY, BoonSystem.BoonTag.UTILITY],
			"effects": {
				"enemy_revelation": true,
				"speed_vs_revealed": 50,
				"revelation_speed_bonus": 25
			}
		},
		{
			"id": "arcane_claws",
			"name": "Garras Arcanas",
			"description": "Garras Afiadas + Escrita Sagrada = Sangramento reduz cooldowns",
			"required_boons": ["bastet_sharp_claws", "thoth_sacred_writing"],
			"required_tags": [BoonSystem.BoonTag.AGILITY, BoonSystem.BoonTag.MAGIC],
			"effects": {
				"bleed_cooldown_reduction": 0.5,
				"special_bleed_bonus": 100
			}
		},
		
		# Bastet + Anubis Synergies (Defense + Death)
		{
			"id": "protective_judgment",
			"name": "Julgamento Protetor",
			"description": "Mãe Protetora + Guia dos Mortos = Cura dupla ao matar",
			"required_boons": ["bastet_protective_mother", "anubis_guide_of_dead"],
			"required_tags": [BoonSystem.BoonTag.DEFENSE, BoonSystem.BoonTag.DEATH],
			"effects": {
				"kill_heal_multiplier": 2.0,
				"heal_nearby_allies": true
			}
		},
		{
			"id": "nine_lives",
			"name": "Nove Vidas",
			"description": "Salto da Gata + Múmia Real = Dash pode evitar morte",
			"required_boons": ["bastet_cat_leap", "anubis_royal_mummy"],
			"required_tags": [BoonSystem.BoonTag.AGILITY, BoonSystem.BoonTag.DEATH],
			"effects": {
				"dash_death_save": true,
				"death_save_cooldown": 30.0
			}
		},
		
		# Thoth + Anubis Synergies (Magic + Death)
		{
			"id": "ancient_judgment",
			"name": "Julgamento Ancestral",
			"description": "Língua Antiga + Balança da Verdade = Cooldowns reduzem com corrupção",
			"required_boons": ["thoth_ancient_tongue", "anubis_scales_of_truth"],
			"required_tags": [BoonSystem.BoonTag.MAGIC, BoonSystem.BoonTag.JUSTICE],
			"effects": {
				"corruption_cooldown_reduction": true,
				"max_cooldown_reduction": 75
			}
		},
		{
			"id": "forbidden_execution",
			"name": "Execução Proibida", 
			"description": "Conhecimento Proibido + Veredito Final = Execuções dão experiência extra",
			"required_boons": ["thoth_forbidden_knowledge", "anubis_final_judgment"],
			"required_tags": [BoonSystem.BoonTag.UTILITY, BoonSystem.BoonTag.DEATH],
			"effects": {
				"execution_exp_multiplier": 3.0,
				"execution_chance_vs_elites": 15
			}
		},
		
		# Triple God Synergies (Legendary combinations)
		{
			"id": "divine_trinity_fire",
			"name": "Trindade Divina: Fogo",
			"description": "Ra + Bastet + Thoth = Avatar de fogo com conhecimento",
			"required_gods": [BoonSystem.EgyptianGod.RA, BoonSystem.EgyptianGod.BASTET, BoonSystem.EgyptianGod.THOTH],
			"required_tag_count": {
				BoonSystem.BoonTag.FIRE: 2,
				BoonSystem.BoonTag.DEFENSE: 1,
				BoonSystem.BoonTag.MAGIC: 1
			},
			"effects": {
				"fire_avatar": true,
				"fire_immunity": true,
				"spell_damage_multiplier": 2.0,
				"fire_aura_radius": 8.0
			}
		},
		{
			"id": "divine_trinity_death",
			"name": "Trindade Divina: Morte",
			"description": "Anubis + Thoth + Bastet = Avatar da morte justa",
			"required_gods": [BoonSystem.EgyptianGod.ANUBIS, BoonSystem.EgyptianGod.THOTH, BoonSystem.EgyptianGod.BASTET],
			"required_tag_count": {
				BoonSystem.BoonTag.DEATH: 2,
				BoonSystem.BoonTag.JUSTICE: 1,
				BoonSystem.BoonTag.MAGIC: 1
			},
			"effects": {
				"death_avatar": true,
				"execution_threshold": 75,
				"revive_on_death": true,
				"death_aura": true
			}
		}
	]

func _on_boon_applied(boon_data: Dictionary):
	"""Check for new synergies when a boon is applied"""
	print("🔮 BoonSynergySystem: Checking synergies after %s applied" % boon_data.name)
	
	_check_for_new_synergies()

func _check_for_new_synergies():
	"""Check if any new synergies are now active"""
	if not boon_system:
		return
	
	var active_boons = boon_system.get_active_boons()
	var newly_activated: Array[Dictionary] = []
	
	for synergy in synergy_combinations:
		# Skip if already active
		if _is_synergy_active(synergy.id):
			continue
		
		# Check if synergy requirements are met
		if _check_synergy_requirements(synergy, active_boons):
			_activate_synergy(synergy)
			newly_activated.append(synergy)
	
	if newly_activated.size() > 0:
		print("🔮 BoonSynergySystem: %d new synergies activated!" % newly_activated.size())

func _check_synergy_requirements(synergy: Dictionary, active_boons: Array[Dictionary]) -> bool:
	"""Check if synergy requirements are satisfied"""
	
	# Check required specific boons
	if synergy.has("required_boons"):
		var required_boons = synergy.required_boons
		for required_boon_id in required_boons:
			var found = false
			for boon in active_boons:
				if boon.get("id", "") == required_boon_id:
					found = true
					break
			if not found:
				return false
	
	# Check required tags
	if synergy.has("required_tags"):
		var active_tags: Array[int] = []
		for boon in active_boons:
			var boon_tags = boon.get("tags", [])
			for tag in boon_tags:
				if not active_tags.has(tag):
					active_tags.append(tag)
		
		for required_tag in synergy.required_tags:
			if not active_tags.has(required_tag):
				return false
	
	# Check required gods
	if synergy.has("required_gods"):
		var active_gods: Array[int] = []
		for boon in active_boons:
			var boon_god = boon.get("god", -1)
			if not active_gods.has(boon_god):
				active_gods.append(boon_god)
		
		for required_god in synergy.required_gods:
			if not active_gods.has(required_god):
				return false
	
	# Check required tag counts
	if synergy.has("required_tag_count"):
		var tag_counts: Dictionary = {}
		for boon in active_boons:
			var boon_tags = boon.get("tags", [])
			for tag in boon_tags:
				tag_counts[tag] = tag_counts.get(tag, 0) + 1
		
		for required_tag in synergy.required_tag_count.keys():
			var required_count = synergy.required_tag_count[required_tag]
			var actual_count = tag_counts.get(required_tag, 0)
			if actual_count < required_count:
				return false
	
	return true

func _is_synergy_active(synergy_id: String) -> bool:
	"""Check if synergy is already active"""
	for synergy in active_synergies:
		if synergy.get("id", "") == synergy_id:
			return true
	return false

func _activate_synergy(synergy: Dictionary):
	"""Activate a synergy effect"""
	print("✨ BoonSynergySystem: Activating synergy: %s" % synergy.name)
	
	# Add to active synergies
	active_synergies.append(synergy)
	
	# Apply synergy effects
	_apply_synergy_effects(synergy)
	
	# Emit signal
	synergy_activated.emit(synergy)
	
	print("🔮 BoonSynergySystem: %s activated successfully!" % synergy.name)

func _apply_synergy_effects(synergy: Dictionary):
	"""Apply the effects of an active synergy"""
	if not player:
		print("⚠️ BoonSynergySystem: No player to apply synergy effects!")
		return
	
	var effects = synergy.get("effects", {})
	
	for effect_name in effects.keys():
		var effect_value = effects[effect_name]
		_apply_single_synergy_effect(effect_name, effect_value, synergy.id)

func _apply_single_synergy_effect(effect_name: String, effect_value, synergy_id: String):
	"""Apply a single synergy effect"""
	match effect_name:
		"aura_heal":
			if player.has_method("add_heal_aura"):
				player.add_heal_aura(effect_value, synergy_id)
		
		"aura_damage":
			if player.has_method("add_damage_aura"):
				player.add_damage_aura(effect_value, synergy_id)
		
		"dodge_blind":
			if player.has_method("enable_dodge_blind"):
				player.enable_dodge_blind(synergy_id)
		
		"fire_avatar":
			if player.has_method("become_fire_avatar"):
				player.become_fire_avatar(synergy_id)
		
		"death_avatar":
			if player.has_method("become_death_avatar"):
				player.become_death_avatar(synergy_id)
		
		"fire_immunity":
			if player.has_method("add_damage_immunity"):
				player.add_damage_immunity("fire", synergy_id)
		
		"execution_threshold":
			if player.has_method("set_synergy_execution_threshold"):
				player.set_synergy_execution_threshold(effect_value, synergy_id)
		
		"revive_on_death":
			if player.has_method("enable_synergy_revive"):
				player.enable_synergy_revive(synergy_id)
		
		_:
			print("⚠️ BoonSynergySystem: Unknown effect: %s" % effect_name)

func get_active_synergies() -> Array[Dictionary]:
	"""Get list of currently active synergies"""
	return active_synergies.duplicate()

func get_potential_synergies() -> Array[Dictionary]:
	"""Get list of synergies that could be activated with current boons"""
	if not boon_system:
		return []
	
	var active_boons = boon_system.get_active_boons()
	var potential: Array[Dictionary] = []
	
	for synergy in synergy_combinations:
		if _is_synergy_active(synergy.id):
			continue
		
		# Check how close we are to activating this synergy
		var requirements_met = _count_synergy_requirements_met(synergy, active_boons)
		var total_requirements = _count_total_synergy_requirements(synergy)
		
		if requirements_met > 0:
			synergy["progress"] = float(requirements_met) / float(total_requirements)
			potential.append(synergy)
	
	return potential

func _count_synergy_requirements_met(synergy: Dictionary, active_boons: Array[Dictionary]) -> int:
	"""Count how many requirements of a synergy are currently met"""
	var met_count = 0
	
	# Count required boons
	if synergy.has("required_boons"):
		for required_boon_id in synergy.required_boons:
			for boon in active_boons:
				if boon.get("id", "") == required_boon_id:
					met_count += 1
					break
	
	# Count required tags
	if synergy.has("required_tags"):
		var active_tags: Array[int] = []
		for boon in active_boons:
			var boon_tags = boon.get("tags", [])
			for tag in boon_tags:
				if not active_tags.has(tag):
					active_tags.append(tag)
		
		for required_tag in synergy.required_tags:
			if active_tags.has(required_tag):
				met_count += 1
	
	return met_count

func _count_total_synergy_requirements(synergy: Dictionary) -> int:
	"""Count total requirements for a synergy"""
	var total = 0
	
	if synergy.has("required_boons"):
		total += synergy.required_boons.size()
	
	if synergy.has("required_tags"):
		total += synergy.required_tags.size()
	
	if synergy.has("required_gods"):
		total += synergy.required_gods.size()
	
	return total

func clear_all_synergies():
	"""Clear all active synergies (for new run)"""
	for synergy in active_synergies:
		_deactivate_synergy(synergy)
	
	active_synergies.clear()
	print("🔮 BoonSynergySystem: All synergies cleared")

func _deactivate_synergy(synergy: Dictionary):
	"""Deactivate a synergy and remove its effects"""
	print("🔮 BoonSynergySystem: Deactivating synergy: %s" % synergy.name)
	
	# Remove synergy effects (would need implementation in player)
	if player and player.has_method("remove_synergy_effects"):
		player.remove_synergy_effects(synergy.id)
	
	synergy_deactivated.emit(synergy)

# Save/load support
func get_save_data() -> Dictionary:
	return {
		"active_synergies": active_synergies
	}

func load_save_data(data: Dictionary):
	active_synergies = data.get("active_synergies", [])
	
	# Reapply synergy effects
	for synergy in active_synergies:
		_apply_synergy_effects(synergy)
	
	print("🔮 BoonSynergySystem: Save data loaded - %d synergies active" % active_synergies.size())