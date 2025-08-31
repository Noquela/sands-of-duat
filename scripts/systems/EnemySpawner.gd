extends Node3D
## EnemySpawner - Sistema de spawn de inimigos para Sands of Duat
## Gerencia ondas de inimigos e spawn points

# Enemy scenes
var basic_enemy_scene: PackedScene = preload("res://scenes/enemies/BasicEnemy.tscn")
var shade_scene: PackedScene = null  # Will be created as needed
var mummy_archer_scene: PackedScene = null
var sand_djinn_scene: PackedScene = null

# Spawn configuration
var spawn_points: Array[Vector3] = []
var max_enemies: int = 8
var current_enemies: int = 0
var spawn_cooldown: float = 3.0
var spawn_timer: float = 0.0

# Wave system
var current_wave: int = 1
var enemies_per_wave: int = 5
var wave_multiplier: float = 1.2
var player_reference: Node3D = null

signal wave_started(wave_number)
signal wave_completed(wave_number)
signal enemy_spawned(enemy)

func _ready():
	print("⚔️ EnemySpawner initialized")
	
	# Find player reference
	find_player_reference()
	
	# Setup default spawn points if none provided
	if spawn_points.is_empty():
		setup_default_spawn_points()
	
	# Start first wave
	await get_tree().create_timer(2.0).timeout  # Delay before first wave
	start_wave(current_wave)

func _process(delta):
	# Update spawn timer
	if spawn_timer > 0:
		spawn_timer -= delta
	
	# Check if can spawn more enemies
	if current_enemies < max_enemies and spawn_timer <= 0:
		attempt_spawn()

func find_player_reference():
	"""Find player in scene"""
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player_reference = player
		print("⚔️ EnemySpawner found player reference")
	else:
		print("⚠️ EnemySpawner: Player not found!")

func setup_default_spawn_points():
	"""Setup default spawn points in a circle around origin"""
	var radius = 15.0
	var num_points = 8
	
	for i in range(num_points):
		var angle = (i * TAU) / num_points
		var spawn_pos = Vector3(
			cos(angle) * radius,
			0,
			sin(angle) * radius
		)
		spawn_points.append(spawn_pos)
	
	print("⚔️ EnemySpawner: Created ", num_points, " default spawn points")

func add_spawn_point(position: Vector3):
	"""Add custom spawn point"""
	spawn_points.append(position)
	print("⚔️ EnemySpawner: Added spawn point at ", position)

func start_wave(wave_number: int):
	"""Start a new wave"""
	current_wave = wave_number
	print("🌊 Wave ", wave_number, " starting!")
	
	# Calculate wave difficulty
	var wave_enemies = int(enemies_per_wave * pow(wave_multiplier, wave_number - 1))
	max_enemies = min(wave_enemies, 12)  # Cap at 12 enemies
	
	wave_started.emit(wave_number)

func attempt_spawn():
	"""Try to spawn an enemy"""
	if spawn_points.is_empty():
		print("⚠️ EnemySpawner: No spawn points available!")
		return
	
	# Choose random spawn point
	var spawn_pos = spawn_points[randi() % spawn_points.size()]
	
	# Check distance from player (don't spawn too close)
	if player_reference:
		var distance_to_player = spawn_pos.distance_to(player_reference.global_position)
		if distance_to_player < 8.0:
			# Find different spawn point
			for point in spawn_points:
				if point.distance_to(player_reference.global_position) >= 8.0:
					spawn_pos = point
					break
	
	# Choose enemy type based on wave
	var enemy_type = choose_enemy_type()
	
	# Spawn enemy
	var enemy = spawn_enemy(enemy_type, spawn_pos)
	if enemy:
		current_enemies += 1
		spawn_timer = spawn_cooldown
		enemy_spawned.emit(enemy)
		
		# Connect death signal
		if enemy.has_signal("enemy_died"):
			enemy.enemy_died.connect(_on_enemy_died)

func choose_enemy_type() -> String:
	"""Choose which enemy type to spawn based on wave"""
	var wave_factor = current_wave
	
	# Early waves: mostly basic enemies
	if wave_factor <= 2:
		var rand = randf()
		if rand < 0.7:
			return "basic"
		elif rand < 0.9:
			return "shade"
		else:
			return "archer"
	
	# Mid waves: mixed
	elif wave_factor <= 4:
		var rand = randf()
		if rand < 0.4:
			return "basic"
		elif rand < 0.65:
			return "shade"
		elif rand < 0.85:
			return "archer"
		else:
			return "djinn"
	
	# Late waves: more advanced enemies
	else:
		var rand = randf()
		if rand < 0.2:
			return "basic"
		elif rand < 0.45:
			return "shade"
		elif rand < 0.7:
			return "archer"
		else:
			return "djinn"

func spawn_enemy(enemy_type: String, position: Vector3) -> Node3D:
	"""Spawn specific enemy type at position"""
	var enemy: Node3D = null
	
	match enemy_type:
		"basic":
			enemy = create_basic_enemy()
		"shade":
			enemy = create_shade_enemy()
		"archer":
			enemy = create_archer_enemy()
		"djinn":
			enemy = create_djinn_enemy()
		_:
			print("⚠️ Unknown enemy type: ", enemy_type)
			return null
	
	if enemy:
		enemy.global_position = position
		get_parent().add_child(enemy)
		print("⚔️ Spawned ", enemy_type, " at ", position)
	
	return enemy

func create_basic_enemy() -> Node3D:
	"""Create BasicEnemy instance"""
	if basic_enemy_scene:
		return basic_enemy_scene.instantiate()
	else:
		# Create manually if scene not available
		var enemy = preload("res://scripts/enemies/BasicEnemy.gd").new()
		return enemy

func create_shade_enemy() -> Node3D:
	"""Create Shade of the Lost instance"""
	var enemy = preload("res://scripts/enemies/ShadeOfTheLost.gd").new()
	return enemy

func create_archer_enemy() -> Node3D:
	"""Create Mummy Archer instance"""
	var enemy = preload("res://scripts/enemies/MummyArcher.gd").new()
	return enemy

func create_djinn_enemy() -> Node3D:
	"""Create Sand Djinn instance"""
	var enemy = preload("res://scripts/enemies/SandDjinn.gd").new()
	return enemy

func _on_enemy_died(enemy):
	"""Handle enemy death"""
	current_enemies -= 1
	print("⚔️ Enemy died, remaining: ", current_enemies)
	
	# Check if wave completed
	if current_enemies <= 0:
		complete_wave()

func complete_wave():
	"""Complete current wave and prepare next"""
	print("🌊 Wave ", current_wave, " completed!")
	wave_completed.emit(current_wave)
	
	# Short break before next wave
	await get_tree().create_timer(3.0).timeout
	
	# Start next wave
	start_wave(current_wave + 1)

func set_spawn_points(points: Array[Vector3]):
	"""Set custom spawn points"""
	spawn_points = points
	print("⚔️ EnemySpawner: Set ", points.size(), " custom spawn points")

func pause_spawning():
	"""Pause enemy spawning"""
	set_process(false)
	print("⚔️ EnemySpawner: Paused")

func resume_spawning():
	"""Resume enemy spawning"""
	set_process(true)
	print("⚔️ EnemySpawner: Resumed")

func clear_all_enemies():
	"""Remove all spawned enemies"""
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	current_enemies = 0
	print("⚔️ EnemySpawner: Cleared all enemies")