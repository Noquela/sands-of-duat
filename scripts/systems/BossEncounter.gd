extends Node
class_name BossEncounter

# Boss Encounter Management System
# Handles boss fight flow, victory/defeat conditions, and arena management

signal boss_encounter_started(boss_name: String)
signal boss_encounter_ended(boss_name: String, victory: bool)
signal boss_dialogue_display(dialogue: String)
signal boss_phase_transition(phase: int)

@export_group("Encounter Settings")
@export var encounter_arena_radius: float = 15.0
@export var victory_delay: float = 3.0
@export var defeat_respawn_delay: float = 2.0
@export var dialogue_display_duration: float = 4.0

# Encounter state
var is_encounter_active: bool = false
var current_boss: Node3D
var encounter_arena_center: Vector3
var player: CharacterBody3D
var boss_intro_triggered: bool = false

# UI and effects
var dialogue_timer: Timer
var victory_effects_active: bool = false

func _ready():
	setup_boss_encounter()
	connect_boss_signals()

func _process(_delta):
	if is_encounter_active and current_boss:
		monitor_encounter_conditions()

func setup_boss_encounter():
	add_to_group("boss_encounter")
	
	# Find player reference
	player = get_tree().get_first_node_in_group("player")
	
	# Set up dialogue timer
	dialogue_timer = Timer.new()
	dialogue_timer.one_shot = true
	dialogue_timer.timeout.connect(_on_dialogue_timer_timeout)
	add_child(dialogue_timer)
	
	print("Boss Encounter system initialized")

func connect_boss_signals():
	# Find boss in scene and connect signals
	var boss = get_tree().get_first_node_in_group("boss")
	if boss:
		setup_boss_connection(boss)

func setup_boss_connection(boss: Node3D):
	current_boss = boss
	
	if boss.has_signal("boss_defeated"):
		boss.boss_defeated.connect(_on_boss_defeated)
	if boss.has_signal("conspiracy_revelation"):
		boss.conspiracy_revelation.connect(_on_conspiracy_revelation)
	if boss.has_signal("boss_phase_changed"):
		boss.boss_phase_changed.connect(_on_boss_phase_changed)
	if boss.has_signal("boss_attack_telegraph"):
		boss.boss_attack_telegraph.connect(_on_boss_attack_telegraph)
	
	print("Boss signals connected: ", boss.name if boss.has_method("get") else "Boss")

func trigger_boss_encounter():
	if is_encounter_active:
		return
	
	if not current_boss:
		push_error("No boss found for encounter!")
		return
	
	is_encounter_active = true
	encounter_arena_center = current_boss.global_position
	
	boss_encounter_started.emit(current_boss.name if current_boss.has_method("get") else "Boss")
	
	# Lock arena (prevent player from leaving)
	setup_arena_boundaries()
	
	# Start encounter music/effects
	start_encounter_effects()
	
	print("=== BOSS ENCOUNTER STARTED ===")

func setup_arena_boundaries():
	# This would create invisible barriers around the arena
	# For now, just print
	print("Arena boundaries active - radius: ", encounter_arena_radius)

func start_encounter_effects():
	# Trigger dramatic effects for boss encounter start
	print("Boss encounter effects: dramatic music, camera zoom, etc.")

func monitor_encounter_conditions():
	if not current_boss or not player:
		return
	
	# Check if boss is still alive
	if current_boss.has_method("is_alive") and not current_boss.is_alive():
		if not victory_effects_active:
			trigger_boss_victory()
		return
	
	# Check if player died (would need health system integration)
	if player.has_method("is_alive") and not player.is_alive():
		trigger_boss_defeat()
		return
	
	# Check arena boundaries
	check_arena_boundaries()

func check_arena_boundaries():
	if not player:
		return
	
	var distance_from_center = player.global_position.distance_to(encounter_arena_center)
	if distance_from_center > encounter_arena_radius:
		# Push player back into arena
		var direction_to_center = (encounter_arena_center - player.global_position).normalized()
		var boundary_position = encounter_arena_center + direction_to_center * encounter_arena_radius
		
		# This would smoothly push player back - for now just warn
		print("Player too far from arena! Distance: ", distance_from_center)

func trigger_boss_victory():
	victory_effects_active = true
	print("=== BOSS VICTORY ===")
	
	# Victory effects
	create_victory_effects()
	
	# Delay before ending encounter
	var victory_timer = get_tree().create_timer(victory_delay)
	victory_timer.timeout.connect(complete_boss_victory)

func create_victory_effects():
	print("Victory effects: celebration, loot drops, experience gain")
	
	# Grant rewards
	grant_boss_victory_rewards()

func complete_boss_victory():
	is_encounter_active = false
	victory_effects_active = false
	
	boss_encounter_ended.emit(current_boss.name if current_boss.has_method("get") else "Boss", true)
	
	# Remove arena boundaries
	remove_arena_boundaries()
	
	# Unlock progression (next area, etc.)
	unlock_post_boss_progression()
	
	print("Boss encounter completed - Victory!")

func trigger_boss_defeat():
	print("=== BOSS DEFEAT ===")
	
	# Player died - handle defeat
	is_encounter_active = false
	
	boss_encounter_ended.emit(current_boss.name if current_boss.has_method("get") else "Boss", false)
	
	# Respawn player or restart encounter
	var defeat_timer = get_tree().create_timer(defeat_respawn_delay)
	defeat_timer.timeout.connect(handle_boss_defeat_respawn)

func handle_boss_defeat_respawn():
	print("Handling boss defeat respawn...")
	# This would reset the boss fight or respawn the player

func remove_arena_boundaries():
	print("Arena boundaries removed")

func unlock_post_boss_progression():
	print("Post-boss progression unlocked")
	
	# This would unlock the next area or story progression
	var room_system = get_tree().get_first_node_in_group("room_system")
	if room_system and room_system.has_method("unlock_next_area"):
		room_system.unlock_next_area()

func grant_boss_victory_rewards():
	if not player:
		return
	
	print("Granting boss victory rewards...")
	
	# Experience for weapon mastery
	var weapon_system = player.get_node_or_null("WeaponSystem")
	if weapon_system:
		var boss_exp = 200.0  # Significant experience for boss victory
		weapon_system.gain_weapon_experience(weapon_system.current_weapon, boss_exp)
		print("Granted ", boss_exp, " weapon experience")
	
	# Currency/fragments
	var currency_gain = 500
	print("Granted ", currency_gain, " Ankh Fragments")
	
	# Potential boon selection
	var boon_system = get_tree().get_first_node_in_group("boon_system")
	if boon_system and boon_system.has_method("trigger_boon_selection"):
		print("Boss victory boon selection available")

# SIGNAL CALLBACKS

func _on_boss_defeated():
	print("Boss defeated signal received")
	# Victory handled in monitor_encounter_conditions()

func _on_conspiracy_revelation(dialogue: String):
	print("CONSPIRACY: ", dialogue)
	boss_dialogue_display.emit(dialogue)
	
	# Display dialogue for set duration
	dialogue_timer.wait_time = dialogue_display_duration
	dialogue_timer.start()

func _on_boss_phase_changed(phase: int):
	print("Boss entered phase: ", phase)
	boss_phase_transition.emit(phase)
	
	# Phase-specific effects
	match phase:
		2:
			print("Phase 2: Conspiracy revelation begins...")
		3:
			print("Phase 3: Boss becomes desperate...")

func _on_boss_attack_telegraph(attack_name: String, duration: float):
	print("Boss telegraphs: ", attack_name, " (", duration, "s)")
	# This would trigger UI warnings or visual effects

func _on_dialogue_timer_timeout():
	# Hide dialogue display
	boss_dialogue_display.emit("")

# BOSS ARENA SETUP

func setup_boss_arena_from_scene():
	# Called when boss arena scene is loaded
	var trigger = get_tree().get_first_node_in_group("boss_intro_trigger")
	if trigger and trigger.has_signal("body_entered"):
		trigger.body_entered.connect(_on_boss_intro_trigger)
	
	print("Boss arena setup complete")

func _on_boss_intro_trigger(body: Node3D):
	if body.is_in_group("player") and not boss_intro_triggered:
		boss_intro_triggered = true
		trigger_boss_encounter()

# PUBLIC API

func get_encounter_status() -> Dictionary:
	return {
		"is_active": is_encounter_active,
		"boss_name": current_boss.name if current_boss and current_boss.has_method("get") else "None",
		"arena_center": encounter_arena_center,
		"victory_active": victory_effects_active
	}

func force_start_encounter():
	if current_boss:
		trigger_boss_encounter()

func force_end_encounter(victory: bool):
	if victory:
		trigger_boss_victory()
	else:
		trigger_boss_defeat()