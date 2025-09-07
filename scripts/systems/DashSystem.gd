# DashSystem.gd
# Dash System for Sands of Duat
# Sprint 4: Fast movement ability with stamina management
# Inspired by Hades dash mechanics with Egyptian flavor

extends Node

signal dash_started(direction: Vector3)
signal dash_ended
signal stamina_changed(current: float, max_float: float)
signal dash_attack_performed(damage: int)

# Dash settings from roadmap
const DASH_DISTANCE = 4.0
const DASH_SPEED = 20.0
const DASH_DURATION = 0.2
const STAMINA_COST = 25.0
const MAX_STAMINA = 100.0
const STAMINA_REGEN_RATE = 40.0  # Per second
const DASH_COOLDOWN = 0.1
const INVULNERABILITY_DURATION = 0.15  # Brief invulnerability during dash

# Dash attack settings
const DASH_ATTACK_DAMAGE = 35
const DASH_ATTACK_RANGE = 2.5

# Current state
var current_stamina: float = MAX_STAMINA
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector3 = Vector3.ZERO
var dash_start_position: Vector3 = Vector3.ZERO
var dash_target_position: Vector3 = Vector3.ZERO
var cooldown_timer: float = 0.0

# References
var player: CharacterBody3D
var combat_system: Node

func _ready():
	print("🏃 Dash System: Sprint 4 Initialized")
	print("   Dash Distance: %.1f units" % DASH_DISTANCE)
	print("   Dash Speed: %.1f units/s" % DASH_SPEED)
	print("   Stamina Cost: %.1f" % STAMINA_COST)
	print("   Max Stamina: %.1f" % MAX_STAMINA)
	
	# Get references
	combat_system = get_node("/root/CombatSystem")

func _process(delta):
	# Handle dash duration
	if is_dashing:
		dash_timer += delta
		if dash_timer >= DASH_DURATION:
			_end_dash()
	
	# Handle cooldown
	if cooldown_timer > 0:
		cooldown_timer -= delta
	
	# Regenerate stamina
	if not is_dashing and current_stamina < MAX_STAMINA:
		var old_stamina = current_stamina
		current_stamina = min(MAX_STAMINA, current_stamina + STAMINA_REGEN_RATE * delta)
		if current_stamina != old_stamina:
			stamina_changed.emit(current_stamina, MAX_STAMINA)

# Main dash function called by player
func attempt_dash(dash_player: CharacterBody3D, input_direction: Vector2) -> bool:
	if not can_dash():
		return false
	
	player = dash_player
	
	# Convert 2D input to 3D world direction
	var world_direction = Vector3(input_direction.x, 0, input_direction.y).normalized()
	
	# If no input, dash forward (player's facing direction)
	if world_direction.length() < 0.1:
		world_direction = -player.transform.basis.z
	
	return _perform_dash(world_direction)

func can_dash() -> bool:
	return (not is_dashing and 
			cooldown_timer <= 0 and 
			current_stamina >= STAMINA_COST)

func _perform_dash(direction: Vector3) -> bool:
	if not player:
		return false
	
	print("🏃 Khenti dashes! Direction: " + str(direction))
	
	# Consume stamina
	current_stamina = max(0, current_stamina - STAMINA_COST)
	stamina_changed.emit(current_stamina, MAX_STAMINA)
	
	# Set dash state
	is_dashing = true
	dash_timer = 0.0
	dash_direction = direction
	dash_start_position = player.global_position
	dash_target_position = dash_start_position + (direction * DASH_DISTANCE)
	cooldown_timer = DASH_COOLDOWN
	
	# Make player invulnerable during dash
	if player.has_method("set_invulnerable"):
		player.set_invulnerable(INVULNERABILITY_DURATION)
	
	# Check for dash attack (enemies in path)
	_check_dash_attack()
	
	# Emit signals
	dash_started.emit(direction)
	
	# Create dash effect
	_create_dash_effect()
	
	return true

func _end_dash():
	is_dashing = false
	dash_timer = 0.0
	dash_direction = Vector3.ZERO
	
	print("🏃 Dash completed")
	dash_ended.emit()

# Get dash velocity for player movement
func get_dash_velocity() -> Vector3:
	if not is_dashing:
		return Vector3.ZERO
	
	# Calculate progress (0 to 1)
	var progress = dash_timer / DASH_DURATION
	
	# Use ease-out curve for smooth deceleration
	var ease_progress = 1.0 - pow(1.0 - progress, 3.0)
	
	# Calculate current position along dash path
	var current_pos = dash_start_position.lerp(dash_target_position, ease_progress)
	var target_velocity = (current_pos - player.global_position) / get_physics_process_delta_time()
	
	return target_velocity

# Dash attack mechanics
func _check_dash_attack():
	if not combat_system:
		return
	
	# Find enemies in dash path
	var enemies_in_path = _find_enemies_in_dash_path()
	
	for enemy in enemies_in_path:
		if enemy.has_method("take_damage"):
			enemy.take_damage(DASH_ATTACK_DAMAGE, "dash")
			print("💨⚔️ Dash Attack! %d damage to %s" % [DASH_ATTACK_DAMAGE, enemy.name])
			dash_attack_performed.emit(DASH_ATTACK_DAMAGE)

func _find_enemies_in_dash_path() -> Array[Node3D]:
	var enemies_hit: Array[Node3D] = []
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if not enemy is Node3D:
			continue
		
		# Check if enemy is close to dash path
		var distance_to_path = _point_to_line_distance(
			enemy.global_position, 
			dash_start_position, 
			dash_target_position
		)
		
		if distance_to_path <= DASH_ATTACK_RANGE:
			enemies_hit.append(enemy)
			print("🎯 Enemy in dash path: " + enemy.name)
	
	return enemies_hit

# Calculate distance from point to line segment
func _point_to_line_distance(point: Vector3, line_start: Vector3, line_end: Vector3) -> float:
	var line_vec = line_end - line_start
	var point_vec = point - line_start
	
	# Project point onto line
	var line_length_sq = line_vec.length_squared()
	if line_length_sq == 0:
		return point_vec.length()
	
	var t = point_vec.dot(line_vec) / line_length_sq
	t = clamp(t, 0.0, 1.0)
	
	var projection = line_start + t * line_vec
	return point.distance_to(projection)

func _create_dash_effect():
	# Create visual dash effect
	var effect_scene = preload("res://scenes/effects/DashTrail.tscn")
	if effect_scene:
		var effect = effect_scene.instantiate()
		get_tree().current_scene.add_child(effect)
		effect.global_position = player.global_position
		effect.setup_trail(dash_start_position, dash_target_position, DASH_DURATION)
		print("💨 Dash trail effect created")

# Stamina management
func get_stamina() -> float:
	return current_stamina

func get_max_stamina() -> float:
	return MAX_STAMINA

func get_stamina_percentage() -> float:
	return current_stamina / MAX_STAMINA

func set_stamina(amount: float):
	current_stamina = clamp(amount, 0.0, MAX_STAMINA)
	stamina_changed.emit(current_stamina, MAX_STAMINA)

func restore_stamina(amount: float):
	set_stamina(current_stamina + amount)
	print("💙 Stamina restored: +%.1f" % amount)

# Get system stats for UI and debug
func get_dash_stats() -> Dictionary:
	return {
		"is_dashing": is_dashing,
		"can_dash": can_dash(),
		"current_stamina": current_stamina,
		"max_stamina": MAX_STAMINA,
		"stamina_percentage": get_stamina_percentage(),
		"cooldown_remaining": cooldown_timer,
		"dash_progress": dash_timer / DASH_DURATION if is_dashing else 0.0
	}

# Reset system state
func reset_dash():
	is_dashing = false
	dash_timer = 0.0
	cooldown_timer = 0.0
	current_stamina = MAX_STAMINA
	stamina_changed.emit(current_stamina, MAX_STAMINA)
	print("🏃 Dash system reset")