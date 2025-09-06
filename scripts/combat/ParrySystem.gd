class_name ParrySystem
extends Node

## ⚔️ PERFECT PARRY SYSTEM - SANDS OF DUAT
## Sistema avançado de parry com timing preciso e counter-attacks egípcios
##
## Features:
## - Perfect parry timing (0.2s window)
## - Parry counter-attacks with Egyptian flair
## - Parry-specific boons integration
## - Visual/audio feedback with cultural context
## - Adaptive difficulty based on player skill

signal parry_attempted(success: bool, timing_delta: float)
signal perfect_parry_achieved(enemy: Node, counter_damage: float)
signal parry_counter_attack(attack_type: String, damage: float)
signal parry_boon_triggered(boon_name: String, effect_data: Dictionary)

@export var perfect_parry_window: float = 0.2  # Perfect timing window in seconds
@export var good_parry_window: float = 0.4     # Good timing window
@export var parry_recovery_time: float = 0.3   # Recovery time after failed parry
@export var counter_damage_multiplier: float = 1.5
@export var enable_adaptive_difficulty: bool = true

# Parry timing states
enum ParryState {
	READY,          # Ready to parry
	ACTIVE,         # Parry input received, checking timing
	SUCCESS,        # Successful parry
	FAILED,         # Failed parry attempt
	RECOVERY,       # Recovery period after parry
	COUNTER_ATTACK  # Executing counter attack
}

# Parry quality levels
enum ParryQuality {
	FAILED,   # Mistimed or missed
	GOOD,     # Within good window
	PERFECT,  # Within perfect window
	DIVINE    # Frame-perfect parry (Egyptian gods' blessing)
}

# Egyptian parry counter attacks
enum EgyptianCounterType {
	ANKH_STRIKE,        # Ankh symbol energy blast
	KHOPESH_SLICE,      # Curved sword counter slice
	PHARAOH_COMMAND,    # Divine authority stun
	MAAT_JUDGMENT,      # Justice-based counter
	RA_SUNBURST,        # Solar energy explosion
	ANUBIS_VERDICT      # Death god's judgment
}

# Current parry state
var current_state: ParryState = ParryState.READY
var parry_input_time: float = 0.0
var incoming_attack_time: float = 0.0
var current_enemy: Node = null

# Parry statistics for adaptive difficulty
var parry_attempts: int = 0
var successful_parries: int = 0
var perfect_parries: int = 0
var success_rate: float = 0.0

# Parry-specific boons system
var active_parry_boons: Array[Dictionary] = []
var parry_combo_count: int = 0
var max_parry_combo: int = 0

# Visual effects and feedback
var parry_vfx: ParryVisualEffects
var egyptian_audio_cues: EgyptianAudioCues

# Timing assistance
var parry_timing_display: Control = null
var show_timing_assistance: bool = false

func _ready():
	print("⚔️ ParrySystem initialized")
	setup_parry_system()
	connect_combat_signals()
	
	if enable_adaptive_difficulty:
		print("🎯 Adaptive parry difficulty enabled")

func setup_parry_system():
	"""Inicializa sistema de parry"""
	
	# Setup visual effects
	parry_vfx = ParryVisualEffects.new()
	parry_vfx.name = "ParryVisualEffects"
	add_child(parry_vfx)
	
	# Setup audio cues
	egyptian_audio_cues = EgyptianAudioCues.new()
	egyptian_audio_cues.name = "EgyptianAudioCues"
	add_child(egyptian_audio_cues)
	
	# Load parry boons
	load_parry_boon_system()
	
	print("✅ Parry system setup complete")

func connect_combat_signals():
	"""Conecta sinais do sistema de combate"""
	
	# Connect to combat system
	if GameEvents:
		GameEvents.enemy_attack_incoming.connect(_on_enemy_attack_incoming)
		GameEvents.player_input_received.connect(_on_player_input)
		GameEvents.boon_collected.connect(_on_boon_collected)

func load_parry_boon_system():
	"""Carrega sistema de boons específicos de parry"""
	
	# Load parry-specific boons from data
	var parry_boons_data = load("res://data/boons/parry_boons.tres")
	if parry_boons_data:
		print("✅ Parry boons loaded")
	else:
		# Create default parry boons
		create_default_parry_boons()

func create_default_parry_boons():
	"""Cria boons de parry padrão com tema egípcio"""
	
	var default_boons = [
		{
			"name": "Maat's Perfect Balance",
			"description": "Perfect parries extend parry window by 0.1s for 3s",
			"effect_type": "window_extension",
			"value": 0.1,
			"duration": 3.0,
			"cultural_context": "maat_justice"
		},
		{
			"name": "Ra's Solar Reflection",
			"description": "Successful parries blind nearby enemies",
			"effect_type": "area_blind",
			"radius": 5.0,
			"duration": 2.0,
			"cultural_context": "ra_sun"
		},
		{
			"name": "Anubis Death Counter",
			"description": "Perfect parries deal 200% counter damage",
			"effect_type": "damage_multiplier",
			"value": 2.0,
			"cultural_context": "anubis_death"
		},
		{
			"name": "Khnum's Crafted Defense",
			"description": "Each successful parry increases defense by 10%",
			"effect_type": "defense_stack",
			"value": 0.1,
			"max_stacks": 5,
			"cultural_context": "khnum_craft"
		},
		{
			"name": "Thoth's Wisdom Timing",
			"description": "Shows enemy attack timing indicators",
			"effect_type": "timing_assistance",
			"value": true,
			"cultural_context": "thoth_wisdom"
		}
	]
	
	for boon_data in default_boons:
		active_parry_boons.append(boon_data)
	
	print("✅ Default parry boons created: ", active_parry_boons.size())

func _on_player_input(action: String, pressed: bool):
	"""Callback para input do jogador"""
	
	if action == "parry" and pressed and current_state == ParryState.READY:
		attempt_parry()

func attempt_parry():
	"""Tenta executar parry"""
	
	if current_state != ParryState.READY:
		return
	
	current_state = ParryState.ACTIVE
	parry_input_time = Time.get_time_dict_from_system().second + Time.get_time_dict_from_system().msec / 1000.0
	parry_attempts += 1
	
	print("🛡️ Parry attempted")
	
	# Check for incoming attacks
	check_parry_timing()

func _on_enemy_attack_incoming(enemy: Node, attack_data: Dictionary):
	"""Callback quando inimigo vai atacar"""
	
	current_enemy = enemy
	incoming_attack_time = attack_data.get("impact_time", 0.0)
	
	# Show timing assistance if enabled
	if show_timing_assistance:
		show_parry_timing_indicator(attack_data)

func show_parry_timing_indicator(attack_data: Dictionary):
	"""Mostra indicador visual de timing de parry"""
	
	if parry_timing_display:
		parry_timing_display.show_timing_indicator(attack_data.impact_time)

func check_parry_timing():
	"""Verifica timing do parry"""
	
	if not current_enemy or incoming_attack_time <= 0:
		execute_failed_parry()
		return
	
	var timing_delta = abs(parry_input_time - incoming_attack_time)
	var parry_quality = evaluate_parry_quality(timing_delta)
	
	match parry_quality:
		ParryQuality.FAILED:
			execute_failed_parry()
		ParryQuality.GOOD:
			execute_good_parry(timing_delta)
		ParryQuality.PERFECT:
			execute_perfect_parry(timing_delta)
		ParryQuality.DIVINE:
			execute_divine_parry(timing_delta)
	
	parry_attempted.emit(parry_quality != ParryQuality.FAILED, timing_delta)

func evaluate_parry_quality(timing_delta: float) -> ParryQuality:
	"""Avalia qualidade do parry baseado no timing"""
	
	# Apply adaptive difficulty adjustments
	var adjusted_perfect_window = perfect_parry_window
	var adjusted_good_window = good_parry_window
	
	if enable_adaptive_difficulty:
		var difficulty_adjustment = calculate_adaptive_adjustment()
		adjusted_perfect_window *= difficulty_adjustment.perfect_multiplier
		adjusted_good_window *= difficulty_adjustment.good_multiplier
	
	# Check for divine parry (frame-perfect)
	if timing_delta <= 0.016:  # 1 frame at 60fps
		return ParryQuality.DIVINE
	
	# Check timing windows
	if timing_delta <= adjusted_perfect_window:
		return ParryQuality.PERFECT
	elif timing_delta <= adjusted_good_window:
		return ParryQuality.GOOD
	else:
		return ParryQuality.FAILED

func calculate_adaptive_adjustment() -> Dictionary:
	"""Calcula ajuste de dificuldade adaptativo"""
	
	success_rate = float(successful_parries) / max(parry_attempts, 1)
	
	var perfect_multiplier = 1.0
	var good_multiplier = 1.0
	
	# If player is struggling, make windows more forgiving
	if success_rate < 0.3:
		perfect_multiplier = 1.3
		good_multiplier = 1.4
	elif success_rate < 0.5:
		perfect_multiplier = 1.15
		good_multiplier = 1.2
	# If player is too good, make it more challenging
	elif success_rate > 0.8:
		perfect_multiplier = 0.85
		good_multiplier = 0.9
	elif success_rate > 0.65:
		perfect_multiplier = 0.95
		good_multiplier = 0.95
	
	return {
		"perfect_multiplier": perfect_multiplier,
		"good_multiplier": good_multiplier
	}

func execute_failed_parry():
	"""Executa parry falhado"""
	
	current_state = ParryState.FAILED
	
	print("❌ Parry failed")
	
	# Visual feedback
	parry_vfx.show_failed_parry()
	egyptian_audio_cues.play_failed_parry_sound()
	
	# Reset combo
	parry_combo_count = 0
	
	# Start recovery period
	await get_tree().create_timer(parry_recovery_time).timeout
	current_state = ParryState.READY

func execute_good_parry(timing_delta: float):
	"""Executa parry bom"""
	
	current_state = ParryState.SUCCESS
	successful_parries += 1
	parry_combo_count += 1
	
	print("✅ Good parry! Delta: ", "%.3f" % timing_delta, "s")
	
	# Visual/audio feedback
	parry_vfx.show_good_parry()
	egyptian_audio_cues.play_good_parry_sound()
	
	# Trigger counter attack
	var counter_type = choose_counter_attack(ParryQuality.GOOD)
	execute_counter_attack(counter_type, 1.0)
	
	# Apply parry boons
	apply_parry_boons(ParryQuality.GOOD)

func execute_perfect_parry(timing_delta: float):
	"""Executa parry perfeito"""
	
	current_state = ParryState.SUCCESS
	successful_parries += 1
	perfect_parries += 1
	parry_combo_count += 1
	max_parry_combo = max(max_parry_combo, parry_combo_count)
	
	print("⭐ Perfect parry! Delta: ", "%.3f" % timing_delta, "s")
	
	# Enhanced visual/audio feedback
	parry_vfx.show_perfect_parry()
	egyptian_audio_cues.play_perfect_parry_sound()
	
	# Trigger enhanced counter attack
	var counter_type = choose_counter_attack(ParryQuality.PERFECT)
	execute_counter_attack(counter_type, counter_damage_multiplier)
	
	# Apply parry boons with bonus
	apply_parry_boons(ParryQuality.PERFECT)
	
	perfect_parry_achieved.emit(current_enemy, counter_damage_multiplier)

func execute_divine_parry(timing_delta: float):
	"""Executa parry divino (frame-perfect)"""
	
	current_state = ParryState.SUCCESS
	successful_parries += 1
	perfect_parries += 1
	parry_combo_count += 1
	max_parry_combo = max(max_parry_combo, parry_combo_count)
	
	print("🌟 DIVINE PARRY! Frame-perfect timing! Delta: ", "%.3f" % timing_delta, "s")
	
	# Divine visual/audio feedback
	parry_vfx.show_divine_parry()
	egyptian_audio_cues.play_divine_parry_sound()
	
	# Trigger divine counter attack
	var counter_type = EgyptianCounterType.RA_SUNBURST  # Divine parries always use Ra's power
	execute_counter_attack(counter_type, counter_damage_multiplier * 2.0)
	
	# Apply all parry boons with maximum bonus
	apply_parry_boons(ParryQuality.DIVINE)
	
	# Divine blessing effect
	trigger_divine_blessing_effect()
	
	perfect_parry_achieved.emit(current_enemy, counter_damage_multiplier * 2.0)

func choose_counter_attack(quality: ParryQuality) -> EgyptianCounterType:
	"""Escolhe tipo de contra-ataque baseado na qualidade do parry"""
	
	match quality:
		ParryQuality.GOOD:
			# Random basic counter
			var basic_counters = [EgyptianCounterType.ANKH_STRIKE, EgyptianCounterType.KHOPESH_SLICE]
			return basic_counters[randi() % basic_counters.size()]
		
		ParryQuality.PERFECT:
			# More powerful counters
			var perfect_counters = [EgyptianCounterType.PHARAOH_COMMAND, EgyptianCounterType.MAAT_JUDGMENT, EgyptianCounterType.ANUBIS_VERDICT]
			return perfect_counters[randi() % perfect_counters.size()]
		
		ParryQuality.DIVINE:
			# Always divine power
			return EgyptianCounterType.RA_SUNBURST
		
		_:
			return EgyptianCounterType.ANKH_STRIKE

func execute_counter_attack(counter_type: EgyptianCounterType, damage_multiplier: float):
	"""Executa contra-ataque egípcio"""
	
	if not current_enemy:
		return
	
	current_state = ParryState.COUNTER_ATTACK
	
	var attack_name = EgyptianCounterType.keys()[counter_type]
	var counter_damage = calculate_counter_damage(counter_type, damage_multiplier)
	
	print("⚔️ Executing counter attack: ", attack_name, " (", counter_damage, " damage)")
	
	# Execute specific counter attack
	match counter_type:
		EgyptianCounterType.ANKH_STRIKE:
			execute_ankh_strike(counter_damage)
		EgyptianCounterType.KHOPESH_SLICE:
			execute_khopesh_slice(counter_damage)
		EgyptianCounterType.PHARAOH_COMMAND:
			execute_pharaoh_command(counter_damage)
		EgyptianCounterType.MAAT_JUDGMENT:
			execute_maat_judgment(counter_damage)
		EgyptianCounterType.RA_SUNBURST:
			execute_ra_sunburst(counter_damage)
		EgyptianCounterType.ANUBIS_VERDICT:
			execute_anubis_verdict(counter_damage)
	
	parry_counter_attack.emit(attack_name, counter_damage)
	
	# Return to ready state after counter
	await get_tree().create_timer(0.5).timeout
	current_state = ParryState.READY

func calculate_counter_damage(counter_type: EgyptianCounterType, multiplier: float) -> float:
	"""Calcula dano do contra-ataque"""
	
	var base_damage = 100.0  # Base counter damage
	
	# Type-specific multipliers
	match counter_type:
		EgyptianCounterType.ANKH_STRIKE:
			base_damage *= 1.0
		EgyptianCounterType.KHOPESH_SLICE:
			base_damage *= 1.2
		EgyptianCounterType.PHARAOH_COMMAND:
			base_damage *= 1.5
		EgyptianCounterType.MAAT_JUDGMENT:
			base_damage *= 1.3
		EgyptianCounterType.RA_SUNBURST:
			base_damage *= 2.0
		EgyptianCounterType.ANUBIS_VERDICT:
			base_damage *= 1.8
	
	# Apply parry combo bonus
	var combo_bonus = 1.0 + (parry_combo_count * 0.1)
	
	return base_damage * multiplier * combo_bonus

# Counter attack implementations

func execute_ankh_strike(damage: float):
	"""Executa Ankh Strike - projétil de energia ankh"""
	parry_vfx.show_ankh_strike_effect(current_enemy.global_position)
	deal_counter_damage(damage)

func execute_khopesh_slice(damage: float):
	"""Executa Khopesh Slice - corte curvo rápido"""
	parry_vfx.show_khopesh_slice_effect()
	deal_counter_damage(damage)

func execute_pharaoh_command(damage: float):
	"""Executa Pharaoh Command - comando divino que atordoa"""
	parry_vfx.show_pharaoh_command_effect()
	deal_counter_damage(damage)
	if current_enemy.has_method("apply_stun"):
		current_enemy.apply_stun(2.0)

func execute_maat_judgment(damage: float):
	"""Executa Maat Judgment - julgamento da justiça"""
	parry_vfx.show_maat_judgment_effect()
	deal_counter_damage(damage * 1.5)  # Bonus damage for justice

func execute_ra_sunburst(damage: float):
	"""Executa Ra Sunburst - explosão solar divina"""
	parry_vfx.show_ra_sunburst_effect()
	deal_counter_damage(damage)
	
	# Area damage to nearby enemies
	var nearby_enemies = find_nearby_enemies(5.0)
	for enemy in nearby_enemies:
		if enemy != current_enemy:
			enemy.take_damage(damage * 0.5, "ra_sunburst")

func execute_anubis_verdict(damage: float):
	"""Executa Anubis Verdict - veredicto da morte"""
	parry_vfx.show_anubis_verdict_effect()
	deal_counter_damage(damage)
	
	# Death mark effect
	if current_enemy.has_method("apply_death_mark"):
		current_enemy.apply_death_mark(5.0)

func deal_counter_damage(damage: float):
	"""Aplica dano do contra-ataque ao inimigo"""
	
	if current_enemy and current_enemy.has_method("take_damage"):
		current_enemy.take_damage(damage, "parry_counter")

func find_nearby_enemies(radius: float) -> Array:
	"""Encontra inimigos próximos para ataques em área"""
	
	var nearby_enemies = []
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if enemy.global_position.distance_to(get_parent().global_position) <= radius:
			nearby_enemies.append(enemy)
	
	return nearby_enemies

func apply_parry_boons(quality: ParryQuality):
	"""Aplica boons específicos de parry"""
	
	for boon in active_parry_boons:
		if should_trigger_boon(boon, quality):
			trigger_parry_boon(boon, quality)

func should_trigger_boon(boon: Dictionary, quality: ParryQuality) -> bool:
	"""Verifica se boon deve ser ativado"""
	
	# Check trigger conditions
	var trigger_on_good = boon.get("trigger_on_good", true)
	var trigger_on_perfect = boon.get("trigger_on_perfect", true)
	var trigger_on_divine = boon.get("trigger_on_divine", true)
	
	match quality:
		ParryQuality.GOOD:
			return trigger_on_good
		ParryQuality.PERFECT:
			return trigger_on_perfect
		ParryQuality.DIVINE:
			return trigger_on_divine
		_:
			return false

func trigger_parry_boon(boon: Dictionary, quality: ParryQuality):
	"""Ativa efeito de boon de parry"""
	
	var effect_type = boon.get("effect_type", "")
	var boon_name = boon.get("name", "Unknown Boon")
	
	print("✨ Triggering parry boon: ", boon_name)
	
	match effect_type:
		"window_extension":
			extend_parry_window(boon.get("value", 0.1), boon.get("duration", 3.0))
		"area_blind":
			blind_nearby_enemies(boon.get("radius", 5.0), boon.get("duration", 2.0))
		"damage_multiplier":
			# This affects next counter attack
			pass  # Already handled in calculate_counter_damage
		"defense_stack":
			apply_defense_stack(boon.get("value", 0.1))
		"timing_assistance":
			enable_timing_assistance()
	
	parry_boon_triggered.emit(boon_name, boon)

func extend_parry_window(extension: float, duration: float):
	"""Estende janela de parry temporariamente"""
	
	perfect_parry_window += extension
	good_parry_window += extension
	
	# Restore after duration
	await get_tree().create_timer(duration).timeout
	perfect_parry_window -= extension
	good_parry_window -= extension

func blind_nearby_enemies(radius: float, duration: float):
	"""Cega inimigos próximos com luz de Ra"""
	
	var nearby_enemies = find_nearby_enemies(radius)
	for enemy in nearby_enemies:
		if enemy.has_method("apply_blind"):
			enemy.apply_blind(duration)

func apply_defense_stack(bonus: float):
	"""Aplica stack de defesa"""
	
	var player = get_parent()
	if player.has_method("add_defense_modifier"):
		player.add_defense_modifier("parry_defense", bonus, 10.0)

func enable_timing_assistance():
	"""Ativa assistência de timing"""
	
	show_timing_assistance = true

func trigger_divine_blessing_effect():
	"""Dispara efeito de bênção divina para parry divino"""
	
	# Slow motion effect
	Engine.time_scale = 0.3
	await get_tree().create_timer(1.0).timeout
	Engine.time_scale = 1.0
	
	# Healing
	var player = get_parent()
	if player.has_method("heal"):
		player.heal(50.0)

func _on_boon_collected(boon_data: Dictionary):
	"""Callback quando boon é coletado"""
	
	if boon_data.get("category", "") == "parry":
		active_parry_boons.append(boon_data)
		print("✨ Parry boon collected: ", boon_data.get("name", "Unknown"))

# Visual Effects System
class ParryVisualEffects extends Node2D:
	"""Sistema de efeitos visuais para parry"""
	
	func show_failed_parry():
		print("❌ VFX: Failed parry")
	
	func show_good_parry():
		print("✅ VFX: Good parry")
	
	func show_perfect_parry():
		print("⭐ VFX: Perfect parry")
	
	func show_divine_parry():
		print("🌟 VFX: Divine parry")
	
	func show_ankh_strike_effect(target_pos: Vector3):
		print("⚔️ VFX: Ankh strike at ", target_pos)
	
	func show_khopesh_slice_effect():
		print("⚔️ VFX: Khopesh slice")
	
	func show_pharaoh_command_effect():
		print("👑 VFX: Pharaoh command")
	
	func show_maat_judgment_effect():
		print("⚖️ VFX: Maat judgment")
	
	func show_ra_sunburst_effect():
		print("☀️ VFX: Ra sunburst")
	
	func show_anubis_verdict_effect():
		print("🐺 VFX: Anubis verdict")

# Audio System
class EgyptianAudioCues extends AudioStreamPlayer2D:
	"""Sistema de áudio egípcio para parry"""
	
	func play_failed_parry_sound():
		print("🔊 Audio: Failed parry")
	
	func play_good_parry_sound():
		print("🔊 Audio: Good parry")
	
	func play_perfect_parry_sound():
		print("🔊 Audio: Perfect parry")
	
	func play_divine_parry_sound():
		print("🔊 Audio: Divine parry")

# Public interface

func get_parry_statistics() -> Dictionary:
	"""Retorna estatísticas de parry"""
	
	return {
		"attempts": parry_attempts,
		"successful": successful_parries,
		"perfect": perfect_parries,
		"success_rate": success_rate,
		"max_combo": max_parry_combo,
		"current_combo": parry_combo_count,
		"active_boons": active_parry_boons.size()
	}

func reset_parry_statistics():
	"""Reseta estatísticas de parry"""
	
	parry_attempts = 0
	successful_parries = 0
	perfect_parries = 0
	success_rate = 0.0
	parry_combo_count = 0
	max_parry_combo = 0

func set_parry_windows(perfect: float, good: float):
	"""Define janelas de parry customizadas"""
	
	perfect_parry_window = perfect
	good_parry_window = good
	print("🛡️ Parry windows updated: perfect=", perfect, "s, good=", good, "s")

# Debug functions

func debug_trigger_perfect_parry():
	"""Debug: simula parry perfeito"""
	execute_perfect_parry(0.05)

func debug_show_parry_info():
	"""Debug: mostra informações do sistema de parry"""
	var stats = get_parry_statistics()
	print("\n⚔️ PARRY SYSTEM INFO")
	print("==================")
	print("State: ", ParryState.keys()[current_state])
	print("Windows: Perfect=", perfect_parry_window, "s, Good=", good_parry_window, "s")
	print("Success Rate: ", "%.1f" % (stats.success_rate * 100), "%")
	print("Perfect Rate: ", "%.1f" % ((float(stats.perfect) / max(stats.attempts, 1)) * 100), "%")
	print("Max Combo: ", stats.max_combo)
	print("Active Boons: ", stats.active_boons)