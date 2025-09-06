extends CharacterBody3D
class_name Ammit

signal ammit_defeated()
signal soul_devour_phase_started()
signal judgment_chamber_activated()
signal devoured_souls_released()
signal final_judgment_begun()

@export_group("Ammit Boss Stats")
@export var max_health: int = 2400  # Massive boss health (3 phases: 800 each)
@export var movement_speed: float = 6.0
@export var charge_speed: float = 18.0
@export var soul_damage: int = 80
@export var devour_damage: int = 120
@export var detection_range: float = 30.0

@export_group("Boss Phases")
@export var phase_1_health_threshold: int = 1600  # 66% health
@export var phase_2_health_threshold: int = 800   # 33% health
@export var soul_devour_range: float = 12.0
@export var judgment_chamber_radius: float = 20.0

# Node references
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var detection_area: Area3D = $DetectionArea
@onready var phase_timer: Timer = $PhaseTimer
@onready var devour_timer: Timer = $DevourTimer
@onready var soul_particles: GPUParticles3D = $SoulParticles
@onready var judgment_light: OmniLight3D = $JudgmentLight

# Boss state
var current_health: int
var current_phase: int = 1
var player_target: Node3D
var is_devouring_souls: bool = false
var is_charging: bool = false
var judgment_chamber_active: bool = false

# Soul devourer mechanics
var devoured_souls: int = 0
var soul_energy: int = 0
var player_sins_detected: int = 0
var moral_judgment_level: String = "unknown"

# Ammit's three aspects (crocodile head, lion body, hippo hindquarters)
var crocodile_head: Node3D
var lion_body: Node3D  
var hippo_hindquarters: Node3D

# Boss abilities per phase
var abilities_phase_1: Array[String] = ["soul_bite", "judgment_roar", "sin_detection"]
var abilities_phase_2: Array[String] = ["soul_devour_aura", "false_heart_crush", "guilty_soul_hunt"]
var abilities_phase_3: Array[String] = ["final_judgment", "soul_storm", "divine_annihilation"]

func _ready():
	setup_ammit_boss()
	create_ammit_appearance()
	create_judgment_chamber()
	setup_boss_systems()
	connect_signals()

func setup_ammit_boss():
	current_health = max_health
	add_to_group("judgment_hall_bosses")
	add_to_group("soul_devourers")
	add_to_group("divine_bosses")
	add_to_group("ammit")
	
	# Boss physics (massive, intimidating presence)
	up_direction = Vector3.UP
	floor_stop_on_slope = true
	floor_max_angle = deg_to_rad(25)

func create_ammit_appearance():
	# Main boss body (composite creature - lion body base)
	var ammit_mesh = CapsuleMesh.new()
	ammit_mesh.radius = 2.5
	ammit_mesh.height = 6.0
	mesh_instance.mesh = ammit_mesh
	
	# Ammit body material (tawny lion hide)
	var body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color(0.8, 0.6, 0.3, 1.0)      # Tawny lion color
	body_material.emission_enabled = true
	body_material.emission = Color(0.9, 0.7, 0.4, 1.0)         # Warm predator glow
	body_material.metallic = 0.1
	body_material.roughness = 0.8                               # Fur-like texture
	body_material.rim_enabled = true
	body_material.rim = Color(1.0, 0.8, 0.5, 1.0)             # Divine authority rim
	mesh_instance.material_override = body_material
	
	# Collision shape (massive boss)
	var capsule_shape = CapsuleShape3D.new()
	capsule_shape.radius = 2.5
	capsule_shape.height = 6.0
	collision_shape.shape = capsule_shape
	
	# Create Ammit's three divine aspects
	create_crocodile_head()
	create_lion_body()
	create_hippo_hindquarters()

func create_crocodile_head():
	crocodile_head = MeshInstance3D.new()
	crocodile_head.name = "CrocodileHead"
	add_child(crocodile_head)
	
	# Massive crocodile head (soul-devouring maw)
	var head_mesh = BoxMesh.new()  # Stylized crocodile snout
	head_mesh.size = Vector3(4.0, 2.0, 6.0)
	crocodile_head.mesh = head_mesh
	crocodile_head.position = Vector3(0, 2.5, 3.5)
	
	# Crocodile head material (dark green, ancient)
	var head_material = StandardMaterial3D.new()
	head_material.albedo_color = Color(0.2, 0.4, 0.2, 1.0)      # Dark swamp green
	head_material.emission_enabled = true
	head_material.emission = Color(0.3, 0.6, 0.3, 1.0)
	head_material.metallic = 0.3
	head_material.roughness = 0.7
	crocodile_head.material_override = head_material
	
	# Add crocodile teeth and eyes
	create_crocodile_teeth()
	create_soul_devouring_eyes()

func create_crocodile_teeth():
	# Upper jaw teeth
	for i in range(8):
		var tooth = MeshInstance3D.new()
		tooth.name = "Tooth" + str(i)
		crocodile_head.add_child(tooth)
		
		var tooth_mesh = CylinderMesh.new()
		tooth_mesh.radius_top = 0.1
		tooth_mesh.radius_bottom = 0.2
		tooth_mesh.height = 0.8
		tooth.mesh = tooth_mesh
		tooth.position = Vector3(-1.5 + i * 0.4, -0.5, 2.5)
		tooth.rotation_degrees = Vector3(15, 0, 0)
		
		# Tooth material (ivory with soul stains)
		var tooth_material = StandardMaterial3D.new()
		tooth_material.albedo_color = Color(0.9, 0.8, 0.6, 1.0)
		tooth_material.emission_enabled = true
		tooth_material.emission = Color(0.8, 0.6, 0.4, 1.0)
		tooth.material_override = tooth_material

func create_soul_devouring_eyes():
	# Left eye
	var left_eye = MeshInstance3D.new()
	left_eye.name = "LeftEye"
	crocodile_head.add_child(left_eye)
	
	var eye_mesh = SphereMesh.new()
	eye_mesh.radius = 0.6
	left_eye.mesh = eye_mesh
	left_eye.position = Vector3(-1.2, 0.5, 1.5)
	
	# Right eye
	var right_eye = MeshInstance3D.new()
	right_eye.name = "RightEye"
	crocodile_head.add_child(right_eye)
	right_eye.mesh = eye_mesh
	right_eye.position = Vector3(1.2, 0.5, 1.5)
	
	# Soul-seeing eye material
	var eye_material = StandardMaterial3D.new()
	eye_material.albedo_color = Color(1.0, 0.3, 0.1, 1.0)       # Burning soul-sight
	eye_material.emission_enabled = true
	eye_material.emission = Color(1.0, 0.4, 0.2, 1.0)
	eye_material.metallic = 0.0
	eye_material.roughness = 0.1
	left_eye.material_override = eye_material
	right_eye.material_override = eye_material
	
	# Add soul-detecting pupils
	create_soul_pupils(left_eye)
	create_soul_pupils(right_eye)

func create_soul_pupils(eye: MeshInstance3D):
	var pupil = MeshInstance3D.new()
	pupil.name = "SoulPupil"
	eye.add_child(pupil)
	
	var pupil_mesh = SphereMesh.new()
	pupil_mesh.radius = 0.3
	pupil.mesh = pupil_mesh
	pupil.position = Vector3(0, 0, 0.4)
	
	# Soul-detecting pupil material
	var pupil_material = StandardMaterial3D.new()
	pupil_material.albedo_color = Color(0.0, 0.0, 0.0, 1.0)     # Void that sees souls
	pupil_material.emission_enabled = true
	pupil_material.emission = Color(0.5, 0.1, 0.0, 1.0)
	pupil.material_override = pupil_material

func create_lion_body():
	lion_body = MeshInstance3D.new()
	lion_body.name = "LionBody"
	add_child(lion_body)
	
	# Lion mane (divine authority)
	var mane_mesh = SphereMesh.new()
	mane_mesh.radius = 3.0
	lion_body.mesh = mane_mesh
	lion_body.position = Vector3(0, 1.0, 0)
	
	# Mane material (golden divine majesty)
	var mane_material = StandardMaterial3D.new()
	mane_material.albedo_color = Color(0.9, 0.7, 0.3, 0.8)
	mane_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mane_material.emission_enabled = true
	mane_material.emission = Color(1.0, 0.8, 0.4, 1.0)
	mane_material.grow_amount = 0.3                             # Fluffy mane effect
	lion_body.material_override = mane_material
	
	# Add lion claws
	create_lion_claws()

func create_lion_claws():
	# Front claws
	for i in range(4):
		var claw = MeshInstance3D.new()
		claw.name = "Claw" + str(i)
		lion_body.add_child(claw)
		
		var claw_mesh = CylinderMesh.new()
		claw_mesh.radius_top = 0.1
		claw_mesh.radius_bottom = 0.3
		claw_mesh.height = 1.5
		claw.mesh = claw_mesh
		
		# Position claws at corners
		var angle = i * PI / 2
		claw.position = Vector3(cos(angle) * 2.2, -2.0, sin(angle) * 2.2)
		claw.rotation_degrees = Vector3(30, rad_to_deg(angle), 0)
		
		# Claw material (divine justice claws)
		var claw_material = StandardMaterial3D.new()
		claw_material.albedo_color = Color(0.8, 0.8, 0.9, 1.0)
		claw_material.emission_enabled = true
		claw_material.emission = Color(0.9, 0.9, 1.0, 1.0)
		claw_material.metallic = 0.8
		claw_material.roughness = 0.2
		claw.material_override = claw_material

func create_hippo_hindquarters():
	hippo_hindquarters = MeshInstance3D.new()
	hippo_hindquarters.name = "HippoHindquarters"
	add_child(hippo_hindquarters)
	
	# Massive hippo rear (stability and power)
	var hippo_mesh = BoxMesh.new()
	hippo_mesh.size = Vector3(4.0, 3.0, 4.0)
	hippo_hindquarters.mesh = hippo_mesh
	hippo_hindquarters.position = Vector3(0, -1.0, -3.0)
	
	# Hippo material (dark gray, massive)
	var hippo_material = StandardMaterial3D.new()
	hippo_material.albedo_color = Color(0.3, 0.3, 0.4, 1.0)     # Dark gray hide
	hippo_material.emission_enabled = true
	hippo_material.emission = Color(0.4, 0.4, 0.5, 1.0)
	hippo_material.metallic = 0.2
	hippo_material.roughness = 0.9
	hippo_hindquarters.material_override = hippo_material
	
	# Add hippo tail (divine authority whip)
	create_divine_tail()

func create_divine_tail():
	var tail = MeshInstance3D.new()
	tail.name = "DivineTail"
	hippo_hindquarters.add_child(tail)
	
	var tail_mesh = CylinderMesh.new()
	tail_mesh.radius_top = 0.3
	tail_mesh.radius_bottom = 0.1
	tail_mesh.height = 2.5
	tail.mesh = tail_mesh
	tail.position = Vector3(0, 1.0, -2.5)
	tail.rotation_degrees = Vector3(45, 0, 0)
	
	# Tail material (divine whip)
	var tail_material = StandardMaterial3D.new()
	tail_material.albedo_color = Color(0.6, 0.4, 0.2, 1.0)
	tail_material.emission_enabled = true
	tail_material.emission = Color(0.8, 0.6, 0.3, 1.0)
	tail.material_override = tail_material

func create_judgment_chamber():
	# Judgment chamber forms around Ammit during boss fight
	# This is created dynamically when combat starts
	pass

func setup_boss_systems():
	# Detection area (massive boss presence)
	var detection_collision = CollisionShape3D.new()
	var detection_shape = SphereShape3D.new()
	detection_shape.radius = detection_range
	detection_collision.shape = detection_shape
	detection_area.add_child(detection_collision)
	
	# Boss ability timers
	phase_timer.wait_time = 4.0   # Between phase abilities
	phase_timer.one_shot = true
	devour_timer.wait_time = 8.0  # Soul devour cooldown
	devour_timer.one_shot = true
	
	# Soul particles (devoured souls swirling around Ammit)
	if soul_particles:
		soul_particles.emitting = true
		soul_particles.amount = 150
		# Configure soul particle effects (ghostly wisps, screaming faces)
	
	# Judgment light (divine authority)
	if judgment_light:
		judgment_light.light_energy = 3.0
		judgment_light.light_color = Color(1.0, 0.7, 0.3, 1.0)  # Divine judgment light
		judgment_light.omni_range = judgment_chamber_radius

func connect_signals():
	detection_area.body_entered.connect(_on_player_detected)
	detection_area.body_exited.connect(_on_player_lost)
	phase_timer.timeout.connect(_on_phase_ability_ready)
	devour_timer.timeout.connect(_on_devour_cooldown_finished)

func _physics_process(delta):
	if not is_instance_valid(player_target):
		search_for_player()
		return
	
	update_boss_behavior(delta)
	update_phase_transitions()
	move_and_slide()

func search_for_player():
	player_target = get_tree().get_first_node_in_group("player")

func update_boss_behavior(delta: float):
	if not player_target:
		return
	
	# Behavior changes dramatically per phase
	match current_phase:
		1:
			execute_phase_1_behavior(delta)
		2:
			execute_phase_2_behavior(delta)
		3:
			execute_phase_3_behavior(delta)

func execute_phase_1_behavior(delta: float):
	# Phase 1: Aggressive predator - soul bite, judgment roar, sin detection
	var distance_to_player = global_position.distance_to(player_target.global_position)
	
	if distance_to_player <= soul_devour_range and can_use_soul_bite():
		perform_soul_bite()
	elif can_use_judgment_roar():
		execute_judgment_roar()
	elif can_use_sin_detection():
		activate_sin_detection()
	else:
		stalk_player_menacingly(delta)

func execute_phase_2_behavior(delta: float):
	# Phase 2: Soul devourer - soul devour aura, false heart crush, guilty soul hunt
	var distance_to_player = global_position.distance_to(player_target.global_position)
	
	if can_use_soul_devour_aura():
		activate_soul_devour_aura()
	elif distance_to_player <= 8.0 and can_use_false_heart_crush():
		perform_false_heart_crush()
	elif can_use_guilty_soul_hunt():
		begin_guilty_soul_hunt()
	else:
		circle_for_soul_consumption(delta)

func execute_phase_3_behavior(delta: float):
	# Phase 3: Final judgment - final judgment, soul storm, divine annihilation
	if not judgment_chamber_active:
		activate_judgment_chamber()
	
	if can_use_final_judgment():
		cast_final_judgment()
	elif can_use_soul_storm():
		unleash_soul_storm()
	elif can_use_divine_annihilation():
		execute_divine_annihilation()
	else:
		float_with_divine_authority(delta)

func stalk_player_menacingly(delta: float):
	# Phase 1 movement: Predatory stalking
	var direction = (player_target.global_position - global_position).normalized()
	velocity = direction * movement_speed
	
	# Face player with crocodile head
	look_at(player_target.global_position, Vector3.UP)
	
	# Rotate crocodile head to track player
	if crocodile_head:
		crocodile_head.look_at(player_target.global_position, Vector3.UP)

func circle_for_soul_consumption(delta: float):
	# Phase 2 movement: Circling for optimal soul consumption
	var player_pos = player_target.global_position
	var circle_center = player_pos
	var circle_radius = 10.0
	
	# Calculate circular movement
	var angle = atan2(global_position.z - player_pos.z, global_position.x - player_pos.x)
	angle += delta * 1.2  # Circle speed
	
	var target_position = circle_center + Vector3(cos(angle), 0, sin(angle)) * circle_radius
	var direction = (target_position - global_position).normalized()
	velocity = direction * movement_speed * 1.2
	
	# Always face player while circling
	look_at(player_target.global_position, Vector3.UP)

func float_with_divine_authority(delta: float):
	# Phase 3 movement: Floating divine presence
	var target_height = player_target.global_position.y + 5.0
	var height_difference = target_height - global_position.y
	
	velocity.y = height_difference * 2.0
	
	# Slow, menacing approach
	var horizontal_direction = Vector3(
		player_target.global_position.x - global_position.x,
		0,
		player_target.global_position.z - global_position.z
	).normalized()
	
	velocity.x = horizontal_direction.x * movement_speed * 0.6
	velocity.z = horizontal_direction.z * movement_speed * 0.6
	
	# Face player with divine authority
	look_at(player_target.global_position, Vector3.UP)

func update_phase_transitions():
	# Check for phase transitions based on health
	if current_phase == 1 and current_health <= phase_1_health_threshold:
		transition_to_phase_2()
	elif current_phase == 2 and current_health <= phase_2_health_threshold:
		transition_to_phase_3()

func transition_to_phase_2():
	current_phase = 2
	soul_devour_phase_started.emit()
	
	# Visual transition
	create_phase_transition_effect()
	
	# Enhanced stats for phase 2
	movement_speed *= 1.3
	soul_damage = int(soul_damage * 1.2)
	
	print("Ammit enters Soul Devourer Phase - Hunger for guilty souls awakens!")
	
	# Phase 2 visual changes
	if soul_particles:
		soul_particles.amount = 250
	if judgment_light:
		judgment_light.light_color = Color(1.0, 0.5, 0.2, 1.0)  # Hungrier light

func transition_to_phase_3():
	current_phase = 3
	final_judgment_begun.emit()
	
	# Massive visual transition
	create_phase_transition_effect()
	
	# Final phase enhancements
	movement_speed *= 0.8    # Slower but more powerful
	soul_damage = int(soul_damage * 1.8)
	devour_damage = int(devour_damage * 1.6)
	
	print("Ammit begins Final Judgment - Divine annihilation approaches!")
	
	# Phase 3 visual changes
	if soul_particles:
		soul_particles.amount = 400
	if judgment_light:
		judgment_light.light_energy = 5.0
		judgment_light.light_color = Color(1.0, 0.3, 0.1, 1.0)  # Final judgment light

func create_phase_transition_effect():
	# Dramatic phase transition with soul energy burst
	var transition = Area3D.new()
	transition.name = "PhaseTransition"
	transition.position = global_position
	get_parent().add_child(transition)
	
	# Massive soul energy explosion
	var explosion_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 15.0
	explosion_mesh.mesh = mesh
	transition.add_child(explosion_mesh)
	
	# Transition material
	var transition_material = StandardMaterial3D.new()
	transition_material.albedo_color = Color(1.0, 0.6, 0.3, 0.8)
	transition_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	transition_material.emission_enabled = true
	transition_material.emission = Color(1.0, 0.4, 0.2, 1.0)
	explosion_mesh.material_override = transition_material
	
	# Transition animation
	var transition_tween = create_tween()
	transition_tween.parallel().tween_property(transition, "scale", Vector3.ZERO, 2.0)
	transition_tween.parallel().tween_property(transition_material, "albedo_color:a", 0.0, 2.0)
	transition_tween.tween_callback(transition.queue_free)

# Phase 1 Abilities
func perform_soul_bite():
	if not can_use_soul_bite() or not player_target:
		return
	
	print("Ammit performs Soul Bite - the crocodile maw seeks guilty souls!")
	
	# Charge forward with massive bite attack
	is_charging = true
	var bite_direction = (player_target.global_position - global_position).normalized()
	velocity = bite_direction * charge_speed
	
	# Create bite attack area
	var bite_area = Area3D.new()
	bite_area.name = "SoulBite"
	bite_area.position = global_position + bite_direction * 4.0
	get_parent().add_child(bite_area)
	
	# Bite collision (cone-shaped)
	var bite_collision = CollisionShape3D.new()
	var bite_shape = BoxShape3D.new()
	bite_shape.size = Vector3(6.0, 4.0, 8.0)
	bite_collision.shape = bite_shape
	bite_area.add_child(bite_collision)
	
	# Visual bite effect
	var bite_mesh = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(6.0, 4.0, 8.0)
	bite_mesh.mesh = mesh
	bite_area.add_child(bite_mesh)
	
	# Bite material (soul-consuming maw)
	var bite_material = StandardMaterial3D.new()
	bite_material.albedo_color = Color(0.3, 0.6, 0.3, 0.7)
	bite_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bite_material.emission_enabled = true
	bite_material.emission = Color(0.4, 0.8, 0.4, 1.0)
	bite_mesh.material_override = bite_material
	
	# Damage detection
	bite_area.body_entered.connect(_on_soul_bite_hit)
	
	# End charge after duration
	var charge_timer = Timer.new()
	charge_timer.wait_time = 1.5
	charge_timer.timeout.connect(_end_soul_bite_charge.bind(bite_area))
	charge_timer.one_shot = true
	charge_timer.autostart = true
	add_child(charge_timer)
	
	phase_timer.start()

func execute_judgment_roar():
	if not can_use_judgment_roar():
		return
	
	print("Ammit unleashes Judgment Roar - divine authority shakes the hall!")
	
	velocity = Vector3.ZERO  # Stand still for roar
	
	# Create roar shockwave
	var roar = Area3D.new()
	roar.name = "JudgmentRoar"
	roar.position = global_position
	get_parent().add_child(roar)
	
	# Roar collision (expanding sphere)
	var roar_collision = CollisionShape3D.new()
	var roar_shape = SphereShape3D.new()
	roar_shape.radius = 18.0
	roar_collision.shape = roar_shape
	roar.add_child(roar_collision)
	
	# Visual roar wave
	var roar_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 18.0
	roar_mesh.mesh = mesh
	roar.add_child(roar_mesh)
	
	# Roar material
	var roar_material = StandardMaterial3D.new()
	roar_material.albedo_color = Color(1.0, 0.8, 0.4, 0.5)
	roar_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	roar_material.emission_enabled = true
	roar_material.emission = Color(1.0, 0.7, 0.3, 1.0)
	roar_mesh.material_override = roar_material
	
	# Roar effects
	roar.body_entered.connect(_on_judgment_roar_hit)
	
	# Animate roar expansion
	var roar_tween = create_tween()
	roar_tween.parallel().tween_property(roar, "scale", Vector3(1.5, 1.5, 1.5), 1.0)
	roar_tween.parallel().tween_property(roar_material, "albedo_color:a", 0.0, 1.2)
	roar_tween.tween_callback(roar.queue_free)
	
	phase_timer.start()

func activate_sin_detection():
	if not can_use_sin_detection():
		return
	
	print("Ammit activates Sin Detection - all guilty souls are revealed!")
	
	# Detect player's moral alignment and sins
	var judgment_hall = get_tree().get_first_node_in_group("judgment_hall_biome")
	if judgment_hall and judgment_hall.has_method("get_player_moral_stats"):
		var moral_stats = judgment_hall.get_player_moral_stats()
		player_sins_detected = moral_stats.get("lies", 0)
		var player_virtues = moral_stats.get("truths", 0)
		
		if player_sins_detected > player_virtues:
			moral_judgment_level = "guilty"
		elif player_virtues > player_sins_detected * 2:
			moral_judgment_level = "virtuous"
		else:
			moral_judgment_level = "neutral"
	
	# Create sin detection aura
	var detection = Area3D.new()
	detection.name = "SinDetection"
	detection.position = global_position
	add_child(detection)
	
	# Sin detection visual
	var detection_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = detection_range
	detection_mesh.mesh = mesh
	detection.add_child(detection_mesh)
	
	# Detection material (soul-piercing light)
	var detection_material = StandardMaterial3D.new()
	detection_material.albedo_color = Color(1.0, 0.9, 0.7, 0.3)
	detection_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	detection_material.emission_enabled = true
	detection_material.emission = Color(1.0, 0.8, 0.6, 1.0)
	detection_mesh.material_override = detection_material
	
	# Apply sin detection effects
	detection.body_entered.connect(_on_sin_detection_triggered)
	
	# Detection lasts for extended time
	var detection_timer = Timer.new()
	detection_timer.wait_time = 12.0
	detection_timer.timeout.connect(detection.queue_free)
	detection_timer.one_shot = true
	detection_timer.autostart = true
	detection.add_child(detection_timer)
	
	phase_timer.start()

# Phase 2 Abilities
func activate_soul_devour_aura():
	if not can_use_soul_devour_aura():
		return
	
	print("Ammit activates Soul Devour Aura - hungry for guilty souls!")
	is_devouring_souls = true
	
	# Create soul devour aura around Ammit
	var devour_aura = Area3D.new()
	devour_aura.name = "SoulDevourAura"
	devour_aura.position = global_position
	add_child(devour_aura)
	
	# Aura collision
	var aura_collision = CollisionShape3D.new()
	var aura_shape = SphereShape3D.new()
	aura_shape.radius = soul_devour_range
	aura_collision.shape = aura_shape
	devour_aura.add_child(aura_collision)
	
	# Visual devour aura (swirling souls)
	var aura_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = soul_devour_range
	aura_mesh.mesh = mesh
	devour_aura.add_child(aura_mesh)
	
	# Soul devour material
	var aura_material = StandardMaterial3D.new()
	aura_material.albedo_color = Color(0.6, 0.2, 0.8, 0.4)
	aura_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	aura_material.emission_enabled = true
	aura_material.emission = Color(0.8, 0.3, 1.0, 1.0)
	aura_mesh.material_override = aura_material
	
	# Continuous soul consumption
	devour_aura.body_entered.connect(_on_soul_devour_aura_entered)
	devour_aura.body_exited.connect(_on_soul_devour_aura_exited)
	
	# Store aura for later cleanup
	set_meta("devour_aura", devour_aura)
	
	# Aura duration
	var aura_timer = Timer.new()
	aura_timer.wait_time = 10.0
	aura_timer.timeout.connect(_end_soul_devour_aura.bind(devour_aura))
	aura_timer.one_shot = true
	aura_timer.autostart = true
	devour_aura.add_child(aura_timer)
	
	devour_timer.start()

func perform_false_heart_crush():
	if not can_use_false_heart_crush() or not player_target:
		return
	
	print("Ammit crushes false hearts - lies become chains!")
	
	# Target player's location
	var crush_position = player_target.global_position
	
	# Create false heart crush area
	var crush = Area3D.new()
	crush.name = "FalseHeartCrush"
	crush.position = crush_position
	get_parent().add_child(crush)
	
	# Crush collision
	var crush_collision = CollisionShape3D.new()
	var crush_shape = SphereShape3D.new()
	crush_shape.radius = 6.0
	crush_collision.shape = crush_shape
	crush.add_child(crush_collision)
	
	# Visual crush effect (dark energy sphere)
	var crush_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 6.0
	crush_mesh.mesh = mesh
	crush.add_child(crush_mesh)
	
	# Crush material
	var crush_material = StandardMaterial3D.new()
	crush_material.albedo_color = Color(0.2, 0.0, 0.4, 0.8)
	crush_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crush_material.emission_enabled = true
	crush_material.emission = Color(0.4, 0.1, 0.8, 1.0)
	crush_mesh.material_override = crush_material
	
	# Crush damage based on player's lies
	crush.body_entered.connect(_on_false_heart_crush_hit)
	
	# Crush animation
	var crush_tween = create_tween()
	crush_tween.parallel().tween_property(crush, "scale", Vector3(0.5, 0.5, 0.5), 1.0)
	crush_tween.parallel().tween_property(crush_material, "albedo_color:a", 0.0, 1.2)
	crush_tween.tween_callback(crush.queue_free)
	
	phase_timer.start()

func begin_guilty_soul_hunt():
	if not can_use_guilty_soul_hunt():
		return
	
	print("Ammit begins Guilty Soul Hunt - nowhere to hide from judgment!")
	
	# Lock onto player's soul
	velocity = Vector3.ZERO
	look_at(player_target.global_position, Vector3.UP)
	
	# Create soul tracking projectiles
	for i in range(3):
		create_soul_hunter_projectile(i)
	
	phase_timer.start()

func create_soul_hunter_projectile(index: int):
	var hunter = Area3D.new()
	hunter.name = "SoulHunter" + str(index)
	hunter.position = global_position + Vector3(0, 2, 0)
	get_parent().add_child(hunter)
	
	# Hunter visual (spectral hound)
	var hunter_mesh = MeshInstance3D.new()
	var mesh = CapsuleMesh.new()
	mesh.radius = 0.8
	mesh.height = 2.0
	hunter_mesh.mesh = mesh
	hunter.add_child(hunter_mesh)
	
	# Hunter material (soul-hunting specter)
	var hunter_material = StandardMaterial3D.new()
	hunter_material.albedo_color = Color(0.8, 0.4, 1.0, 0.7)
	hunter_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hunter_material.emission_enabled = true
	hunter_material.emission = Color(0.9, 0.5, 1.0, 1.0)
	hunter_mesh.material_override = hunter_material
	
	# Hunter collision
	var hunter_collision = CollisionShape3D.new()
	var hunter_shape = CapsuleShape3D.new()
	hunter_shape.radius = 1.0
	hunter_shape.height = 2.5
	hunter_collision.shape = hunter_shape
	hunter.add_child(hunter_collision)
	
	# Hunter AI - track player
	var hunter_body = RigidBody3D.new()
	hunter_body.name = "HunterBody"
	hunter_body.position = hunter.global_position
	get_parent().add_child(hunter_body)
	
	# Move hunter to rigid body
	hunter.reparent(hunter_body)
	hunter.position = Vector3.ZERO
	
	# Launch toward player with homing
	var launch_direction = (player_target.global_position - hunter_body.global_position).normalized()
	hunter_body.linear_velocity = launch_direction * 12.0
	
	# Hunter damage
	hunter.body_entered.connect(_on_soul_hunter_hit)
	
	# Hunter lifetime
	var hunter_timer = Timer.new()
	hunter_timer.wait_time = 8.0
	hunter_timer.timeout.connect(hunter_body.queue_free)
	hunter_timer.one_shot = true
	hunter_timer.autostart = true
	hunter_body.add_child(hunter_timer)

# Phase 3 Abilities  
func activate_judgment_chamber():
	if judgment_chamber_active:
		return
	
	judgment_chamber_active = true
	judgment_chamber_activated.emit()
	
	print("Ammit activates Judgment Chamber - final divine trial begins!")
	
	# Create judgment chamber arena
	var chamber = Area3D.new()
	chamber.name = "JudgmentChamber"
	chamber.position = global_position
	get_parent().add_child(chamber)
	
	# Chamber collision (arena bounds)
	var chamber_collision = CollisionShape3D.new()
	var chamber_shape = SphereShape3D.new()
	chamber_shape.radius = judgment_chamber_radius
	chamber_collision.shape = chamber_shape
	chamber.add_child(chamber_collision)
	
	# Visual chamber (divine court)
	var chamber_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = judgment_chamber_radius
	chamber_mesh.mesh = mesh
	chamber.add_child(chamber_mesh)
	
	# Chamber material (divine judgment space)
	var chamber_material = StandardMaterial3D.new()
	chamber_material.albedo_color = Color(1.0, 0.9, 0.7, 0.2)
	chamber_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	chamber_material.emission_enabled = true
	chamber_material.emission = Color(1.0, 0.8, 0.5, 1.0)
	chamber_mesh.material_override = chamber_material
	
	# Chamber effects
	chamber.body_entered.connect(_on_judgment_chamber_entered)
	chamber.body_exited.connect(_on_judgment_chamber_exited)
	
	# Store chamber reference
	set_meta("judgment_chamber", chamber)

func cast_final_judgment():
	if not can_use_final_judgment():
		return
	
	print("Ammit casts Final Judgment - souls are weighed against truth!")
	
	# Stop all movement for final judgment
	velocity = Vector3.ZERO
	
	# Create final judgment beam
	var judgment = Area3D.new()
	judgment.name = "FinalJudgment"
	judgment.position = global_position + Vector3(0, 10, 0)
	get_parent().add_child(judgment)
	
	# Judgment beam (from heavens to earth)
	var judgment_mesh = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.radius_top = 2.0
	mesh.radius_bottom = 8.0
	mesh.height = 25.0
	judgment_mesh.mesh = mesh
	judgment_mesh.position = Vector3(0, -12.5, 0)
	judgment.add_child(judgment_mesh)
	
	# Final judgment material
	var judgment_material = StandardMaterial3D.new()
	judgment_material.albedo_color = Color(1.0, 1.0, 0.9, 0.9)
	judgment_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	judgment_material.emission_enabled = true
	judgment_material.emission = Color(1.0, 0.9, 0.7, 1.0)
	judgment_mesh.material_override = judgment_material
	
	# Judgment collision
	var judgment_collision = CollisionShape3D.new()
	var judgment_shape = CylinderShape3D.new()
	judgment_shape.radius_top = 3.0
	judgment_shape.radius_bottom = 9.0
	judgment_shape.height = 25.0
	judgment_collision.shape = judgment_shape
	judgment_collision.position = Vector3(0, -12.5, 0)
	judgment.add_child(judgment_collision)
	
	# Judgment effects
	judgment.body_entered.connect(_on_final_judgment_hit)
	
	# Judgment animation
	var judgment_tween = create_tween()
	judgment_tween.parallel().tween_property(judgment, "scale", Vector3(1.2, 1.0, 1.2), 3.0)
	judgment_tween.parallel().tween_property(judgment_material, "albedo_color:a", 0.0, 4.0)
	judgment_tween.tween_callback(judgment.queue_free)
	
	phase_timer.start()

func unleash_soul_storm():
	if not can_use_soul_storm():
		return
	
	print("Ammit unleashes Soul Storm - all devoured souls cry out!")
	
	# Release all devoured souls as attacking projectiles
	for i in range(devoured_souls + 5):  # Minimum 5 souls
		create_soul_storm_projectile(i)
	
	devoured_souls_released.emit()
	devoured_souls = 0  # Reset devoured souls
	
	phase_timer.start()

func create_soul_storm_projectile(index: int):
	var soul = Area3D.new()
	soul.name = "StormSoul" + str(index)
	
	# Random position around Ammit
	var angle = randf() * TAU
	var radius = randf_range(5.0, 15.0)
	soul.position = global_position + Vector3(cos(angle) * radius, randf_range(3.0, 8.0), sin(angle) * radius)
	get_parent().add_child(soul)
	
	# Soul visual (tormented spirit)
	var soul_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.6
	soul_mesh.mesh = mesh
	soul.add_child(soul_mesh)
	
	# Soul material (tormented energy)
	var soul_material = StandardMaterial3D.new()
	soul_material.albedo_color = Color(0.9, 0.6, 1.0, 0.8)
	soul_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	soul_material.emission_enabled = true
	soul_material.emission = Color(1.0, 0.7, 1.0, 1.0)
	soul_mesh.material_override = soul_material
	
	# Soul collision
	var soul_collision = CollisionShape3D.new()
	var soul_shape = SphereShape3D.new()
	soul_shape.radius = 0.8
	soul_collision.shape = soul_shape
	soul.add_child(soul_collision)
	
	# Soul AI - attack player
	var soul_body = RigidBody3D.new()
	soul_body.name = "SoulBody"
	soul_body.position = soul.global_position
	get_parent().add_child(soul_body)
	
	# Move soul to rigid body
	soul.reparent(soul_body)
	soul.position = Vector3.ZERO
	
	# Launch toward player
	var launch_direction = (player_target.global_position - soul_body.global_position).normalized()
	soul_body.linear_velocity = launch_direction * 15.0
	
	# Soul damage
	soul.body_entered.connect(_on_soul_storm_hit)
	
	# Soul lifetime
	var soul_timer = Timer.new()
	soul_timer.wait_time = 6.0
	soul_timer.timeout.connect(soul_body.queue_free)
	soul_timer.one_shot = true
	soul_timer.autostart = true
	soul_body.add_child(soul_timer)

func execute_divine_annihilation():
	if not can_use_divine_annihilation():
		return
	
	print("Ammit executes Divine Annihilation - ultimate judgment descends!")
	
	# Stop all movement for ultimate attack
	velocity = Vector3.ZERO
	
	# Create massive annihilation area covering entire chamber
	var annihilation = Area3D.new()
	annihilation.name = "DivineAnnihilation"
	annihilation.position = global_position
	get_parent().add_child(annihilation)
	
	# Annihilation collision (entire chamber)
	var ann_collision = CollisionShape3D.new()
	var ann_shape = SphereShape3D.new()
	ann_shape.radius = judgment_chamber_radius * 1.2
	ann_collision.shape = ann_shape
	annihilation.add_child(ann_collision)
	
	# Visual annihilation (divine destruction)
	var ann_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = judgment_chamber_radius * 1.2
	ann_mesh.mesh = mesh
	annihilation.add_child(ann_mesh)
	
	# Annihilation material
	var ann_material = StandardMaterial3D.new()
	ann_material.albedo_color = Color(1.0, 0.8, 0.5, 0.9)
	ann_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ann_material.emission_enabled = true
	ann_material.emission = Color(1.0, 0.6, 0.3, 1.0)
	ann_mesh.material_override = ann_material
	
	# Annihilation effects
	annihilation.body_entered.connect(_on_divine_annihilation_hit)
	
	# Annihilation buildup and execution
	var ann_tween = create_tween()
	ann_tween.tween_property(annihilation, "scale", Vector3(0.1, 0.1, 0.1), 2.0)  # Charge up
	ann_tween.tween_property(annihilation, "scale", Vector3(1.5, 1.5, 1.5), 1.0)   # Explode
	ann_tween.tween_property(annihilation, "modulate:a", 0.0, 2.0)                 # Fade
	ann_tween.tween_callback(annihilation.queue_free)
	
	phase_timer.start()

# Ability availability checks
func can_use_soul_bite() -> bool:
	return current_phase == 1 and phase_timer.is_stopped() and not is_charging

func can_use_judgment_roar() -> bool:
	return current_phase == 1 and phase_timer.is_stopped()

func can_use_sin_detection() -> bool:
	return current_phase == 1 and phase_timer.is_stopped()

func can_use_soul_devour_aura() -> bool:
	return current_phase == 2 and devour_timer.is_stopped() and not is_devouring_souls

func can_use_false_heart_crush() -> bool:
	return current_phase == 2 and phase_timer.is_stopped()

func can_use_guilty_soul_hunt() -> bool:
	return current_phase == 2 and phase_timer.is_stopped()

func can_use_final_judgment() -> bool:
	return current_phase == 3 and phase_timer.is_stopped()

func can_use_soul_storm() -> bool:
	return current_phase == 3 and phase_timer.is_stopped() and devoured_souls > 0

func can_use_divine_annihilation() -> bool:
	return current_phase == 3 and phase_timer.is_stopped() and current_health < max_health * 0.1

func take_damage(damage: int, damage_type: String = ""):
	# Ammit takes reduced damage based on player's moral state
	var actual_damage = damage
	
	match moral_judgment_level:
		"guilty":
			# Ammit takes less damage from guilty players (they deserve punishment)
			actual_damage = int(damage * 0.7)
		"virtuous":
			# Ammit takes more damage from virtuous players (divine justice)
			actual_damage = int(damage * 1.3)
		"neutral":
			# Standard damage
			actual_damage = damage
	
	current_health -= actual_damage
	
	# Boss damage feedback
	create_boss_damage_flash()
	
	if current_health <= 0:
		die()
	else:
		# Anger increases with damage
		if randf() < 0.4:  # 40% chance to trigger retaliation
			trigger_boss_retaliation()

func create_boss_damage_flash():
	var flash_tween = create_tween()
	flash_tween.tween_property(mesh_instance, "modulate", Color(1.5, 1.2, 1.0, 1.0), 0.15)
	flash_tween.tween_property(mesh_instance, "modulate", Color.WHITE, 0.15)

func trigger_boss_retaliation():
	# Boss retaliation based on current phase
	match current_phase:
		1:
			if can_use_judgment_roar():
				execute_judgment_roar()
		2:
			if can_use_false_heart_crush():
				perform_false_heart_crush()
		3:
			if can_use_soul_storm():
				unleash_soul_storm()

func die():
	ammit_defeated.emit()
	
	# Epic boss death sequence
	create_ammit_death_sequence()
	
	print("Ammit the Soul Devourer is defeated - divine judgment has been challenged!")
	
	# Wait for death sequence then remove
	var death_timer = Timer.new()
	death_timer.wait_time = 5.0
	death_timer.timeout.connect(queue_free)
	death_timer.one_shot = true
	death_timer.autostart = true
	add_child(death_timer)

func create_ammit_death_sequence():
	# Massive soul release explosion
	var death_explosion = Area3D.new()
	death_explosion.name = "AmmitDeathExplosion"
	death_explosion.position = global_position
	get_parent().add_child(death_explosion)
	
	# Death explosion visual
	var explosion_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 25.0
	explosion_mesh.mesh = mesh
	death_explosion.add_child(explosion_mesh)
	
	var explosion_material = StandardMaterial3D.new()
	explosion_material.albedo_color = Color(1.0, 0.7, 0.4, 0.8)
	explosion_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	explosion_material.emission_enabled = true
	explosion_material.emission = Color(1.0, 0.6, 0.3, 1.0)
	explosion_mesh.material_override = explosion_material
	
	# Release all devoured souls
	for i in range(devoured_souls + 10):
		create_released_soul(i)
	
	# Death explosion animation
	var death_tween = create_tween()
	death_tween.parallel().tween_property(death_explosion, "scale", Vector3(2.0, 2.0, 2.0), 3.0)
	death_tween.parallel().tween_property(explosion_material, "albedo_color:a", 0.0, 4.0)
	death_tween.tween_callback(death_explosion.queue_free)

func create_released_soul(index: int):
	# Released souls ascend to freedom
	var soul = MeshInstance3D.new()
	soul.name = "ReleasedSoul" + str(index)
	get_parent().add_child(soul)
	soul.position = global_position + Vector3(randf_range(-5, 5), 0, randf_range(-5, 5))
	
	var soul_mesh = SphereMesh.new()
	soul_mesh.radius = 0.4
	soul.mesh = soul_mesh
	
	var soul_material = StandardMaterial3D.new()
	soul_material.albedo_color = Color(1.0, 1.0, 0.9, 0.9)
	soul_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	soul_material.emission_enabled = true
	soul_material.emission = Color(1.0, 0.95, 0.8, 1.0)
	soul.material_override = soul_material
	
	# Soul ascension animation
	var soul_tween = create_tween()
	soul_tween.parallel().tween_property(soul, "position:y", soul.position.y + 20, 4.0)
	soul_tween.parallel().tween_property(soul, "modulate:a", 0.0, 4.0)
	soul_tween.tween_callback(soul.queue_free)

# Helper functions for cleanup
func _end_soul_bite_charge(bite_area: Area3D):
	is_charging = false
	velocity = Vector3.ZERO
	if is_instance_valid(bite_area):
		bite_area.queue_free()

func _end_soul_devour_aura(aura: Area3D):
	is_devouring_souls = false
	if is_instance_valid(aura):
		aura.queue_free()

# Signal handlers
func _on_player_detected(body: Node3D):
	if body.is_in_group("player"):
		player_target = body
		print("Ammit detects a soul for judgment - the devourer awakens!")

func _on_player_lost(body: Node3D):
	if body == player_target:
		player_target = null

func _on_phase_ability_ready():
	# Phase abilities are now ready to use again
	pass

func _on_devour_cooldown_finished():
	is_devouring_souls = false

# Damage handlers for all abilities
func _on_soul_bite_hit(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		var bite_damage = devour_damage
		
		# Extra damage to guilty souls
		if moral_judgment_level == "guilty":
			bite_damage = int(bite_damage * 1.5)
		
		body.take_damage(bite_damage, "soul_bite")
		
		# Devour soul energy
		devoured_souls += 1
		soul_energy += 25
		
		print("Soul Bite devours for ", bite_damage, " damage! Souls devoured: ", devoured_souls)

func _on_judgment_roar_hit(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		var roar_damage = soul_damage
		body.take_damage(roar_damage, "judgment_roar")
		
		# Apply fear/stun effect
		if body.has_method("apply_status_effect"):
			body.apply_status_effect("divine_terror", 3.0)
		
		print("Judgment Roar terrifies for ", roar_damage, " damage!")

func _on_sin_detection_triggered(body: Node3D):
	if body == player_target:
		# Apply sin-based effects
		match moral_judgment_level:
			"guilty":
				if body.has_method("apply_status_effect"):
					body.apply_status_effect("marked_for_judgment", 15.0)
				print("Guilty soul detected - marked for divine judgment!")
			"virtuous":
				if body.has_method("apply_status_effect"):
					body.apply_status_effect("divine_protection", 10.0)
				print("Virtuous soul detected - granted temporary protection")
			"neutral":
				print("Neutral soul detected - judgment remains undecided")

func _on_soul_devour_aura_entered(body: Node3D):
	if body == player_target:
		print("Soul Devour Aura begins consuming the player's essence!")

func _on_soul_devour_aura_exited(body: Node3D):
	if body == player_target:
		print("Player escapes the Soul Devour Aura")

func _on_false_heart_crush_hit(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		var crush_damage = soul_damage * 2
		
		# Damage multiplied by player's lies
		crush_damage += player_sins_detected * 15
		
		body.take_damage(crush_damage, "false_heart_crush")
		
		# Apply guilt debuff
		if body.has_method("apply_status_effect"):
			body.apply_status_effect("crushing_guilt", 8.0)
		
		print("False Heart Crush inflicts ", crush_damage, " damage based on detected lies!")

func _on_soul_hunter_hit(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		body.take_damage(soul_damage, "soul_hunter")
		
		# Soul hunter marks target
		if body.has_method("apply_status_effect"):
			body.apply_status_effect("soul_hunted", 5.0)
		
		print("Soul Hunter strikes for ", soul_damage, " damage!")

func _on_judgment_chamber_entered(body: Node3D):
	if body == player_target:
		print("Player enters the Judgment Chamber - final trial begins!")

func _on_judgment_chamber_exited(body: Node3D):
	if body == player_target:
		print("Player cannot escape divine judgment!")
		# Pull player back into chamber
		if body.has_method("apply_knockback"):
			var pull_direction = (global_position - body.global_position).normalized()
			body.apply_knockback(pull_direction * 10.0)

func _on_final_judgment_hit(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		var judgment_damage = devour_damage * 3  # Massive damage
		
		# Judgment damage based on moral state
		match moral_judgment_level:
			"guilty":
				judgment_damage = int(judgment_damage * 2.0)  # Double damage for guilty
			"virtuous":
				judgment_damage = int(judgment_damage * 0.3)  # Reduced for virtuous
		
		body.take_damage(judgment_damage, "final_judgment")
		print("Final Judgment delivers ", judgment_damage, " divine damage!")

func _on_soul_storm_hit(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		body.take_damage(soul_damage, "soul_storm")
		print("Soul Storm soul strikes for ", soul_damage, " damage!")

func _on_divine_annihilation_hit(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		var annihilation_damage = devour_damage * 4  # Ultimate damage
		body.take_damage(annihilation_damage, "divine_annihilation")
		print("Divine Annihilation devastates for ", annihilation_damage, " damage!")

# Public API
func get_ammit_boss_info() -> Dictionary:
	return {
		"health": current_health,
		"max_health": max_health,
		"current_phase": current_phase,
		"devoured_souls": devoured_souls,
		"soul_energy": soul_energy,
		"moral_judgment": moral_judgment_level,
		"sins_detected": player_sins_detected,
		"judgment_chamber_active": judgment_chamber_active
	}

func force_phase_transition():
	if current_phase == 1:
		transition_to_phase_2()
	elif current_phase == 2:
		transition_to_phase_3()

func get_devoured_souls_count() -> int:
	return devoured_souls