extends CharacterBody3D
class_name MoltenGuard

signal guard_defeated()
signal lava_slam_triggered(position: Vector3)
signal molten_charge_initiated(target: Node3D)

@export_group("Molten Guard Stats")
@export var max_health: int = 200
@export var movement_speed: float = 6.0
@export var charge_speed: float = 15.0
@export var melee_damage: int = 45
@export var lava_slam_damage: int = 60
@export var detection_range: float = 18.0

@export_group("Combat Abilities") 
@export var charge_range: float = 25.0
@export var slam_radius: float = 8.0
@export var slam_cooldown: float = 5.0
@export var charge_cooldown: float = 4.0
@export var armor_value: int = 15

# Node references
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var detection_area: Area3D = $DetectionArea
@onready var slam_timer: Timer = $SlamTimer
@onready var charge_timer: Timer = $ChargeTimer
@onready var molten_particles: GPUParticles3D = $MoltenParticles
@onready var guard_light: OmniLight3D = $GuardLight

# Combat state
var current_health: int
var current_armor: int
var player_target: Node3D
var is_charging: bool = false
var is_slamming: bool = false
var is_guarding: bool = false
var charge_direction: Vector3

# Guard behavior
var patrol_points: Array[Vector3] = []
var current_patrol_index: int = 0
var patrol_mode: bool = true
var guard_stance_time: float = 0.0

# Molten effects
var molten_aura_radius: float = 3.0
var lava_pools: Array[Area3D] = []
var heat_damage_per_second: int = 10

func _ready():
	setup_molten_guard()
	create_guard_appearance()
	setup_combat_systems()
	initialize_patrol_route()
	connect_signals()

func setup_molten_guard():
	current_health = max_health
	current_armor = armor_value
	add_to_group("fire_river_enemies")
	add_to_group("molten_guards")
	
	# Heavy guard physics
	up_direction = Vector3.UP
	floor_stop_on_slope = true
	floor_max_angle = deg_to_rad(45)

func create_guard_appearance():
	# Main guard body (humanoid but bulky)
	var guard_mesh = CapsuleMesh.new()
	guard_mesh.radius = 1.2
	guard_mesh.height = 3.5
	mesh_instance.mesh = guard_mesh
	
	# Molten guard material - armored lava
	var guard_material = StandardMaterial3D.new()
	guard_material.albedo_color = Color(0.3, 0.1, 0.05, 1.0)  # Dark molten rock
	guard_material.emission_enabled = true
	guard_material.emission = Color(0.8, 0.3, 0.1, 1.0)      # Lava glow from cracks
	guard_material.metallic = 0.8
	guard_material.roughness = 0.4
	guard_material.rim_enabled = true
	guard_material.rim = Color(1.0, 0.4, 0.0, 1.0)          # Molten rim
	mesh_instance.material_override = guard_material
	
	# Collision shape - slightly smaller than visual
	var capsule_shape = CapsuleShape3D.new()
	capsule_shape.radius = 1.0
	capsule_shape.height = 3.5
	collision_shape.shape = capsule_shape
	
	# Add guard weapon (molten hammer)
	create_molten_hammer()
	
	# Add guard armor plates
	create_armor_plates()

func create_molten_hammer():
	var hammer = MeshInstance3D.new()
	hammer.name = "MoltenHammer"
	add_child(hammer)
	
	# Hammer head
	var hammer_mesh = BoxMesh.new()
	hammer_mesh.size = Vector3(0.8, 0.4, 1.5)
	hammer.mesh = hammer_mesh
	hammer.position = Vector3(1.5, 0.5, 0)  # To the side
	
	# Molten hammer material
	var hammer_material = StandardMaterial3D.new()
	hammer_material.albedo_color = Color(0.6, 0.2, 0.1, 1.0)
	hammer_material.emission_enabled = true
	hammer_material.emission = Color(1.0, 0.5, 0.0, 1.0)
	hammer_material.metallic = 0.9
	hammer_material.roughness = 0.2
	hammer.material_override = hammer_material
	
	# Hammer handle
	var handle = MeshInstance3D.new()
	hammer.add_child(handle)
	
	var handle_mesh = CylinderMesh.new()
	handle_mesh.radius_top = 0.1
	handle_mesh.radius_bottom = 0.1
	handle_mesh.height = 1.2
	handle.mesh = handle_mesh
	handle.position = Vector3(0, -0.6, 0)
	
	# Dark handle material
	var handle_material = StandardMaterial3D.new()
	handle_material.albedo_color = Color(0.2, 0.1, 0.05, 1.0)
	handle_material.roughness = 0.8
	handle.material_override = handle_material

func create_armor_plates():
	# Chest plate
	var chest_plate = MeshInstance3D.new()
	chest_plate.name = "ChestPlate"
	add_child(chest_plate)
	
	var chest_mesh = BoxMesh.new()
	chest_mesh.size = Vector3(2.0, 1.5, 0.3)
	chest_plate.mesh = chest_mesh
	chest_plate.position = Vector3(0, 0.5, -1.0)
	
	# Armored plate material
	var armor_material = StandardMaterial3D.new()
	armor_material.albedo_color = Color(0.4, 0.15, 0.08, 1.0)
	armor_material.emission_enabled = true
	armor_material.emission = Color(0.6, 0.2, 0.05, 1.0)
	armor_material.metallic = 0.9
	armor_material.roughness = 0.3
	chest_plate.material_override = armor_material
	
	# Shoulder guards
	create_shoulder_guard(Vector3(-1.0, 1.0, -0.5))  # Left
	create_shoulder_guard(Vector3(1.0, 1.0, -0.5))   # Right

func create_shoulder_guard(pos: Vector3):
	var shoulder = MeshInstance3D.new()
	add_child(shoulder)
	
	var shoulder_mesh = SphereMesh.new()
	shoulder_mesh.radius = 0.6
	shoulder.mesh = shoulder_mesh
	shoulder.position = pos
	
	# Same armor material
	var armor_material = StandardMaterial3D.new()
	armor_material.albedo_color = Color(0.4, 0.15, 0.08, 1.0)
	armor_material.emission_enabled = true
	armor_material.emission = Color(0.6, 0.2, 0.05, 1.0)
	armor_material.metallic = 0.9
	armor_material.roughness = 0.3
	shoulder.material_override = armor_material

func setup_combat_systems():
	# Detection area
	var detection_collision = CollisionShape3D.new()
	var detection_shape = SphereShape3D.new()
	detection_shape.radius = detection_range
	detection_collision.shape = detection_shape
	detection_area.add_child(detection_collision)
	
	# Ability timers
	slam_timer.wait_time = slam_cooldown
	slam_timer.one_shot = true
	charge_timer.wait_time = charge_cooldown
	charge_timer.one_shot = true
	
	# Molten particle system
	if molten_particles:
		molten_particles.emitting = true
		molten_particles.amount = 75
	
	# Guard light (molten glow)
	if guard_light:
		guard_light.light_energy = 1.2
		guard_light.light_color = Color(1.0, 0.4, 0.1, 1.0)
		guard_light.omni_range = molten_aura_radius * 2

func initialize_patrol_route():
	# Set up patrol points around spawn area
	var base_pos = global_position
	patrol_points = [
		base_pos + Vector3(10, 0, 0),
		base_pos + Vector3(10, 0, 10),
		base_pos + Vector3(-10, 0, 10),
		base_pos + Vector3(-10, 0, 0)
	]

func connect_signals():
	detection_area.body_entered.connect(_on_player_detected)
	detection_area.body_exited.connect(_on_player_lost)
	slam_timer.timeout.connect(_on_slam_cooldown_finished)
	charge_timer.timeout.connect(_on_charge_cooldown_finished)

func _physics_process(delta):
	if not is_instance_valid(player_target):
		search_for_player()
		patrol_behavior(delta)
	else:
		combat_behavior(delta)
	
	update_molten_aura(delta)
	move_and_slide()

func search_for_player():
	player_target = get_tree().get_first_node_in_group("player")

func patrol_behavior(delta: float):
	if not patrol_mode or patrol_points.is_empty():
		return
	
	var target_point = patrol_points[current_patrol_index]
	var distance_to_point = global_position.distance_to(target_point)
	
	if distance_to_point < 2.0:
		# Reached patrol point
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		
		# Guard stance - wait and look around
		enter_guard_stance()
	else:
		# Move toward patrol point
		var direction = (target_point - global_position).normalized()
		velocity = direction * movement_speed * 0.5
		look_at(target_point, Vector3.UP)

func enter_guard_stance():
	is_guarding = true
	velocity = Vector3.ZERO
	guard_stance_time = 2.0  # Stand guard for 2 seconds

func combat_behavior(delta: float):
	if not player_target:
		return
	
	patrol_mode = false
	is_guarding = false
	
	var distance_to_player = global_position.distance_to(player_target.global_position)
	
	# Choose combat action based on distance and cooldowns
	if distance_to_player <= slam_radius and can_slam():
		perform_lava_slam()
	elif distance_to_player >= charge_range * 0.5 and distance_to_player <= charge_range and can_charge():
		initiate_molten_charge()
	elif distance_to_player > slam_radius and not is_charging:
		advance_toward_player(delta)
	elif is_charging:
		execute_charge_attack(delta)

func advance_toward_player(delta: float):
	var direction = (player_target.global_position - global_position).normalized()
	velocity = direction * movement_speed
	look_at(player_target.global_position, Vector3.UP)
	
	# Create small lava pools while moving
	if randf() < 0.1:  # 10% chance per frame
		create_movement_lava_pool()

func perform_lava_slam():
	if not can_slam():
		return
	
	is_slamming = true
	velocity = Vector3.ZERO
	
	# Face player
	look_at(player_target.global_position, Vector3.UP)
	
	# Slam animation (brief pause then impact)
	var slam_delay_timer = Timer.new()
	slam_delay_timer.wait_time = 0.8  # Wind-up time
	slam_delay_timer.timeout.connect(_execute_lava_slam)
	slam_delay_timer.one_shot = true
	slam_delay_timer.autostart = true
	add_child(slam_delay_timer)
	
	slam_timer.start()
	lava_slam_triggered.emit(global_position)
	
	print("Molten Guard prepares devastating lava slam!")

func _execute_lava_slam():
	# Create large lava shockwave
	var slam_area = Area3D.new()
	slam_area.name = "LavaSlamArea"
	slam_area.position = global_position
	get_parent().add_child(slam_area)
	
	# Large circular damage area
	var slam_collision = CollisionShape3D.new()
	var slam_shape = CylinderShape3D.new()
	slam_shape.radius = slam_radius
	slam_shape.height = 2.0
	slam_collision.shape = slam_shape
	slam_area.add_child(slam_collision)
	
	# Visual slam effect
	var slam_effect = MeshInstance3D.new()
	var effect_mesh = CylinderMesh.new()
	effect_mesh.radius_top = slam_radius
	effect_mesh.radius_bottom = slam_radius
	effect_mesh.height = 0.5
	slam_effect.mesh = effect_mesh
	slam_area.add_child(slam_effect)
	
	# Lava slam material
	var slam_material = StandardMaterial3D.new()
	slam_material.albedo_color = Color(1.0, 0.3, 0.0, 0.8)
	slam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	slam_material.emission_enabled = true
	slam_material.emission = Color(1.0, 0.5, 0.0, 1.0)
	slam_effect.material_override = slam_material
	
	# Damage detection
	slam_area.body_entered.connect(_on_slam_hit)
	
	# Persistent lava pool after slam
	create_persistent_lava_pool(global_position, slam_radius * 0.6)
	
	# Remove slam effect after brief duration
	var effect_timer = Timer.new()
	effect_timer.wait_time = 1.0
	effect_timer.timeout.connect(slam_area.queue_free)
	effect_timer.autostart = true
	slam_area.add_child(effect_timer)

func initiate_molten_charge():
	if not can_charge():
		return
	
	is_charging = true
	charge_direction = (player_target.global_position - global_position).normalized()
	
	# Face charge direction
	look_at(player_target.global_position, Vector3.UP)
	
	charge_timer.start()
	molten_charge_initiated.emit(player_target)
	
	print("Molten Guard begins devastating charge attack!")

func execute_charge_attack(delta: float):
	velocity = charge_direction * charge_speed
	
	# Create lava trail during charge
	if randf() < 0.3:  # 30% chance per frame during charge
		create_charge_lava_trail()
	
	# Check for collision with player or obstacles
	check_charge_collision()

func check_charge_collision():
	# Would check for collision with player during charge
	if player_target and global_position.distance_to(player_target.global_position) < 2.0:
		hit_player_with_charge()

func hit_player_with_charge():
	if player_target and player_target.has_method("take_damage"):
		player_target.take_damage(melee_damage * 1.5, "fire")  # Charge does extra damage
		
		# Knockback effect
		if player_target.has_method("apply_knockback"):
			player_target.apply_knockback(charge_direction * 10.0)
		
		print("Molten Guard charge hits player for ", melee_damage * 1.5, " damage!")
	
	# End charge after hit
	is_charging = false
	velocity = Vector3.ZERO

func create_movement_lava_pool():
	create_persistent_lava_pool(global_position, 2.0)

func create_charge_lava_trail():
	create_persistent_lava_pool(global_position, 1.5)

func create_persistent_lava_pool(pos: Vector3, radius: float):
	var lava_pool = Area3D.new()
	lava_pool.name = "GuardLavaPool"
	lava_pool.position = pos
	get_parent().add_child(lava_pool)
	
	# Pool appearance
	var pool_mesh = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.radius_top = radius
	mesh.radius_bottom = radius
	mesh.height = 0.3
	pool_mesh.mesh = mesh
	lava_pool.add_child(pool_mesh)
	
	# Lava material
	var lava_material = StandardMaterial3D.new()
	lava_material.albedo_color = Color(0.9, 0.2, 0.05, 1.0)
	lava_material.emission_enabled = true
	lava_material.emission = Color(1.0, 0.4, 0.0, 1.0)
	pool_mesh.material_override = lava_material
	
	# Collision for damage
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = radius
	shape.height = 0.3
	collision.shape = shape
	lava_pool.add_child(collision)
	
	# Continuous damage
	lava_pool.body_entered.connect(_on_lava_pool_entered)
	
	# Pool duration
	var pool_timer = Timer.new()
	pool_timer.wait_time = 12.0  # Pools last 12 seconds
	pool_timer.timeout.connect(lava_pool.queue_free)
	pool_timer.autostart = true
	lava_pool.add_child(pool_timer)
	
	lava_pools.append(lava_pool)

func update_molten_aura(delta: float):
	# Continuous heat damage to nearby player
	if player_target and global_position.distance_to(player_target.global_position) <= molten_aura_radius:
		if player_target.has_method("take_damage"):
			player_target.take_damage(heat_damage_per_second * delta, "fire")

func can_slam() -> bool:
	return not is_slamming and slam_timer.is_stopped()

func can_charge() -> bool:
	return not is_charging and charge_timer.is_stopped()

func take_damage(damage: int, damage_type: String = ""):
	# Apply armor reduction
	var actual_damage = max(1, damage - current_armor)
	current_health -= actual_damage
	
	# Visual damage feedback
	create_damage_flash()
	
	# Armor degradation from repeated hits
	if randf() < 0.1:  # 10% chance
		current_armor = max(0, current_armor - 1)
		if current_armor == 0:
			print("Molten Guard's armor has been destroyed!")
			remove_armor_visual()
	
	if current_health <= 0:
		die()
	else:
		# Enrage when below 30% health
		if current_health < max_health * 0.3:
			enter_berserker_mode()

func create_damage_flash():
	var flash_tween = create_tween()
	flash_tween.tween_property(mesh_instance, "modulate", Color.WHITE, 0.1)
	flash_tween.tween_property(mesh_instance, "modulate", Color.RED, 0.1)
	flash_tween.tween_property(mesh_instance, "modulate", Color.WHITE, 0.1)

func remove_armor_visual():
	# Remove armor plates when armor is destroyed
	var chest_plate = get_node_or_null("ChestPlate")
	if chest_plate:
		chest_plate.queue_free()

func enter_berserker_mode():
	print("Molten Guard enters berserker mode - attacks intensify!")
	
	# Reduce cooldowns
	slam_cooldown *= 0.6
	charge_cooldown *= 0.6
	
	# Increase speed
	movement_speed *= 1.4
	charge_speed *= 1.2
	
	# Enhanced visual effects
	if molten_particles:
		molten_particles.amount = 150
	if guard_light:
		guard_light.light_energy = 2.0

func die():
	guard_defeated.emit()
	
	# Create death lava explosion
	create_death_lava_explosion()
	
	# Clean up lava pools
	for pool in lava_pools:
		if is_instance_valid(pool):
			pool.queue_free()
	
	print("Molten Guard falls - armor crumbles to ash")
	queue_free()

func create_death_lava_explosion():
	# Large lava explosion on death
	var explosion_pool = Area3D.new()
	explosion_pool.name = "DeathExplosion"
	explosion_pool.position = global_position
	get_parent().add_child(explosion_pool)
	
	var explosion_mesh = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.radius_top = 6.0
	mesh.radius_bottom = 6.0
	mesh.height = 1.0
	explosion_mesh.mesh = mesh
	explosion_pool.add_child(explosion_mesh)
	
	# Intense lava material
	var explosion_material = StandardMaterial3D.new()
	explosion_material.albedo_color = Color(1.0, 0.4, 0.0, 0.9)
	explosion_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	explosion_material.emission_enabled = true
	explosion_material.emission = Color(1.0, 0.6, 0.0, 1.0)
	explosion_mesh.material_override = explosion_material
	
	# Fade out explosion
	var explosion_tween = create_tween()
	explosion_tween.parallel().tween_property(explosion_pool, "scale", Vector3.ZERO, 1.0)
	explosion_tween.parallel().tween_property(explosion_mesh, "modulate:a", 0.0, 1.0)
	explosion_tween.tween_callback(explosion_pool.queue_free)

# Signal handlers
func _on_player_detected(body: Node3D):
	if body.is_in_group("player"):
		player_target = body
		print("Molten Guard detects intruder - combat mode engaged")

func _on_player_lost(body: Node3D):
	if body == player_target:
		player_target = null
		patrol_mode = true

func _on_slam_cooldown_finished():
	is_slamming = false

func _on_charge_cooldown_finished():
	is_charging = false

func _on_slam_hit(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		body.take_damage(lava_slam_damage, "fire")
		print("Lava slam devastates player for ", lava_slam_damage, " damage!")

func _on_lava_pool_entered(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		body.take_damage(20, "fire")  # Pool damage

# Public API
func get_guard_info() -> Dictionary:
	return {
		"health": current_health,
		"max_health": max_health,
		"armor": current_armor,
		"is_charging": is_charging,
		"is_slamming": is_slamming,
		"is_guarding": is_guarding,
		"lava_pools_created": lava_pools.size()
	}

func set_patrol_route(points: Array[Vector3]):
	patrol_points = points
	current_patrol_index = 0

func force_berserker_mode():
	enter_berserker_mode()