extends Node3D
class_name CombatSystem

signal hit_landed(target: Node3D, damage: float)
signal attack_started
signal attack_ended

@export var attack_range: float = 3.0
@export var attack_damage: float = 25.0
@export var attack_cooldown: float = 0.3
@export var hitstop_duration: float = 0.05
@export var combo_window: float = 0.8

var can_attack: bool = true
var is_attacking: bool = false
var combo_count: int = 0
var combo_timer: float = 0.0

func _ready():
	pass

func _process(delta):
	# Update combo timer
	if combo_timer > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_count = 0

func try_attack(attacker: CharacterBody3D) -> bool:
	if not can_attack or is_attacking:
		print("Attack blocked - can_attack: ", can_attack, " is_attacking: ", is_attacking)
		return false
	
	print("Attack started!")
	perform_attack(attacker)
	return true

func perform_attack(attacker: CharacterBody3D):
	is_attacking = true
	can_attack = false
	
	# Update combo system
	combo_count += 1
	if combo_count > 3:
		combo_count = 1
	combo_timer = combo_window
	
	# Calculate combo damage multiplier
	var damage_multiplier = 1.0
	match combo_count:
		1:
			damage_multiplier = 1.0
			print("Combo 1: Basic Attack")
		2:
			damage_multiplier = 1.2
			print("Combo 2: Enhanced Attack")
		3:
			damage_multiplier = 1.5
			print("Combo 3: Power Attack!")
	
	attack_started.emit()
	
	# Get attack direction toward mouse cursor
	var camera = get_viewport().get_camera_3d()
	var mouse_pos = get_viewport().get_mouse_position()
	
	# Raycast from camera to world position at mouse cursor
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * 1000.0
	
	# Find where mouse ray hits the ground plane
	var ground_plane = Plane(Vector3.UP, 0.0)
	var mouse_world_pos = ground_plane.intersects_ray(from, to - from)
	
	var attack_origin = attacker.global_position + Vector3(0, 1, 0)
	var attack_direction = Vector3.ZERO
	
	if mouse_world_pos:
		attack_direction = (mouse_world_pos - attack_origin).normalized()
	else:
		# Fallback to player facing direction if mouse raycast fails
		attack_direction = -attacker.transform.basis.z
	
	# Check if using bow for ranged attack
	var weapon_system = attacker.weapon_system
	var current_weapon = weapon_system.get_current_weapon() if weapon_system else null
	
	if current_weapon and current_weapon.name == "Egyptian Bow":
		# Fire projectile
		fire_projectile(attack_origin, attack_direction, attack_damage * damage_multiplier)
	else:
		# Melee attack - perform raycast
		var attack_end = attack_origin + attack_direction * attack_range
		
		var space_state = attacker.get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(attack_origin, attack_end)
		query.collision_mask = 2  # Layer 2 (Enemies) = bit position 2 = mask value 2
		query.exclude = [attacker]
		
		var result = space_state.intersect_ray(query)
		
		# Show attack swipe animation
		spawn_attack_swipe(attack_origin, attack_direction, attack_range)
		
		if result:
			var hit_target = result.collider
			var final_damage = attack_damage * damage_multiplier
			deal_damage(hit_target, final_damage)
			apply_hitstop()
		else:
			print("Melee attack missed - no target in range")
	
	# Attack duration and cooldown
	await get_tree().create_timer(0.1).timeout  # Reduced attack animation time
	is_attacking = false
	attack_ended.emit()
	
	await get_tree().create_timer(attack_cooldown).timeout
	can_attack = true

func deal_damage(target: Node3D, damage: float):
	if target.has_method("take_damage"):
		target.take_damage(damage)
		hit_landed.emit(target, damage)
		
		# Spawn damage number
		spawn_damage_number(target, damage)
		
		# Flash enemy red briefly
		flash_target_red(target)

func spawn_damage_number(target: Node3D, damage: float):
	var DamageNumberClass = preload("res://scripts/ui/DamageNumber.gd")
	var damage_number = DamageNumberClass.new()
	get_tree().current_scene.add_child(damage_number)
	damage_number.show_damage(damage, target.global_position + Vector3(0, 2, 0))

func flash_target_red(target: Node3D):
	var mesh_instance = target.get_node("EnemyMesh")
	if mesh_instance and mesh_instance is MeshInstance3D and is_instance_valid(target):
		var original_material = mesh_instance.get_surface_override_material(0)
		var flash_material = StandardMaterial3D.new()
		flash_material.albedo_color = Color.RED
		mesh_instance.set_surface_override_material(0, flash_material)
		
		await get_tree().create_timer(0.1).timeout
		
		# Check if target still exists before restoring material
		if is_instance_valid(target) and is_instance_valid(mesh_instance):
			mesh_instance.set_surface_override_material(0, original_material)

func fire_projectile(origin: Vector3, direction: Vector3, projectile_damage: float):
	var ProjectileScene = preload("res://scenes/combat/Arrow.tscn")
	var projectile = ProjectileScene.instantiate()
	
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = origin
	projectile.setup(direction, projectile_damage, get_parent())
	
	print("Fired arrow for ", projectile_damage, " damage")

func spawn_attack_swipe(origin: Vector3, direction: Vector3, attack_range: float):
	var AttackSwipeScene = preload("res://scenes/effects/AttackSwipe.tscn")
	var swipe = AttackSwipeScene.instantiate()
	
	get_tree().current_scene.add_child(swipe)
	swipe.global_position = origin + direction * (attack_range * 0.5)
	swipe.setup_swipe(direction, attack_range)

func apply_hitstop():
	# Freeze game briefly for impact feeling
	Engine.time_scale = 0.1
	await get_tree().create_timer(hitstop_duration * 0.1).timeout
	Engine.time_scale = 1.0
