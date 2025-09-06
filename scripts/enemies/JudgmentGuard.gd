extends CharacterBody3D
class_name JudgmentGuard

signal guard_defeated()
signal shield_of_justice_activated()
signal divine_judgment_cast(target: Node3D)
signal moral_aura_triggered(aura_type: String)

@export_group("Judgment Guard Stats")
@export var max_health: int = 250
@export var movement_speed: float = 5.0
@export var shield_bash_speed: float = 12.0
@export var divine_damage: int = 50
@export var justice_shield_armor: int = 20
@export var detection_range: float = 20.0

@export_group("Divine Abilities")
@export var shield_bash_range: float = 8.0
@export var divine_judgment_range: float = 15.0
@export var moral_aura_radius: float = 10.0
@export var righteousness_duration: float = 8.0

# Node references
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var detection_area: Area3D = $DetectionArea
@onready var ability_timer: Timer = $AbilityTimer
@onready var shield_timer: Timer = $ShieldTimer
@onready var divine_particles: GPUParticles3D = $DivineParticles
@onready var justice_light: OmniLight3D = $JusticeLight

# Combat state
var current_health: int
var current_armor: int
var player_target: Node3D
var is_shield_bashing: bool = false
var is_casting_judgment: bool = false
var shield_active: bool = true
var righteousness_active: bool = false

# Divine abilities
var moral_detection_active: bool = true
var player_moral_alignment: String = "unknown"
var justice_stance: String = "defensive"  # "defensive", "aggressive", "righteous"
var divine_favor_level: int = 3

# Equipment - divine shield and was scepter
var divine_shield: Node3D
var judgment_scepter: Node3D

func _ready():
	setup_judgment_guard()
	create_guard_appearance()
	create_divine_equipment()
	setup_divine_systems()
	connect_signals()

func setup_judgment_guard():
	current_health = max_health
	current_armor = justice_shield_armor
	add_to_group("judgment_hall_enemies")
	add_to_group("judgment_guards")
	add_to_group("divine_enemies")
	
	# Divine guardian physics
	up_direction = Vector3.UP
	floor_stop_on_slope = true
	floor_max_angle = deg_to_rad(35)

func create_guard_appearance():
	# Main guard body (tall, imposing Egyptian guardian)
	var guard_mesh = CapsuleMesh.new()
	guard_mesh.radius = 1.2
	guard_mesh.height = 4.0
	mesh_instance.mesh = guard_mesh
	
	# Divine guardian material
	var guard_material = StandardMaterial3D.new()
	guard_material.albedo_color = Color(0.9, 0.8, 0.6, 1.0)    # Divine bronze-gold
	guard_material.emission_enabled = true
	guard_material.emission = Color(1.0, 0.9, 0.4, 1.0)        # Golden divine glow
	guard_material.metallic = 0.8
	guard_material.roughness = 0.2
	guard_material.rim_enabled = true
	guard_material.rim = Color(1.0, 1.0, 1.0, 1.0)            # Divine white rim
	mesh_instance.material_override = guard_material
	
	# Collision shape
	var capsule_shape = CapsuleShape3D.new()
	capsule_shape.radius = 1.0
	capsule_shape.height = 4.0
	collision_shape.shape = capsule_shape
	
	# Add divine crown/helmet
	create_divine_crown()

func create_divine_crown():
	var crown = MeshInstance3D.new()
	crown.name = "DivineCrown"
	add_child(crown)
	
	var crown_mesh = CylinderMesh.new()
	crown_mesh.radius_top = 0.8
	crown_mesh.radius_bottom = 1.0
	crown_mesh.height = 1.0
	crown.mesh = crown_mesh
	crown.position = Vector3(0, 2.5, 0)
	
	# Crown material - pure divine gold
	var crown_material = StandardMaterial3D.new()
	crown_material.albedo_color = Color(1.0, 0.9, 0.3, 1.0)
	crown_material.emission_enabled = true
	crown_material.emission = Color(1.0, 0.8, 0.2, 1.0)
	crown_material.metallic = 1.0
	crown_material.roughness = 0.0
	crown.material_override = crown_material
	
	# Add eye of Horus on crown
	create_eye_of_horus(crown)

func create_eye_of_horus(parent: MeshInstance3D):
	var eye = MeshInstance3D.new()
	eye.name = "EyeOfHorus"
	parent.add_child(eye)
	
	var eye_mesh = SphereMesh.new()
	eye_mesh.radius = 0.3
	eye.mesh = eye_mesh
	eye.position = Vector3(0, 0, 0.6)
	
	# Mystical eye material
	var eye_material = StandardMaterial3D.new()
	eye_material.albedo_color = Color(0.1, 0.7, 1.0, 1.0)  # Divine blue
	eye_material.emission_enabled = true
	eye_material.emission = Color(0.3, 0.8, 1.0, 1.0)
	eye_material.metallic = 0.0
	eye_material.roughness = 0.1
	eye.material_override = eye_material

func create_divine_equipment():
	# Divine Shield - Shield of Ma'at
	create_divine_shield()
	
	# Judgment Scepter - Was of Divine Authority
	create_judgment_scepter()

func create_divine_shield():
	divine_shield = MeshInstance3D.new()
	divine_shield.name = "ShieldOfMaat"
	add_child(divine_shield)
	
	# Shield shape (Egyptian round shield with ankh symbol)
	var shield_mesh = CylinderMesh.new()
	shield_mesh.radius_top = 1.5
	shield_mesh.radius_bottom = 1.5
	shield_mesh.height = 0.2
	divine_shield.mesh = shield_mesh
	divine_shield.position = Vector3(-1.8, 0.5, 0)  # Left arm
	divine_shield.rotation_degrees = Vector3(0, 0, 90)  # Vertical orientation
	
	# Shield material - divine protection
	var shield_material = StandardMaterial3D.new()
	shield_material.albedo_color = Color(1.0, 0.9, 0.4, 1.0)  # Golden shield
	shield_material.emission_enabled = true
	shield_material.emission = Color(0.8, 0.9, 1.0, 1.0)      # Divine white-blue glow
	shield_material.metallic = 0.9
	shield_material.roughness = 0.1
	shield_material.rim_enabled = true
	shield_material.rim = Color(1.0, 1.0, 1.0, 1.0)
	divine_shield.material_override = shield_material
	
	# Add ankh symbol on shield
	create_ankh_symbol(divine_shield)

func create_ankh_symbol(parent_shield: MeshInstance3D):
	var ankh = MeshInstance3D.new()
	ankh.name = "AnkhSymbol"
	parent_shield.add_child(ankh)
	
	# Ankh cross shape (simplified)
	var ankh_mesh = CylinderMesh.new()
	ankh_mesh.radius_top = 0.1
	ankh_mesh.radius_bottom = 0.1
	ankh_mesh.height = 1.0
	ankh.mesh = ankh_mesh
	ankh.position = Vector3(0, 0, 0.15)
	
	# Ankh material - divine life symbol
	var ankh_material = StandardMaterial3D.new()
	ankh_material.albedo_color = Color(0.1, 0.8, 0.3, 1.0)  # Divine green (life)
	ankh_material.emission_enabled = true
	ankh_material.emission = Color(0.2, 1.0, 0.4, 1.0)
	ankh.material_override = ankh_material

func create_judgment_scepter():
	judgment_scepter = MeshInstance3D.new()
	judgment_scepter.name = "JudgmentScepter"
	add_child(judgment_scepter)
	
	# Scepter shaft
	var scepter_mesh = CylinderMesh.new()
	scepter_mesh.radius_top = 0.15
	scepter_mesh.radius_bottom = 0.15
	scepter_mesh.height = 2.5
	judgment_scepter.mesh = scepter_mesh
	judgment_scepter.position = Vector3(1.5, 0, 0)  # Right hand
	
	# Scepter material - divine authority
	var scepter_material = StandardMaterial3D.new()
	scepter_material.albedo_color = Color(0.8, 0.6, 0.2, 1.0)
	scepter_material.emission_enabled = true
	scepter_material.emission = Color(1.0, 0.8, 0.3, 1.0)
	scepter_material.metallic = 0.8
	scepter_material.roughness = 0.2
	judgment_scepter.material_override = scepter_material
	
	# Scepter head (Set animal head - symbol of divine judgment)
	create_scepter_head()

func create_scepter_head():
	var scepter_head = MeshInstance3D.new()
	scepter_head.name = "ScepterHead"
	judgment_scepter.add_child(scepter_head)
	
	var head_mesh = BoxMesh.new()  # Stylized animal head
	head_mesh.size = Vector3(0.6, 0.4, 0.8)
	scepter_head.mesh = head_mesh
	scepter_head.position = Vector3(0, 1.4, 0)
	
	# Divine judgment material
	var head_material = StandardMaterial3D.new()
	head_material.albedo_color = Color(0.9, 0.7, 0.1, 1.0)
	head_material.emission_enabled = true
	head_material.emission = Color(1.0, 0.9, 0.2, 1.0)
	head_material.metallic = 0.9
	head_material.roughness = 0.0
	scepter_head.material_override = head_material

func setup_divine_systems():
	# Detection area
	var detection_collision = CollisionShape3D.new()
	var detection_shape = SphereShape3D.new()
	detection_shape.radius = detection_range
	detection_collision.shape = detection_shape
	detection_area.add_child(detection_collision)
	
	# Ability timers
	ability_timer.wait_time = 3.0  # Between special abilities
	ability_timer.one_shot = true
	shield_timer.wait_time = 1.5   # Shield bash cooldown
	shield_timer.one_shot = true
	
	# Divine particle system
	if divine_particles:
		divine_particles.emitting = true
		divine_particles.amount = 80
		# Configure divine particles (golden sparkles)
	
	# Justice light (divine aura)
	if justice_light:
		justice_light.light_energy = 1.5
		justice_light.light_color = Color(1.0, 0.9, 0.6, 1.0)
		justice_light.omni_range = moral_aura_radius

func connect_signals():
	detection_area.body_entered.connect(_on_player_detected)
	detection_area.body_exited.connect(_on_player_lost)
	ability_timer.timeout.connect(_on_ability_cooldown_finished)
	shield_timer.timeout.connect(_on_shield_cooldown_finished)

func _physics_process(delta):
	if not is_instance_valid(player_target):
		search_for_player()
		return
	
	update_moral_detection(delta)
	update_divine_behavior(delta)
	move_and_slide()

func search_for_player():
	player_target = get_tree().get_first_node_in_group("player")

func update_moral_detection(delta: float):
	if not player_target or not moral_detection_active:
		return
	
	# Detect player's moral alignment (integrates with JudgmentHall system)
	var judgment_hall = get_tree().get_first_node_in_group("judgment_hall_biome")
	if judgment_hall and judgment_hall.has_method("get_current_moral_alignment"):
		var detected_alignment = judgment_hall.get_current_moral_alignment()
		if detected_alignment != player_moral_alignment:
			player_moral_alignment = detected_alignment
			adapt_to_moral_alignment()

func adapt_to_moral_alignment():
	# Behavior changes based on player's moral choices
	match player_moral_alignment:
		"truth":
			# Guard is more respectful, less aggressive
			justice_stance = "defensive"
			divine_favor_level = 5
			movement_speed *= 0.8  # Slower, more ceremonial
		"lies":
			# Guard is hostile, more aggressive
			justice_stance = "aggressive"  
			divine_favor_level = 1
			movement_speed *= 1.3  # Faster, more punishing
		"neutral", "unknown":
			# Standard behavior
			justice_stance = "defensive"
			divine_favor_level = 3
	
	update_visual_based_on_stance()
	print("Judgment Guard adapts to player alignment: ", player_moral_alignment)

func update_visual_based_on_stance():
	match justice_stance:
		"defensive":
			# Brighter divine glow
			if justice_light:
				justice_light.light_color = Color(1.0, 0.9, 0.6, 1.0)
				justice_light.light_energy = 1.5
		"aggressive":
			# Reddish judgment glow
			if justice_light:
				justice_light.light_color = Color(1.0, 0.6, 0.3, 1.0)
				justice_light.light_energy = 2.0
		"righteous":
			# Brilliant white-gold glow
			if justice_light:
				justice_light.light_color = Color(1.0, 1.0, 0.8, 1.0)
				justice_light.light_energy = 2.5

func update_divine_behavior(delta: float):
	if not player_target:
		return
	
	var distance_to_player = global_position.distance_to(player_target.global_position)
	
	# Choose combat action based on distance and moral stance
	if distance_to_player <= shield_bash_range and can_shield_bash():
		perform_shield_bash()
	elif distance_to_player <= divine_judgment_range and can_cast_judgment():
		cast_divine_judgment()
	elif distance_to_player <= moral_aura_radius and not righteousness_active:
		activate_righteousness_aura()
	else:
		advance_with_purpose(delta)

func advance_with_purpose(delta: float):
	# Move toward player with divine authority
	var direction = (player_target.global_position - global_position).normalized()
	velocity = direction * movement_speed
	
	# Face player
	look_at(player_target.global_position, Vector3.UP)
	
	# Shield always facing player
	if divine_shield:
		var shield_look_direction = (player_target.global_position - global_position).normalized()
		divine_shield.look_at(global_position + shield_look_direction, Vector3.UP)

func perform_shield_bash():
	if not can_shield_bash() or not player_target:
		return
	
	is_shield_bashing = true
	shield_active = true
	
	# Charge toward player with shield
	var bash_direction = (player_target.global_position - global_position).normalized()
	velocity = bash_direction * shield_bash_speed
	
	# Face target
	look_at(player_target.global_position, Vector3.UP)
	
	# Shield bash effect
	create_shield_bash_effect()
	
	shield_timer.start()
	shield_of_justice_activated.emit()
	
	# End bash after brief duration
	var bash_timer = Timer.new()
	bash_timer.wait_time = 1.0
	bash_timer.timeout.connect(_end_shield_bash)
	bash_timer.one_shot = true
	bash_timer.autostart = true
	add_child(bash_timer)
	
	print("Judgment Guard charges with Shield of Ma'at!")

func create_shield_bash_effect():
	# Divine energy wave from shield
	var bash_wave = Area3D.new()
	bash_wave.name = "ShieldBashWave"
	bash_wave.position = global_position
	get_parent().add_child(bash_wave)
	
	# Wave collision
	var wave_collision = CollisionShape3D.new()
	var wave_shape = SphereShape3D.new()
	wave_shape.radius = shield_bash_range
	wave_collision.shape = wave_shape
	bash_wave.add_child(wave_collision)
	
	# Visual wave effect
	var wave_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = shield_bash_range
	wave_mesh.mesh = mesh
	bash_wave.add_child(wave_mesh)
	
	# Divine wave material
	var wave_material = StandardMaterial3D.new()
	wave_material.albedo_color = Color(1.0, 0.9, 0.6, 0.6)
	wave_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wave_material.emission_enabled = true
	wave_material.emission = Color(1.0, 0.8, 0.4, 1.0)
	wave_mesh.material_override = wave_material
	
	# Damage detection
	bash_wave.body_entered.connect(_on_shield_bash_hit)
	
	# Animate and remove wave
	var wave_tween = create_tween()
	wave_tween.parallel().tween_property(bash_wave, "scale", Vector3.ZERO, 0.5)
	wave_tween.parallel().tween_property(wave_material, "albedo_color:a", 0.0, 0.5)
	wave_tween.tween_callback(bash_wave.queue_free)

func cast_divine_judgment():
	if not can_cast_judgment() or not player_target:
		return
	
	is_casting_judgment = true
	velocity = Vector3.ZERO  # Stand still while casting
	
	# Face player for judgment
	look_at(player_target.global_position, Vector3.UP)
	
	# Raise scepter for divine judgment
	animate_scepter_raise()
	
	# Cast judgment after channeling
	var cast_timer = Timer.new()
	cast_timer.wait_time = 1.5  # Channeling time
	cast_timer.timeout.connect(_execute_divine_judgment)
	cast_timer.one_shot = true
	cast_timer.autostart = true
	add_child(cast_timer)
	
	ability_timer.start()
	print("Judgment Guard channels divine judgment!")

func animate_scepter_raise():
	if not judgment_scepter:
		return
	
	# Animate scepter raising and glowing
	var scepter_tween = create_tween()
	scepter_tween.tween_property(judgment_scepter, "position:y", 2.0, 0.8)
	scepter_tween.tween_property(judgment_scepter, "position:y", 0.0, 0.7)

func _execute_divine_judgment():
	if not player_target:
		return
	
	# Create divine judgment beam
	var judgment_beam = Area3D.new()
	judgment_beam.name = "DivineJudgmentBeam"
	judgment_beam.position = global_position + Vector3(0, 1, 0)
	get_parent().add_child(judgment_beam)
	
	# Beam from guard to player
	var beam_direction = (player_target.global_position - global_position).normalized()
	var beam_distance = global_position.distance_to(player_target.global_position)
	
	# Beam visual
	var beam_mesh = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	mesh.size = Vector3(1.0, 1.0, beam_distance)
	beam_mesh.mesh = mesh
	beam_mesh.position = beam_direction * beam_distance * 0.5
	beam_mesh.look_at(global_position + beam_direction, Vector3.UP)
	judgment_beam.add_child(beam_mesh)
	
	# Divine beam material
	var beam_material = StandardMaterial3D.new()
	beam_material.albedo_color = Color(1.0, 1.0, 0.8, 0.9)
	beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_material.emission_enabled = true
	beam_material.emission = Color(1.0, 0.9, 0.6, 1.0)
	beam_mesh.material_override = beam_material
	
	# Beam collision
	var beam_collision = CollisionShape3D.new()
	var beam_shape = BoxShape3D.new()
	beam_shape.size = Vector3(1.5, 1.5, beam_distance)
	beam_collision.shape = beam_shape
	beam_collision.position = beam_direction * beam_distance * 0.5
	judgment_beam.add_child(beam_collision)
	
	# Damage detection
	judgment_beam.body_entered.connect(_on_divine_judgment_hit)
	
	divine_judgment_cast.emit(player_target)
	
	# Remove beam after duration
	var beam_timer = Timer.new()
	beam_timer.wait_time = 1.0
	beam_timer.timeout.connect(judgment_beam.queue_free)
	beam_timer.one_shot = true
	beam_timer.autostart = true
	judgment_beam.add_child(beam_timer)

func activate_righteousness_aura():
	if righteousness_active:
		return
	
	righteousness_active = true
	justice_stance = "righteous"
	
	# Create righteousness aura effect
	var aura = Area3D.new()
	aura.name = "RighteousnessAura"
	aura.position = global_position
	add_child(aura)
	
	# Aura collision
	var aura_collision = CollisionShape3D.new()
	var aura_shape = SphereShape3D.new()
	aura_shape.radius = moral_aura_radius
	aura_collision.shape = aura_shape
	aura.add_child(aura_collision)
	
	# Visual aura
	var aura_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = moral_aura_radius
	aura_mesh.mesh = mesh
	aura.add_child(aura_mesh)
	
	# Righteousness material
	var aura_material = StandardMaterial3D.new()
	aura_material.albedo_color = Color(1.0, 1.0, 0.9, 0.3)
	aura_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	aura_material.emission_enabled = true
	aura_material.emission = Color(1.0, 0.9, 0.7, 1.0)
	aura_material.grow_amount = 0.2
	aura_mesh.material_override = aura_material
	
	# Continuous aura effects
	aura.body_entered.connect(_on_righteousness_aura_entered)
	aura.body_exited.connect(_on_righteousness_aura_exited)
	
	# Enhanced stats during righteousness
	current_armor += 10
	movement_speed *= 1.2
	
	update_visual_based_on_stance()
	moral_aura_triggered.emit("righteousness")
	
	# End righteousness after duration
	var righteousness_timer = Timer.new()
	righteousness_timer.wait_time = righteousness_duration
	righteousness_timer.timeout.connect(_end_righteousness_aura.bind(aura))
	righteousness_timer.one_shot = true
	righteousness_timer.autostart = true
	add_child(righteousness_timer)
	
	print("Judgment Guard activates Righteousness Aura!")

func _end_shield_bash():
	is_shield_bashing = false
	velocity = Vector3.ZERO

func _end_righteousness_aura(aura: Area3D):
	righteousness_active = false
	justice_stance = "defensive"
	current_armor -= 10
	movement_speed /= 1.2
	
	if is_instance_valid(aura):
		aura.queue_free()
	
	update_visual_based_on_stance()

func can_shield_bash() -> bool:
	return not is_shield_bashing and shield_timer.is_stopped()

func can_cast_judgment() -> bool:
	return not is_casting_judgment and ability_timer.is_stopped()

func take_damage(damage: int, damage_type: String = ""):
	# Divine armor reduces damage
	var actual_damage = max(1, damage - current_armor)
	
	# Moral alignment affects damage taken
	match player_moral_alignment:
		"truth":
			# Guard takes less damage from truth-aligned player
			actual_damage = int(actual_damage * 0.7)
		"lies":
			# Guard takes more damage from lie-aligned player (righteous fury)
			actual_damage = int(actual_damage * 1.3)
	
	current_health -= actual_damage
	
	# Visual damage feedback
	create_divine_damage_flash()
	
	# Divine retaliation
	if randf() < 0.3:  # 30% chance
		trigger_divine_retaliation()
	
	if current_health <= 0:
		die()
	else:
		# Intensify divine power when damaged
		if current_health < max_health * 0.5:
			enter_divine_fury()

func create_divine_damage_flash():
	var flash_tween = create_tween()
	flash_tween.tween_property(mesh_instance, "modulate", Color(1.5, 1.5, 1.0, 1.0), 0.1)
	flash_tween.tween_property(mesh_instance, "modulate", Color.WHITE, 0.1)

func trigger_divine_retaliation():
	# Create retaliating divine burst
	var retaliation = Area3D.new()
	retaliation.name = "DivineRetaliation"
	retaliation.position = global_position
	get_parent().add_child(retaliation)
	
	var ret_collision = CollisionShape3D.new()
	var ret_shape = SphereShape3D.new()
	ret_shape.radius = 6.0
	ret_collision.shape = ret_shape
	retaliation.add_child(ret_collision)
	
	# Visual retaliation
	var ret_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 6.0
	ret_mesh.mesh = mesh
	retaliation.add_child(ret_mesh)
	
	var ret_material = StandardMaterial3D.new()
	ret_material.albedo_color = Color(1.0, 0.8, 0.3, 0.8)
	ret_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ret_material.emission_enabled = true
	ret_material.emission = Color(1.0, 0.9, 0.5, 1.0)
	ret_mesh.material_override = ret_material
	
	# Damage nearby targets
	retaliation.body_entered.connect(_on_retaliation_hit)
	
	# Fade out retaliation
	var ret_tween = create_tween()
	ret_tween.parallel().tween_property(retaliation, "scale", Vector3.ZERO, 0.8)
	ret_tween.parallel().tween_property(ret_material, "albedo_color:a", 0.0, 0.8)
	ret_tween.tween_callback(retaliation.queue_free)

func enter_divine_fury():
	print("Judgment Guard enters Divine Fury - Divine justice intensifies!")
	
	# Enhanced abilities in divine fury
	movement_speed *= 1.4
	divine_damage = int(divine_damage * 1.3)
	
	# Visual enhancement
	if divine_particles:
		divine_particles.amount = 150
	if justice_light:
		justice_light.light_energy = 3.0
		justice_light.light_color = Color(1.0, 0.8, 0.4, 1.0)

func die():
	guard_defeated.emit()
	
	# Divine death effect - ascension
	create_divine_ascension()
	
	print("Judgment Guard falls - Divine justice has been challenged")
	queue_free()

func create_divine_ascension():
	# Divine ascension beam
	var ascension = MeshInstance3D.new()
	get_parent().add_child(ascension)
	ascension.position = global_position
	
	var ascension_mesh = CylinderMesh.new()
	ascension_mesh.radius_top = 0.5
	ascension_mesh.radius_bottom = 3.0
	ascension_mesh.height = 20.0
	ascension.mesh = ascension_mesh
	ascension.position.y += 10.0
	
	var ascension_material = StandardMaterial3D.new()
	ascension_material.albedo_color = Color(1.0, 1.0, 1.0, 0.8)
	ascension_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ascension_material.emission_enabled = true
	ascension_material.emission = Color(1.0, 0.9, 0.7, 1.0)
	ascension.material_override = ascension_material
	
	# Ascension animation
	var ascension_tween = create_tween()
	ascension_tween.parallel().tween_property(ascension, "scale", Vector3.ZERO, 2.0)
	ascension_tween.parallel().tween_property(ascension, "modulate:a", 0.0, 2.0)
	ascension_tween.tween_callback(ascension.queue_free)

# Signal handlers
func _on_player_detected(body: Node3D):
	if body.is_in_group("player"):
		player_target = body
		print("Judgment Guard detects challenger - Divine authority asserted")

func _on_player_lost(body: Node3D):
	if body == player_target:
		player_target = null

func _on_ability_cooldown_finished():
	is_casting_judgment = false

func _on_shield_cooldown_finished():
	is_shield_bashing = false

func _on_shield_bash_hit(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		var damage = divine_damage
		# Damage varies by moral alignment
		match player_moral_alignment:
			"lies":
				damage = int(damage * 1.5)  # Extra damage to deceptive players
			"truth":
				damage = int(damage * 0.8)  # Reduced damage to truthful players
		
		body.take_damage(damage, "divine")
		
		# Knockback effect
		if body.has_method("apply_knockback"):
			var knockback_direction = (body.global_position - global_position).normalized()
			body.apply_knockback(knockback_direction * 8.0)
		
		print("Shield of Ma'at strikes for ", damage, " divine damage!")

func _on_divine_judgment_hit(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		var judgment_damage = divine_damage * 2  # Powerful judgment attack
		
		# Apply moral-based effects
		match player_moral_alignment:
			"lies":
				judgment_damage = int(judgment_damage * 1.8)
				# Apply "guilt" status effect
				if body.has_method("apply_status_effect"):
					body.apply_status_effect("guilt", 5.0)
			"truth":
				judgment_damage = int(judgment_damage * 0.5)
				# Apply "blessing" status effect instead
				if body.has_method("apply_status_effect"):
					body.apply_status_effect("divine_blessing", 3.0)
		
		body.take_damage(judgment_damage, "divine_judgment")
		print("Divine Judgment delivers ", judgment_damage, " judgment damage!")

func _on_righteousness_aura_entered(body: Node3D):
	if body == player_target:
		# Apply righteousness effects based on moral alignment
		match player_moral_alignment:
			"truth":
				# Healing and blessing for truthful players
				if body.has_method("heal"):
					body.heal(20)
				if body.has_method("apply_status_effect"):
					body.apply_status_effect("righteousness_blessing", 5.0)
			"lies":
				# Damage and debuff for deceptive players
				if body.has_method("take_damage"):
					body.take_damage(15, "righteousness_burn")
				if body.has_method("apply_status_effect"):
					body.apply_status_effect("divine_judgment", 5.0)

func _on_righteousness_aura_exited(body: Node3D):
	if body == player_target:
		# Remove temporary aura effects
		if body.has_method("remove_status_effect"):
			body.remove_status_effect("righteousness_blessing")

func _on_retaliation_hit(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		body.take_damage(25, "divine_retaliation")

# Public API
func get_judgment_guard_info() -> Dictionary:
	return {
		"health": current_health,
		"max_health": max_health,
		"armor": current_armor,
		"moral_alignment_detected": player_moral_alignment,
		"justice_stance": justice_stance,
		"divine_favor_level": divine_favor_level,
		"shield_active": shield_active,
		"righteousness_active": righteousness_active
	}

func set_moral_alignment_override(alignment: String):
	player_moral_alignment = alignment
	adapt_to_moral_alignment()

func force_righteousness_mode():
	activate_righteousness_aura()

func get_divine_favor_level() -> int:
	return divine_favor_level