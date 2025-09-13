# EnemySpawnManager.gd - Intelligent enemy spawning system
# SPRINT 9: Enemy Expansion & AI Enhancement
# CRITICAL: Manages intelligent enemy spawning and room composition

extends Node
class_name EnemySpawnManager

signal enemies_spawned(enemy_count: int, room_type: String)
signal spawn_wave_complete(wave: int, total_waves: int)
signal room_composition_generated(composition: Dictionary)

# Spawn configuration
var spawn_points: Array[Vector3] = []
var room_bounds: Array[Vector3] = []
var safe_spawn_distance: float = 5.0
var player_reference: Node3D

# Room composition rules
var room_compositions: Dictionary = {
	"combat": {
		"min_enemies": 3,
		"max_enemies": 8,
		"elite_chance": 0.1,
		"composition_rules": ["basic_heavy", "mixed_roles", "coordinated_group"]
	},
	"elite": {
		"min_enemies": 5,
		"max_enemies": 12,
		"elite_chance": 0.3,
		"composition_rules": ["tank_support", "caster_protection", "elite_pack"]
	},
	"treasure": {
		"min_enemies": 2,
		"max_enemies": 6,
		"elite_chance": 0.05,
		"composition_rules": ["treasure_guards", "light_defense"]
	}
}

# Spawning waves
var wave_spawning: bool = true
var waves_per_room: int = 2
var wave_delay: float = 3.0
var current_wave: int = 0

# Performance optimization
var max_concurrent_spawns: int = 3
var spawn_cooldown: float = 0.5
var last_spawn_time: float = 0.0

func _ready():
	_find_player_reference()
	print("👹 EnemySpawnManager: Sistema iniciado")

func _find_player_reference():
	"""Find player reference for spawn calculations"""
	player_reference = get_tree().get_first_node_in_group("player")
	
	if not player_reference:
		player_reference = get_node_or_null("/root/MainGameScene/Player")
		if not player_reference:
			player_reference = get_tree().current_scene.get_node_or_null("Player")
	
	if player_reference:
		print("🎯 EnemySpawnManager: Player encontrado para spawn calculations")
	else:
		push_warning("EnemySpawnManager: Player não encontrado - spawn positions podem ser imprecisos")

func generate_room_enemies(room_type: String, room_data: Dictionary, enemy_manager: Node):
	"""Generate enemy composition for room"""
	
	if not room_type in room_compositions:
		push_warning("Room type não reconhecido: " + room_type)
		room_type = "combat"  # Fallback
	
	var composition_rules = room_compositions[room_type]
	
	# Generate spawn points from room data
	_generate_spawn_points(room_data)
	
	# Calculate enemy composition
	var composition = _calculate_room_composition(room_type, composition_rules)
	
	# Emit composition for debugging
	room_composition_generated.emit(composition)
	
	# Execute spawning
	if wave_spawning:
		_spawn_in_waves(composition, enemy_manager)
	else:
		_spawn_all_at_once(composition, enemy_manager)
	
	print("👹 Generated %d enemies for %s room" % [composition.total_count, room_type])

func _generate_spawn_points(room_data: Dictionary):
	"""Generate valid spawn points from room data"""
	
	spawn_points.clear()
	room_bounds.clear()
	
	# Try to get spawn points from room data
	if "spawn_points" in room_data:
		spawn_points = room_data.spawn_points.duplicate()
	else:
		# Generate default spawn points based on room bounds
		_generate_default_spawn_points(room_data)
	
	# Filter spawn points that are too close to player
	_filter_spawn_points_by_player_distance()
	
	print("📍 Generated %d spawn points" % spawn_points.size())

func _generate_default_spawn_points(room_data: Dictionary):
	"""Generate default spawn points if none provided"""
	
	var room_size = room_data.get("size", Vector3(20, 0, 20))
	var room_center = room_data.get("center", Vector3.ZERO)
	
	# Generate spawn points around room perimeter
	var points_per_side = 3
	var offset = 2.0
	
	# North side
	for i in points_per_side:
		var x = room_center.x - room_size.x/2 + (i * room_size.x/(points_per_side-1))
		var z = room_center.z + room_size.z/2 - offset
		spawn_points.append(Vector3(x, 0, z))
	
	# South side
	for i in points_per_side:
		var x = room_center.x - room_size.x/2 + (i * room_size.x/(points_per_side-1))
		var z = room_center.z - room_size.z/2 + offset
		spawn_points.append(Vector3(x, 0, z))
	
	# East side
	for i in points_per_side:
		var x = room_center.x + room_size.x/2 - offset
		var z = room_center.z - room_size.z/2 + (i * room_size.z/(points_per_side-1))
		spawn_points.append(Vector3(x, 0, z))
	
	# West side
	for i in points_per_side:
		var x = room_center.x - room_size.x/2 + offset
		var z = room_center.z - room_size.z/2 + (i * room_size.z/(points_per_side-1))
		spawn_points.append(Vector3(x, 0, z))

func _filter_spawn_points_by_player_distance():
	"""Remove spawn points too close to player"""
	
	if not player_reference:
		return
	
	var player_pos = player_reference.global_position
	var filtered_points = []
	
	for point in spawn_points:
		var distance = point.distance_to(player_pos)
		if distance >= safe_spawn_distance:
			filtered_points.append(point)
		else:
			print("📍 Filtered spawn point too close to player: %s" % point)
	
	spawn_points = filtered_points

func _calculate_room_composition(room_type: String, rules: Dictionary) -> Dictionary:
	"""Calculate optimal enemy composition for room"""
	
	var composition = {
		"enemies": [],
		"total_count": 0,
		"waves": [],
		"elite_enemies": []
	}
	
	# Determine enemy count
	var min_count = rules.min_enemies
	var max_count = rules.max_enemies
	var enemy_count = randi_range(min_count, max_count)
	
	# Don't exceed spawn points
	enemy_count = min(enemy_count, spawn_points.size())
	composition.total_count = enemy_count
	
	# Choose composition rule
	var composition_rules = rules.composition_rules
	var selected_rule = composition_rules[randi() % composition_rules.size()]
	
	# Generate enemy list based on rule
	match selected_rule:
		"basic_heavy":
			composition.enemies = _generate_basic_heavy_composition(enemy_count)
		"mixed_roles":
			composition.enemies = _generate_mixed_roles_composition(enemy_count)
		"coordinated_group":
			composition.enemies = _generate_coordinated_group_composition(enemy_count)
		"tank_support":
			composition.enemies = _generate_tank_support_composition(enemy_count)
		"caster_protection":
			composition.enemies = _generate_caster_protection_composition(enemy_count)
		"elite_pack":
			composition.enemies = _generate_elite_pack_composition(enemy_count)
		"treasure_guards":
			composition.enemies = _generate_treasure_guards_composition(enemy_count)
		"light_defense":
			composition.enemies = _generate_light_defense_composition(enemy_count)
		_:
			composition.enemies = _generate_mixed_roles_composition(enemy_count)
	
	# Add elites based on chance
	_add_elite_enemies(composition, rules.elite_chance)
	
	# Organize into waves
	composition.waves = _organize_into_waves(composition.enemies)
	
	print("👹 Room composition: %s (%d enemies, %d waves)" % [selected_rule, composition.total_count, composition.waves.size()])
	
	return composition

func _generate_basic_heavy_composition(count: int) -> Array:
	"""Generate basic heavy composition (warriors + some variety)"""
	var enemies = []
	
	# 60% basic warriors, 40% variety
	var warrior_count = int(count * 0.6)
	var variety_count = count - warrior_count
	
	# Add warriors
	for i in warrior_count:
		enemies.append({
			"type": "basic_warrior",
			"level": randi_range(1, 3),
			"spawn_priority": 1
		})
	
	# Add variety enemies
	var variety_types = ["bone_construct", "tomb_archer", "scarab_swarm"]
	for i in variety_count:
		var type = variety_types[randi() % variety_types.size()]
		enemies.append({
			"type": type,
			"level": randi_range(1, 2),
			"spawn_priority": 2
		})
	
	return enemies

func _generate_mixed_roles_composition(count: int) -> Array:
	"""Generate mixed roles composition (balanced)"""
	var enemies = []
	
	# Define role distribution
	var roles = {
		"melee": ["basic_warrior", "bone_construct", "anubis_guard"],
		"ranged": ["tomb_archer", "pharaoh_mage"],
		"fast": ["scarab_swarm", "shadow_stalker"],
		"support": ["cursed_priest", "desert_elemental"]
	}
	
	# Distribute enemies across roles
	var role_keys = roles.keys()
	for i in count:
		var role = role_keys[i % role_keys.size()]
		var types = roles[role]
		var type = types[randi() % types.size()]
		
		enemies.append({
			"type": type,
			"level": randi_range(1, 3),
			"spawn_priority": randi_range(1, 3)
		})
	
	return enemies

func _generate_coordinated_group_composition(count: int) -> Array:
	"""Generate coordinated group composition (synergy focus)"""
	var enemies = []
	
	# Define synergy groups
	var synergy_groups = [
		["anubis_guard", "pharaoh_mage", "tomb_archer"],  # Tank + Caster + Support
		["shadow_stalker", "scarab_swarm", "cursed_priest"],  # Stealth + Swarm + Debuff
		["desert_elemental", "bone_construct", "tomb_archer"]  # Area Control + Tank + Ranged
	]
	
	var selected_group = synergy_groups[randi() % synergy_groups.size()]
	
	# Fill composition with synergy group
	for i in count:
		var type = selected_group[i % selected_group.size()]
		enemies.append({
			"type": type,
			"level": randi_range(1, 3),
			"spawn_priority": 1,  # High priority for coordinated spawning
			"synergy_group": true
		})
	
	return enemies

func _generate_tank_support_composition(count: int) -> Array:
	"""Generate tank and support composition (elite room style)"""
	var enemies = []
	
	# Ensure at least one tank
	enemies.append({
		"type": "anubis_guard",
		"level": randi_range(2, 4),
		"spawn_priority": 1,
		"role": "tank"
	})
	
	# Add supports and DPS
	var support_types = ["cursed_priest", "pharaoh_mage", "tomb_archer"]
	var remaining = count - 1
	
	for i in remaining:
		var type = support_types[i % support_types.size()]
		enemies.append({
			"type": type,
			"level": randi_range(1, 3),
			"spawn_priority": 2,
			"role": "support"
		})
	
	return enemies

func _generate_caster_protection_composition(count: int) -> Array:
	"""Generate caster protection composition"""
	var enemies = []
	
	# Central caster
	enemies.append({
		"type": "pharaoh_mage",
		"level": randi_range(2, 4),
		"spawn_priority": 1,
		"role": "main_caster"
	})
	
	# Protectors
	var protector_types = ["anubis_guard", "bone_construct", "basic_warrior"]
	var remaining = count - 1
	
	for i in remaining:
		var type = protector_types[i % protector_types.size()]
		enemies.append({
			"type": type,
			"level": randi_range(1, 3),
			"spawn_priority": 2,
			"role": "protector"
		})
	
	return enemies

func _generate_elite_pack_composition(count: int) -> Array:
	"""Generate elite pack composition (high-tier enemies)"""
	var enemies = []
	
	var elite_types = ["pharaoh_mage", "anubis_guard", "shadow_stalker", "desert_elemental"]
	
	for i in count:
		var type = elite_types[i % elite_types.size()]
		enemies.append({
			"type": type,
			"level": randi_range(2, 4),
			"spawn_priority": 1,
			"is_elite": true
		})
	
	return enemies

func _generate_treasure_guards_composition(count: int) -> Array:
	"""Generate treasure room guards"""
	var enemies = []
	
	# Light but dangerous guards
	var guard_types = ["shadow_stalker", "tomb_archer", "scarab_swarm"]
	
	for i in count:
		var type = guard_types[i % guard_types.size()]
		enemies.append({
			"type": type,
			"level": randi_range(1, 2),
			"spawn_priority": 1,
			"role": "treasure_guard"
		})
	
	return enemies

func _generate_light_defense_composition(count: int) -> Array:
	"""Generate light defense composition"""
	var enemies = []
	
	var light_types = ["basic_warrior", "scarab_swarm", "tomb_archer"]
	
	for i in count:
		var type = light_types[i % light_types.size()]
		enemies.append({
			"type": type,
			"level": 1,
			"spawn_priority": randi_range(1, 2)
		})
	
	return enemies

func _add_elite_enemies(composition: Dictionary, elite_chance: float):
	"""Add elite enemies based on chance"""
	
	if randf() > elite_chance:
		return
	
	# Upgrade random enemies to elite
	var elite_count = max(1, int(composition.total_count * 0.2))
	
	for i in elite_count:
		if i < composition.enemies.size():
			var enemy = composition.enemies[i]
			enemy["is_elite"] = true
			enemy["level"] = enemy.get("level", 1) + 2
			composition.elite_enemies.append(enemy)

func _organize_into_waves(enemies: Array) -> Array:
	"""Organize enemies into spawn waves"""
	
	if not wave_spawning or enemies.size() <= 3:
		return [enemies]  # Single wave
	
	var waves = []
	var enemies_per_wave = max(2, int(enemies.size() / waves_per_room))
	
	# Sort by spawn priority
	enemies.sort_custom(func(a, b): return a.get("spawn_priority", 1) < b.get("spawn_priority", 1))
	
	# Divide into waves
	for wave_index in waves_per_room:
		var wave_start = wave_index * enemies_per_wave
		var wave_end = min(wave_start + enemies_per_wave, enemies.size())
		
		if wave_start < enemies.size():
			var wave = enemies.slice(wave_start, wave_end)
			waves.append(wave)
	
	return waves

func _spawn_in_waves(composition: Dictionary, enemy_manager: Node):
	"""Spawn enemies in waves"""
	
	current_wave = 0
	var waves = composition.waves
	
	if waves.size() == 0:
		return
	
	# Spawn first wave immediately
	_spawn_wave(waves[0], enemy_manager)
	enemy_manager.enemy_spawns_remaining += _count_remaining_enemies(waves, 1)
	
	# Schedule remaining waves
	if waves.size() > 1:
		_schedule_next_wave(waves, 1, enemy_manager)

func _spawn_wave(wave_enemies: Array, enemy_manager: Node):
	"""Spawn a single wave of enemies"""
	
	current_wave += 1
	var spawned_count = 0
	
	for enemy_data in wave_enemies:
		var spawn_position = _get_next_spawn_position(spawned_count)
		if spawn_position == Vector3.ZERO:
			continue
		
		var enemy = enemy_manager.spawn_enemy(
			enemy_data.type, 
			spawn_position, 
			enemy_data.get("level", 1)
		)
		
		if enemy:
			spawned_count += 1
			
			# Apply special properties
			if enemy_data.get("is_elite", false):
				_apply_elite_modifiers(enemy)
	
	enemies_spawned.emit(spawned_count, "wave_" + str(current_wave))
	print("👹 Wave %d spawned: %d enemies" % [current_wave, spawned_count])

func _schedule_next_wave(waves: Array, wave_index: int, enemy_manager: Node):
	"""Schedule next wave spawn"""
	
	if wave_index >= waves.size():
		return
	
	# Create timer for next wave
	var timer = Timer.new()
	timer.wait_time = wave_delay
	timer.one_shot = true
	timer.timeout.connect(_spawn_next_wave.bind(waves, wave_index, enemy_manager, timer))
	add_child(timer)
	timer.start()

func _spawn_next_wave(waves: Array, wave_index: int, enemy_manager: Node, timer: Timer):
	"""Spawn next wave callback"""
	
	if wave_index < waves.size():
		_spawn_wave(waves[wave_index], enemy_manager)
		
		# Update remaining count
		enemy_manager.enemy_spawns_remaining += _count_remaining_enemies(waves, wave_index + 1)
		
		# Schedule next wave
		if wave_index + 1 < waves.size():
			_schedule_next_wave(waves, wave_index + 1, enemy_manager)
		else:
			spawn_wave_complete.emit(current_wave, waves.size())
	
	# Clean up timer
	timer.queue_free()

func _count_remaining_enemies(waves: Array, from_wave: int) -> int:
	"""Count enemies in remaining waves"""
	var count = 0
	for i in range(from_wave, waves.size()):
		count += waves[i].size()
	return count

func _spawn_all_at_once(composition: Dictionary, enemy_manager: Node):
	"""Spawn all enemies at once"""
	
	var enemies = composition.enemies
	var spawned_count = 0
	
	for i in enemies.size():
		var enemy_data = enemies[i]
		var spawn_position = _get_next_spawn_position(i)
		
		if spawn_position == Vector3.ZERO:
			continue
		
		var enemy = enemy_manager.spawn_enemy(
			enemy_data.type, 
			spawn_position, 
			enemy_data.get("level", 1)
		)
		
		if enemy:
			spawned_count += 1
			
			# Apply special modifiers
			if enemy_data.get("is_elite", false):
				_apply_elite_modifiers(enemy)
	
	enemies_spawned.emit(spawned_count, "all_at_once")
	print("👹 Spawned all enemies at once: %d total" % spawned_count)

func _get_next_spawn_position(index: int) -> Vector3:
	"""Get next available spawn position"""
	
	if spawn_points.size() == 0:
		push_warning("No spawn points available!")
		return Vector3.ZERO
	
	var spawn_index = index % spawn_points.size()
	var base_position = spawn_points[spawn_index]
	
	# Add slight randomization to prevent exact overlap
	var offset = Vector3(
		randf_range(-1.0, 1.0),
		0.0,
		randf_range(-1.0, 1.0)
	)
	
	return base_position + offset

func _apply_elite_modifiers(enemy: Node):
	"""Apply elite modifiers to enemy"""
	
	if enemy.has_method("set_elite_status"):
		enemy.set_elite_status(true)
	
	# Could add visual effects, stat boosts, etc.
	print("👑 Elite enemy spawned: %s" % enemy.name)

# Debug and utility methods
func get_spawn_metrics() -> Dictionary:
	return {
		"spawn_points_available": spawn_points.size(),
		"current_wave": current_wave,
		"wave_spawning_enabled": wave_spawning,
		"waves_per_room": waves_per_room,
		"player_reference_found": player_reference != null
	}

func force_spawn_test_enemies(enemy_manager: Node, count: int = 3):
	"""Force spawn test enemies for debugging"""
	
	if spawn_points.size() == 0:
		# Generate basic test spawn points
		for i in count:
			var angle = (i * 360.0 / count)
			var distance = 8.0
			var pos = Vector3(
				cos(deg_to_rad(angle)) * distance,
				0.0,
				sin(deg_to_rad(angle)) * distance
			)
			spawn_points.append(pos)
	
	# Spawn test composition
	for i in count:
		var enemy_types = ["basic_warrior", "scarab_swarm", "tomb_archer"]
		var type = enemy_types[i % enemy_types.size()]
		var position = _get_next_spawn_position(i)
		
		enemy_manager.spawn_enemy(type, position, 1)
	
	print("👹 Force spawned %d test enemies" % count)

func reset_for_new_room():
	"""Reset spawn manager for new room"""
	
	spawn_points.clear()
	room_bounds.clear()
	current_wave = 0
	last_spawn_time = 0.0
	
	# Re-find player in new room
	_find_player_reference()
	
	print("👹 EnemySpawnManager: Reset para nova sala")