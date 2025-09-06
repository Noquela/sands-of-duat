class_name ComboSystem
extends Node

## 🔥 COMBO SYSTEM - SANDS OF DUAT
## Sistema avançado de combos com armas egípcias e ataques aéreos
##
## Features:
## - Weapon-specific combo chains
## - Air combo system
## - Combo finishers with Egyptian flair
## - Combo meter with divine energy buildup
## - Cultural combo naming and effects

signal combo_started(weapon_type: String, combo_name: String)
signal combo_hit_landed(hit_number: int, damage: float, combo_multiplier: float)
signal combo_finished(combo_data: Dictionary)
signal combo_broken(reason: String)
signal combo_finisher_ready(finisher_name: String)
signal divine_combo_achieved(combo_count: int, divine_energy: float)

@export var combo_timeout: float = 2.0  # Time window between combo hits
@export var air_combo_gravity_reduction: float = 0.3  # Reduced gravity during air combos
@export var combo_damage_scaling: float = 0.15  # 15% damage increase per combo hit
@export var max_combo_multiplier: float = 3.0  # Maximum damage multiplier
@export var finisher_combo_requirement: int = 5  # Hits needed for finisher

# Combo state tracking
enum ComboState {
	IDLE,           # No active combo
	BUILDING,       # Combo in progress
	FINISHER_READY, # Ready to execute finisher
	EXECUTING,      # Executing combo or finisher
	COOLDOWN        # Post-combo cooldown
}

# Egyptian weapon types with unique combo chains
enum EgyptianWeapon {
	KHOPESH,        # Curved Egyptian sword
	WAS_SCEPTER,    # Staff of Ra
	SPEAR_OF_RA,    # Solar spear
	BOW_OF_WINDS,   # Divine bow
	ANKH_STAFF      # Life-giving staff
}

# Combo chain data structure
class ComboChain:
	var weapon_type: EgyptianWeapon
	var combo_name: String
	var hit_sequence: Array[Dictionary] = []
	var finisher: Dictionary = {}
	var cultural_theme: String = ""
	var divine_energy_gain: float = 10.0
	
	func _init(weapon: EgyptianWeapon, name: String):
		weapon_type = weapon
		combo_name = name

class ComboHit:
	var hit_name: String
	var damage_multiplier: float = 1.0
	var hitstun_duration: float = 0.3
	var pushback_force: float = 5.0
	var animation_name: String = ""
	var vfx_effect: String = ""
	var audio_cue: String = ""
	var can_air_combo: bool = false
	
	func _init(name: String, damage_mult: float = 1.0):
		hit_name = name
		damage_multiplier = damage_mult

# Current combo state
var current_state: ComboState = ComboState.IDLE
var active_combo: ComboChain = null
var current_hit_index: int = 0
var combo_timer: float = 0.0
var total_combo_hits: int = 0
var combo_damage_dealt: float = 0.0

# Air combo system
var is_air_combo: bool = false
var air_combo_count: int = 0
var original_gravity: float = 0.0

# Combo meter and divine energy
var combo_multiplier: float = 1.0
var divine_energy: float = 0.0
var max_divine_energy: float = 100.0

# Weapon combo definitions
var weapon_combos: Dictionary = {}
var available_finishers: Array[Dictionary] = []

# Visual and audio systems
var combo_vfx: ComboVisualEffects
var combo_audio: ComboAudioSystem

func _ready():
	print("🔥 ComboSystem initialized")
	setup_combo_system()
	create_egyptian_weapon_combos()
	connect_combat_signals()

func _process(delta):
	"""Update combo system"""
	
	if current_state == ComboState.BUILDING:
		update_combo_timer(delta)
	
	if is_air_combo:
		update_air_combo(delta)

func setup_combo_system():
	"""Inicializa sistema de combos"""
	
	# Setup visual effects
	combo_vfx = ComboVisualEffects.new()
	combo_vfx.name = "ComboVisualEffects"
	add_child(combo_vfx)
	
	# Setup audio system
	combo_audio = ComboAudioSystem.new()
	combo_audio.name = "ComboAudioSystem"
	add_child(combo_audio)
	
	print("✅ Combo system setup complete")

func connect_combat_signals():
	"""Conecta sinais do sistema de combate"""
	
	if GameEvents:
		GameEvents.player_attack_input.connect(_on_attack_input)
		GameEvents.player_landed_hit.connect(_on_hit_landed)
		GameEvents.player_airborne.connect(_on_player_airborne)
		GameEvents.player_grounded.connect(_on_player_grounded)

func create_egyptian_weapon_combos():
	"""Cria combos específicos para armas egípcias"""
	
	# Khopesh combos (curved sword)
	create_khopesh_combos()
	
	# Was Scepter combos (staff)
	create_was_scepter_combos()
	
	# Spear of Ra combos (spear)
	create_spear_combos()
	
	# Bow of Winds combos (ranged)
	create_bow_combos()
	
	# Ankh Staff combos (magic)
	create_ankh_staff_combos()
	
	print("✅ Egyptian weapon combos created: ", weapon_combos.size(), " weapons")

func create_khopesh_combos():
	"""Cria combos do khopesh (espada curva egípcia)"""
	
	# Pharaoh's Wrath combo
	var pharaoh_wrath = ComboChain.new(EgyptianWeapon.KHOPESH, "Pharaoh's Wrath")
	pharaoh_wrath.cultural_theme = "royal_authority"
	pharaoh_wrath.divine_energy_gain = 15.0
	
	pharaoh_wrath.hit_sequence = [
		{"hit_name": "Royal Strike", "damage_multiplier": 1.0, "animation": "khopesh_slash_1"},
		{"hit_name": "Curved Slice", "damage_multiplier": 1.2, "animation": "khopesh_slash_2"},
		{"hit_name": "Pharaoh's Decree", "damage_multiplier": 1.5, "animation": "khopesh_uppercut"},
	]
	
	pharaoh_wrath.finisher = {
		"name": "Divine Judgment Slash",
		"damage_multiplier": 3.0,
		"animation": "khopesh_finisher",
		"vfx": "golden_slash_wave",
		"area_damage": true,
		"area_radius": 5.0
	}
	
	# Desert Storm combo  
	var desert_storm = ComboChain.new(EgyptianWeapon.KHOPESH, "Desert Storm")
	desert_storm.cultural_theme = "sandstorm_fury"
	desert_storm.divine_energy_gain = 12.0
	
	desert_storm.hit_sequence = [
		{"hit_name": "Sand Slash", "damage_multiplier": 0.8, "animation": "khopesh_quick_1"},
		{"hit_name": "Wind Cut", "damage_multiplier": 0.8, "animation": "khopesh_quick_2"}, 
		{"hit_name": "Storm Strike", "damage_multiplier": 0.9, "animation": "khopesh_quick_3"},
		{"hit_name": "Sandstorm Fury", "damage_multiplier": 1.8, "animation": "khopesh_spin"},
	]
	
	desert_storm.finisher = {
		"name": "Sandstorm Devastation",
		"damage_multiplier": 2.5,
		"animation": "khopesh_storm_finisher",
		"vfx": "sandstorm_explosion",
		"blind_enemies": true,
		"blind_duration": 3.0
	}
	
	if not weapon_combos.has(EgyptianWeapon.KHOPESH):
		weapon_combos[EgyptianWeapon.KHOPESH] = []
	
	weapon_combos[EgyptianWeapon.KHOPESH].append(pharaoh_wrath)
	weapon_combos[EgyptianWeapon.KHOPESH].append(desert_storm)

func create_was_scepter_combos():
	"""Cria combos do Was Scepter (cajado de Ra)"""
	
	# Solar Authority combo
	var solar_authority = ComboChain.new(EgyptianWeapon.WAS_SCEPTER, "Solar Authority")
	solar_authority.cultural_theme = "ra_sun_power"
	solar_authority.divine_energy_gain = 20.0
	
	solar_authority.hit_sequence = [
		{"hit_name": "Sun Strike", "damage_multiplier": 1.3, "animation": "staff_overhead"},
		{"hit_name": "Solar Sweep", "damage_multiplier": 1.1, "animation": "staff_sweep"},
		{"hit_name": "Ra's Command", "damage_multiplier": 1.6, "animation": "staff_slam"},
	]
	
	solar_authority.finisher = {
		"name": "Solar Annihilation", 
		"damage_multiplier": 3.5,
		"animation": "staff_solar_finisher",
		"vfx": "solar_explosion",
		"burn_effect": true,
		"burn_duration": 5.0
	}
	
	if not weapon_combos.has(EgyptianWeapon.WAS_SCEPTER):
		weapon_combos[EgyptianWeapon.WAS_SCEPTER] = []
	
	weapon_combos[EgyptianWeapon.WAS_SCEPTER].append(solar_authority)

func create_spear_combos():
	"""Cria combos da Spear of Ra (lança solar)"""
	
	# Piercing Light combo
	var piercing_light = ComboChain.new(EgyptianWeapon.SPEAR_OF_RA, "Piercing Light")
	piercing_light.cultural_theme = "divine_precision"
	piercing_light.divine_energy_gain = 18.0
	
	piercing_light.hit_sequence = [
		{"hit_name": "Light Thrust", "damage_multiplier": 1.2, "animation": "spear_thrust_1", "can_air_combo": true},
		{"hit_name": "Solar Pierce", "damage_multiplier": 1.4, "animation": "spear_thrust_2", "can_air_combo": true},
		{"hit_name": "Divine Lance", "damage_multiplier": 1.8, "animation": "spear_spin", "can_air_combo": true},
	]
	
	piercing_light.finisher = {
		"name": "Radiant Spear Storm",
		"damage_multiplier": 4.0,
		"animation": "spear_storm_finisher",
		"vfx": "light_spear_rain",
		"projectile_count": 7,
		"homing": true
	}
	
	if not weapon_combos.has(EgyptianWeapon.SPEAR_OF_RA):
		weapon_combos[EgyptianWeapon.SPEAR_OF_RA] = []
	
	weapon_combos[EgyptianWeapon.SPEAR_OF_RA].append(piercing_light)

func create_bow_combos():
	"""Cria combos do Bow of Winds (arco divino)"""
	
	# Wind Arrow combo
	var wind_arrow = ComboChain.new(EgyptianWeapon.BOW_OF_WINDS, "Wind Arrow Barrage")
	wind_arrow.cultural_theme = "sky_mastery"
	wind_arrow.divine_energy_gain = 14.0
	
	wind_arrow.hit_sequence = [
		{"hit_name": "Swift Shot", "damage_multiplier": 0.8, "animation": "bow_quick_shot"},
		{"hit_name": "Wind Arrow", "damage_multiplier": 1.0, "animation": "bow_wind_shot"},
		{"hit_name": "Piercing Gale", "damage_multiplier": 1.3, "animation": "bow_charged_shot"},
	]
	
	wind_arrow.finisher = {
		"name": "Hurricane Volley",
		"damage_multiplier": 2.8,
		"animation": "bow_volley_finisher",
		"vfx": "wind_arrow_storm",
		"arrow_count": 12,
		"spread_pattern": "spiral"
	}
	
	if not weapon_combos.has(EgyptianWeapon.BOW_OF_WINDS):
		weapon_combos[EgyptianWeapon.BOW_OF_WINDS] = []
	
	weapon_combos[EgyptianWeapon.BOW_OF_WINDS].append(wind_arrow)

func create_ankh_staff_combos():
	"""Cria combos do Ankh Staff (cajado da vida)"""
	
	# Life Force combo
	var life_force = ComboChain.new(EgyptianWeapon.ANKH_STAFF, "Life Force Channeling")
	life_force.cultural_theme = "isis_healing"
	life_force.divine_energy_gain = 25.0
	
	life_force.hit_sequence = [
		{"hit_name": "Life Tap", "damage_multiplier": 0.9, "animation": "ankh_tap", "heal_player": 10.0},
		{"hit_name": "Vital Strike", "damage_multiplier": 1.1, "animation": "ankh_strike", "heal_player": 15.0},
		{"hit_name": "Ankh Blessing", "damage_multiplier": 1.5, "animation": "ankh_blessing", "heal_player": 25.0},
	]
	
	life_force.finisher = {
		"name": "Resurrection Wave",
		"damage_multiplier": 2.2,
		"animation": "ankh_resurrection_finisher",
		"vfx": "golden_life_wave",
		"full_heal": true,
		"temporary_invincibility": 3.0
	}
	
	if not weapon_combos.has(EgyptianWeapon.ANKH_STAFF):
		weapon_combos[EgyptianWeapon.ANKH_STAFF] = []
	
	weapon_combos[EgyptianWeapon.ANKH_STAFF].append(life_force)

func _on_attack_input(weapon_type: int, input_type: String):
	"""Callback para input de ataque"""
	
	var egyptian_weapon = weapon_type as EgyptianWeapon
	
	match current_state:
		ComboState.IDLE:
			start_combo(egyptian_weapon)
		ComboState.BUILDING:
			continue_combo(egyptian_weapon, input_type)
		ComboState.FINISHER_READY:
			if input_type == "heavy_attack":
				execute_finisher()
			else:
				continue_combo(egyptian_weapon, input_type)

func start_combo(weapon: EgyptianWeapon):
	"""Inicia novo combo"""
	
	if not weapon_combos.has(weapon) or weapon_combos[weapon].is_empty():
		return
	
	# Choose combo based on context (for now, random)
	active_combo = weapon_combos[weapon][0]  # First combo for simplicity
	current_state = ComboState.BUILDING
	current_hit_index = 0
	combo_timer = combo_timeout
	total_combo_hits = 0
	combo_damage_dealt = 0.0
	combo_multiplier = 1.0
	
	print("🔥 Starting combo: ", active_combo.combo_name)
	combo_started.emit(EgyptianWeapon.keys()[weapon], active_combo.combo_name)
	
	execute_combo_hit()

func continue_combo(weapon: EgyptianWeapon, input_type: String):
	"""Continua combo existente"""
	
	if not active_combo:
		return
	
	# Check if weapon matches
	if active_combo.weapon_type != weapon:
		break_combo("weapon_mismatch")
		return
	
	# Check timing window
	if combo_timer <= 0:
		break_combo("timing_missed")
		return
	
	# Continue to next hit
	current_hit_index += 1
	combo_timer = combo_timeout
	
	if current_hit_index >= active_combo.hit_sequence.size():
		# Combo complete, ready for finisher
		current_state = ComboState.FINISHER_READY
		combo_finisher_ready.emit(active_combo.finisher.name)
		print("⭐ Combo finisher ready: ", active_combo.finisher.name)
	else:
		execute_combo_hit()

func execute_combo_hit():
	"""Executa hit do combo"""
	
	if not active_combo or current_hit_index >= active_combo.hit_sequence.size():
		return
	
	current_state = ComboState.EXECUTING
	var hit_data = active_combo.hit_sequence[current_hit_index]
	
	# Calculate damage
	combo_multiplier = 1.0 + (total_combo_hits * combo_damage_scaling)
	combo_multiplier = min(combo_multiplier, max_combo_multiplier)
	
	var hit_damage = calculate_hit_damage(hit_data, combo_multiplier)
	
	# Check for air combo
	if hit_data.get("can_air_combo", false) and is_player_airborne():
		start_air_combo(hit_data)
	
	# Execute hit effects
	apply_hit_effects(hit_data, hit_damage)
	
	# Update tracking
	total_combo_hits += 1
	combo_damage_dealt += hit_damage
	divine_energy = min(divine_energy + active_combo.divine_energy_gain, max_divine_energy)
	
	# Visual and audio feedback
	combo_vfx.show_combo_hit(hit_data, current_hit_index + 1)
	combo_audio.play_combo_hit_sound(hit_data.hit_name)
	
	combo_hit_landed.emit(current_hit_index + 1, hit_damage, combo_multiplier)
	
	# Return to building state
	await get_tree().create_timer(0.3).timeout
	current_state = ComboState.BUILDING

func execute_finisher():
	"""Executa finisher do combo"""
	
	if not active_combo or current_state != ComboState.FINISHER_READY:
		return
	
	current_state = ComboState.EXECUTING
	var finisher = active_combo.finisher
	
	print("💥 Executing finisher: ", finisher.name)
	
	# Calculate finisher damage
	var finisher_damage = calculate_finisher_damage(finisher, combo_multiplier * 2.0)
	
	# Apply finisher effects
	apply_finisher_effects(finisher, finisher_damage)
	
	# Max divine energy bonus
	divine_energy = max_divine_energy
	
	# Check for divine combo
	if total_combo_hits >= 10:
		trigger_divine_combo()
	
	# Visual and audio feedback
	combo_vfx.show_finisher(finisher, total_combo_hits)
	combo_audio.play_finisher_sound(finisher.name)
	
	# Complete combo
	finish_combo()

func calculate_hit_damage(hit_data: Dictionary, multiplier: float) -> float:
	"""Calcula dano do hit do combo"""
	
	var base_damage = 100.0  # Base damage per hit
	var hit_multiplier = hit_data.get("damage_multiplier", 1.0)
	
	return base_damage * hit_multiplier * multiplier

func calculate_finisher_damage(finisher: Dictionary, multiplier: float) -> float:
	"""Calcula dano do finisher"""
	
	var base_damage = 200.0  # Base finisher damage
	var finisher_multiplier = finisher.get("damage_multiplier", 1.0)
	
	return base_damage * finisher_multiplier * multiplier

func apply_hit_effects(hit_data: Dictionary, damage: float):
	"""Aplica efeitos do hit"""
	
	# Damage to target
	var target = find_combo_target()
	if target and target.has_method("take_damage"):
		target.take_damage(damage, "combo_hit")
	
	# Special effects
	if hit_data.has("heal_player"):
		heal_player(hit_data.heal_player)

func apply_finisher_effects(finisher: Dictionary, damage: float):
	"""Aplica efeitos do finisher"""
	
	var target = find_combo_target()
	
	# Base damage
	if target and target.has_method("take_damage"):
		target.take_damage(damage, "combo_finisher")
	
	# Area damage
	if finisher.get("area_damage", false):
		apply_area_damage(finisher, damage * 0.6)
	
	# Status effects
	if finisher.get("burn_effect", false):
		apply_burn_to_target(target, finisher.get("burn_duration", 3.0))
	
	if finisher.get("blind_enemies", false):
		blind_nearby_enemies(finisher.get("blind_duration", 2.0))
	
	# Healing effects
	if finisher.get("full_heal", false):
		heal_player_full()
	
	# Temporary effects
	if finisher.get("temporary_invincibility", 0.0) > 0:
		grant_temporary_invincibility(finisher.temporary_invincibility)

func start_air_combo(hit_data: Dictionary):
	"""Inicia combo aéreo"""
	
	if is_air_combo:
		return
	
	is_air_combo = true
	air_combo_count = 1
	
	# Reduce gravity
	var player = get_parent()
	if player.has_method("set_gravity_scale"):
		original_gravity = player.gravity_scale
		player.set_gravity_scale(air_combo_gravity_reduction)
	
	print("🌪️ Air combo started!")

func update_air_combo(delta: float):
	"""Atualiza combo aéreo"""
	
	# Check if still airborne
	if not is_player_airborne():
		end_air_combo()

func end_air_combo():
	"""Termina combo aéreo"""
	
	if not is_air_combo:
		return
	
	is_air_combo = false
	
	# Restore gravity
	var player = get_parent()
	if player.has_method("set_gravity_scale"):
		player.set_gravity_scale(original_gravity)
	
	# Air combo bonus
	if air_combo_count >= 5:
		divine_energy += 20.0
		combo_vfx.show_air_combo_bonus(air_combo_count)
	
	print("🌪️ Air combo ended with ", air_combo_count, " hits")
	air_combo_count = 0

func break_combo(reason: String):
	"""Quebra combo atual"""
	
	print("💔 Combo broken: ", reason)
	
	if is_air_combo:
		end_air_combo()
	
	combo_broken.emit(reason)
	reset_combo_state()

func finish_combo():
	"""Finaliza combo com sucesso"""
	
	var combo_data = {
		"combo_name": active_combo.combo_name,
		"weapon_type": EgyptianWeapon.keys()[active_combo.weapon_type],
		"total_hits": total_combo_hits,
		"total_damage": combo_damage_dealt,
		"max_multiplier": combo_multiplier,
		"divine_energy_gained": active_combo.divine_energy_gain,
		"air_combo_hits": air_combo_count
	}
	
	print("🎉 Combo finished: ", combo_data)
	combo_finished.emit(combo_data)
	
	# Cooldown period
	current_state = ComboState.COOLDOWN
	await get_tree().create_timer(1.0).timeout
	
	reset_combo_state()

func reset_combo_state():
	"""Reseta estado do combo"""
	
	current_state = ComboState.IDLE
	active_combo = null
	current_hit_index = 0
	combo_timer = 0.0
	total_combo_hits = 0
	combo_damage_dealt = 0.0
	combo_multiplier = 1.0
	
	if is_air_combo:
		end_air_combo()

func update_combo_timer(delta: float):
	"""Atualiza timer do combo"""
	
	combo_timer -= delta
	
	if combo_timer <= 0 and current_state == ComboState.BUILDING:
		break_combo("timeout")

func trigger_divine_combo():
	"""Dispara combo divino especial"""
	
	print("✨ DIVINE COMBO ACHIEVED!")
	
	# Divine energy burst
	divine_energy = max_divine_energy
	divine_combo_achieved.emit(total_combo_hits, divine_energy)
	
	# Special divine effects
	combo_vfx.show_divine_combo_effect()
	grant_temporary_divine_blessing()

func grant_temporary_divine_blessing():
	"""Concede bênção divina temporária"""
	
	var player = get_parent()
	if player.has_method("add_temporary_buff"):
		player.add_temporary_buff("divine_combo_blessing", {
			"damage_multiplier": 1.5,
			"speed_multiplier": 1.3,
			"divine_glow": true
		}, 10.0)

# Utility functions

func find_combo_target() -> Node:
	"""Encontra alvo do combo"""
	
	# For now, find nearest enemy
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.is_empty():
		return null
	
	var player_pos = get_parent().global_position
	var nearest_enemy = enemies[0]
	var min_distance = player_pos.distance_to(nearest_enemy.global_position)
	
	for enemy in enemies:
		var distance = player_pos.distance_to(enemy.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest_enemy = enemy
	
	return nearest_enemy

func is_player_airborne() -> bool:
	"""Verifica se player está no ar"""
	
	var player = get_parent()
	if player.has_method("is_on_floor"):
		return not player.is_on_floor()
	
	return false

func apply_area_damage(finisher: Dictionary, damage: float):
	"""Aplica dano em área"""
	
	var radius = finisher.get("area_radius", 5.0)
	var enemies = get_tree().get_nodes_in_group("enemies")
	var player_pos = get_parent().global_position
	
	for enemy in enemies:
		if enemy.global_position.distance_to(player_pos) <= radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage, "combo_area")

func apply_burn_to_target(target: Node, duration: float):
	"""Aplica efeito de queimadura"""
	
	if target and target.has_method("apply_status_effect"):
		target.apply_status_effect("burn", duration)

func blind_nearby_enemies(duration: float):
	"""Cega inimigos próximos"""
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	var player_pos = get_parent().global_position
	
	for enemy in enemies:
		if enemy.global_position.distance_to(player_pos) <= 8.0:
			if enemy.has_method("apply_status_effect"):
				enemy.apply_status_effect("blind", duration)

func heal_player(amount: float):
	"""Cura o jogador"""
	
	var player = get_parent()
	if player.has_method("heal"):
		player.heal(amount)

func heal_player_full():
	"""Cura completa do jogador"""
	
	var player = get_parent()
	if player.has_method("heal_full"):
		player.heal_full()

func grant_temporary_invincibility(duration: float):
	"""Concede invincibilidade temporária"""
	
	var player = get_parent()
	if player.has_method("set_invincible"):
		player.set_invincible(true)
		await get_tree().create_timer(duration).timeout
		player.set_invincible(false)

# Event callbacks

func _on_hit_landed(target: Node, damage: float):
	"""Callback quando hit é conectado"""
	
	if current_state == ComboState.EXECUTING:
		# Hit landed successfully, combo can continue
		pass

func _on_player_airborne():
	"""Callback quando player fica no ar"""
	
	# Check if current combo hit supports air combo
	if active_combo and current_hit_index < active_combo.hit_sequence.size():
		var hit_data = active_combo.hit_sequence[current_hit_index]
		if hit_data.get("can_air_combo", false):
			start_air_combo(hit_data)

func _on_player_grounded():
	"""Callback quando player toca o chão"""
	
	if is_air_combo:
		end_air_combo()

# Visual Effects System
class ComboVisualEffects extends Node2D:
	"""Sistema de efeitos visuais para combos"""
	
	func show_combo_hit(hit_data: Dictionary, hit_number: int):
		print("✨ VFX: Combo hit #", hit_number, " - ", hit_data.hit_name)
	
	func show_finisher(finisher: Dictionary, combo_hits: int):
		print("💥 VFX: Finisher - ", finisher.name, " (", combo_hits, " hits)")
	
	func show_air_combo_bonus(hits: int):
		print("🌪️ VFX: Air combo bonus - ", hits, " hits")
	
	func show_divine_combo_effect():
		print("✨ VFX: Divine combo effect!")

# Audio System
class ComboAudioSystem extends AudioStreamPlayer2D:
	"""Sistema de áudio para combos"""
	
	func play_combo_hit_sound(hit_name: String):
		print("🔊 Audio: ", hit_name)
	
	func play_finisher_sound(finisher_name: String):
		print("🔊 Audio: Finisher - ", finisher_name)

# Public interface

func get_combo_statistics() -> Dictionary:
	"""Retorna estatísticas de combo"""
	
	return {
		"current_state": ComboState.keys()[current_state],
		"active_combo": active_combo.combo_name if active_combo else "",
		"current_hits": total_combo_hits,
		"combo_multiplier": combo_multiplier,
		"divine_energy": divine_energy,
		"is_air_combo": is_air_combo,
		"air_combo_hits": air_combo_count
	}

func force_break_combo():
	"""Força quebra do combo"""
	
	break_combo("forced")

func set_combo_timeout(timeout: float):
	"""Define timeout do combo"""
	
	combo_timeout = timeout

# Debug functions

func debug_trigger_divine_combo():
	"""Debug: dispara combo divino"""
	
	total_combo_hits = 15
	divine_energy = max_divine_energy
	trigger_divine_combo()

func debug_show_available_combos():
	"""Debug: mostra combos disponíveis"""
	
	print("\n🔥 AVAILABLE COMBOS")
	print("==================")
	
	for weapon in weapon_combos.keys():
		var weapon_name = EgyptianWeapon.keys()[weapon]
		print(weapon_name, ":")
		
		for combo in weapon_combos[weapon]:
			print("  - ", combo.combo_name, " (", combo.hit_sequence.size(), " hits)")
			print("    Theme: ", combo.cultural_theme)
			print("    Finisher: ", combo.finisher.name)