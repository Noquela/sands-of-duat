extends CharacterBody3D
class_name Sekhmet

signal boss_defeated()
signal phase_transition(phase: int)
signal divine_wrath_triggered()
signal lioness_roar_unleashed(position: Vector3)
signal purification_complete()

@export_group("Sekhmet Boss Stats")
@export var max_health: int = 1800  # 3 phases: 600 HP each
@export var movement_speed: float = 8.0
@export var charge_speed: float = 18.0
@export var base_damage: int = 60
@export var divine_damage_multiplier: float = 1.5

@export_group("Boss Phases")
@export var phase_1_threshold: float = 0.66  # 66% HP
@export var phase_2_threshold: float = 0.33  # 33% HP
@export var arena_radius: float = 25.0

# Node references
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var detection_area: Area3D = $DetectionArea
@onready var phase_timer: Timer = $PhaseTimer
@onready var ability_timer: Timer = $AbilityTimer
@onready var lioness_particles: GPUParticles3D = $LionessParticles
@onready var divine_light: OmniLight3D = $DivineLight
@onready var roar_area: Area3D = $RoarArea

# Boss state
var current_health: int
var current_phase: int = 1
var player_target: Node3D
var is_transitioning: bool = false
var is_channeling: bool = false
var is_enraged: bool = false

# Phase-specific behaviors
var phase_abilities: Dictionary = {
	1: ["flame_pounce", "fire_breath", "lava_pools"],
	2: ["divine_charge", "solar_flare", "healing_flames"],
	3: ["apocalyptic_roar", "meteor_storm", "lioness_fury"]
}

# Combat mechanics
var last_ability_used: String = ""
var ability_queue: Array[String] = []
var arena_center: Vector3
var lava_hazards: Array[Area3D] = []
var divine_effects: Array[Node3D] = []

# Sekhmet-specific powers
var divine_form_active: bool = false
var purification_progress: float = 0.0
var lioness_rage_stacks: int = 0

func _ready():
	setup_sekhmet_boss()
	create_lioness_appearance()
	setup_boss_systems()
	initialize_arena()
	connect_signals()

func setup_sekhmet_boss():
	current_health = max_health
	arena_center = global_position
	add_to_group("bosses")
	add_to_group("fire_river_boss")
	add_to_group("sekhmet")
	
	# Boss physics - powerful but grounded
	up_direction = Vector3.UP
	floor_stop_on_slope = true
	floor_max_angle = deg_to_rad(30)

func create_lioness_appearance():
	# Main lioness body (feline predator form)
	var lioness_mesh = CapsuleMesh.new()
	lioness_mesh.radius = 1.8
	lioness_mesh.height = 4.5
	mesh_instance.mesh = lioness_mesh
	
	# Sekhmet material - divine lioness with solar power
	var sekhmet_material = StandardMaterial3D.new()
	sekhmet_material.albedo_color = Color(0.8, 0.4, 0.1, 1.0)    # Golden lion fur
	sekhmet_material.emission_enabled = true
	sekhmet_material.emission = Color(1.0, 0.6, 0.0, 1.0)        # Solar radiance
	sekhmet_material.metallic = 0.6
	sekhmet_material.roughness = 0.3
	sekhmet_material.rim_enabled = true
	sekhmet_material.rim = Color(1.0, 0.8, 0.2, 1.0)            # Divine aura
	mesh_instance.material_override = sekhmet_material
	
	# Collision shape
	var capsule_shape = CapsuleShape3D.new()
	capsule_shape.radius = 1.5
	capsule_shape.height = 4.5
	collision_shape.shape = capsule_shape
	
	# Add lioness features
	create_lioness_mane()
	create_divine_crown()
	create_solar_disk()

func create_lioness_mane():
	# Majestic mane around head/neck area
	var mane = MeshInstance3D.new()
	mane.name = "LionessMane"
	add_child(mane)
	
	var mane_mesh = SphereMesh.new()
	mane_mesh.radius = 2.2
	mane.mesh = mane_mesh
	mane.position = Vector3(0, 1.5, 0)  # Head area
	
	# Mane material - flowing and flame-like
	var mane_material = StandardMaterial3D.new()
	mane_material.albedo_color = Color(0.9, 0.3, 0.05, 0.8)
	mane_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mane_material.emission_enabled = true
	mane_material.emission = Color(1.0, 0.5, 0.0, 1.0)
	mane_material.rim_enabled = true
	mane_material.rim = Color(1.0, 0.7, 0.1, 1.0)
	mane.material_override = mane_material

func create_divine_crown():
	# Egyptian crown/headdress
	var crown = MeshInstance3D.new()
	crown.name = "DivineCrown"
	add_child(crown)
	
	var crown_mesh = CylinderMesh.new()
	crown_mesh.radius_top = 1.0
	crown_mesh.radius_bottom = 1.2
	crown_mesh.height = 1.5
	crown.mesh = crown_mesh
	crown.position = Vector3(0, 2.8, 0)
	
	# Divine crown material - golden with hieroglyphs
	var crown_material = StandardMaterial3D.new()
	crown_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)  # Pure gold
	crown_material.emission_enabled = true
	crown_material.emission = Color(1.0, 0.9, 0.4, 1.0)
	crown_material.metallic = 0.95
	crown_material.roughness = 0.05
	crown.material_override = crown_material

func create_solar_disk():
	# Solar disk behind head (symbol of Ra's power)
	var solar_disk = MeshInstance3D.new()
	solar_disk.name = "SolarDisk"
	add_child(solar_disk)
	
	var disk_mesh = CylinderMesh.new()
	disk_mesh.radius_top = 2.5
	disk_mesh.radius_bottom = 2.5
	disk_mesh.height = 0.2
	solar_disk.mesh = disk_mesh
	solar_disk.position = Vector3(0, 2.0, -1.5)  # Behind head
	
	# Solar disk material - brilliant sun
	var solar_material = StandardMaterial3D.new()
	solar_material.albedo_color = Color(1.0, 1.0, 0.5, 0.9)
	solar_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	solar_material.emission_enabled = true
	solar_material.emission = Color(1.0, 0.9, 0.3, 1.0)
	solar_material.grow_amount = 0.2  # Radiant glow
	solar_disk.material_override = solar_material
	
	# Rotate solar disk slowly
	var rotate_tween = create_tween()
	rotate_tween.set_loops()
	rotate_tween.tween_property(solar_disk, "rotation_degrees:y", 360, 10.0)
	rotate_tween.tween_property(solar_disk, "rotation_degrees:y", 0, 0.01)

func setup_boss_systems():
	# Detection area (entire arena)
	var detection_collision = CollisionShape3D.new()
	var detection_shape = SphereShape3D.new()
	detection_shape.radius = arena_radius * 1.2
	detection_collision.shape = detection_shape
	detection_area.add_child(detection_collision)
	
	# Roar area (fear effect)
	var roar_collision = CollisionShape3D.new()
	var roar_shape = SphereShape3D.new()
	roar_shape.radius = arena_radius
	roar_collision.shape = roar_shape
	roar_area.add_child(roar_collision)
	
	# Timers
	phase_timer.wait_time = 2.0  # Phase transition duration
	phase_timer.one_shot = true
	ability_timer.wait_time = 1.5  # Between abilities
	ability_timer.one_shot = true
	
	# Visual effects
	if lioness_particles:
		lioness_particles.emitting = true
		lioness_particles.amount = 100
	
	if divine_light:
		divine_light.light_energy = 2.0
		divine_light.light_color = Color(1.0, 0.7, 0.2, 1.0)
		divine_light.omni_range = arena_radius

func initialize_arena():
	print("Sekhmet, Lioness of Destruction, awakens in her fiery domain!")
	
	# Arena introduction sequence
	create_arena_introduction()
	
	# Initialize first phase
	begin_phase(1)

func create_arena_introduction():
	# Dramatic entrance effects
	var entrance_light = OmniLight3D.new()
	entrance_light.name = "EntranceLight"
	entrance_light.position = Vector3(0, 10, 0)
	entrance_light.light_energy = 5.0
	entrance_light.light_color = Color(1.0, 0.4, 0.0, 1.0)
	entrance_light.omni_range = arena_radius * 2
	get_parent().add_child(entrance_light)
	
	# Fade in entrance light
	var intro_tween = create_tween()
	intro_tween.tween_property(entrance_light, "light_energy", 2.0, 3.0)
	intro_tween.tween_callback(entrance_light.queue_free)

func connect_signals():
	detection_area.body_entered.connect(_on_player_entered_arena)
	phase_timer.timeout.connect(_on_phase_transition_complete)
	ability_timer.timeout.connect(_on_ability_cooldown_finished)

func _physics_process(delta):
	if not is_instance_valid(player_target):
		search_for_player()
		return
	
	if is_transitioning:
		return
	
	update_boss_behavior(delta)
	update_divine_effects(delta)
	move_and_slide()

func search_for_player():
	player_target = get_tree().get_first_node_in_group("player")

func update_boss_behavior(delta: float):
	if not player_target:
		return
	
	# Check for phase transitions
	check_phase_transitions()
	
	# Execute current phase behavior
	match current_phase:
		1: execute_phase_1_behavior(delta)
		2: execute_phase_2_behavior(delta)
		3: execute_phase_3_behavior(delta)

func check_phase_transitions():
	var health_percentage = float(current_health) / float(max_health)
	
	if current_phase == 1 and health_percentage <= phase_1_threshold:
		transition_to_phase(2)
	elif current_phase == 2 and health_percentage <= phase_2_threshold:
		transition_to_phase(3)

func transition_to_phase(new_phase: int):
	if is_transitioning:
		return
	
	is_transitioning = true
	current_phase = new_phase
	
	# Visual phase transition
	create_phase_transition_effects()
	
	phase_timer.start()
	phase_transition.emit(new_phase)
	
	print("Sekhmet transitions to Phase ", new_phase, " - Divine wrath intensifies!")

func create_phase_transition_effects():
	# Blinding flash
	var flash = MeshInstance3D.new()
	get_parent().add_child(flash)
	flash.position = global_position
	
	var flash_mesh = SphereMesh.new()
	flash_mesh.radius = arena_radius
	flash.mesh = flash_mesh
	
	var flash_material = StandardMaterial3D.new()
	flash_material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	flash_material.emission_enabled = true
	flash_material.emission = Color(1.0, 0.8, 0.4, 1.0)
	flash.material_override = flash_material
	
	# Fade out flash
	var flash_tween = create_tween()
	flash_tween.tween_property(flash, "modulate:a", 0.0, 1.5)
	flash_tween.tween_callback(flash.queue_free)
	
	# Enhance visual appearance for new phase
	enhance_phase_appearance()

func enhance_phase_appearance():
	match current_phase:
		2:
			# Divine form - brighter, more golden
			if divine_light:
				divine_light.light_energy = 3.0
				divine_light.light_color = Color(1.0, 0.9, 0.4, 1.0)
		3:
			# Apocalyptic form - intense solar energy
			if divine_light:
				divine_light.light_energy = 4.0
				divine_light.light_color = Color(1.0, 0.2, 0.0, 1.0)
			lioness_rage_stacks = 5  # Maximum rage

func begin_phase(phase: int):
	current_phase = phase
	ability_queue = phase_abilities.get(phase, []).duplicate()
	ability_queue.shuffle()  # Randomize ability order

func execute_phase_1_behavior(delta: float):
	# Phase 1: "Divine Huntress" - Agile predator attacks
	if ability_timer.is_stopped() and not ability_queue.is_empty():
		var next_ability = ability_queue.pop_front()
		execute_ability(next_ability)
	elif ability_queue.is_empty():
		# Refill ability queue
		ability_queue = phase_abilities[1].duplicate()
		ability_queue.shuffle()

func execute_phase_2_behavior(delta: float):
	# Phase 2: "Solar Wrath" - Divine powers and healing
	if ability_timer.is_stopped() and not ability_queue.is_empty():
		var next_ability = ability_queue.pop_front()
		execute_ability(next_ability)
		
		# Phase 2 has chance to heal
		if randf() < 0.2:  # 20% chance
			perform_healing_flames()
	elif ability_queue.is_empty():
		ability_queue = phase_abilities[2].duplicate()
		ability_queue.shuffle()

func execute_phase_3_behavior(delta: float):
	# Phase 3: "Apocalyptic Fury" - Devastating finale
	if not is_enraged:
		enter_enraged_state()
	
	if ability_timer.is_stopped() and not ability_queue.is_empty():
		var next_ability = ability_queue.pop_front()
		execute_ability(next_ability)
		
		# Phase 3 uses multiple abilities in sequence
		if randf() < 0.3:  # 30% chance for combo
			perform_ability_combo()
	elif ability_queue.is_empty():
		ability_queue = phase_abilities[3].duplicate()
		ability_queue.shuffle()

func execute_ability(ability_name: String):
	last_ability_used = ability_name
	ability_timer.start()
	
	match ability_name:
		# Phase 1 abilities
		"flame_pounce": perform_flame_pounce()
		"fire_breath": perform_fire_breath()
		"lava_pools": create_strategic_lava_pools()
		
		# Phase 2 abilities
		"divine_charge": perform_divine_charge()
		"solar_flare": trigger_solar_flare()
		"healing_flames": perform_healing_flames()
		
		# Phase 3 abilities
		"apocalyptic_roar": unleash_apocalyptic_roar()
		"meteor_storm": summon_meteor_storm()
		"lioness_fury": activate_lioness_fury()

# Phase 1 Abilities
func perform_flame_pounce():
	if not player_target:
		return
	
	# Leap toward player with flame trail
	var pounce_direction = (player_target.global_position - global_position).normalized()
	velocity = pounce_direction * charge_speed * 1.2
	velocity.y = 8.0  # Upward component for leap
	
	# Create flame trail during pounce
	create_pounce_flame_trail()
	
	# Face target
	look_at(player_target.global_position, Vector3.UP)
	
	print("Sekhmet pounces with fiery claws!")

func perform_fire_breath():
	if not player_target:
		return
	
	# Face player
	look_at(player_target.global_position, Vector3.UP)
	
	# Create wide fire breath cone
	create_fire_breath_attack()
	
	print("Sekhmet breathes devastating solar flames!")

func create_strategic_lava_pools():
	# Create multiple lava pools to limit player movement
	var pool_positions = [
		arena_center + Vector3(8, 0, 8),
		arena_center + Vector3(-8, 0, 8),
		arena_center + Vector3(8, 0, -8),
		arena_center + Vector3(-8, 0, -8)
	]
	
	for pos in pool_positions:
		create_boss_lava_pool(pos, 4.0)

# Phase 2 Abilities
func perform_divine_charge():
	if not player_target:
		return
	
	divine_form_active = true
	
	# Become temporarily invulnerable during charge
	set_collision_layer_value(1, false)
	
	var charge_direction = (player_target.global_position - global_position).normalized()
	velocity = charge_direction * charge_speed * 1.5
	
	# Divine trail effect
	create_divine_charge_trail()
	
	# End divine form after brief duration
	var divine_timer = Timer.new()
	divine_timer.wait_time = 2.0
	divine_timer.timeout.connect(_end_divine_charge)
	divine_timer.one_shot = true
	divine_timer.autostart = true
	add_child(divine_timer)
	
	print("Sekhmet charges with divine solar energy!")

func trigger_solar_flare():
	# Blinding area attack
	var flare = Area3D.new()
	flare.name = "SolarFlare"
	flare.position = global_position
	get_parent().add_child(flare)
	
	# Large area effect
	var flare_collision = CollisionShape3D.new()
	var flare_shape = SphereShape3D.new()
	flare_shape.radius = arena_radius * 0.8
	flare_collision.shape = flare_shape
	flare.add_child(flare_collision)
	
	# Brilliant visual effect
	var flare_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = arena_radius * 0.8
	flare_mesh.mesh = mesh
	flare.add_child(flare_mesh)
	
	var flare_material = StandardMaterial3D.new()
	flare_material.albedo_color = Color(1.0, 1.0, 0.8, 0.8)
	flare_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flare_material.emission_enabled = true
	flare_material.emission = Color(1.0, 0.9, 0.5, 1.0)
	flare_mesh.material_override = flare_material
	
	# Damage and blind effect
	flare.body_entered.connect(_on_solar_flare_hit)
	
	# Fade out flare
	var flare_tween = create_tween()
	flare_tween.tween_property(flare, "modulate:a", 0.0, 2.0)
	flare_tween.tween_callback(flare.queue_free)
	
	print("Sekhmet unleashes blinding solar flare!")

func perform_healing_flames():
	# Sekhmet heals herself with purifying fire
	var heal_amount = max_health * 0.1  # Heal 10% of max HP
	current_health = min(max_health, current_health + heal_amount)
	
	# Visual healing effect
	create_healing_aura()
	
	print("Sekhmet channels healing solar flames - restored ", heal_amount, " HP!")

# Phase 3 Abilities
func unleash_apocalyptic_roar():
	is_channeling = true
	velocity = Vector3.ZERO
	
	# Devastating roar that affects entire arena
	lioness_roar_unleashed.emit(global_position)
	
	# Create shockwave effect
	var roar_wave = Area3D.new()
	roar_wave.name = "RoarShockwave"
	roar_wave.position = global_position
	get_parent().add_child(roar_wave)
	
	# Expanding shockwave
	var wave_collision = CollisionShape3D.new()
	var wave_shape = SphereShape3D.new()
	wave_shape.radius = 2.0
	wave_collision.shape = wave_shape
	roar_wave.add_child(wave_collision)
	
	# Visual shockwave
	var wave_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 2.0
	wave_mesh.mesh = mesh
	roar_wave.add_child(wave_mesh)
	
	var wave_material = StandardMaterial3D.new()
	wave_material.albedo_color = Color(1.0, 0.3, 0.0, 0.6)
	wave_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wave_material.emission_enabled = true
	wave_material.emission = Color(1.0, 0.5, 0.0, 1.0)
	wave_mesh.material_override = wave_material
	
	# Expand shockwave
	var wave_tween = create_tween()
	wave_tween.parallel().tween_property(roar_wave, "scale", Vector3.ONE * arena_radius, 1.5)
	wave_tween.parallel().tween_property(wave_material, "albedo_color:a", 0.0, 1.5)
	wave_tween.tween_callback(roar_wave.queue_free)
	
	# Damage detection
	roar_wave.body_entered.connect(_on_roar_hit)
	
	# End channeling
	var roar_timer = Timer.new()
	roar_timer.wait_time = 1.5
	roar_timer.timeout.connect(_end_roar_channel)
	roar_timer.one_shot = true
	roar_timer.autostart = true
	add_child(roar_timer)
	
	divine_wrath_triggered.emit()
	print("Sekhmet's apocalyptic roar shakes the very foundations of the underworld!")

func summon_meteor_storm():
	# Rain of fire meteors across arena
	for i in range(8):
		var delay = i * 0.3  # Stagger meteor impacts
		var meteor_timer = Timer.new()
		meteor_timer.wait_time = delay
		meteor_timer.timeout.connect(_create_meteor.bind(i))
		meteor_timer.one_shot = true
		meteor_timer.autostart = true
		add_child(meteor_timer)
	
	print("Sekhmet calls down meteoric judgment!")

func _create_meteor(meteor_index: int):
	# Random position within arena
	var meteor_pos = arena_center + Vector3(
		randf_range(-arena_radius * 0.7, arena_radius * 0.7),
		0,
		randf_range(-arena_radius * 0.7, arena_radius * 0.7)
	)
	
	# Create meteor impact
	var meteor = Area3D.new()
	meteor.name = "Meteor" + str(meteor_index)
	meteor.position = meteor_pos
	get_parent().add_child(meteor)
	
	# Warning indicator (appears first)
	var warning = MeshInstance3D.new()
	var warning_mesh = CylinderMesh.new()
	warning_mesh.radius_top = 3.0
	warning_mesh.radius_bottom = 3.0
	warning_mesh.height = 0.1
	warning.mesh = warning_mesh
	meteor.add_child(warning)
	
	var warning_material = StandardMaterial3D.new()
	warning_material.albedo_color = Color(1.0, 0.5, 0.0, 0.8)
	warning_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	warning_material.emission_enabled = true
	warning_material.emission = Color(1.0, 0.7, 0.0, 1.0)
	warning.material_override = warning_material
	
	# Actual meteor impact after warning
	var impact_timer = Timer.new()
	impact_timer.wait_time = 1.0  # Warning duration
	impact_timer.timeout.connect(_trigger_meteor_impact.bind(meteor))
	impact_timer.one_shot = true
	impact_timer.autostart = true
	meteor.add_child(impact_timer)

func _trigger_meteor_impact(meteor: Area3D):
	# Replace warning with actual impact
	for child in meteor.get_children():
		if child.name.begins_with("Warning"):
			child.queue_free()
	
	# Impact collision
	var impact_collision = CollisionShape3D.new()
	var impact_shape = SphereShape3D.new()
	impact_shape.radius = 4.0
	impact_collision.shape = impact_shape
	meteor.add_child(impact_collision)
	
	# Impact visual
	var impact_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 4.0
	impact_mesh.mesh = mesh
	meteor.add_child(impact_mesh)
	
	var impact_material = StandardMaterial3D.new()
	impact_material.albedo_color = Color(1.0, 0.2, 0.0, 0.9)
	impact_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	impact_material.emission_enabled = true
	impact_material.emission = Color(1.0, 0.4, 0.0, 1.0)
	impact_mesh.material_override = impact_material
	
	# Damage detection
	meteor.body_entered.connect(_on_meteor_hit)
	
	# Remove meteor after brief duration
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 1.0
	cleanup_timer.timeout.connect(meteor.queue_free)
	cleanup_timer.one_shot = true
	cleanup_timer.autostart = true
	meteor.add_child(cleanup_timer)

func activate_lioness_fury():
	# Sekhmet enters berserker state with multiple rapid attacks
	is_enraged = true
	lioness_rage_stacks = 10
	
	# Rapid attack sequence
	for i in range(5):
		var attack_timer = Timer.new()
		attack_timer.wait_time = i * 0.4  # Rapid succession
		attack_timer.timeout.connect(_fury_attack.bind(i))
		attack_timer.one_shot = true
		attack_timer.autostart = true
		add_child(attack_timer)
	
	print("Sekhmet enters lioness fury - unleashing unstoppable wrath!")

func _fury_attack(attack_index: int):
	if not player_target:
		return
	
	# Different attack each time
	match attack_index:
		0: perform_flame_pounce()
		1: create_strategic_lava_pools()
		2: perform_divine_charge()
		3: trigger_solar_flare()
		4: perform_fire_breath()

func create_pounce_flame_trail():
	var trail = MeshInstance3D.new()
	get_parent().add_child(trail)
	trail.position = global_position
	
	var trail_mesh = CylinderMesh.new()
	trail_mesh.radius_top = 1.0
	trail_mesh.radius_bottom = 2.0
	trail_mesh.height = 0.5
	trail.mesh = trail_mesh
	
	var trail_material = StandardMaterial3D.new()
	trail_material.albedo_color = Color(1.0, 0.4, 0.0, 0.7)
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_material.emission_enabled = true
	trail_material.emission = Color(1.0, 0.6, 0.0, 1.0)
	trail.material_override = trail_material
	
	# Fade out trail
	var trail_tween = create_tween()
	trail_tween.parallel().tween_property(trail, "scale", Vector3.ZERO, 1.0)
	trail_tween.parallel().tween_property(trail, "modulate:a", 0.0, 1.0)
	trail_tween.tween_callback(trail.queue_free)

func create_fire_breath_attack():
	var breath = Area3D.new()
	breath.name = "SekhmetFireBreath"
	breath.position = global_position + transform.basis.z * -3
	breath.rotation = global_rotation
	get_parent().add_child(breath)
	
	# Large cone shape
	var breath_collision = CollisionShape3D.new()
	var breath_shape = BoxShape3D.new()  # Simplified cone
	breath_shape.size = Vector3(15.0, 6.0, 20.0)
	breath_collision.shape = breath_shape
	breath_collision.position = Vector3(0, 0, -10.0)
	breath.add_child(breath_collision)
	
	# Fire breath visual
	var breath_mesh = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(12.0, 5.0, 18.0)
	breath_mesh.mesh = mesh
	breath_mesh.position = Vector3(0, 0, -10.0)
	breath.add_child(breath_mesh)
	
	var breath_material = StandardMaterial3D.new()
	breath_material.albedo_color = Color(1.0, 0.3, 0.0, 0.8)
	breath_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	breath_material.emission_enabled = true
	breath_material.emission = Color(1.0, 0.5, 0.0, 1.0)
	breath_mesh.material_override = breath_material
	
	# Damage detection
	breath.body_entered.connect(_on_fire_breath_hit)
	
	# Remove breath after duration
	var breath_timer = Timer.new()
	breath_timer.wait_time = 2.0
	breath_timer.timeout.connect(breath.queue_free)
	breath_timer.one_shot = true
	breath_timer.autostart = true
	breath.add_child(breath_timer)

func create_boss_lava_pool(pos: Vector3, radius: float):
	var lava_pool = Area3D.new()
	lava_pool.name = "SekhmetLavaPool"
	lava_pool.position = pos
	get_parent().add_child(lava_pool)
	
	# Pool visual
	var pool_mesh = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.radius_top = radius
	mesh.radius_bottom = radius
	mesh.height = 0.4
	pool_mesh.mesh = mesh
	lava_pool.add_child(pool_mesh)
	
	var pool_material = StandardMaterial3D.new()
	pool_material.albedo_color = Color(1.0, 0.2, 0.0, 1.0)
	pool_material.emission_enabled = true
	pool_material.emission = Color(1.0, 0.4, 0.0, 1.0)
	pool_mesh.material_override = pool_material
	
	# Collision for damage
	var pool_collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = radius
	shape.height = 0.4
	pool_collision.shape = shape
	lava_pool.add_child(pool_collision)
	
	# Continuous damage
	lava_pool.body_entered.connect(_on_boss_lava_entered)
	
	# Pool duration
	var duration_timer = Timer.new()
	duration_timer.wait_time = 15.0  # Boss pools last longer
	duration_timer.timeout.connect(lava_pool.queue_free)
	duration_timer.autostart = true
	lava_pool.add_child(duration_timer)
	
	lava_hazards.append(lava_pool)

func create_divine_charge_trail():
	var trail = MeshInstance3D.new()
	get_parent().add_child(trail)
	trail.position = global_position
	
	var trail_mesh = SphereMesh.new()
	trail_mesh.radius = 2.0
	trail.mesh = trail_mesh
	
	var trail_material = StandardMaterial3D.new()
	trail_material.albedo_color = Color(1.0, 0.9, 0.4, 0.8)
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_material.emission_enabled = true
	trail_material.emission = Color(1.0, 0.8, 0.3, 1.0)
	trail.material_override = trail_material
	
	# Fade trail
	var trail_tween = create_tween()
	trail_tween.parallel().tween_property(trail, "scale", Vector3.ZERO, 1.2)
	trail_tween.parallel().tween_property(trail, "modulate:a", 0.0, 1.2)
	trail_tween.tween_callback(trail.queue_free)

func create_healing_aura():
	var aura = MeshInstance3D.new()
	add_child(aura)
	
	var aura_mesh = SphereMesh.new()
	aura_mesh.radius = 3.0
	aura.mesh = aura_mesh
	
	var aura_material = StandardMaterial3D.new()
	aura_material.albedo_color = Color(0.2, 1.0, 0.3, 0.6)
	aura_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	aura_material.emission_enabled = true
	aura_material.emission = Color(0.4, 1.0, 0.5, 1.0)
	aura.material_override = aura_material
	
	# Pulse healing aura
	var pulse_tween = create_tween()
	pulse_tween.set_loops(3)
	pulse_tween.tween_property(aura, "scale", Vector3.ONE * 1.5, 0.5)
	pulse_tween.tween_property(aura, "scale", Vector3.ONE, 0.5)
	pulse_tween.tween_callback(aura.queue_free)

func perform_ability_combo():
	# Chain multiple abilities together for devastating combo
	print("Sekhmet performs devastating ability combo!")
	
	# Quick succession of abilities
	var combo_abilities = ["fire_breath", "divine_charge", "solar_flare"]
	for i in range(combo_abilities.size()):
		var combo_timer = Timer.new()
		combo_timer.wait_time = i * 0.8
		combo_timer.timeout.connect(execute_ability.bind(combo_abilities[i]))
		combo_timer.one_shot = true
		combo_timer.autostart = true
		add_child(combo_timer)

func enter_enraged_state():
	if is_enraged:
		return
	
	is_enraged = true
	lioness_rage_stacks = 5
	
	# Enhanced stats when enraged
	movement_speed *= 1.3
	charge_speed *= 1.2
	
	# Visual changes
	modulate = Color(1.2, 0.6, 0.3, 1.0)  # Reddish glow
	if divine_light:
		divine_light.light_energy = 5.0
		divine_light.light_color = Color(1.0, 0.1, 0.0, 1.0)
	
	print("Sekhmet enters apocalyptic rage - her fury knows no bounds!")

func update_divine_effects(delta: float):
	# Update various ongoing divine effects
	purification_progress += delta * 0.1
	
	# Rage stack decay
	if lioness_rage_stacks > 0 and randf() < 0.01:
		lioness_rage_stacks -= 1

func take_damage(damage: int, damage_type: String = ""):
	# Boss damage reduction
	var actual_damage = damage
	if divine_form_active:
		actual_damage = damage / 2  # Divine form reduces damage
	
	current_health -= actual_damage
	
	# Visual damage feedback
	create_boss_damage_flash()
	
	# Lioness rage builds when damaged
	lioness_rage_stacks = min(10, lioness_rage_stacks + 1)
	
	if current_health <= 0:
		die()

func create_boss_damage_flash():
	var flash_tween = create_tween()
	flash_tween.tween_property(mesh_instance, "modulate", Color.RED, 0.15)
	flash_tween.tween_property(mesh_instance, "modulate", Color.WHITE, 0.15)

func die():
	print("Sekhmet, Lioness of Destruction, falls - her divine flames extinguished...")
	
	boss_defeated.emit()
	purification_complete.emit()
	
	# Epic death sequence
	create_boss_death_effects()
	
	# Clean up arena hazards
	cleanup_arena()
	
	# Award boss completion
	award_boss_victory()

func create_boss_death_effects():
	# Massive explosion of divine energy
	var death_explosion = MeshInstance3D.new()
	get_parent().add_child(death_explosion)
	death_explosion.position = global_position
	
	var explosion_mesh = SphereMesh.new()
	explosion_mesh.radius = arena_radius
	death_explosion.mesh = explosion_mesh
	
	var explosion_material = StandardMaterial3D.new()
	explosion_material.albedo_color = Color(1.0, 0.8, 0.3, 0.9)
	explosion_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	explosion_material.emission_enabled = true
	explosion_material.emission = Color(1.0, 0.9, 0.5, 1.0)
	death_explosion.material_override = explosion_material
	
	# Massive expansion and fade
	var death_tween = create_tween()
	death_tween.parallel().tween_property(death_explosion, "scale", Vector3.ONE * 2.0, 3.0)
	death_tween.parallel().tween_property(death_explosion, "modulate:a", 0.0, 3.0)
	death_tween.tween_callback(death_explosion.queue_free)

func cleanup_arena():
	# Remove all boss-created hazards
	for hazard in lava_hazards:
		if is_instance_valid(hazard):
			hazard.queue_free()
	lava_hazards.clear()
	
	for effect in divine_effects:
		if is_instance_valid(effect):
			effect.queue_free()
	divine_effects.clear()

func award_boss_victory():
	# Award boss-specific rewards
	print("Purification trial complete - Sekhmet's blessing obtained")
	
	# Could integrate with reward system
	# reward_system.award_boss_completion("sekhmet")

# Signal handlers
func _on_player_entered_arena(body: Node3D):
	if body.is_in_group("player"):
		player_target = body
		print("Sekhmet senses the challenger - let the trial of purification begin!")

func _on_phase_transition_complete():
	is_transitioning = false
	begin_phase(current_phase)

func _on_ability_cooldown_finished():
	# Ready for next ability
	pass

func _end_divine_charge():
	divine_form_active = false
	set_collision_layer_value(1, true)  # Restore collision

func _end_roar_channel():
	is_channeling = false

func _on_fire_breath_hit(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		var damage = base_damage * divine_damage_multiplier
		body.take_damage(damage, "fire")
		print("Sekhmet's fire breath devastates for ", damage, " damage!")

func _on_solar_flare_hit(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		var damage = base_damage * 1.2
		body.take_damage(damage, "solar")
		# Apply blind effect
		if body.has_method("apply_status_effect"):
			body.apply_status_effect("blinded", 3.0)

func _on_roar_hit(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		var damage = base_damage * 2.0  # Massive damage
		body.take_damage(damage, "sonic")
		# Apply fear effect
		if body.has_method("apply_status_effect"):
			body.apply_status_effect("feared", 2.0)

func _on_meteor_hit(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		var damage = base_damage * 1.8
		body.take_damage(damage, "meteor")

func _on_boss_lava_entered(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		body.take_damage(30, "fire")  # Boss lava does more damage

# Public API
func get_boss_info() -> Dictionary:
	return {
		"name": "Sekhmet, Lioness of Destruction",
		"health": current_health,
		"max_health": max_health,
		"current_phase": current_phase,
		"is_enraged": is_enraged,
		"divine_form_active": divine_form_active,
		"lioness_rage_stacks": lioness_rage_stacks,
		"purification_progress": purification_progress,
		"arena_center": arena_center
	}

func force_phase_transition(phase: int):
	transition_to_phase(phase)

func set_arena_center(center: Vector3):
	arena_center = center