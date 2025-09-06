extends CharacterBody3D
class_name FlameSpirit

signal spirit_defeated()
signal flame_burst_triggered(position: Vector3)
signal possession_attempted(target: Node3D)

@export_group("Flame Spirit Stats")
@export var max_health: int = 100
@export var flight_speed: float = 10.0
@export var dash_speed: float = 20.0
@export var flame_damage: int = 25
@export var possession_damage: int = 40
@export var detection_range: float = 22.0

@export_group("Spectral Abilities")
@export var phase_duration: float = 3.0
@export var flame_burst_radius: float = 6.0
@export var possession_range: float = 4.0
@export var teleport_distance: float = 15.0
@export var flame_trail_intensity: float = 0.8

# Node references
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var detection_area: Area3D = $DetectionArea
@onready var phase_timer: Timer = $PhaseTimer
@onready var ability_timer: Timer = $AbilityTimer
@onready var flame_particles: GPUParticles3D = $FlameParticles
@onready var spirit_light: OmniLight3D = $SpiritLight

# Combat state
var current_health: int
var player_target: Node3D
var is_phased: bool = false
var is_dashing: bool = false
var is_possessing: bool = false
var dash_direction: Vector3

# Spirit behavior
var floating_height: float = 3.0
var base_position: Vector3
var current_pattern: String = "hover"
var pattern_timer: float = 0.0

# Flame effects
var flame_trails: Array[Node3D] = []
var flame_bursts: Array[Area3D] = []
var possession_target: Node3D

func _ready():
	setup_flame_spirit()
	create_spirit_appearance()
	setup_spectral_systems()
	initialize_flight_behavior()
	connect_signals()

func setup_flame_spirit():
	current_health = max_health
	base_position = global_position
	add_to_group("fire_river_enemies")
	add_to_group("flame_spirits")
	
	# Spectral physics - can phase through walls
	up_direction = Vector3.UP
	floor_stop_on_slope = false
	
	# Start floating
	global_position.y += floating_height

func create_spirit_appearance():
	# Main spirit form (ethereal flame orb)
	var spirit_mesh = SphereMesh.new()
	spirit_mesh.radius = 0.8
	mesh_instance.mesh = spirit_mesh
	
	# Flame spirit material - translucent with inner fire
	var spirit_material = StandardMaterial3D.new()
	spirit_material.albedo_color = Color(1.0, 0.3, 0.0, 0.7)   # Translucent flame
	spirit_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spirit_material.emission_enabled = true
	spirit_material.emission = Color(1.0, 0.6, 0.0, 1.0)      # Bright inner flame
	spirit_material.rim_enabled = true
	spirit_material.rim = Color(1.0, 0.8, 0.2, 1.0)          # Golden rim
	spirit_material.grow_amount = 0.1                          # Slight glow expansion
	mesh_instance.material_override = spirit_material
	
	# Collision shape - smaller than visual for easier dodging
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.6
	collision_shape.shape = sphere_shape
	
	# Add flame tendrils for visual flair
	create_flame_tendrils()
	
	# Add spirit core
	create_spirit_core()

func create_flame_tendrils():
	# Create 6 flame tendrils around the spirit
	for i in range(6):
		var tendril = MeshInstance3D.new()
		tendril.name = "FlameTendril" + str(i)
		add_child(tendril)
		
		var tendril_mesh = CylinderMesh.new()
		tendril_mesh.radius_top = 0.05
		tendril_mesh.radius_bottom = 0.1
		tendril_mesh.height = 1.5
		tendril.mesh = tendril_mesh
		
		# Position tendrils in circle around spirit
		var angle = (i * 2 * PI) / 6
		tendril.position = Vector3(cos(angle) * 0.8, 0, sin(angle) * 0.8)
		tendril.rotation_degrees.y = angle * 180 / PI
		
		# Tendril material - like main spirit but dimmer
		var tendril_material = StandardMaterial3D.new()
		tendril_material.albedo_color = Color(0.8, 0.2, 0.0, 0.6)
		tendril_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tendril_material.emission_enabled = true
		tendril_material.emission = Color(0.9, 0.4, 0.0, 1.0)
		tendril.material_override = tendril_material

func create_spirit_core():
	# Inner spirit core (darker, more solid)
	var core = MeshInstance3D.new()
	core.name = "SpiritCore"
	add_child(core)
	
	var core_mesh = SphereMesh.new()
	core_mesh.radius = 0.3
	core.mesh = core_mesh
	
	# Core material - solid flame heart
	var core_material = StandardMaterial3D.new()
	core_material.albedo_color = Color(0.6, 0.1, 0.0, 1.0)
	core_material.emission_enabled = true
	core_material.emission = Color(1.0, 0.3, 0.0, 1.0)
	core_material.metallic = 0.8
	core_material.roughness = 0.1
	core.material_override = core_material

func setup_spectral_systems():
	# Detection area
	var detection_collision = CollisionShape3D.new()
	var detection_shape = SphereShape3D.new()
	detection_shape.radius = detection_range
	detection_collision.shape = detection_shape
	detection_area.add_child(detection_collision)
	
	# Phase timer
	phase_timer.wait_time = phase_duration
	phase_timer.one_shot = true
	
	# Ability timer (for various attacks)
	ability_timer.wait_time = 2.0
	ability_timer.one_shot = true
	
	# Flame particle system
	if flame_particles:
		flame_particles.emitting = true
		flame_particles.amount = 60
		# Configure flame particles (would use custom flame shader)
	
	# Spirit light
	if spirit_light:
		spirit_light.light_energy = 1.5
		spirit_light.light_color = Color(1.0, 0.4, 0.0, 1.0)
		spirit_light.omni_range = 8.0

func initialize_flight_behavior():
	# Set initial flight pattern
	current_pattern = "hover"
	pattern_timer = 0.0

func connect_signals():
	detection_area.body_entered.connect(_on_player_detected)
	detection_area.body_exited.connect(_on_player_lost)
	phase_timer.timeout.connect(_on_phase_ended)
	ability_timer.timeout.connect(_on_ability_cooldown_finished)

func _physics_process(delta):
	if not is_instance_valid(player_target):
		search_for_player()
		perform_idle_flight(delta)
	else:
		perform_combat_flight(delta)
	
	update_flame_effects(delta)
	move_and_slide()

func search_for_player():
	player_target = get_tree().get_first_node_in_group("player")

func perform_idle_flight(delta: float):
	pattern_timer += delta
	
	match current_pattern:
		"hover":
			perform_hovering_pattern(delta)
		"circle":
			perform_circular_flight(delta)
		"patrol":
			perform_patrol_flight(delta)
	
	# Change pattern every 5-8 seconds
	if pattern_timer > randf_range(5.0, 8.0):
		change_flight_pattern()

func perform_hovering_pattern(delta: float):
	# Gentle up-down floating motion
	var hover_offset = sin(pattern_timer * 2.0) * 0.5
	var target_height = base_position.y + floating_height + hover_offset
	
	velocity = Vector3.ZERO
	velocity.y = (target_height - global_position.y) * 2.0

func perform_circular_flight(delta: float):
	# Circular flight around base position
	var radius = 8.0
	var angle = pattern_timer * 0.5
	var target_pos = base_position + Vector3(cos(angle) * radius, floating_height, sin(angle) * radius)
	
	var direction = (target_pos - global_position).normalized()
	velocity = direction * flight_speed * 0.5

func perform_patrol_flight(delta: float):
	# Simple back-and-forth patrol
	var patrol_distance = 12.0
	var patrol_direction = Vector3(sin(pattern_timer * 0.3) * patrol_distance, 0, 0)
	var target_pos = base_position + patrol_direction + Vector3(0, floating_height, 0)
	
	var direction = (target_pos - global_position).normalized()
	velocity = direction * flight_speed * 0.3

func change_flight_pattern():
	var patterns = ["hover", "circle", "patrol"]
	current_pattern = patterns[randi() % patterns.size()]
	pattern_timer = 0.0

func perform_combat_flight(delta: float):
	if not player_target:
		return
	
	var distance_to_player = global_position.distance_to(player_target.global_position)
	
	if is_dashing:
		execute_flame_dash(delta)
	elif distance_to_player <= possession_range and can_possess():
		attempt_possession()
	elif distance_to_player <= flame_burst_radius and can_burst():
		trigger_flame_burst()
	elif distance_to_player > 10.0 and can_teleport():
		perform_spirit_teleport()
	else:
		perform_harassment_flight(delta)

func perform_harassment_flight(delta: float):
	# Circle around player at medium distance, occasionally diving in
	var target_distance = 8.0
	var player_pos = player_target.global_position + Vector3(0, floating_height, 0)
	var current_distance = global_position.distance_to(player_pos)
	
	if current_distance > target_distance:
		# Move closer
		var direction = (player_pos - global_position).normalized()
		velocity = direction * flight_speed
	else:
		# Circle around player
		var to_player = (player_pos - global_position).normalized()
		var circle_direction = Vector3(-to_player.z, 0, to_player.x)  # Perpendicular
		velocity = circle_direction * flight_speed * 0.7
		
		# Occasional dive attack
		if randf() < 0.02:  # 2% chance per frame
			initiate_flame_dash()

func initiate_flame_dash():
	if not player_target or is_dashing:
		return
	
	is_dashing = true
	dash_direction = (player_target.global_position - global_position).normalized()
	
	# Visual effect - spirit glows brighter
	var dash_tween = create_tween()
	dash_tween.tween_property(mesh_instance, "scale", Vector3.ONE * 1.3, 0.2)
	dash_tween.tween_property(mesh_instance, "scale", Vector3.ONE, 0.2)
	
	print("Flame Spirit initiates burning dash attack!")

func execute_flame_dash(delta: float):
	velocity = dash_direction * dash_speed
	
	# Create flame trail during dash
	create_flame_trail()
	
	# Check for player collision during dash
	if player_target and global_position.distance_to(player_target.global_position) < 1.5:
		hit_player_with_dash()
	
	# End dash after brief duration or if hit wall
	if is_on_wall() or pattern_timer > 1.0:
		end_flame_dash()

func hit_player_with_dash():
	if player_target and player_target.has_method("take_damage"):
		player_target.take_damage(flame_damage, "fire")
		
		# Apply burning effect
		if player_target.has_method("apply_status_effect"):
			player_target.apply_status_effect("burning", 3.0)
		
		print("Flame Spirit dash burns player for ", flame_damage, " damage!")
	
	end_flame_dash()

func end_flame_dash():
	is_dashing = false
	pattern_timer = 0.0
	
	# Brief hover after dash
	velocity = Vector3.ZERO

func attempt_possession():
	if not can_possess() or not player_target:
		return
	
	is_possessing = true
	possession_target = player_target
	
	# Phase into spectral form
	enter_phase_mode()
	
	# Move toward player rapidly
	var direction = (player_target.global_position - global_position).normalized()
	velocity = direction * dash_speed * 1.5
	
	possession_attempted.emit(player_target)
	print("Flame Spirit attempts to possess player!")

func trigger_flame_burst():
	if not can_burst():
		return
	
	# Create expanding flame burst around spirit
	var burst_area = Area3D.new()
	burst_area.name = "FlameBurst"
	burst_area.position = global_position
	get_parent().add_child(burst_area)
	
	# Expanding flame sphere
	var burst_mesh = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.5
	burst_mesh.mesh = sphere_mesh
	burst_area.add_child(burst_mesh)
	
	# Burst material
	var burst_material = StandardMaterial3D.new()
	burst_material.albedo_color = Color(1.0, 0.5, 0.0, 0.8)
	burst_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	burst_material.emission_enabled = true
	burst_material.emission = Color(1.0, 0.7, 0.0, 1.0)
	burst_mesh.material_override = burst_material
	
	# Collision for damage detection
	var burst_collision = CollisionShape3D.new()
	var burst_shape = SphereShape3D.new()
	burst_shape.radius = 0.5
	burst_collision.shape = burst_shape
	burst_area.add_child(burst_collision)
	
	# Animate expansion
	var expansion_tween = create_tween()
	expansion_tween.parallel().tween_property(burst_area, "scale", Vector3.ONE * flame_burst_radius, 0.5)
	expansion_tween.parallel().tween_property(burst_material, "albedo_color:a", 0.0, 0.5)
	expansion_tween.tween_callback(burst_area.queue_free)
	
	# Damage detection
	burst_area.body_entered.connect(_on_flame_burst_hit)
	
	flame_burst_triggered.emit(global_position)
	ability_timer.start()

func perform_spirit_teleport():
	# Teleport to strategic position near player
	if not player_target:
		return
	
	# Choose teleport position (flanking player)
	var player_pos = player_target.global_position
	var teleport_positions = [
		player_pos + Vector3(teleport_distance, floating_height, 0),
		player_pos + Vector3(-teleport_distance, floating_height, 0),
		player_pos + Vector3(0, floating_height, teleport_distance),
		player_pos + Vector3(0, floating_height, -teleport_distance)
	]
	
	var chosen_pos = teleport_positions[randi() % teleport_positions.size()]
	
	# Teleport effect
	create_teleport_effect(global_position, chosen_pos)
	
	# Instant teleport
	global_position = chosen_pos
	
	print("Flame Spirit teleports to flank player!")

func create_teleport_effect(from_pos: Vector3, to_pos: Vector3):
	# Disappear effect at origin
	create_flame_puff(from_pos)
	
	# Appear effect at destination
	var appear_timer = Timer.new()
	appear_timer.wait_time = 0.2
	appear_timer.timeout.connect(create_flame_puff.bind(to_pos))
	appear_timer.one_shot = true
	appear_timer.autostart = true
	add_child(appear_timer)

func create_flame_puff(pos: Vector3):
	var puff = MeshInstance3D.new()
	get_parent().add_child(puff)
	puff.position = pos
	
	var puff_mesh = SphereMesh.new()
	puff_mesh.radius = 2.0
	puff.mesh = puff_mesh
	
	var puff_material = StandardMaterial3D.new()
	puff_material.albedo_color = Color(1.0, 0.4, 0.0, 0.8)
	puff_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puff_material.emission_enabled = true
	puff_material.emission = Color(1.0, 0.6, 0.0, 1.0)
	puff.material_override = puff_material
	
	# Fade out puff
	var puff_tween = create_tween()
	puff_tween.parallel().tween_property(puff, "scale", Vector3.ZERO, 0.5)
	puff_tween.parallel().tween_property(puff, "modulate:a", 0.0, 0.5)
	puff_tween.tween_callback(puff.queue_free)

func enter_phase_mode():
	if is_phased:
		return
	
	is_phased = true
	
	# Become translucent and immune to physical attacks
	modulate.a = 0.5
	collision_layer = 0  # Phase through everything
	
	phase_timer.start()
	print("Flame Spirit phases into spectral form!")

func exit_phase_mode():
	is_phased = false
	is_possessing = false
	
	# Return to solid form
	modulate.a = 1.0
	collision_layer = 1  # Resume normal collisions

func create_flame_trail():
	var trail = MeshInstance3D.new()
	trail.name = "FlameTrail"
	get_parent().add_child(trail)
	trail.position = global_position
	
	var trail_mesh = SphereMesh.new()
	trail_mesh.radius = 0.5 * flame_trail_intensity
	trail.mesh = trail_mesh
	
	var trail_material = StandardMaterial3D.new()
	trail_material.albedo_color = Color(1.0, 0.3, 0.0, 0.6)
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_material.emission_enabled = true
	trail_material.emission = Color(0.8, 0.4, 0.0, 1.0)
	trail.material_override = trail_material
	
	# Fade out trail
	var trail_tween = create_tween()
	trail_tween.parallel().tween_property(trail, "scale", Vector3.ZERO, 1.0)
	trail_tween.parallel().tween_property(trail, "modulate:a", 0.0, 1.0)
	trail_tween.tween_callback(trail.queue_free)
	
	flame_trails.append(trail)

func update_flame_effects(delta: float):
	# Animate flame tendrils
	for i in range(6):
		var tendril = get_node_or_null("FlameTendril" + str(i))
		if tendril:
			# Gentle waving motion
			tendril.rotation_degrees.z = sin(Time.get_time_dict_from_system().second * 2 + i) * 15
	
	# Pulse spirit core
	var core = get_node_or_null("SpiritCore")
	if core:
		var pulse = sin(Time.get_time_dict_from_system().second * 4) * 0.1 + 1.0
		core.scale = Vector3.ONE * pulse

func can_possess() -> bool:
	return not is_possessing and ability_timer.is_stopped() and not is_phased

func can_burst() -> bool:
	return ability_timer.is_stopped() and not is_dashing

func can_teleport() -> bool:
	return ability_timer.is_stopped() and not is_dashing and not is_possessing

func take_damage(damage: int, damage_type: String = ""):
	# Phased spirits take reduced damage
	var actual_damage = damage
	if is_phased:
		actual_damage = damage / 2
	
	current_health -= actual_damage
	
	# Visual damage feedback
	create_damage_flash()
	
	if current_health <= 0:
		die()
	else:
		# Enter phase mode when low health
		if current_health < max_health * 0.3 and not is_phased:
			enter_phase_mode()

func create_damage_flash():
	var flash_tween = create_tween()
	flash_tween.tween_property(mesh_instance, "modulate", Color.WHITE, 0.1)
	flash_tween.tween_property(mesh_instance, "modulate", Color.YELLOW, 0.1)
	flash_tween.tween_property(mesh_instance, "modulate", Color.WHITE, 0.1)

func die():
	spirit_defeated.emit()
	
	# Spectral death effect - spirit disperses
	create_spirit_dispersal()
	
	# Clean up flame trails
	for trail in flame_trails:
		if is_instance_valid(trail):
			trail.queue_free()
	
	print("Flame Spirit disperses - its flame extinguished")
	queue_free()

func create_spirit_dispersal():
	# Multiple small flame orbs dispersing
	for i in range(8):
		var dispersal_orb = MeshInstance3D.new()
		get_parent().add_child(dispersal_orb)
		dispersal_orb.position = global_position
		
		var orb_mesh = SphereMesh.new()
		orb_mesh.radius = 0.3
		dispersal_orb.mesh = orb_mesh
		
		var orb_material = StandardMaterial3D.new()
		orb_material.albedo_color = Color(1.0, 0.4, 0.0, 0.8)
		orb_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		orb_material.emission_enabled = true
		orb_material.emission = Color(1.0, 0.5, 0.0, 1.0)
		dispersal_orb.material_override = orb_material
		
		# Random dispersal direction
		var direction = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		
		# Animate dispersal
		var dispersal_tween = create_tween()
		dispersal_tween.parallel().tween_property(dispersal_orb, "position", dispersal_orb.position + direction * 5, 1.5)
		dispersal_tween.parallel().tween_property(dispersal_orb, "scale", Vector3.ZERO, 1.5)
		dispersal_tween.parallel().tween_property(dispersal_orb, "modulate:a", 0.0, 1.5)
		dispersal_tween.tween_callback(dispersal_orb.queue_free)

# Signal handlers
func _on_player_detected(body: Node3D):
	if body.is_in_group("player"):
		player_target = body
		print("Flame Spirit senses living essence - beginning spiritual assault")

func _on_player_lost(body: Node3D):
	if body == player_target:
		player_target = null

func _on_phase_ended():
	exit_phase_mode()

func _on_ability_cooldown_finished():
	# Ready for next special ability
	pass

func _on_flame_burst_hit(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		body.take_damage(flame_damage * 1.5, "fire")  # Burst does extra damage
		print("Flame burst engulfs player for ", flame_damage * 1.5, " damage!")

# Public API
func get_spirit_info() -> Dictionary:
	return {
		"health": current_health,
		"max_health": max_health,
		"is_phased": is_phased,
		"is_dashing": is_dashing,
		"is_possessing": is_possessing,
		"current_pattern": current_pattern,
		"flame_trails": flame_trails.size()
	}

func force_phase_mode():
	enter_phase_mode()

func set_flame_intensity(intensity: float):
	flame_trail_intensity = intensity
	if spirit_light:
		spirit_light.light_energy = 1.5 * intensity