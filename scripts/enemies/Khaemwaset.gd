extends CharacterBody3D
class_name Khaemwaset

# Khaemwaset - Corrupted High Priest Boss
# First boss that reveals the conspiracy against Khenti

signal boss_phase_changed(phase: int)
signal conspiracy_revelation(dialogue: String)
signal boss_defeated()
signal boss_attack_telegraph(attack_name: String, duration: float)

enum BossPhase {
	PHASE_1_DEFENSIVE = 1,    # 100% -> 66% HP - Dark barriers & summons
	PHASE_2_REVELATION = 2,   # 66% -> 33% HP - Conspiracy revealed
	PHASE_3_DESPERATION = 3   # 33% -> 0% HP - Shadow transformation
}

enum AttackType {
	SHADOW_BARRIER,
	SUMMON_SHADES, 
	DARK_PROJECTILES,
	SHADOW_WAVE,
	CORRUPTION_BLAST,
	DESPERATE_TORNADO,
	MASS_SHADOW_STRIKE
}

@export_group("Boss Stats")
@export var max_health: float = 1200.0
@export var phase_1_threshold: float = 800.0  # 66%
@export var phase_2_threshold: float = 400.0  # 33%
@export var movement_speed: float = 2.0
@export var boss_arena_radius: float = 15.0

@export_group("Attack Settings") 
@export var attack_cooldown: float = 3.0
@export var telegraph_duration: float = 1.5
@export var phase_transition_duration: float = 2.0

# Boss state
var current_health: float
var current_phase: BossPhase = BossPhase.PHASE_1_DEFENSIVE
var is_transitioning: bool = false
var attack_timer: float = 0.0
var is_telegraphing: bool = false

# Phase-specific data
var phase_attacks = {
	BossPhase.PHASE_1_DEFENSIVE: [AttackType.SHADOW_BARRIER, AttackType.SUMMON_SHADES, AttackType.DARK_PROJECTILES],
	BossPhase.PHASE_2_REVELATION: [AttackType.SHADOW_WAVE, AttackType.CORRUPTION_BLAST, AttackType.DARK_PROJECTILES],
	BossPhase.PHASE_3_DESPERATION: [AttackType.DESPERATE_TORNADO, AttackType.MASS_SHADOW_STRIKE, AttackType.CORRUPTION_BLAST]
}

# Conspiracy dialogue per phase
var conspiracy_dialogues = {
	BossPhase.PHASE_2_REVELATION: [
		"You were never meant to escape, Prince Khenti!",
		"Your brother Set orchestrated everything...",
		"The assassination, your death - all planned!",
		"He needed you gone to claim the throne!"
	],
	BossPhase.PHASE_3_DESPERATION: [
		"Set promised me power beyond imagination!",
		"But you... you're ruining everything!",
		"The portal to the living world... it's in the Temple of Eternity!",
		"Set's corruption spreads through all of Egypt!"
	]
}

# References
var player: CharacterBody3D
var arena_center: Vector3
var shade_spawns: Array[Node3D] = []
var active_barriers: Array[Node3D] = []
var dialogue_index: int = 0

func _ready():
	setup_boss()
	find_player_and_arena()
	start_boss_encounter()

func _physics_process(delta):
	if is_transitioning:
		return
		
	update_attack_timer(delta)
	handle_boss_movement(delta)
	check_phase_transitions()
	
	move_and_slide()

func setup_boss():
	add_to_group("enemies")
	add_to_group("boss")
	current_health = max_health
	
	# Boss collision setup
	collision_layer = 2  # Enemies layer
	collision_mask = 5   # Player + Environment
	
	print("Khaemwaset boss initialized - Phase 1: Defensive Magic")

func find_player_and_arena():
	player = get_tree().get_first_node_in_group("player")
	if not player:
		push_error("Player not found for boss fight!")
		return
	
	# Set arena center to boss starting position
	arena_center = global_position
	print("Boss arena center set to: ", arena_center)

func start_boss_encounter():
	# Boss introduction
	print("=== BOSS ENCOUNTER START ===")
	print("Khaemwaset, Corrupted High Priest")
	print("Phase 1: Defensive Magic - HP: ", current_health, "/", max_health)
	
	# Trigger encounter music/effects
	conspiracy_revelation.emit("So... Prince Khenti awakens in the Duat...")

func update_attack_timer(delta):
	if is_telegraphing:
		return
		
	attack_timer -= delta
	if attack_timer <= 0.0:
		execute_phase_attack()
		attack_timer = attack_cooldown + randf_range(-0.5, 0.5)

func handle_boss_movement(delta):
	if not player or is_telegraphing:
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	var desired_distance = 8.0 + (current_phase - 1) * 2.0  # Closer in later phases
	
	# Move towards or away from player to maintain optimal distance
	var direction = Vector3.ZERO
	if distance_to_player > desired_distance:
		direction = (player.global_position - global_position).normalized()
	elif distance_to_player < desired_distance - 2.0:
		direction = (global_position - player.global_position).normalized()
	
	# Stay within arena bounds
	var distance_from_center = global_position.distance_to(arena_center)
	if distance_from_center > boss_arena_radius:
		var center_direction = (arena_center - global_position).normalized()
		direction = center_direction
	
	velocity = direction * movement_speed
	
	# Face the player
	if direction.length() > 0.1:
		var target_rotation = atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 3.0 * delta)

func execute_phase_attack():
	if not player:
		return
		
	var available_attacks = phase_attacks[current_phase]
	var chosen_attack = available_attacks[randi() % available_attacks.size()]
	
	telegraph_attack(chosen_attack)

func telegraph_attack(attack: AttackType):
	is_telegraphing = true
	var attack_name = get_attack_name(attack)
	
	print("Khaemwaset telegraphs: ", attack_name)
	boss_attack_telegraph.emit(attack_name, telegraph_duration)
	
	# Visual/audio telegraph effects would go here
	create_telegraph_effect(attack)
	
	# Execute attack after telegraph
	var telegraph_timer = get_tree().create_timer(telegraph_duration)
	telegraph_timer.timeout.connect(func(): perform_attack(attack))

func create_telegraph_effect(attack: AttackType):
	# Visual indicators for incoming attacks
	match attack:
		AttackType.SHADOW_BARRIER:
			print("Dark energy swirls around Khaemwaset...")
		AttackType.SUMMON_SHADES:
			print("Shadow portals begin to open...")
		AttackType.DARK_PROJECTILES:
			print("Dark magic charges in Khaemwaset's hands...")
		AttackType.SHADOW_WAVE:
			print("The ground trembles with dark power...")
		AttackType.CORRUPTION_BLAST:
			print("Corruption energy builds to critical levels...")
		AttackType.DESPERATE_TORNADO:
			print("The air itself begins to swirl with malice...")
		AttackType.MASS_SHADOW_STRIKE:
			print("Multiple shadow rifts tear through reality...")

func perform_attack(attack: AttackType):
	is_telegraphing = false
	
	match attack:
		AttackType.SHADOW_BARRIER:
			cast_shadow_barrier()
		AttackType.SUMMON_SHADES:
			summon_shade_minions()
		AttackType.DARK_PROJECTILES:
			launch_dark_projectiles()
		AttackType.SHADOW_WAVE:
			cast_shadow_wave()
		AttackType.CORRUPTION_BLAST:
			cast_corruption_blast()
		AttackType.DESPERATE_TORNADO:
			cast_desperate_tornado()
		AttackType.MASS_SHADOW_STRIKE:
			cast_mass_shadow_strike()

# PHASE 1 ATTACKS - Defensive Magic

func cast_shadow_barrier():
	print("Khaemwaset casts Shadow Barrier!")
	
	# Create protective barriers around boss
	var barrier_count = 4
	for i in barrier_count:
		var angle = (i * TAU) / barrier_count
		var barrier_pos = global_position + Vector3(cos(angle), 1.0, sin(angle)) * 3.0
		create_shadow_barrier(barrier_pos)
	
	# Temporary damage reduction
	set_meta("damage_reduction", 0.5)
	var barrier_timer = get_tree().create_timer(8.0)
	barrier_timer.timeout.connect(remove_shadow_barriers)

func create_shadow_barrier(position: Vector3):
	# Create barrier visual effect (placeholder - would be actual 3D mesh)
	print("Shadow barrier created at: ", position)
	# This would create an actual 3D object with collision

func remove_shadow_barriers():
	remove_meta("damage_reduction")
	print("Shadow barriers dispelled!")

func summon_shade_minions():
	print("Khaemwaset summons Shade minions!")
	
	var shade_count = 2 + (current_phase - 1)  # More shades in later phases
	
	for i in shade_count:
		var spawn_angle = randf() * TAU
		var spawn_distance = randf_range(5.0, 10.0)
		var spawn_pos = arena_center + Vector3(cos(spawn_angle), 0.2, sin(spawn_angle)) * spawn_distance
		
		summon_shade_at_position(spawn_pos)

func summon_shade_at_position(position: Vector3):
	# This would instantiate actual Shade enemy
	print("Shade summoned at: ", position)
	# For now, just print - actual implementation would create Shade enemy

func launch_dark_projectiles():
	print("Khaemwaset launches Dark Projectiles!")
	
	if not player:
		return
	
	var projectile_count = 3 + current_phase
	var spread_angle = 45.0
	
	for i in projectile_count:
		var angle_offset = (i - projectile_count / 2.0) * (spread_angle / projectile_count)
		var base_direction = (player.global_position - global_position).normalized()
		
		# Rotate direction by offset
		var rotated_direction = base_direction.rotated(Vector3.UP, deg_to_rad(angle_offset))
		
		launch_dark_projectile(rotated_direction)

func launch_dark_projectile(direction: Vector3):
	var projectile_speed = 12.0
	var projectile_damage = 35.0
	
	print("Dark projectile launched in direction: ", direction)
	# This would create actual projectile with physics

# PHASE 2 ATTACKS - Aggressive Revelation

func cast_shadow_wave():
	print("Khaemwaset casts Shadow Wave!")
	
	# Expanding ring of dark energy from boss
	var wave_speed = 8.0
	var wave_damage = 45.0
	var max_radius = 12.0
	
	create_expanding_shadow_wave(global_position, wave_speed, max_radius, wave_damage)

func create_expanding_shadow_wave(origin: Vector3, speed: float, max_radius: float, damage: float):
	print("Shadow wave expanding from: ", origin)
	# This would create expanding collision shape that damages player

func cast_corruption_blast():
	print("Khaemwaset casts Corruption Blast!")
	
	if not player:
		return
	
	var blast_center = player.global_position
	var blast_radius = 4.0
	var blast_damage = 55.0
	
	# Delayed explosion at player location
	var delay_timer = get_tree().create_timer(1.0)
	delay_timer.timeout.connect(func(): explode_corruption_blast(blast_center, blast_radius, blast_damage))
	
	print("Corruption blast targeting: ", blast_center)

func explode_corruption_blast(center: Vector3, radius: float, damage: float):
	print("Corruption blast explodes at: ", center, " radius: ", radius)
	
	# Check if player is in blast radius
	if player and player.global_position.distance_to(center) <= radius:
		if player.has_method("take_damage"):
			player.take_damage(damage)
		
		# Apply corruption status effect
		var status_system = get_tree().get_first_node_in_group("status_system")
		if status_system:
			status_system.apply_status_effect(player, 1, 5.0, 1.0, self)  # Burn effect

# PHASE 3 ATTACKS - Desperate Measures  

func cast_desperate_tornado():
	print("Khaemwaset casts Desperate Tornado!")
	
	var tornado_duration = 6.0
	var tornado_damage_per_second = 25.0
	
	# Create moving tornado that follows player
	create_shadow_tornado(tornado_duration, tornado_damage_per_second)

func create_shadow_tornado(duration: float, dps: float):
	print("Shadow tornado active for ", duration, " seconds")
	# This would create moving hazard that follows player

func cast_mass_shadow_strike():
	print("Khaemwaset casts Mass Shadow Strike!")
	
	var strike_count = 8
	var strike_damage = 40.0
	
	for i in strike_count:
		var delay = i * 0.3  # Staggered strikes
		var strike_timer = get_tree().create_timer(delay)
		strike_timer.timeout.connect(func(): shadow_strike_random_location(strike_damage))

func shadow_strike_random_location(damage: float):
	var random_angle = randf() * TAU
	var random_distance = randf_range(3.0, boss_arena_radius - 2.0)
	var strike_pos = arena_center + Vector3(cos(random_angle), 0, sin(random_angle)) * random_distance
	
	print("Shadow strike at: ", strike_pos)
	
	# Check if player is near strike location
	if player and player.global_position.distance_to(strike_pos) <= 2.0:
		if player.has_method("take_damage"):
			player.take_damage(damage)

# PHASE TRANSITION SYSTEM

func check_phase_transitions():
	if is_transitioning:
		return
	
	match current_phase:
		BossPhase.PHASE_1_DEFENSIVE:
			if current_health <= phase_1_threshold:
				transition_to_phase(BossPhase.PHASE_2_REVELATION)
		BossPhase.PHASE_2_REVELATION:
			if current_health <= phase_2_threshold:
				transition_to_phase(BossPhase.PHASE_3_DESPERATION)
		BossPhase.PHASE_3_DESPERATION:
			if current_health <= 0:
				boss_death()

func transition_to_phase(new_phase: BossPhase):
	is_transitioning = true
	current_phase = new_phase
	
	boss_phase_changed.emit(new_phase)
	
	match new_phase:
		BossPhase.PHASE_2_REVELATION:
			start_phase_2_revelation()
		BossPhase.PHASE_3_DESPERATION:
			start_phase_3_desperation()
	
	# End transition after duration
	var transition_timer = get_tree().create_timer(phase_transition_duration)
	transition_timer.timeout.connect(func(): is_transitioning = false)

func start_phase_2_revelation():
	print("=== PHASE 2: REVELATION ===")
	print("HP: ", current_health, "/", max_health)
	
	# Trigger conspiracy dialogue
	dialogue_index = 0
	reveal_conspiracy_dialogue()
	
	# Visual transformation
	print("Khaemwaset's corruption becomes more visible...")

func start_phase_3_desperation():
	print("=== PHASE 3: DESPERATION ===") 
	print("HP: ", current_health, "/", max_health)
	
	# More conspiracy reveals
	dialogue_index = 0  
	reveal_final_conspiracy_dialogue()
	
	# Shadow transformation
	print("Khaemwaset partially transforms into shadow...")
	movement_speed *= 1.5  # Faster in final phase

func reveal_conspiracy_dialogue():
	var dialogues = conspiracy_dialogues[current_phase]
	if dialogue_index < dialogues.size():
		var dialogue = dialogues[dialogue_index]
		conspiracy_revelation.emit(dialogue)
		print("CONSPIRACY REVEAL: ", dialogue)
		dialogue_index += 1
		
		# Continue revealing over time
		if dialogue_index < dialogues.size():
			var next_dialogue_timer = get_tree().create_timer(2.0)
			next_dialogue_timer.timeout.connect(reveal_conspiracy_dialogue)

func reveal_final_conspiracy_dialogue():
	var dialogues = conspiracy_dialogues[BossPhase.PHASE_3_DESPERATION]
	if dialogue_index < dialogues.size():
		var dialogue = dialogues[dialogue_index]
		conspiracy_revelation.emit(dialogue)
		print("FINAL REVELATION: ", dialogue)
		dialogue_index += 1
		
		if dialogue_index < dialogues.size():
			var next_dialogue_timer = get_tree().create_timer(2.5)
			next_dialogue_timer.timeout.connect(reveal_final_conspiracy_dialogue)

# DAMAGE AND DEATH SYSTEM

func take_damage(damage: float, attacker: Node3D = null):
	# Apply damage reduction if barrier is active
	var reduction = get_meta("damage_reduction", 0.0)
	var final_damage = damage * (1.0 - reduction)
	
	current_health -= final_damage
	current_health = max(current_health, 0.0)
	
	print("Khaemwaset takes ", final_damage, " damage! HP: ", current_health, "/", max_health)
	
	# Trigger phase transitions or death
	if current_health <= 0:
		boss_death()

func boss_death():
	print("=== KHAEMWASET DEFEATED ===")
	
	# Final revelation
	conspiracy_revelation.emit("The Temple of Eternity... find it... Set's power grows...")
	
	boss_defeated.emit()
	
	# Cleanup and reward
	cleanup_boss_effects()
	grant_victory_rewards()
	
	# Remove boss from scene
	queue_free()

func cleanup_boss_effects():
	# Clean up any active boss effects
	for barrier in active_barriers:
		if is_instance_valid(barrier):
			barrier.queue_free()
	active_barriers.clear()
	
	for shade in shade_spawns:
		if is_instance_valid(shade):
			shade.queue_free()
	shade_spawns.clear()

func grant_victory_rewards():
	print("Boss victory rewards granted!")
	# This would integrate with reward systems

# UTILITY FUNCTIONS

func get_attack_name(attack: AttackType) -> String:
	match attack:
		AttackType.SHADOW_BARRIER:
			return "Shadow Barrier"
		AttackType.SUMMON_SHADES:
			return "Summon Shades"
		AttackType.DARK_PROJECTILES:
			return "Dark Projectiles"
		AttackType.SHADOW_WAVE:
			return "Shadow Wave"
		AttackType.CORRUPTION_BLAST:
			return "Corruption Blast"
		AttackType.DESPERATE_TORNADO:
			return "Desperate Tornado"
		AttackType.MASS_SHADOW_STRIKE:
			return "Mass Shadow Strike"
		_:
			return "Unknown Attack"

func get_health_percentage() -> float:
	return current_health / max_health

func is_alive() -> bool:
	return current_health > 0

# Public API for boss encounter management
func get_boss_info() -> Dictionary:
	return {
		"name": "Khaemwaset",
		"title": "Corrupted High Priest",
		"current_phase": current_phase,
		"health": current_health,
		"max_health": max_health,
		"health_percentage": get_health_percentage(),
		"is_transitioning": is_transitioning,
		"is_alive": is_alive()
	}