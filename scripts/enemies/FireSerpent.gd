extends CharacterBody3D
class_name FireSerpent

signal serpent_defeated()
signal fire_attack_launched(target: Node3D)

@export_group("Fire Serpent Stats")
@export var max_health: int = 150
@export var movement_speed: float = 8.0
@export var fire_damage: int = 35
@export var lava_immunity: bool = true
@export var detection_range: float = 20.0

@export_group("Attack Settings")
@export var fire_breath_range: float = 15.0
@export var fire_breath_cone_angle: float = 45.0
@export var attack_cooldown: float = 3.0
@export var slither_attack_speed: float = 12.0

# Node references
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var detection_area: Area3D = $DetectionArea
@onready var attack_timer: Timer = $AttackTimer
@onready var fire_particles: GPUParticles3D = $FireParticles

# Combat state
var current_health: int
var player_target: Node3D
var is_attacking: bool = false
var is_slithering: bool = false
var last_attack_time: float = 0.0

# Movement state
var serpent_segments: Array[Node3D] = []
var segment_positions: Array[Vector3] = []
var base_position: Vector3

# Fire effects
var fire_breath_active: bool = false
var lava_trail_nodes: Array[Node3D] = []

func _ready():
	setup_fire_serpent()
	create_serpent_appearance()
	setup_combat_systems()
	connect_signals()

func setup_fire_serpent():
	current_health = max_health
	base_position = global_position
	add_to_group("fire_river_enemies")
	add_to_group("fire_serpents")
	
	# Serpent physics
	up_direction = Vector3.UP
	floor_stop_on_slope = false
	floor_max_angle = deg_to_rad(60)

func create_serpent_appearance():
	# Main serpent body (elongated)
	var serpent_mesh = CapsuleMesh.new()
	serpent_mesh.radius = 1.0
	serpent_mesh.height = 6.0
	mesh_instance.mesh = serpent_mesh
	
	# Fire serpent material
	var serpent_material = StandardMaterial3D.new()
	serpent_material.albedo_color = Color(0.8, 0.2, 0.1, 1.0)  # Deep red
	serpent_material.emission_enabled = true
	serpent_material.emission = Color(1.0, 0.4, 0.0, 1.0)     # Fire glow
	serpent_material.metallic = 0.3
	serpent_material.roughness = 0.7
	serpent_material.rim_enabled = true
	serpent_material.rim = Color(1.0, 0.8, 0.2, 1.0)         # Golden rim
	mesh_instance.material_override = serpent_material
	
	# Collision shape
	var capsule_shape = CapsuleShape3D.new()
	capsule_shape.radius = 1.0
	capsule_shape.height = 6.0
	collision_shape.shape = capsule_shape
	
	# Create serpent segments for visual effect
	create_serpent_segments()

func create_serpent_segments():
	# Create 4 additional segments following main body
	for i in range(4):
		var segment = MeshInstance3D.new()
		add_child(segment)
		
		var segment_mesh = SphereMesh.new()
		segment_mesh.radius = 0.8 - (i * 0.15)  # Gradually smaller
		segment.mesh = segment_mesh
		
		# Same material as main body but slightly dimmer
		var segment_material = StandardMaterial3D.new()
		segment_material.albedo_color = Color(0.7, 0.15, 0.05, 1.0)
		segment_material.emission_enabled = true
		segment_material.emission = Color(0.8, 0.3, 0.0, 1.0) * (1.0 - i * 0.1)
		segment.material_override = segment_material
		
		segment.position = Vector3(0, 0, -2.0 * (i + 1))
		serpent_segments.append(segment)
		segment_positions.append(segment.position)

func setup_combat_systems():
	# Detection area
	var detection_collision = CollisionShape3D.new()
	var detection_shape = SphereShape3D.new()
	detection_shape.radius = detection_range
	detection_collision.shape = detection_shape
	detection_area.add_child(detection_collision)
	
	# Attack timer
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	
	# Fire particle system
	if fire_particles:
		fire_particles.emitting = true
		fire_particles.amount = 50
		# Configure fire particles (would use custom fire shader)

func connect_signals():
	detection_area.body_entered.connect(_on_player_detected)
	detection_area.body_exited.connect(_on_player_lost)
	attack_timer.timeout.connect(_on_attack_cooldown_finished)

func _physics_process(delta):
	if not is_instance_valid(player_target):
		search_for_player()
		return
	
	update_serpent_behavior(delta)
	update_serpent_segments(delta)
	move_and_slide()

func search_for_player():
	player_target = get_tree().get_first_node_in_group("player")

func update_serpent_behavior(delta: float):
	if not player_target:
		return
	
	var distance_to_player = global_position.distance_to(player_target.global_position)
	
	if distance_to_player <= fire_breath_range and can_attack():
		perform_fire_breath_attack()
	elif distance_to_player > fire_breath_range:
		slither_toward_player(delta)
	else:
		# Within range but on cooldown
		perform_defensive_maneuvers(delta)

func slither_toward_player(delta: float):
	is_slithering = true
	var direction = (player_target.global_position - global_position).normalized()
	
	# Serpentine movement pattern
	var serpentine_offset = sin(Time.get_time_dict_from_system().second * 3.0) * 2.0
	var sideways = Vector3(-direction.z, 0, direction.x) * serpentine_offset
	
	velocity = (direction + sideways.normalized() * 0.3) * movement_speed
	
	# Face movement direction
	if velocity.length() > 0:
		look_at(global_position + velocity, Vector3.UP)
	
	# Leave lava trail when slithering
	create_lava_trail()

func perform_fire_breath_attack():
	if not can_attack():
		return
	
	is_attacking = true
	fire_breath_active = true
	last_attack_time = Time.get_time_dict_from_system().second
	
	# Face player
	look_at(player_target.global_position, Vector3.UP)
	
	# Create fire breath effect
	create_fire_breath_cone()
	
	# Launch attack signal
	fire_attack_launched.emit(player_target)
	
	# Start cooldown
	attack_timer.start()
	
	print("Fire Serpent launches fire breath attack!")

func create_fire_breath_cone():
	var fire_cone = Area3D.new()
	fire_cone.name = "FireBreathCone"
	get_parent().add_child(fire_cone)
	
	# Position in front of serpent
	fire_cone.global_position = global_position + transform.basis.z * -2
	fire_cone.global_rotation = global_rotation
	
	# Cone shape collision
	var cone_collision = CollisionShape3D.new()
	var cone_shape = BoxShape3D.new()  # Simplified cone as box
	cone_shape.size = Vector3(fire_breath_range * 0.5, 3.0, fire_breath_range)
	cone_collision.shape = cone_shape
	cone_collision.position = Vector3(0, 0, -fire_breath_range * 0.5)
	fire_cone.add_child(cone_collision)
	
	# Visual fire effect
	var fire_effect = MeshInstance3D.new()
	var fire_mesh = BoxMesh.new()
	fire_mesh.size = Vector3(fire_breath_range * 0.4, 2.0, fire_breath_range * 0.8)
	fire_effect.mesh = fire_mesh
	fire_effect.position = Vector3(0, 0, -fire_breath_range * 0.5)
	fire_cone.add_child(fire_effect)
	
	# Fire material
	var fire_material = StandardMaterial3D.new()
	fire_material.albedo_color = Color(1.0, 0.3, 0.0, 0.8)
	fire_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fire_material.emission_enabled = true
	fire_material.emission = Color(1.0, 0.5, 0.0, 1.0)
	fire_effect.material_override = fire_material
	
	# Damage detection
	fire_cone.body_entered.connect(_on_fire_breath_hit)
	
	# Remove fire breath after duration
	var fire_duration_timer = Timer.new()
	fire_duration_timer.wait_time = 1.5
	fire_duration_timer.timeout.connect(fire_cone.queue_free)
	fire_duration_timer.autostart = true
	fire_cone.add_child(fire_duration_timer)

func create_lava_trail():
	# Create temporary lava pool where serpent slithered
	var lava_trail = Area3D.new()
	lava_trail.name = "SerpentLavaTrail"
	lava_trail.position = global_position
	get_parent().add_child(lava_trail)
	
	# Trail appearance
	var trail_mesh = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.radius_top = 1.2
	mesh.radius_bottom = 1.2
	mesh.height = 0.2
	trail_mesh.mesh = mesh
	lava_trail.add_child(trail_mesh)
	
	# Lava material
	var lava_material = StandardMaterial3D.new()
	lava_material.albedo_color = Color(0.9, 0.3, 0.1, 1.0)
	lava_material.emission_enabled = true
	lava_material.emission = Color(1.0, 0.4, 0.0, 1.0)
	trail_mesh.material_override = lava_material
	
	# Collision for damage
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = 1.2
	shape.height = 0.2
	collision.shape = shape
	lava_trail.add_child(collision)
	
	# Damage over time
	lava_trail.body_entered.connect(_on_lava_trail_entered)
	
	# Remove trail after time
	var trail_timer = Timer.new()
	trail_timer.wait_time = 8.0
	trail_timer.timeout.connect(lava_trail.queue_free)
	trail_timer.autostart = true
	lava_trail.add_child(trail_timer)
	
	lava_trail_nodes.append(lava_trail)

func perform_defensive_maneuvers(delta: float):
	# Circle around player while on cooldown
	var direction_to_player = (player_target.global_position - global_position).normalized()
	var circle_direction = Vector3(-direction_to_player.z, 0, direction_to_player.x)
	
	velocity = circle_direction * movement_speed * 0.6
	look_at(player_target.global_position, Vector3.UP)

func update_serpent_segments(delta: float):
	# Update segment positions to follow main body with delay
	if serpent_segments.size() > 0:
		# Update positions array
		segment_positions.push_front(Vector3.ZERO)
		if segment_positions.size() > serpent_segments.size():
			segment_positions.resize(serpent_segments.size())
		
		# Apply positions to segments
		for i in range(serpent_segments.size()):
			if i < segment_positions.size():
				var target_pos = segment_positions[i] + Vector3(0, 0, -2.0 * (i + 1))
				serpent_segments[i].position = serpent_segments[i].position.lerp(target_pos, delta * 5.0)

func can_attack() -> bool:
	return not is_attacking and attack_timer.is_stopped()

func take_damage(damage: int, damage_type: String = ""):
	# Fire serpents are immune to fire damage
	if damage_type == "fire" and lava_immunity:
		return
	
	current_health -= damage
	
	# Visual damage feedback
	create_damage_flash()
	
	if current_health <= 0:
		die()
	else:
		# Enrage when below 50% health
		if current_health < max_health * 0.5:
			enter_enraged_state()

func create_damage_flash():
	# Flash red when taking damage
	var flash_tween = create_tween()
	flash_tween.tween_property(mesh_instance, "modulate", Color.WHITE, 0.1)
	flash_tween.tween_property(mesh_instance, "modulate", Color.RED, 0.1)
	flash_tween.tween_property(mesh_instance, "modulate", Color.WHITE, 0.1)

func enter_enraged_state():
	# Increase speed and reduce cooldown when enraged
	movement_speed *= 1.3
	attack_cooldown *= 0.7
	
	# Enhanced visual effects
	if fire_particles:
		fire_particles.amount = 100
		fire_particles.emitting = true

func die():
	serpent_defeated.emit()
	
	# Death explosion effect
	create_death_explosion()
	
	# Clean up lava trails
	for trail in lava_trail_nodes:
		if is_instance_valid(trail):
			trail.queue_free()
	
	print("Fire Serpent defeated - flames extinguished")
	queue_free()

func create_death_explosion():
	# Create fire explosion on death
	var explosion = MeshInstance3D.new()
	get_parent().add_child(explosion)
	explosion.global_position = global_position
	
	var explosion_mesh = SphereMesh.new()
	explosion_mesh.radius = 3.0
	explosion.mesh = explosion_mesh
	
	var explosion_material = StandardMaterial3D.new()
	explosion_material.albedo_color = Color(1.0, 0.5, 0.0, 0.8)
	explosion_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	explosion_material.emission_enabled = true
	explosion_material.emission = Color(1.0, 0.7, 0.0, 1.0)
	explosion.material_override = explosion_material
	
	# Animate explosion
	var explosion_tween = create_tween()
	explosion_tween.parallel().tween_property(explosion, "scale", Vector3.ZERO, 0.5)
	explosion_tween.parallel().tween_property(explosion, "modulate:a", 0.0, 0.5)
	explosion_tween.tween_callback(explosion.queue_free)

# Signal handlers
func _on_player_detected(body: Node3D):
	if body.is_in_group("player"):
		player_target = body
		print("Fire Serpent detects player - beginning pursuit")

func _on_player_lost(body: Node3D):
	if body == player_target:
		player_target = null

func _on_attack_cooldown_finished():
	is_attacking = false
	fire_breath_active = false

func _on_fire_breath_hit(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		body.take_damage(fire_damage, "fire")
		print("Fire breath hits player for ", fire_damage, " fire damage")

func _on_lava_trail_entered(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		# Continuous damage from lava trail
		body.take_damage(15, "fire")

# Public API
func get_serpent_info() -> Dictionary:
	return {
		"health": current_health,
		"max_health": max_health,
		"is_attacking": is_attacking,
		"is_slithering": is_slithering,
		"segments": serpent_segments.size(),
		"lava_trails": lava_trail_nodes.size()
	}

func force_enrage():
	enter_enraged_state()

func set_player_target(target: Node3D):
	player_target = target