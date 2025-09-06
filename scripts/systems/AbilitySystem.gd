extends Node3D
class_name AbilitySystem

signal ability_used(ability_name: String)
signal ability_cooldown_started(ability_name: String, duration: float)
signal ability_cooldown_finished(ability_name: String)
signal mana_changed(current_mana: float, max_mana: float)

enum AbilityType {
	AREA_SLAM,
	PROJECTILE_SHOT,
	SHIELD_BLOCK,
	WALL_SLAM
}

@export_group("Mana System")
@export var max_mana: float = 100.0
@export var mana_regeneration_rate: float = 10.0
@export var ability_mana_costs = {
	AbilityType.AREA_SLAM: 30.0,
	AbilityType.PROJECTILE_SHOT: 20.0,
	AbilityType.SHIELD_BLOCK: 25.0,
	AbilityType.WALL_SLAM: 35.0
}

@export_group("Cooldowns")
@export var ability_cooldowns = {
	AbilityType.AREA_SLAM: 5.0,
	AbilityType.PROJECTILE_SHOT: 3.0,
	AbilityType.SHIELD_BLOCK: 4.0,
	AbilityType.WALL_SLAM: 6.0
}

# Current state
var current_mana: float
var cooldown_timers = {}
var abilities_available = {}

# References
var player: CharacterBody3D
var combat_system

# Ability prefabs/scenes (placeholder - scenes will be created later)
# var area_slam_effect_scene = preload("res://scenes/abilities/AreaSlamEffect.tscn")
# var projectile_scene = preload("res://scenes/abilities/MagicProjectile.tscn")

func _ready():
	# Initialize systems
	setup_ability_system()
	
	# Start with full mana
	current_mana = max_mana
	
	# Initialize availability
	for ability in AbilityType.values():
		abilities_available[ability] = true
		cooldown_timers[ability] = 0.0

func setup_ability_system():
	# Get player reference
	player = get_parent()
	if not player or not player is CharacterBody3D:
		push_error("AbilitySystem must be child of CharacterBody3D (Player)")
		return
	
	# Get combat system reference
	combat_system = player.get_node_or_null("CombatSystem")
	if not combat_system:
		push_warning("CombatSystem not found - some abilities may not work")

func _process(delta):
	update_mana_regeneration(delta)
	update_cooldowns(delta)
	handle_ability_inputs()

func update_mana_regeneration(delta):
	if current_mana < max_mana:
		current_mana = min(current_mana + mana_regeneration_rate * delta, max_mana)
		mana_changed.emit(current_mana, max_mana)

func update_cooldowns(delta):
	for ability in cooldown_timers.keys():
		if cooldown_timers[ability] > 0:
			cooldown_timers[ability] -= delta
			if cooldown_timers[ability] <= 0:
				abilities_available[ability] = true
				ability_cooldown_finished.emit(get_ability_name(ability))

func handle_ability_inputs():
	# Area Slam - Q key
	if Input.is_action_just_pressed("ability_area_slam"):
		use_ability(AbilityType.AREA_SLAM)
	
	# Projectile Shot - E key  
	elif Input.is_action_just_pressed("ability_projectile"):
		use_ability(AbilityType.PROJECTILE_SHOT)
	
	# Shield Block - R key
	elif Input.is_action_just_pressed("ability_shield"):
		use_ability(AbilityType.SHIELD_BLOCK)
	
	# Wall Slam - F key
	elif Input.is_action_just_pressed("ability_wall_slam"):
		use_ability(AbilityType.WALL_SLAM)

func use_ability(ability_type: AbilityType) -> bool:
	# Check if ability is available
	if not can_use_ability(ability_type):
		return false
	
	# Consume mana
	var mana_cost = ability_mana_costs.get(ability_type, 0.0)
	current_mana -= mana_cost
	mana_changed.emit(current_mana, max_mana)
	
	# Start cooldown
	start_cooldown(ability_type)
	
	# Execute specific ability
	match ability_type:
		AbilityType.AREA_SLAM:
			perform_area_slam()
		AbilityType.PROJECTILE_SHOT:
			perform_projectile_shot()
		AbilityType.SHIELD_BLOCK:
			perform_shield_block()
		AbilityType.WALL_SLAM:
			perform_wall_slam()
	
	# Emit signal
	ability_used.emit(get_ability_name(ability_type))
	
	return true

func can_use_ability(ability_type: AbilityType) -> bool:
	var mana_cost = ability_mana_costs.get(ability_type, 0.0)
	return abilities_available.get(ability_type, false) and current_mana >= mana_cost

func start_cooldown(ability_type: AbilityType):
	var cooldown_duration = ability_cooldowns.get(ability_type, 1.0)
	cooldown_timers[ability_type] = cooldown_duration
	abilities_available[ability_type] = false
	ability_cooldown_started.emit(get_ability_name(ability_type), cooldown_duration)

func perform_area_slam():
	print("Area Slam activated!")
	
	# Get all enemies in range
	var slam_radius = 8.0
	var slam_damage = 50.0
	var slam_position = player.global_position
	
	# Find enemies in range
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_enemies = []
	
	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = slam_position.distance_to(enemy.global_position)
			if distance <= slam_radius:
				hit_enemies.append(enemy)
	
	# Deal damage to enemies
	for enemy in hit_enemies:
		if enemy.has_method("take_damage"):
			enemy.take_damage(slam_damage)
			print("Area Slam hit ", enemy.name, " for ", slam_damage, " damage")
	
	# Create visual effect (placeholder)
	create_area_slam_effect(slam_position, slam_radius)

func perform_projectile_shot():
	print("Projectile Shot activated!")
	
	# Get mouse position for targeting
	var viewport = get_viewport()
	var camera = viewport.get_camera_3d()
	var mouse_pos = viewport.get_mouse_position()
	
	if not camera:
		print("No camera found for projectile targeting")
		return
	
	# Cast ray from camera through mouse position
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	
	# Find intersection with ground plane (Y = player.position.y)
	var player_y = player.global_position.y
	var t = (player_y - ray_origin.y) / ray_direction.y
	var target_position = ray_origin + ray_direction * t
	
	# Launch projectile
	launch_projectile(player.global_position, target_position)

func perform_shield_block():
	print("Shield Block activated!")
	
	# Create temporary shield buff
	var shield_duration = 2.0
	var shield_reduction = 0.75  # 75% damage reduction
	
	# Apply shield effect to player
	apply_shield_effect(shield_duration, shield_reduction)

func perform_wall_slam():
	print("Wall Slam activated!")
	
	# Get wall slam system reference
	var wall_slam_system = get_tree().get_first_node_in_group("wall_slam_system")
	if not wall_slam_system:
		print("Wall Slam System not found!")
		return
	
	# Use the wall slam system to find and slam a target
	var success = wall_slam_system.player_wall_slam_ability()
	if not success:
		print("Wall Slam failed - no valid target near walls")

func launch_projectile(start_pos: Vector3, target_pos: Vector3):
	# Create projectile (placeholder - would use actual scene)
	print("Launching projectile from ", start_pos, " to ", target_pos)
	
	# Calculate direction
	var direction = (target_pos - start_pos).normalized()
	direction.y = 0  # Keep projectile horizontal
	
	# Create projectile effect
	create_projectile_effect(start_pos, direction)

func apply_shield_effect(duration: float, damage_reduction: float):
	# Set shield flag on player
	player.set_meta("has_shield", true)
	player.set_meta("shield_reduction", damage_reduction)
	
	# Create shield timer
	var shield_timer = get_tree().create_timer(duration)
	shield_timer.timeout.connect(_on_shield_expired)
	
	print("Shield active for ", duration, " seconds with ", damage_reduction * 100, "% damage reduction")

func create_area_slam_effect(slam_position: Vector3, radius: float):
	# Placeholder for area slam visual effect
	print("Creating area slam effect at ", slam_position, " with radius ", radius)
	
	# Create simple expanding ring effect (placeholder)
	var _effect_tween = create_tween()
	# This would create actual 3D particles or mesh effects

func create_projectile_effect(start_pos: Vector3, direction: Vector3):
	# Placeholder for projectile effect
	print("Creating projectile effect from ", start_pos, " in direction ", direction)
	
	# This would instantiate actual projectile scene and move it

func get_ability_name(ability_type: AbilityType) -> String:
	match ability_type:
		AbilityType.AREA_SLAM:
			return "Area Slam"
		AbilityType.PROJECTILE_SHOT:
			return "Projectile Shot"
		AbilityType.SHIELD_BLOCK:
			return "Shield Block"
		AbilityType.WALL_SLAM:
			return "Wall Slam"
		_:
			return "Unknown"

func _on_shield_expired():
	player.remove_meta("has_shield")
	player.remove_meta("shield_reduction")
	print("Shield expired")

# Public API
func get_mana_percentage() -> float:
	return current_mana / max_mana

func get_ability_cooldown_progress(ability_type: AbilityType) -> float:
	var max_cooldown = ability_cooldowns.get(ability_type, 1.0)
	var remaining_cooldown = cooldown_timers.get(ability_type, 0.0)
	return 1.0 - (remaining_cooldown / max_cooldown)

func is_ability_ready(ability_type: AbilityType) -> bool:
	return can_use_ability(ability_type)

func get_ability_info() -> Dictionary:
	return {
		"current_mana": current_mana,
		"max_mana": max_mana,
		"mana_percentage": get_mana_percentage(),
		"abilities": {
			"area_slam": {
				"ready": is_ability_ready(AbilityType.AREA_SLAM),
				"cooldown_progress": get_ability_cooldown_progress(AbilityType.AREA_SLAM),
				"mana_cost": ability_mana_costs.get(AbilityType.AREA_SLAM)
			},
			"projectile_shot": {
				"ready": is_ability_ready(AbilityType.PROJECTILE_SHOT),
				"cooldown_progress": get_ability_cooldown_progress(AbilityType.PROJECTILE_SHOT),
				"mana_cost": ability_mana_costs.get(AbilityType.PROJECTILE_SHOT)
			},
			"shield_block": {
				"ready": is_ability_ready(AbilityType.SHIELD_BLOCK),
				"cooldown_progress": get_ability_cooldown_progress(AbilityType.SHIELD_BLOCK),
				"mana_cost": ability_mana_costs.get(AbilityType.SHIELD_BLOCK)
			},
			"wall_slam": {
				"ready": is_ability_ready(AbilityType.WALL_SLAM),
				"cooldown_progress": get_ability_cooldown_progress(AbilityType.WALL_SLAM),
				"mana_cost": ability_mana_costs.get(AbilityType.WALL_SLAM)
			}
		}
	}