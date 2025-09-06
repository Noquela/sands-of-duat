extends CharacterBody3D
class_name DivineSentinel

signal sentinel_defeated()
signal divine_barrier_raised(barrier_area: Area3D)
signal holy_smite_cast(target: Node3D)
signal sanctuary_protection_activated()

@export_group("Divine Sentinel Stats")
@export var max_health: int = 320
@export var movement_speed: float = 4.0
@export var barrier_speed: float = 8.0
@export var divine_damage: int = 60
@export var divine_armor: int = 25
@export var detection_range: float = 25.0

@export_group("Divine Abilities")
@export var holy_smite_range: float = 18.0
@export var divine_barrier_radius: float = 12.0
@export var sanctuary_radius: float = 15.0
@export var protection_duration: float = 10.0

# Node references
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var detection_area: Area3D = $DetectionArea
@onready var ability_timer: Timer = $AbilityTimer
@onready var smite_timer: Timer = $SmiteTimer
@onready var divine_particles: GPUParticles3D = $DivineParticles
@onready var sanctuary_light: OmniLight3D = $SanctuaryLight

# Combat state
var current_health: int
var current_armor: int
var player_target: Node3D
var is_casting_smite: bool = false
var is_raising_barrier: bool = false
var sanctuary_active: bool = false
var barrier_active: bool = false

# Divine protection systems
var protected_allies: Array[Node3D] = []
var active_barriers: Array[Area3D] = []
var sanctuary_area: Area3D
var divine_protection_level: int = 5

# Divine equipment
var divine_staff: Node3D
var protection_amulet: Node3D

func _ready():
	setup_divine_sentinel()
	create_sentinel_appearance()
	create_divine_equipment()
	setup_divine_systems()
	connect_signals()

func setup_divine_sentinel():
	current_health = max_health
	current_armor = divine_armor
	add_to_group("judgment_hall_enemies")
	add_to_group("divine_sentinels") 
	add_to_group("protective_enemies")
	add_to_group("divine_enemies")
	
	# Sentinel physics (stable guardian)
	up_direction = Vector3.UP
	floor_stop_on_slope = true
	floor_max_angle = deg_to_rad(30)

func create_sentinel_appearance():
	# Main sentinel body (imposing divine guardian)
	var sentinel_mesh = CylinderMesh.new()
	sentinel_mesh.radius_top = 1.0
	sentinel_mesh.radius_bottom = 1.4
	sentinel_mesh.height = 3.5
	mesh_instance.mesh = sentinel_mesh
	
	# Divine sentinel material (radiant white-gold)
	var sentinel_material = StandardMaterial3D.new()
	sentinel_material.albedo_color = Color(1.0, 0.95, 0.8, 1.0)      # Divine white-gold
	sentinel_material.emission_enabled = true
	sentinel_material.emission = Color(1.0, 0.9, 0.7, 1.0)           # Warm divine glow
	sentinel_material.metallic = 0.7
	sentinel_material.roughness = 0.1
	sentinel_material.rim_enabled = true
	sentinel_material.rim = Color(1.0, 1.0, 1.0, 1.0)               # Pure white rim
	mesh_instance.material_override = sentinel_material
	
	# Collision shape
	var cylinder_shape = CylinderShape3D.new()
	cylinder_shape.radius_top = 1.0
	cylinder_shape.radius_bottom = 1.4
	cylinder_shape.height = 3.5
	collision_shape.shape = cylinder_shape
	
	# Add divine armor plating
	create_divine_armor()

func create_divine_armor():
	var armor = MeshInstance3D.new()
	armor.name = "DivineArmor"
	add_child(armor)
	
	# Armor plating (additional protection layer)
	var armor_mesh = CylinderMesh.new()
	armor_mesh.radius_top = 1.1
	armor_mesh.radius_bottom = 1.5
	armor_mesh.height = 3.2
	armor.mesh = armor_mesh
	armor.position = Vector3(0, 0.15, 0)
	
	# Armor material - brilliant divine protection
	var armor_material = StandardMaterial3D.new()
	armor_material.albedo_color = Color(0.9, 0.9, 1.0, 0.9)
	armor_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	armor_material.emission_enabled = true
	armor_material.emission = Color(0.8, 0.9, 1.0, 1.0)    # Divine blue-white
	armor_material.metallic = 0.9
	armor_material.roughness = 0.0
	armor.material_override = armor_material
	
	# Add divine helmet
	create_divine_helmet()

func create_divine_helmet():
	var helmet = MeshInstance3D.new()
	helmet.name = "DivineHelmet"
	add_child(helmet)
	
	var helmet_mesh = SphereMesh.new()
	helmet_mesh.radius = 1.0
	helmet.mesh = helmet_mesh
	helmet.position = Vector3(0, 2.2, 0)
	
	# Helmet material - pure divine protection
	var helmet_material = StandardMaterial3D.new()
	helmet_material.albedo_color = Color(1.0, 1.0, 0.95, 1.0)
	helmet_material.emission_enabled = true
	helmet_material.emission = Color(1.0, 0.95, 0.85, 1.0)
	helmet_material.metallic = 0.8
	helmet_material.roughness = 0.0
	helmet.material_override = helmet_material
	
	# Add divine crest
	create_divine_crest(helmet)

func create_divine_crest(parent_helmet: MeshInstance3D):
	var crest = MeshInstance3D.new()
	crest.name = "DivineCrest"
	parent_helmet.add_child(crest)
	
	# Crest shape (divine symbol)
	var crest_mesh = PrismMesh.new()
	crest_mesh.size = Vector3(0.6, 1.2, 0.3)
	crest.mesh = crest_mesh
	crest.position = Vector3(0, 0.8, 0)
	
	# Crest material - brilliant divine authority
	var crest_material = StandardMaterial3D.new()
	crest_material.albedo_color = Color(1.0, 0.9, 0.6, 1.0)
	crest_material.emission_enabled = true
	crest_material.emission = Color(1.0, 0.8, 0.4, 1.0)
	crest_material.metallic = 1.0
	crest_material.roughness = 0.0
	crest.material_override = crest_material

func create_divine_equipment():
	# Divine Staff - Staff of Protection
	create_divine_staff()
	
	# Protection Amulet - Amulet of Sanctuary
	create_protection_amulet()

func create_divine_staff():
	divine_staff = MeshInstance3D.new()
	divine_staff.name = "StaffOfProtection"
	add_child(divine_staff)
	
	# Staff shaft
	var staff_mesh = CylinderMesh.new()
	staff_mesh.radius_top = 0.1
	staff_mesh.radius_bottom = 0.15
	staff_mesh.height = 3.0
	divine_staff.mesh = staff_mesh
	divine_staff.position = Vector3(1.8, 0, 0)  # Right side
	
	# Staff material - divine protection wood
	var staff_material = StandardMaterial3D.new()
	staff_material.albedo_color = Color(0.7, 0.5, 0.3, 1.0)
	staff_material.emission_enabled = true
	staff_material.emission = Color(1.0, 0.8, 0.6, 1.0)
	staff_material.metallic = 0.3
	staff_material.roughness = 0.4
	divine_staff.material_override = staff_material
	
	# Staff head (protection crystal)
	create_protection_crystal()

func create_protection_crystal():
	var crystal = MeshInstance3D.new()
	crystal.name = "ProtectionCrystal"
	divine_staff.add_child(crystal)
	
	var crystal_mesh = SphereMesh.new()
	crystal_mesh.radius = 0.4
	crystal.mesh = crystal_mesh
	crystal.position = Vector3(0, 1.8, 0)
	
	# Protection crystal material
	var crystal_material = StandardMaterial3D.new()
	crystal_material.albedo_color = Color(0.8, 1.0, 1.0, 0.9)
	crystal_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	crystal_material.emission_enabled = true
	crystal_material.emission = Color(0.9, 1.0, 1.0, 1.0)
	crystal_material.metallic = 0.0
	crystal_material.roughness = 0.0
	crystal.material_override = crystal_material
	
	# Crystal orbit animation
	animate_crystal_rotation()

func animate_crystal_rotation():
	var crystal = divine_staff.get_node("ProtectionCrystal")
	if crystal:
		var rotate_tween = create_tween()
		rotate_tween.set_loops()
		rotate_tween.tween_property(crystal, "rotation:y", TAU, 4.0)

func create_protection_amulet():
	protection_amulet = MeshInstance3D.new()
	protection_amulet.name = "AmuletOfSanctuary"
	add_child(protection_amulet)
	
	# Amulet (protective talisman)
	var amulet_mesh = TorusMesh.new()
	amulet_mesh.inner_radius = 0.3
	amulet_mesh.outer_radius = 0.5
	protection_amulet.mesh = amulet_mesh
	protection_amulet.position = Vector3(0, 1.5, 0.8)  # Chest area
	
	# Amulet material - sanctuary power
	var amulet_material = StandardMaterial3D.new()
	amulet_material.albedo_color = Color(0.9, 0.8, 1.0, 1.0)
	amulet_material.emission_enabled = true
	amulet_material.emission = Color(1.0, 0.9, 1.0, 1.0)
	amulet_material.metallic = 0.8
	amulet_material.roughness = 0.1
	protection_amulet.material_override = amulet_material

func setup_divine_systems():
	# Detection area
	var detection_collision = CollisionShape3D.new()
	var detection_shape = SphereShape3D.new()
	detection_shape.radius = detection_range
	detection_collision.shape = detection_shape
	detection_area.add_child(detection_collision)
	
	# Ability timers
	ability_timer.wait_time = 6.0   # Between special abilities
	ability_timer.one_shot = true
	smite_timer.wait_time = 3.5     # Holy smite cooldown
	smite_timer.one_shot = true
	
	# Divine particles
	if divine_particles:
		divine_particles.emitting = true
		divine_particles.amount = 100
		# Configure protective particles (shields, crosses, halos)
	
	# Sanctuary light
	if sanctuary_light:
		sanctuary_light.light_energy = 2.0
		sanctuary_light.light_color = Color(1.0, 0.95, 0.9, 1.0)
		sanctuary_light.omni_range = sanctuary_radius

func connect_signals():
	detection_area.body_entered.connect(_on_player_detected)
	detection_area.body_exited.connect(_on_player_lost)
	ability_timer.timeout.connect(_on_ability_cooldown_finished)
	smite_timer.timeout.connect(_on_smite_cooldown_finished)

func _physics_process(delta):
	if not is_instance_valid(player_target):
		search_for_player()
		return
	
	update_protection_systems(delta)
	update_sentinel_behavior(delta)
	move_and_slide()

func search_for_player():
	player_target = get_tree().get_first_node_in_group("player")

func update_protection_systems(delta: float):
	# Update ally protection
	scan_for_allies()
	
	# Maintain active barriers
	maintain_divine_barriers()
	
	# Update sanctuary effects
	if sanctuary_active and sanctuary_area:
		update_sanctuary_effects()

func scan_for_allies():
	# Find nearby allies that need protection
	protected_allies.clear()
	
	var nearby_enemies = get_tree().get_nodes_in_group("judgment_hall_enemies")
	for enemy in nearby_enemies:
		if enemy != self and is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance <= sanctuary_radius:
				protected_allies.append(enemy)

func maintain_divine_barriers():
	# Remove expired barriers
	active_barriers = active_barriers.filter(func(barrier): return is_instance_valid(barrier))
	
	# Visual update for active barriers
	for barrier in active_barriers:
		if barrier.has_method("update_barrier_strength"):
			barrier.update_barrier_strength(divine_protection_level)

func update_sanctuary_effects():
	# Apply protective effects to allies within sanctuary
	for ally in protected_allies:
		if is_instance_valid(ally) and ally.has_method("apply_divine_protection"):
			ally.apply_divine_protection(1.5)  # 50% damage reduction

func update_sentinel_behavior(delta: float):
	if not player_target:
		return
	
	var distance_to_player = global_position.distance_to(player_target.global_position)
	
	# Choose action based on situation and range
	if distance_to_player <= holy_smite_range and can_cast_holy_smite():
		cast_holy_smite()
	elif should_raise_barrier() and can_raise_barrier():
		raise_divine_barrier()
	elif not sanctuary_active and can_activate_sanctuary():
		activate_sanctuary_protection()
	else:
		guard_position_defensively(delta)

func guard_position_defensively(delta: float):
	# Move slowly toward optimal defensive position
	var optimal_position = calculate_optimal_guard_position()
	var direction = (optimal_position - global_position).normalized()
	
	if global_position.distance_to(optimal_position) > 2.0:
		velocity = direction * movement_speed * 0.7  # Slower, more deliberate
	else:
		velocity = Vector3.ZERO
	
	# Face toward player while maintaining guard stance
	if player_target:
		look_at(player_target.global_position, Vector3.UP)
	
	# Raise staff defensively
	if divine_staff:
		divine_staff.rotation_degrees.x = -20  # Defensive angle

func calculate_optimal_guard_position() -> Vector3:
	# Position between player and any allies, or at strategic chokepoint
	if protected_allies.size() > 0:
		# Find center of allies to protect
		var ally_center = Vector3.ZERO
		for ally in protected_allies:
			if is_instance_valid(ally):
				ally_center += ally.global_position
		ally_center /= protected_allies.size()
		
		# Position between player and allies
		var player_to_allies = (ally_center - player_target.global_position).normalized()
		return player_target.global_position + player_to_allies * 8.0
	else:
		# Default defensive position
		return global_position

func cast_holy_smite():
	if not can_cast_holy_smite() or not player_target:
		return
	
	is_casting_smite = true
	velocity = Vector3.ZERO  # Stand firm while casting
	
	# Raise staff for smite
	animate_staff_raise_for_smite()
	
	# Face player
	look_at(player_target.global_position, Vector3.UP)
	
	# Cast smite after channeling
	var cast_timer = Timer.new()
	cast_timer.wait_time = 2.0  # Channeling time
	cast_timer.timeout.connect(_execute_holy_smite)
	cast_timer.one_shot = true
	cast_timer.autostart = true
	add_child(cast_timer)
	
	smite_timer.start()
	holy_smite_cast.emit(player_target)
	print("Divine Sentinel channels Holy Smite - divine wrath descends!")

func animate_staff_raise_for_smite():
	if not divine_staff:
		return
	
	# Animate staff raising to the sky
	var staff_tween = create_tween()
	staff_tween.tween_property(divine_staff, "rotation_degrees:x", -90, 1.0)  # Point skyward
	staff_tween.tween_property(divine_staff, "rotation_degrees:x", -20, 1.0)  # Return to guard

func _execute_holy_smite():
	if not player_target:
		return
	
	# Create divine smite from above
	var smite_position = player_target.global_position + Vector3(0, 15, 0)  # High above player
	
	var smite = Area3D.new()
	smite.name = "HolySmite"
	smite.position = smite_position
	get_parent().add_child(smite)
	
	# Smite pillar (divine light beam)
	var smite_mesh = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.radius_top = 1.5
	mesh.radius_bottom = 3.0
	mesh.height = 20.0
	smite_mesh.mesh = mesh
	smite_mesh.position = Vector3(0, -10, 0)  # Center on target
	smite.add_child(smite_mesh)
	
	# Holy smite material
	var smite_material = StandardMaterial3D.new()
	smite_material.albedo_color = Color(1.0, 1.0, 0.9, 0.9)
	smite_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smite_material.emission_enabled = true
	smite_material.emission = Color(1.0, 0.95, 0.8, 1.0)
	smite_material.grow_amount = 0.3
	smite_mesh.material_override = smite_material
	
	# Smite collision
	var smite_collision = CollisionShape3D.new()
	var smite_shape = CylinderShape3D.new()
	smite_shape.radius_top = 2.0
	smite_shape.radius_bottom = 3.5
	smite_shape.height = 20.0
	smite_collision.shape = smite_shape
	smite_collision.position = Vector3(0, -10, 0)
	smite.add_child(smite_collision)
	
	# Smite damage detection
	smite.body_entered.connect(_on_holy_smite_hit)
	
	# Smite animation and cleanup
	var smite_tween = create_tween()
	smite_tween.parallel().tween_property(smite, "scale", Vector3(1.5, 1.0, 1.5), 0.8)
	smite_tween.parallel().tween_property(smite_material, "albedo_color:a", 0.0, 1.2)
	smite_tween.tween_callback(smite.queue_free)

func raise_divine_barrier():
	if not can_raise_barrier():
		return
	
	is_raising_barrier = true
	velocity = Vector3.ZERO
	
	# Create divine barrier area
	var barrier = Area3D.new()
	barrier.name = "DivineBarrier"
	barrier.position = global_position + (player_target.global_position - global_position).normalized() * 6.0
	get_parent().add_child(barrier)
	
	# Barrier collision
	var barrier_collision = CollisionShape3D.new()
	var barrier_shape = CylinderShape3D.new()
	barrier_shape.radius_top = divine_barrier_radius
	barrier_shape.radius_bottom = divine_barrier_radius
	barrier_shape.height = 8.0
	barrier_collision.shape = barrier_shape
	barrier.add_child(barrier_collision)
	
	# Visual barrier (shimmering divine wall)
	var barrier_mesh = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.radius_top = divine_barrier_radius
	mesh.radius_bottom = divine_barrier_radius
	mesh.height = 8.0
	barrier_mesh.mesh = mesh
	barrier.add_child(barrier_mesh)
	
	# Barrier material - protective divine energy
	var barrier_material = StandardMaterial3D.new()
	barrier_material.albedo_color = Color(0.9, 1.0, 1.0, 0.4)
	barrier_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	barrier_material.emission_enabled = true
	barrier_material.emission = Color(1.0, 1.0, 0.9, 1.0)
	barrier_material.grow_amount = 0.2
	barrier_mesh.material_override = barrier_material
	
	# Barrier effects
	barrier.body_entered.connect(_on_barrier_collision)
	
	# Add to active barriers
	active_barriers.append(barrier)
	barrier_active = true
	
	divine_barrier_raised.emit(barrier)
	
	# Barrier duration
	var barrier_timer = Timer.new()
	barrier_timer.wait_time = 15.0
	barrier_timer.timeout.connect(_remove_barrier.bind(barrier))
	barrier_timer.one_shot = true
	barrier_timer.autostart = true
	barrier.add_child(barrier_timer)
	
	ability_timer.start()
	print("Divine Sentinel raises Divine Barrier - protection manifests!")

func activate_sanctuary_protection():
	if not can_activate_sanctuary():
		return
	
	sanctuary_active = true
	
	# Create sanctuary area around sentinel
	sanctuary_area = Area3D.new()
	sanctuary_area.name = "SanctuaryProtection"
	sanctuary_area.position = global_position
	add_child(sanctuary_area)
	
	# Sanctuary collision
	var sanctuary_collision = CollisionShape3D.new()
	var sanctuary_shape = SphereShape3D.new()
	sanctuary_shape.radius = sanctuary_radius
	sanctuary_collision.shape = sanctuary_shape
	sanctuary_area.add_child(sanctuary_collision)
	
	# Visual sanctuary (protective dome)
	var sanctuary_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = sanctuary_radius
	sanctuary_mesh.mesh = mesh
	sanctuary_area.add_child(sanctuary_mesh)
	
	# Sanctuary material
	var sanctuary_material = StandardMaterial3D.new()
	sanctuary_material.albedo_color = Color(1.0, 1.0, 0.95, 0.3)
	sanctuary_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sanctuary_material.emission_enabled = true
	sanctuary_material.emission = Color(1.0, 0.95, 0.9, 1.0)
	sanctuary_material.grow_amount = 0.1
	sanctuary_mesh.material_override = sanctuary_material
	
	# Sanctuary effects
	sanctuary_area.body_entered.connect(_on_sanctuary_entered)
	sanctuary_area.body_exited.connect(_on_sanctuary_exited)
	
	# Enhanced protection during sanctuary
	current_armor += 15
	divine_protection_level = 8
	
	# Visual enhancement
	if sanctuary_light:
		sanctuary_light.light_energy = 3.0
	
	sanctuary_protection_activated.emit()
	
	# End sanctuary after duration
	var sanctuary_timer = Timer.new()
	sanctuary_timer.wait_time = protection_duration
	sanctuary_timer.timeout.connect(_end_sanctuary_protection)
	sanctuary_timer.one_shot = true
	sanctuary_timer.autostart = true
	add_child(sanctuary_timer)
	
	ability_timer.start()
	print("Divine Sentinel activates Sanctuary Protection - allies are shielded!")

func should_raise_barrier() -> bool:
	# Raise barrier when allies need protection or player is advancing
	if protected_allies.size() > 0:
		return true
	
	if player_target:
		var distance_to_player = global_position.distance_to(player_target.global_position)
		return distance_to_player < 12.0
	
	return false

func _remove_barrier(barrier: Area3D):
	if is_instance_valid(barrier):
		active_barriers.erase(barrier)
		barrier.queue_free()
	
	barrier_active = false

func _end_sanctuary_protection():
	sanctuary_active = false
	current_armor -= 15
	divine_protection_level = 5
	
	if sanctuary_area and is_instance_valid(sanctuary_area):
		sanctuary_area.queue_free()
	
	if sanctuary_light:
		sanctuary_light.light_energy = 2.0

func can_cast_holy_smite() -> bool:
	return not is_casting_smite and smite_timer.is_stopped()

func can_raise_barrier() -> bool:
	return not is_raising_barrier and ability_timer.is_stopped() and active_barriers.size() < 3

func can_activate_sanctuary() -> bool:
	return not sanctuary_active and ability_timer.is_stopped()

func take_damage(damage: int, damage_type: String = ""):
	# Divine armor and sanctuary protection
	var actual_damage = max(1, damage - current_armor)
	
	# Sanctuary provides additional protection
	if sanctuary_active:
		actual_damage = int(actual_damage * 0.6)  # 40% damage reduction in sanctuary
	
	current_health -= actual_damage
	
	# Divine damage feedback
	create_divine_damage_flash()
	
	# Divine retaliation chance
	if randf() < 0.25 and can_activate_divine_retaliation():
		trigger_divine_retaliation()
	
	if current_health <= 0:
		die()
	else:
		# Desperate protection mode when low health
		if current_health < max_health * 0.3:
			enter_desperate_protection_mode()

func create_divine_damage_flash():
	var flash_tween = create_tween()
	flash_tween.tween_property(mesh_instance, "modulate", Color(1.3, 1.3, 1.0, 1.0), 0.1)
	flash_tween.tween_property(mesh_instance, "modulate", Color.WHITE, 0.1)

func can_activate_divine_retaliation() -> bool:
	return not is_casting_smite and not is_raising_barrier

func trigger_divine_retaliation():
	# Divine retaliatory burst
	var retaliation = Area3D.new()
	retaliation.name = "DivineRetaliation"
	retaliation.position = global_position
	get_parent().add_child(retaliation)
	
	var ret_collision = CollisionShape3D.new()
	var ret_shape = SphereShape3D.new()
	ret_shape.radius = 8.0
	ret_collision.shape = ret_shape
	retaliation.add_child(ret_collision)
	
	# Visual retaliation
	var ret_mesh = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 8.0
	ret_mesh.mesh = mesh
	retaliation.add_child(ret_mesh)
	
	var ret_material = StandardMaterial3D.new()
	ret_material.albedo_color = Color(1.0, 0.95, 0.8, 0.7)
	ret_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ret_material.emission_enabled = true
	ret_material.emission = Color(1.0, 0.9, 0.8, 1.0)
	ret_mesh.material_override = ret_material
	
	# Damage nearby targets
	retaliation.body_entered.connect(_on_retaliation_hit)
	
	# Fade retaliation
	var ret_tween = create_tween()
	ret_tween.parallel().tween_property(retaliation, "scale", Vector3.ZERO, 1.0)
	ret_tween.parallel().tween_property(ret_material, "albedo_color:a", 0.0, 1.0)
	ret_tween.tween_callback(retaliation.queue_free)

func enter_desperate_protection_mode():
	print("Divine Sentinel enters desperate protection - divine power surges!")
	
	# Enhanced abilities
	movement_speed *= 1.2
	divine_damage = int(divine_damage * 1.4)
	divine_protection_level = 10
	
	# Visual enhancement
	if divine_particles:
		divine_particles.amount = 180
	if sanctuary_light:
		sanctuary_light.light_energy = 4.0
		sanctuary_light.light_color = Color(1.0, 0.9, 0.8, 1.0)

func die():
	sentinel_defeated.emit()
	
	# Final protective blessing for any remaining allies
	grant_final_blessing()
	
	# Divine ascension effect
	create_divine_ascension()
	
	print("Divine Sentinel falls - their protective spirit ascends to the heavens")
	queue_free()

func grant_final_blessing():
	# Final blessing to all nearby allies
	for ally in protected_allies:
		if is_instance_valid(ally) and ally.has_method("receive_divine_blessing"):
			ally.receive_divine_blessing(5.0)  # Temporary power boost

func create_divine_ascension():
	# Ascension pillar of light
	var ascension = MeshInstance3D.new()
	get_parent().add_child(ascension)
	ascension.position = global_position
	
	var ascension_mesh = CylinderMesh.new()
	ascension_mesh.radius_top = 0.5
	ascension_mesh.radius_bottom = 4.0
	ascension_mesh.height = 25.0
	ascension.mesh = ascension_mesh
	ascension.position.y += 12.5
	
	var ascension_material = StandardMaterial3D.new()
	ascension_material.albedo_color = Color(1.0, 1.0, 0.95, 0.9)
	ascension_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ascension_material.emission_enabled = true
	ascension_material.emission = Color(1.0, 0.95, 0.9, 1.0)
	ascension.material_override = ascension_material
	
	# Ascension animation
	var ascension_tween = create_tween()
	ascension_tween.parallel().tween_property(ascension, "scale", Vector3.ZERO, 3.0)
	ascension_tween.parallel().tween_property(ascension, "modulate:a", 0.0, 3.0)
	ascension_tween.tween_callback(ascension.queue_free)

# Signal handlers
func _on_player_detected(body: Node3D):
	if body.is_in_group("player"):
		player_target = body
		print("Divine Sentinel detects threat - divine protection activates")

func _on_player_lost(body: Node3D):
	if body == player_target:
		player_target = null

func _on_ability_cooldown_finished():
	is_raising_barrier = false

func _on_smite_cooldown_finished():
	is_casting_smite = false

func _on_holy_smite_hit(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		var smite_damage = divine_damage * 2  # Powerful smite attack
		body.take_damage(smite_damage, "holy_smite")
		
		# Apply divine judgment effect
		if body.has_method("apply_status_effect"):
			body.apply_status_effect("divine_judgment", 6.0)
		
		print("Holy Smite strikes for ", smite_damage, " divine damage!")

func _on_barrier_collision(body: Node3D):
	if body == player_target:
		# Barrier blocks and repels player attacks
		if body.has_method("apply_knockback"):
			var knockback_direction = (body.global_position - global_position).normalized()
			body.apply_knockback(knockback_direction * 5.0)
		
		print("Divine Barrier repels the intruder!")

func _on_sanctuary_entered(body: Node3D):
	if body.is_in_group("judgment_hall_enemies") and body != self:
		# Grant protection to allied enemies
		if body.has_method("apply_divine_protection"):
			body.apply_divine_protection(0.5)  # 50% damage reduction
		print("Ally enters sanctuary - divine protection granted")
	elif body == player_target:
		# Player entering sanctuary triggers protective response
		print("Intruder enters sacred sanctuary - divine wrath awakens")

func _on_sanctuary_exited(body: Node3D):
	if body.is_in_group("judgment_hall_enemies") and body != self:
		# Remove protection when ally leaves
		if body.has_method("remove_divine_protection"):
			body.remove_divine_protection()

func _on_retaliation_hit(body: Node3D):
	if body == player_target and body.has_method("take_damage"):
		body.take_damage(35, "divine_retaliation")

# Public API
func get_divine_sentinel_info() -> Dictionary:
	return {
		"health": current_health,
		"max_health": max_health,
		"armor": current_armor,
		"sanctuary_active": sanctuary_active,
		"barriers_active": active_barriers.size(),
		"protected_allies": protected_allies.size(),
		"divine_protection_level": divine_protection_level
	}

func force_sanctuary_activation():
	activate_sanctuary_protection()

func emergency_barrier_deployment():
	if can_raise_barrier():
		raise_divine_barrier()

func get_protected_allies() -> Array[Node3D]:
	return protected_allies.duplicate()