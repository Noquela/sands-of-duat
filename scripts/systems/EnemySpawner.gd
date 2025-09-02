extends Node3D
class_name EnemySpawner

signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed

@export_group("Spawning")
@export var max_enemies_alive: int = 8
@export var wave_delay: float = 3.0
@export var spawn_radius: float = 15.0
@export var min_spawn_distance: float = 8.0

@export_group("Enemy Scenes")
var shade_scene = preload("res://scenes/enemies/ShadeOfTheLost.tscn")
var mummy_scene = preload("res://scenes/enemies/MummyArcher.tscn")
var djinn_scene = preload("res://scenes/enemies/SandDjinn.tscn")

# Wave configuration
var wave_configs = [
	# Wave 1: Easy start
	{
		"shades": 2,
		"mummies": 0,
		"djinns": 0
	},
	# Wave 2: Introduction of ranged
	{
		"shades": 1,
		"mummies": 2,
		"djinns": 0
	},
	# Wave 3: Mixed encounter
	{
		"shades": 2,
		"mummies": 1,
		"djinns": 1
	},
	# Wave 4: Magic heavy
	{
		"shades": 1,
		"mummies": 1,
		"djinns": 2
	},
	# Wave 5: Final challenge
	{
		"shades": 3,
		"mummies": 2,
		"djinns": 2
	}
]

# State tracking
var current_wave: int = 0
var enemies_alive: Array = []
var player_target: Node3D
var is_spawning: bool = false

func _ready():
	# Find player
	player_target = get_tree().get_first_node_in_group("player")
	
	# Start first wave after a delay
	await get_tree().create_timer(2.0).timeout
	start_next_wave()

func start_next_wave():
	if current_wave >= wave_configs.size():
		all_waves_completed.emit()
		print("All waves completed!")
		return
	
	if is_spawning:
		return
	
	is_spawning = true
	wave_started.emit(current_wave + 1)
	print("Starting wave ", current_wave + 1)
	
	var config = wave_configs[current_wave]
	
	# Spawn enemies for this wave
	await spawn_wave_enemies(config)
	
	is_spawning = false

func spawn_wave_enemies(config: Dictionary):
	# Spawn Shades
	for i in config.get("shades", 0):
		if enemies_alive.size() >= max_enemies_alive:
			await wait_for_space()
		await spawn_enemy(shade_scene, "Shade")
		await get_tree().create_timer(0.5).timeout  # Small delay between spawns
	
	# Spawn Mummies
	for i in config.get("mummies", 0):
		if enemies_alive.size() >= max_enemies_alive:
			await wait_for_space()
		await spawn_enemy(mummy_scene, "Mummy")
		await get_tree().create_timer(0.5).timeout
	
	# Spawn Djinns
	for i in config.get("djinns", 0):
		if enemies_alive.size() >= max_enemies_alive:
			await wait_for_space()
		await spawn_enemy(djinn_scene, "Djinn")
		await get_tree().create_timer(0.5).timeout

func spawn_enemy(enemy_scene: PackedScene, enemy_type: String):
	var spawn_pos = get_random_spawn_position()
	if spawn_pos == Vector3.ZERO:
		print("Failed to find valid spawn position for ", enemy_type)
		return
	
	var enemy = enemy_scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = spawn_pos
	
	# Connect to enemy death signal
	enemy.enemy_died.connect(_on_enemy_died)
	
	# Add to tracking list
	enemies_alive.append(enemy)
	
	print("Spawned ", enemy_type, " at ", spawn_pos)

func get_random_spawn_position() -> Vector3:
	if not player_target:
		return Vector3.ZERO
	
	var player_pos = player_target.global_position
	var attempts = 20
	
	for i in attempts:
		# Generate random angle
		var angle = randf() * TAU
		var distance = randf_range(min_spawn_distance, spawn_radius)
		
		var spawn_pos = player_pos + Vector3(
			cos(angle) * distance,
			0.5,  # Slightly above ground
			sin(angle) * distance
		)
		
		# Check if position is valid (not inside walls, etc.)
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(
			spawn_pos + Vector3(0, 2, 0),
			spawn_pos + Vector3(0, -2, 0)
		)
		query.collision_mask = 4  # Environment layer
		
		var result = space_state.intersect_ray(query)
		if result:
			# Found ground, adjust Y position
			spawn_pos.y = result.position.y + 0.1
			return spawn_pos
	
	# Fallback position if no valid spot found
	print("Warning: Using fallback spawn position")
	return player_pos + Vector3(10, 0.5, 0)

func wait_for_space():
	while enemies_alive.size() >= max_enemies_alive:
		await get_tree().create_timer(0.5).timeout

func _on_enemy_died(enemy):
	# Remove from tracking
	enemies_alive.erase(enemy)
	print("Enemy died. Remaining: ", enemies_alive.size())
	
	# Check if wave is complete
	if enemies_alive.is_empty() and not is_spawning:
		wave_completed.emit(current_wave + 1)
		print("Wave ", current_wave + 1, " completed!")
		
		current_wave += 1
		
		# Start next wave after delay
		await get_tree().create_timer(wave_delay).timeout
		start_next_wave()

func get_enemies_alive_count() -> int:
	return enemies_alive.size()

func force_next_wave():
	# Debug function to skip to next wave
	for enemy in enemies_alive:
		if is_instance_valid(enemy):
			enemy.queue_free()
	enemies_alive.clear()
	
	current_wave += 1
	start_next_wave()