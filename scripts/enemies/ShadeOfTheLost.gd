extends "res://scripts/enemies/BasicEnemy.gd"
## Shade of the Lost - Alma perdida nas Cavernas dos Esquecidos
## Inimigo melee rápido que representa almas que não conseguiram passar do Duat

func _ready():
	# Override stats para Shade of the Lost
	max_health = 100.0
	current_health = 100.0
	movement_speed = 3.0
	attack_damage = 20.0  # Mais forte que BasicEnemy
	detection_range = 10.0  # Detecta de mais longe
	attack_range = 1.8
	attack_cooldown = 1.2  # Ataca mais rápido
	
	print("👻 Shade of the Lost spawned - Lost Soul")
	
	# Setup visual específico
	setup_shade_visual()
	
	# Setup detection areas com novos valores
	setup_detection_areas()
	
	# Find player reference
	find_player_reference()
	
	# Setup patrol route
	setup_patrol_route()
	
	# Add to enemies group
	add_to_group("enemies")
	add_to_group("shades")

func setup_shade_visual():
	"""Configura visual específico da Shade"""
	# Visual mais escuro e espectral
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.7, 1.4, 0.7)  # Mais fino que BasicEnemy
	mesh_instance.mesh = box_mesh
	
	# Material espectral/sombrio
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.2, 0.1, 0.3, 0.8)  # Roxo escuro com transparência
	material.metallic = 0.0
	material.roughness = 1.0
	material.flags_transparent = true
	mesh_instance.material_override = material
	
	# Collision shape menor
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.7, 1.4, 0.7)
	collision_shape.shape = box_shape
	
	print("👻 Shade visual configured - Spectral appearance")

func handle_chase_state(_delta):
	"""Estado de perseguição específico da Shade - mais agressivo"""
	if not target_player:
		change_state(EnemyState.IDLE)
		return
	
	var direction = (target_player.global_position - global_position).normalized()
	direction.y = 0
	
	# Move faster towards player (Shade é mais agressiva)
	velocity.x = direction.x * movement_speed * 1.2  # 20% mais rápida na perseguição
	velocity.z = direction.z * movement_speed * 1.2
	
	# Face player
	if direction.length() > 0:
		look_at(target_player.global_position, Vector3.UP)
	
	# Check distance to player
	var distance = global_position.distance_to(target_player.global_position)
	
	if distance > detection_range * 1.8:  # Persegue por mais tempo
		change_state(EnemyState.IDLE)
		chase_timer = 0
	elif distance <= attack_range:
		change_state(EnemyState.ATTACKING)

func perform_attack():
	"""Ataque espectral da Shade"""
	if not target_player:
		return
	
	print("👻 Shade performs spectral attack!")
	
	# Check if player is still in range
	var distance = global_position.distance_to(target_player.global_position)
	if distance <= attack_range:
		# Apply damage to player
		if target_player.has_method("take_damage"):
			target_player.take_damage(attack_damage, self)
		
		print("💥 Shade hit player for ", attack_damage, " spectral damage")
		
		# Visual effect: brief flash
		if mesh_instance and mesh_instance.material_override:
			var material = mesh_instance.material_override as StandardMaterial3D
			if material:
				# Flash brighter for attack
				material.albedo_color = Color.WHITE
				await get_tree().create_timer(0.1).timeout
				material.albedo_color = Color(0.2, 0.1, 0.3, 0.8)

func die():
	"""Morte espectral da Shade"""
	print("💀 Shade of the Lost vanished into the void!")
	
	change_state(EnemyState.DEAD)
	
	# Efeito visual: fade out ao invés de ficar no chão
	if mesh_instance:
		var tween = create_tween()
		var material = mesh_instance.material_override as StandardMaterial3D
		if material:
			tween.tween_property(material, "albedo_color:a", 0.0, 1.0)
	
	# Disable collision
	collision_shape.disabled = true
	set_physics_process(false)
	
	# Emit signal
	enemy_died.emit(self)
	
	# Remove after fade
	await get_tree().create_timer(1.5).timeout
	queue_free()