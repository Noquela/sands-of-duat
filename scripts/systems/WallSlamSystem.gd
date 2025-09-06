extends Node
class_name WallSlamSystem

signal wall_slam_performed(attacker: Node3D, victim: Node3D, damage: float)
signal wall_slam_missed(attacker: Node3D, target_position: Vector3)

@export_group("Wall Slam Settings")
@export var slam_range: float = 2.0
@export var slam_force: float = 15.0
@export var base_slam_damage: float = 25.0
@export var wall_detection_distance: float = 1.5
@export var slam_cooldown: float = 3.0

@export_group("Damage Scaling")
@export var damage_per_velocity: float = 2.0  # Extra damage based on impact speed
@export var max_velocity_damage: float = 50.0
@export var crit_chance: float = 20.0  # Chance for critical wall slam
@export var crit_multiplier: float = 2.5

@export_group("Visual Effects")
@export var screen_shake_intensity: float = 0.3
@export var screen_shake_duration: float = 0.2
@export var particle_count: int = 20

# System state
var slam_cooldowns: Dictionary = {} # entity -> time remaining
var active_slams: Dictionary = {} # entity -> slam data

# References  
var player: Node3D
var status_system: Node

func _ready():
	setup_wall_slam_system()
	find_system_references()

func _process(delta):
	update_cooldowns(delta)
	update_active_slams(delta)

func setup_wall_slam_system():
	add_to_group("wall_slam_system")
	print("Wall Slam System initialized")

func find_system_references():
	player = get_tree().get_first_node_in_group("player")
	status_system = get_tree().get_first_node_in_group("status_system")

func update_cooldowns(delta: float):
	var entities_to_remove = []
	for entity in slam_cooldowns:
		slam_cooldowns[entity] -= delta
		if slam_cooldowns[entity] <= 0.0:
			entities_to_remove.append(entity)
	
	for entity in entities_to_remove:
		slam_cooldowns.erase(entity)

func update_active_slams(delta: float):
	var slams_to_complete = []
	
	for entity in active_slams:
		var slam_data = active_slams[entity]
		slam_data.elapsed_time += delta
		
		# Update position during slam
		var progress = slam_data.elapsed_time / slam_data.duration
		if progress < 1.0:
			var current_pos = slam_data.start_position.lerp(slam_data.target_position, progress)
			entity.global_position = current_pos
		else:
			# Slam completed
			slams_to_complete.append(entity)
	
	# Process completed slams
	for entity in slams_to_complete:
		complete_wall_slam(entity, active_slams[entity])
		active_slams.erase(entity)

# Main wall slam function
func attempt_wall_slam(attacker: Node3D, target: Node3D, slam_direction: Vector3 = Vector3.ZERO) -> bool:
	if not can_perform_slam(attacker):
		return false
	
	if not target or not target.is_valid():
		return false
	
	# Determine slam direction
	if slam_direction == Vector3.ZERO:
		slam_direction = (target.global_position - attacker.global_position).normalized()
	
	# Find wall in slam direction
	var wall_info = find_wall_in_direction(target, slam_direction)
	if not wall_info.has_wall:
		# Miss - target not near a wall
		wall_slam_missed.emit(attacker, target.global_position + slam_direction * slam_range)
		return false
	
	# Start the slam motion
	start_wall_slam(attacker, target, wall_info)
	
	# Set cooldown
	slam_cooldowns[attacker] = slam_cooldown
	
	return true

func can_perform_slam(entity: Node3D) -> bool:
	if not entity or not entity.is_valid():
		return false
	
	# Check cooldown
	if entity in slam_cooldowns:
		return false
	
	# Check if already slamming
	if entity in active_slams:
		return false
	
	return true

func find_wall_in_direction(origin: Node3D, direction: Vector3) -> Dictionary:
	var space_state = origin.get_world_3d().direct_space_state
	
	# Cast ray to find wall
	var query = PhysicsRayQueryParameters3D.create(
		origin.global_position,
		origin.global_position + direction * (slam_range + wall_detection_distance)
	)
	query.collision_mask = 4  # Environment layer
	query.collide_with_areas = false
	
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		return {"has_wall": false}
	
	# Check if collision point is close enough to be a "wall slam"
	var distance_to_wall = origin.global_position.distance_to(result.position)
	if distance_to_wall > slam_range:
		return {"has_wall": false}
	
	return {
		"has_wall": true,
		"wall_position": result.position,
		"wall_normal": result.normal,
		"wall_body": result.collider,
		"distance": distance_to_wall
	}

func start_wall_slam(attacker: Node3D, target: Node3D, wall_info: Dictionary):
	var slam_duration = 0.3  # Fast slam motion
	var impact_velocity = slam_force
	
	# Calculate slam trajectory
	var start_pos = target.global_position
	var slam_direction = (wall_info.wall_position - start_pos).normalized()
	var target_pos = wall_info.wall_position - wall_info.wall_normal * 0.5  # Slightly away from wall
	
	# Create slam data
	var slam_data = {
		"attacker": attacker,
		"target": target,
		"start_position": start_pos,
		"target_position": target_pos,
		"wall_info": wall_info,
		"duration": slam_duration,
		"elapsed_time": 0.0,
		"impact_velocity": impact_velocity,
		"slam_direction": slam_direction
	}
	
	active_slams[attacker] = slam_data
	
	# Disable target's movement temporarily
	if target.has_method("set_movement_disabled"):
		target.set_movement_disabled(true)
	
	print(attacker.name, " wall slams ", target.name)

func complete_wall_slam(attacker: Node3D, slam_data: Dictionary):
	var target = slam_data.target
	var wall_info = slam_data.wall_info
	
	# Re-enable target movement
	if target.has_method("set_movement_disabled"):
		target.set_movement_disabled(false)
	
	# Calculate damage
	var damage = calculate_slam_damage(slam_data)
	
	# Apply damage
	if target.has_method("take_damage"):
		target.take_damage(damage, attacker)
	elif target.has_method("apply_damage"):
		target.apply_damage(damage)
	
	# Apply status effects
	apply_slam_status_effects(target, slam_data)
	
	# Visual and audio effects
	create_slam_effects(slam_data)
	
	# Emit signal
	wall_slam_performed.emit(attacker, target, damage)
	
	print(target.name, " slammed into wall for ", damage, " damage!")

func calculate_slam_damage(slam_data: Dictionary) -> float:
	var base_damage = base_slam_damage
	
	# Velocity-based damage
	var velocity_damage = slam_data.impact_velocity * damage_per_velocity
	velocity_damage = min(velocity_damage, max_velocity_damage)
	
	# Total damage
	var total_damage = base_damage + velocity_damage
	
	# Critical hit check
	if randf() * 100 < crit_chance:
		total_damage *= crit_multiplier
		print("CRITICAL WALL SLAM!")
	
	# Apply attacker's damage modifiers
	var attacker = slam_data.attacker
	if attacker and attacker.has_meta("damage_bonus"):
		var bonus = attacker.get_meta("damage_bonus", 0.0)
		total_damage += bonus
	
	# Check for boon effects
	if attacker and attacker.has_meta("wall_slam_damage_multiplier"):
		var multiplier = attacker.get_meta("wall_slam_damage_multiplier", 1.0)
		total_damage *= multiplier
	
	return total_damage

func apply_slam_status_effects(target: Node3D, slam_data: Dictionary):
	if not status_system:
		return
	
	# Always apply stun from wall impact
	var stun_duration = 1.5
	if target.has_method("apply_stun"):
		target.apply_stun(stun_duration)
	
	# Apply Vulnerable status (takes more damage)
	if status_system.has_method("apply_status_effect"):
		status_system.apply_status_effect(target, 8, 8.0, 1.0, slam_data.attacker)  # 8 = VULNERABLE enum value
	
	# Chance for additional effects based on wall material/boons
	var attacker = slam_data.attacker
	if attacker and attacker.has_meta("wall_slam_burn_chance"):
		var burn_chance = attacker.get_meta("wall_slam_burn_chance", 0.0)
		if randf() * 100 < burn_chance:
			status_system.apply_status_effect(target, 1, 6.0, 1.0, attacker)  # 1 = BURN enum value
	
	if attacker and attacker.has_meta("wall_slam_shock_chance"):
		var shock_chance = attacker.get_meta("wall_slam_shock_chance", 0.0)
		if randf() * 100 < shock_chance:
			status_system.apply_status_effect(target, 3, 5.0, 1.0, attacker)  # 3 = SHOCK enum value

func create_slam_effects(slam_data: Dictionary):
	var impact_position = slam_data.target_position
	var wall_normal = slam_data.wall_info.wall_normal
	
	# Screen shake (if player is involved)
	if slam_data.target == player or slam_data.attacker == player:
		create_screen_shake()
	
	# Particle effects
	create_impact_particles(impact_position, wall_normal)
	
	# Sound effect (would need AudioManager)
	# AudioManager.play_sound("wall_slam_impact", impact_position)

func create_screen_shake():
	# This would integrate with a camera shake system
	if player and player.has_method("add_screen_shake"):
		player.add_screen_shake(screen_shake_intensity, screen_shake_duration)
	
	# Alternative: directly shake camera
	var camera = get_tree().get_first_node_in_group("camera")
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(screen_shake_intensity)

func create_impact_particles(position: Vector3, normal: Vector3):
	# Create dust/debris particles
	var particles = CPUParticles3D.new()
	get_tree().current_scene.add_child(particles)
	particles.global_position = position
	
	# Configure particle system
	particles.emitting = false
	particles.amount = particle_count
	particles.lifetime = 2.0
	particles.one_shot = true
	
	# Set emission shape
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 0.5
	
	# Set particle properties
	particles.initial_velocity_min = 2.0
	particles.initial_velocity_max = 8.0
	particles.gravity = Vector3(0, -9.8, 0)
	particles.scale_amount_min = 0.1
	particles.scale_amount_max = 0.3
	
	# Set color (dust/stone color)
	particles.color = Color(0.8, 0.7, 0.5, 1.0)
	
	# Direction away from wall
	particles.direction = normal
	particles.spread = 45.0
	
	# Start emission
	particles.emitting = true
	
	# Clean up after particles finish
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = particles.lifetime + 1.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(func(): particles.queue_free(); cleanup_timer.queue_free())
	add_child(cleanup_timer)
	cleanup_timer.start()

# Player-specific slam abilities
func player_wall_slam_ability() -> bool:
	if not player:
		return false
	
	# Find nearest enemy in front of player
	var target = find_slam_target_for_player()
	if not target:
		print("No wall slam target found")
		return false
	
	# Perform slam
	return attempt_wall_slam(player, target)

func find_slam_target_for_player() -> Node3D:
	if not player:
		return null
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	var player_pos = player.global_position
	var best_target = null
	var closest_distance = slam_range + 1.0
	
	for enemy in enemies:
		if not enemy.is_valid():
			continue
		
		var distance = player_pos.distance_to(enemy.global_position)
		if distance <= slam_range and distance < closest_distance:
			# Check if there's a wall behind the enemy
			var direction = (enemy.global_position - player_pos).normalized()
			var wall_info = find_wall_in_direction(enemy, direction)
			if wall_info.has_wall:
				best_target = enemy
				closest_distance = distance
	
	return best_target

# Enemy AI integration
func try_enemy_wall_slam(enemy: Node3D, target: Node3D) -> bool:
	# Check if enemy has wall slam capability
	if not enemy.has_meta("can_wall_slam"):
		return false
	
	# Check if conditions are right for wall slam
	var distance = enemy.global_position.distance_to(target.global_position)
	if distance > slam_range:
		return false
	
	# Attempt slam
	return attempt_wall_slam(enemy, target)

# Boon system integration
func apply_wall_slam_boon_effects(entity: Node3D):
	# These would be set by the boon system
	# Example boon effects:
	
	# "Slamming Force" - Increased wall slam damage
	if entity.has_meta("wall_slam_damage_bonus"):
		var bonus = entity.get_meta("wall_slam_damage_bonus", 0.0)
		entity.set_meta("wall_slam_damage_multiplier", 1.0 + (bonus / 100.0))
	
	# "Crushing Blow" - Wall slams apply burn
	if entity.has_meta("wall_slam_applies_burn"):
		entity.set_meta("wall_slam_burn_chance", 100.0)
	
	# "Thunder Slam" - Wall slams apply shock
	if entity.has_meta("wall_slam_applies_shock"):
		entity.set_meta("wall_slam_shock_chance", 75.0)
	
	# "Swift Slam" - Reduced cooldown
	if entity.has_meta("wall_slam_cooldown_reduction"):
		var reduction = entity.get_meta("wall_slam_cooldown_reduction", 0.0)
		entity.set_meta("wall_slam_cooldown_multiplier", 1.0 - (reduction / 100.0))

# Public API
func get_slam_cooldown_remaining(entity: Node3D) -> float:
	return slam_cooldowns.get(entity, 0.0)

func is_performing_slam(entity: Node3D) -> bool:
	return entity in active_slams

func get_active_slams() -> Array:
	return active_slams.values()

func force_complete_slam(entity: Node3D) -> bool:
	if entity in active_slams:
		complete_wall_slam(entity, active_slams[entity])
		active_slams.erase(entity)
		return true
	return false

func get_system_info() -> Dictionary:
	return {
		"active_slams": active_slams.size(),
		"entities_on_cooldown": slam_cooldowns.size(),
		"base_damage": base_slam_damage,
		"slam_range": slam_range
	}