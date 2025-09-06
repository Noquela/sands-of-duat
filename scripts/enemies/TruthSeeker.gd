extends CharacterBody3D
class_name TruthSeeker

signal truth_seeker_defeated()
signal truth_probe_cast(target: Node3D)
signal revelation_triggered(truth_revealed: String)
signal mind_reading_started(target: Node3D)

@export_group("Truth Seeker Stats")
@export var max_health: int = 180
@export var movement_speed: float = 6.0
@export var probe_speed: float = 15.0
@export var truth_damage: int = 35
@export var mind_reading_range: float = 12.0
@export var detection_range: float = 18.0

@export_group("Truth Abilities")
@export var truth_probe_range: float = 20.0
@export var revelation_radius: float = 8.0
@export var mind_reading_duration: float = 4.0
@export var levitation_height: float = 3.0

# Node references
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var detection_area: Area3D = $DetectionArea
@onready var ability_timer: Timer = $AbilityTimer
@onready var probe_timer: Timer = $ProbeTimer
@onready var truth_particles: GPUParticles3D = $TruthParticles
@onready var eye_light: SpotLight3D = $EyeLight

# Combat state
var current_health: int
var player_target: Node3D
var is_probing: bool = false
var is_mind_reading: bool = false
var is_levitating: bool = true
var hovering_offset: float = 0.0

# Truth-seeking abilities
var truth_detection_active: bool = true
var player_lies_detected: int = 0
var player_truths_detected: int = 0
var current_truth_level: String = "unknown"
var revealed_secrets: Array[String] = []

# Mystical third eye
var third_eye: Node3D
var truth_crystal: Node3D

func _ready():
	setup_truth_seeker()
	create_seeker_appearance()
	create_mystical_third_eye()
	setup_truth_systems()
	connect_signals()

func setup_truth_seeker():
	current_health = max_health
	add_to_group("judgment_hall_enemies")
	add_to_group("truth_seekers")
	add_to_group("mystical_enemies")
	
	# Floating physics (levitates above ground)
	up_direction = Vector3.UP
	floor_stop_on_slope = false

func create_seeker_appearance():
	# Main body (mystical floating monk-like figure)
	var seeker_mesh = CapsuleMesh.new()
	seeker_mesh.radius = 0.8
	seeker_mesh.height = 2.5
	mesh_instance.mesh = seeker_mesh
	
	# Truth seeker material (ethereal blue-white)
	var seeker_material = StandardMaterial3D.new()
	seeker_material.albedo_color = Color(0.7, 0.9, 1.0, 0.9)      # Ethereal blue-white
	seeker_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	seeker_material.emission_enabled = true
	seeker_material.emission = Color(0.8, 1.0, 1.0, 1.0)          # Truth light
	seeker_material.metallic = 0.0
	seeker_material.roughness = 0.3
	seeker_material.rim_enabled = true
	seeker_material.rim = Color(1.0, 1.0, 1.0, 1.0)              # Mystical rim
	mesh_instance.material_override = seeker_material
	
	# Collision shape
	var capsule_shape = CapsuleShape3D.new()
	capsule_shape.radius = 0.8
	capsule_shape.height = 2.5
	collision_shape.shape = capsule_shape
	
	# Add mystical robes
	create_mystical_robes()

func create_mystical_robes():
	var robes = MeshInstance3D.new()
	robes.name = "MysticalRobes"
	add_child(robes)
	
	# Flowing robe shape
	var robe_mesh = CylinderMesh.new()
	robe_mesh.radius_top = 0.4
	robe_mesh.radius_bottom = 1.2
	robe_mesh.height = 1.8
	robes.mesh = robe_mesh
	robes.position = Vector3(0, -0.3, 0)
	
	# Robe material - deep blue with truth patterns
	var robe_material = StandardMaterial3D.new()
	robe_material.albedo_color = Color(0.2, 0.4, 0.8, 0.8)
	robe_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	robe_material.emission_enabled = true
	robe_material.emission = Color(0.3, 0.6, 1.0, 1.0)
	robe_material.metallic = 0.1
	robe_material.roughness = 0.6
	robes.material_override = robe_material
	
	# Add hood
	create_mystical_hood()

func create_mystical_hood():
	var hood = MeshInstance3D.new()
	hood.name = "MysticalHood"
	add_child(hood)
	
	var hood_mesh = SphereMesh.new()
	hood_mesh.radius = 0.9
	hood.mesh = hood_mesh
	hood.position = Vector3(0, 1.0, 0)
	
	# Hood material - darker mystical blue
	var hood_material = StandardMaterial3D.new()
	hood_material.albedo_color = Color(0.1, 0.3, 0.7, 0.9)
	hood_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hood_material.emission_enabled = true
	hood_material.emission = Color(0.2, 0.5, 0.9, 1.0)
	hood.material_override = hood_material

func create_mystical_third_eye():
	third_eye = MeshInstance3D.new()
	third_eye.name = "ThirdEye"
	add_child(third_eye)
	
	# Third eye sphere (mystical all-seeing eye)
	var eye_mesh = SphereMesh.new()
	eye_mesh.radius = 0.25
	third_eye.mesh = eye_mesh
	third_eye.position = Vector3(0, 1.5, 0.8)
	
	# Third eye material - brilliant truth-seeing
	var eye_material = StandardMaterial3D.new()
	eye_material.albedo_color = Color(1.0, 1.0, 0.9, 1.0)
	eye_material.emission_enabled = true
	eye_material.emission = Color(1.0, 0.9, 0.7, 1.0)          # Golden truth light
	eye_material.metallic = 0.3
	eye_material.roughness = 0.0
	eye_material.grow_amount = 0.1                             # Slight glow effect
	third_eye.material_override = eye_material
	
	# Add pupil
	create_truth_pupil()
	
	# Create floating truth crystal
	create_truth_crystal()

func create_truth_pupil():
	var pupil = MeshInstance3D.new()
	pupil.name = "TruthPupil"
	third_eye.add_child(pupil)
	
	var pupil_mesh = SphereMesh.new()
	pupil_mesh.radius = 0.15
	pupil.mesh = pupil_mesh
	pupil.position = Vector3(0, 0, 0.1)
	
	# Pupil material - deep truth-seeing void
	var pupil_material = StandardMaterial3D.new()
	pupil_material.albedo_color = Color(0.0, 0.0, 0.2, 1.0)    # Deep mystical blue
	pupil_material.emission_enabled = true
	pupil_material.emission = Color(0.2, 0.4, 1.0, 1.0)
	pupil.material_override = pupil_material

func create_truth_crystal():
	truth_crystal = MeshInstance3D.new()
	truth_crystal.name = "TruthCrystal"
	add_child(truth_crystal)
	
	# Floating crystal that orbits the seeker
	var crystal_mesh = PrismMesh.new()
	crystal_mesh.size = Vector3(0.4, 0.8, 0.4)
	truth_crystal.mesh = crystal_mesh
	truth_crystal.position = Vector3(2.0, 2.0, 0)
	
	# Crystal material - pure truth essence
	var crystal_material = StandardMaterial3D.new()
	crystal_material.albedo_color = Color(0.9, 1.0, 1.0, 0.8)
	crystal_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crystal_material.emission_enabled = true
	crystal_material.emission = Color(1.0, 1.0, 0.8, 1.0)
	crystal_material.metallic = 0.0
	crystal_material.roughness = 0.0
	crystal_material.refraction_enabled = true
	truth_crystal.material_override = crystal_material
	
	# Start crystal orbit animation
	animate_crystal_orbit()

func animate_crystal_orbit():
	var orbit_tween = create_tween()
	orbit_tween.set_loops()
	orbit_tween.tween_method(update_crystal_orbit, 0.0, TAU, 8.0)

func update_crystal_orbit(angle: float):
	if truth_crystal:
		var orbit_radius = 2.5
		truth_crystal.position = Vector3(
			cos(angle) * orbit_radius,
			2.0 + sin(angle * 2) * 0.5,  # Up and down bobbing
			sin(angle) * orbit_radius
		)
		truth_crystal.rotation.y = angle

func setup_truth_systems():
	# Detection area
	var detection_collision = CollisionShape3D.new()
	var detection_shape = SphereShape3D.new()
	detection_shape.radius = detection_range
	detection_collision.shape = detection_shape
	detection_area.add_child(detection_collision)
	
	# Ability timers
	ability_timer.wait_time = 4.0  # Between special abilities
	ability_timer.one_shot = true
	probe_timer.wait_time = 2.5    # Truth probe cooldown
	probe_timer.one_shot = true
	
	# Truth particles
	if truth_particles:
		truth_particles.emitting = true
		truth_particles.amount = 60
		# Configure mystical truth particles (floating symbols, eyes)
	
	# Eye light (truth-revealing spotlight)
	if eye_light:
		eye_light.light_energy = 2.0
		eye_light.light_color = Color(0.9, 1.0, 1.0, 1.0)
		eye_light.spot_range = mind_reading_range
		eye_light.spot_angle = 45.0

func connect_signals():
	detection_area.body_entered.connect(_on_player_detected)
	detection_area.body_exited.connect(_on_player_lost)
	ability_timer.timeout.connect(_on_ability_cooldown_finished)
	probe_timer.timeout.connect(_on_probe_cooldown_finished)

func _physics_process(delta):
	if not is_instance_valid(player_target):
		search_for_player()
		return
	
	update_hovering_movement(delta)
	update_truth_detection(delta)
	update_seeker_behavior(delta)
	move_and_slide()

func search_for_player():
	player_target = get_tree().get_first_node_in_group("player")

func update_hovering_movement(delta: float):
	# Mystical levitation - float up and down
	hovering_offset += delta * 2.0
	var hover_y = sin(hovering_offset) * 0.5
	
	# Apply levitation offset
	if is_levitating:
		global_position.y += hover_y * delta

func update_truth_detection(delta: float):
	if not player_target or not truth_detection_active:
		return
	
	# Constantly scan player for truth vs lies
	var judgment_hall = get_tree().get_first_node_in_group("judgment_hall_biome")
	if judgment_hall and judgment_hall.has_method("get_player_truth_stats"):
		var truth_stats = judgment_hall.get_player_truth_stats()
		player_truths_detected = truth_stats.get("truths", 0)
		player_lies_detected = truth_stats.get("lies", 0)
		
		# Determine current truth level
		if player_truths_detected > player_lies_detected * 2:
			current_truth_level = "truthful"
		elif player_lies_detected > player_truths_detected * 2:
			current_truth_level = "deceptive" 
		else:
			current_truth_level = "mixed"
	
	# Visual feedback based on truth detection
	update_truth_seeker_appearance()

func update_truth_seeker_appearance():
	match current_truth_level:
		"truthful":
			# Brighter, more serene appearance for truthful players
			if eye_light:
				eye_light.light_color = Color(0.8, 1.0, 0.9, 1.0)  # Gentle green-white
				eye_light.light_energy = 1.8
		"deceptive":
			# Intense, probing appearance for deceptive players
			if eye_light:
				eye_light.light_color = Color(1.0, 0.8, 0.6, 1.0)  # Piercing amber
				eye_light.light_energy = 2.5
		"mixed":
			# Neutral investigative appearance
			if eye_light:
				eye_light.light_color = Color(0.9, 1.0, 1.0, 1.0)  # Pure white
				eye_light.light_energy = 2.0

func update_seeker_behavior(delta: float):
	if not player_target:
		return
	
	var distance_to_player = global_position.distance_to(player_target.global_position)
	
	# Choose action based on distance and truth detection
	if distance_to_player <= mind_reading_range and can_start_mind_reading():
		start_mind_reading()
	elif distance_to_player <= truth_probe_range and can_cast_truth_probe():
		cast_truth_probe()
	elif distance_to_player <= revelation_radius and can_trigger_revelation():
		trigger_revelation()
	else:
		levitate_toward_player(delta)

func levitate_toward_player(delta: float):
	# Float toward player with mystical movement
	var direction = (player_target.global_position - global_position).normalized()
	velocity = direction * movement_speed
	
	# Maintain levitation height
	var target_y = player_target.global_position.y + levitation_height
	velocity.y = (target_y - global_position.y) * 2.0
	
	# Face player with third eye
	look_at(player_target.global_position, Vector3.UP)
	
	# Point third eye at player
	if third_eye:
		third_eye.look_at(player_target.global_position, Vector3.UP)

func cast_truth_probe():
	if not can_cast_truth_probe() or not player_target:
		return
	
	is_probing = true
	velocity = Vector3.ZERO  # Float still while casting
	
	# Focus third eye on player
	if third_eye:
		third_eye.look_at(player_target.global_position, Vector3.UP)
	
	# Create truth probe projectile
	create_truth_probe()
	
	probe_timer.start()
	truth_probe_cast.emit(player_target)
	print("Truth Seeker casts Truth Probe - seeking hidden truths!")

func create_truth_probe():
	var probe = Area3D.new()
	probe.name = "TruthProbe"
	probe.position = global_position + Vector3(0, 1.5, 0)
	get_parent().add_child(probe)
	
	# Probe visual (mystical searching orb)
	var probe_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.6
	probe_mesh.mesh = mesh
	probe.add_child(probe_mesh)
	
	# Truth probe material
	var probe_material = StandardMaterial3D.new()
	probe_material.albedo_color = Color(0.8, 1.0, 1.0, 0.8)
	probe_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	probe_material.emission_enabled = true
	probe_material.emission = Color(1.0, 1.0, 0.9, 1.0)
	probe_material.grow_amount = 0.2
	probe_mesh.material_override = probe_material
	
	# Probe collision
	var probe_collision = CollisionShape3D.new()
	var probe_shape = SphereShape3D.new()
	probe_shape.radius = 0.8
	probe_collision.shape = probe_shape
	probe.add_child(probe_collision)
	
	# Launch probe toward player
	var probe_direction = (player_target.global_position - probe.global_position).normalized()
	
	# Probe movement
	var probe_body = RigidBody3D.new()
	probe_body.name = "ProbeBody"
	probe_body.position = probe.global_position
	probe_body.linear_velocity = probe_direction * probe_speed
	get_parent().add_child(probe_body)
	
	# Move visual to rigid body
	probe.reparent(probe_body)
	probe.position = Vector3.ZERO
	
	# Probe hit detection
	probe.body_entered.connect(_on_truth_probe_hit)
	
	# Auto-remove after travel time
	var probe_timer = Timer.new()
	probe_timer.wait_time = 3.0
	probe_timer.timeout.connect(probe_body.queue_free)
	probe_timer.one_shot = true
	probe_timer.autostart = true
	probe_body.add_child(probe_timer)

func start_mind_reading():
	if not can_start_mind_reading() or not player_target:
		return
	
	is_mind_reading = true
	velocity = Vector3.ZERO  # Focus completely on mind reading
	
	# Face player directly
	look_at(player_target.global_position, Vector3.UP)
	
	# Create mind reading beam
	create_mind_reading_beam()
	
	ability_timer.start()
	mind_reading_started.emit(player_target)
	
	# Continue mind reading for duration
	var reading_timer = Timer.new()
	reading_timer.wait_time = mind_reading_duration
	reading_timer.timeout.connect(_end_mind_reading)
	reading_timer.one_shot = true
	reading_timer.autostart = true
	add_child(reading_timer)
	
	print("Truth Seeker begins mind reading - revealing hidden thoughts...")

func create_mind_reading_beam():
	var beam = Area3D.new()
	beam.name = "MindReadingBeam"
	beam.position = third_eye.global_position
	add_child(beam)
	
	# Beam from third eye to player
	var beam_direction = (player_target.global_position - third_eye.global_position).normalized()
	var beam_distance = third_eye.global_position.distance_to(player_target.global_position)
	
	# Beam visual (psychic connection)
	var beam_mesh = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.radius_top = 0.1
	mesh.radius_bottom = 0.3
	mesh.height = beam_distance
	beam_mesh.mesh = mesh
	beam_mesh.position = beam_direction * beam_distance * 0.5
	beam_mesh.look_at(third_eye.global_position + beam_direction, Vector3.UP)
	beam.add_child(beam_mesh)
	
	# Mind reading material
	var beam_material = StandardMaterial3D.new()
	beam_material.albedo_color = Color(0.9, 0.8, 1.0, 0.7)
	beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_material.emission_enabled = true
	beam_material.emission = Color(1.0, 0.9, 1.0, 1.0)      # Psychic purple-white
	beam_material.flags_use_point_size = true
	beam_mesh.material_override = beam_material
	
	# Beam collision for continuous effect
	var beam_collision = CollisionShape3D.new()
	var beam_shape = CylinderShape3D.new()
	beam_shape.radius_top = 0.2
	beam_shape.radius_bottom = 0.4
	beam_shape.height = beam_distance
	beam_collision.shape = beam_shape
	beam_collision.position = beam_direction * beam_distance * 0.5
	beam.add_child(beam_collision)
	
	# Continuous mind reading effect
	beam.body_entered.connect(_on_mind_reading_effect)
	
	# Store beam for cleanup
	set_meta("mind_reading_beam", beam)

func trigger_revelation():
	if not can_trigger_revelation() or not player_target:
		return
	
	# Create revelation burst around truth seeker
	var revelation = Area3D.new()
	revelation.name = "TruthRevelation"
	revelation.position = global_position
	get_parent().add_child(revelation)
	
	# Revelation collision
	var rev_collision = CollisionShape3D.new()
	var rev_shape = SphereShape3D.new()
	rev_shape.radius = revelation_radius
	rev_collision.shape = rev_shape
	revelation.add_child(rev_collision)
	
	# Visual revelation (expanding truth sphere)
	var rev_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = revelation_radius
	rev_mesh.mesh = mesh
	revelation.add_child(rev_mesh)
	
	# Revelation material - pure truth energy
	var rev_material = StandardMaterial3D.new()
	rev_material.albedo_color = Color(1.0, 1.0, 0.9, 0.5)
	rev_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	rev_material.emission_enabled = true
	rev_material.emission = Color(1.0, 0.95, 0.8, 1.0)
	rev_material.grow_amount = 0.3
	rev_mesh.material_override = rev_material
	
	# Apply revelation effects
	revelation.body_entered.connect(_on_revelation_triggered)
	
	# Generate specific revelation based on player's history
	var revealed_truth = generate_player_revelation()
	revealed_secrets.append(revealed_truth)
	
	revelation_triggered.emit(revealed_truth)
	
	# Animate revelation expansion and fade
	var rev_tween = create_tween()
	rev_tween.parallel().tween_property(revelation, "scale", Vector3.ZERO, 1.5)
	rev_tween.parallel().tween_property(rev_material, "albedo_color:a", 0.0, 1.5)
	rev_tween.tween_callback(revelation.queue_free)
	
	ability_timer.start()
	print("Truth Seeker triggers Revelation: ", revealed_truth)

func generate_player_revelation() -> String:
	# Generate contextual revelations based on player's journey
	var revelations = []
	
	match current_truth_level:
		"truthful":
			revelations = [
				"Your honesty illuminates the path ahead",
				"Truth flows through your actions like sacred water",
				"The gods smile upon your righteous heart",
				"Your truthful words carry divine blessing"
			]
		"deceptive":
			revelations = [
				"Your lies cast shadows upon your soul",
				"Deception chains your spirit in darkness",
				"The weight of falsehood burdens your ka",
				"Your untruths awaken divine judgment"
			]
		"mixed":
			revelations = [
				"Truth and lies war within your spirit",
				"Your path wavers between light and shadow", 
				"Balance seeks harmony in your choices",
				"The scales of Ma'at weigh your divided heart"
			]
	
	return revelations[randi() % revelations.size()]

func _end_mind_reading():
	is_mind_reading = false
	
	# Clean up mind reading beam
	var beam = get_meta("mind_reading_beam", null)
	if beam and is_instance_valid(beam):
		beam.queue_free()

func take_damage(damage: int, damage_type: String = ""):
	# Truth seekers take modified damage based on truth alignment
	var actual_damage = damage
	
	match current_truth_level:
		"truthful":
			# Reduced damage from truthful players (they don't want to harm truth)
			actual_damage = int(damage * 0.6)
		"deceptive":
			# Increased damage from deceptive players (conflict with truth)
			actual_damage = int(damage * 1.4)
	
	current_health -= actual_damage
	
	# Truth seeker damage flash
	create_truth_damage_flash()
	
	if current_health <= 0:
		die()
	else:
		# Intensify truth seeking when damaged
		if current_health < max_health * 0.5:
			enter_desperate_truth_seeking()

func create_truth_damage_flash():
	var flash_tween = create_tween()
	flash_tween.tween_property(mesh_instance, "modulate", Color(1.2, 1.2, 1.5, 1.0), 0.1)
	flash_tween.tween_property(mesh_instance, "modulate", Color.WHITE, 0.1)

func enter_desperate_truth_seeking():
	print("Truth Seeker enters desperate search - truth must be found!")
	
	# Enhanced abilities
	movement_speed *= 1.3
	mind_reading_range *= 1.2
	truth_damage = int(truth_damage * 1.2)
	
	# Visual enhancement
	if truth_particles:
		truth_particles.amount = 120
	if eye_light:
		eye_light.light_energy = 3.0

func die():
	truth_seeker_defeated.emit()
	
	# Truth revelation death effect
	create_final_truth_revelation()
	
	print("Truth Seeker dissipates - their truths remain in the ether")
	queue_free()

func create_final_truth_revelation():
	# Final revelation explosion
	var final_truth = Area3D.new()
	get_parent().add_child(final_truth)
	final_truth.position = global_position
	
	# Large truth sphere
	var truth_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 8.0
	truth_mesh.mesh = mesh
	final_truth.add_child(truth_mesh)
	
	var truth_material = StandardMaterial3D.new()
	truth_material.albedo_color = Color(1.0, 1.0, 0.95, 0.8)
	truth_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	truth_material.emission_enabled = true
	truth_material.emission = Color(1.0, 0.95, 0.85, 1.0)
	truth_mesh.material_override = truth_material
	
	# Ascension animation
	var truth_tween = create_tween()
	truth_tween.parallel().tween_property(final_truth, "scale", Vector3.ZERO, 3.0)
	truth_tween.parallel().tween_property(final_truth, "modulate:a", 0.0, 3.0)
	truth_tween.tween_callback(final_truth.queue_free)

func can_cast_truth_probe() -> bool:
	return not is_probing and probe_timer.is_stopped()

func can_start_mind_reading() -> bool:
	return not is_mind_reading and ability_timer.is_stopped()

func can_trigger_revelation() -> bool:
	return ability_timer.is_stopped()

# Signal handlers
func _on_player_detected(body: Node3D):
	if body.is_in_group("player"):
		player_target = body
		print("Truth Seeker detects subject - beginning truth analysis")

func _on_player_lost(body: Node3D):
	if body == player_target:
		player_target = null

func _on_ability_cooldown_finished():
	is_mind_reading = false

func _on_probe_cooldown_finished():
	is_probing = false

func _on_truth_probe_hit(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		var probe_damage = truth_damage
		
		# Probe damage varies by truth level
		match current_truth_level:
			"deceptive":
				probe_damage = int(probe_damage * 1.6)  # Painful truth for liars
				# Apply "truth revelation" debuff
				if body.has_method("apply_status_effect"):
					body.apply_status_effect("truth_revelation", 8.0)
			"truthful":
				probe_damage = int(probe_damage * 0.7)  # Gentle for truthful
				# Apply "truth blessing"
				if body.has_method("apply_status_effect"):
					body.apply_status_effect("truth_blessing", 5.0)
		
		body.take_damage(probe_damage, "truth_probe")
		print("Truth Probe reveals hidden aspects for ", probe_damage, " damage!")

func _on_mind_reading_effect(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		# Continuous mind reading damage
		var reading_damage = truth_damage / 4  # Damage over time
		
		# Mind reading reveals player's current thoughts/actions
		if body.has_method("apply_status_effect"):
			body.apply_status_effect("mind_read", 1.0)  # Brief effect
		
		body.take_damage(reading_damage, "mind_reading")
		
		# Reveal player's current weapon/ability usage
		reveal_player_intentions(body)

func reveal_player_intentions(player: Node3D):
	# Logic to reveal what player is about to do (weapons, abilities)
	if player.has_method("get_current_weapon"):
		var weapon = player.get_current_weapon()
		print("Truth Seeker reads mind: Player wields ", weapon)
	
	if player.has_method("get_planned_ability"):
		var ability = player.get_planned_ability()
		print("Truth Seeker reads mind: Player plans to use ", ability)

func _on_revelation_triggered(body: Node3D):
	if body == player_target:
		# Apply revelation effects based on truth level
		match current_truth_level:
			"truthful":
				# Blessing revelation for truthful players
				if body.has_method("heal"):
					body.heal(30)
				if body.has_method("apply_status_effect"):
					body.apply_status_effect("divine_insight", 10.0)
			"deceptive":
				# Punishing revelation for deceptive players
				if body.has_method("take_damage"):
					body.take_damage(50, "truth_revelation")
				if body.has_method("apply_status_effect"):
					body.apply_status_effect("exposed_lies", 10.0)
			"mixed":
				# Neutral revelation effect
				if body.has_method("apply_status_effect"):
					body.apply_status_effect("moral_clarity", 8.0)

# Public API
func get_truth_seeker_info() -> Dictionary:
	return {
		"health": current_health,
		"max_health": max_health,
		"truth_level_detected": current_truth_level,
		"truths_detected": player_truths_detected,
		"lies_detected": player_lies_detected,
		"secrets_revealed": revealed_secrets.size(),
		"is_mind_reading": is_mind_reading,
		"is_probing": is_probing
	}

func force_truth_revelation():
	trigger_revelation()

func set_truth_detection_override(truth_level: String):
	current_truth_level = truth_level
	update_truth_seeker_appearance()

func get_revealed_secrets() -> Array[String]:
	return revealed_secrets.duplicate()