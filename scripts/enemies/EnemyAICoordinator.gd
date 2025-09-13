# EnemyAICoordinator.gd - Coordinated AI system for enemy behaviors
# SPRINT 9: Enemy Expansion & AI Enhancement
# CRITICAL: Manages coordinated attacks and group behaviors

extends Node
class_name EnemyAICoordinator

signal coordinated_attack_triggered(attack_type: String, participants: Array[Node])
signal formation_changed(formation_type: String, enemies: Array[Node])
signal ai_state_changed(state: String)

# AI coordination states
enum CoordinationState {
	IDLE,
	COORDINATING,
	ATTACKING,
	RETREATING,
	FLANKING
}

# Registered enemies by role
var registered_enemies: Array[Node] = []
var enemies_by_role: Dictionary = {}
var coordination_groups: Array = []

# AI state management
var current_state: CoordinationState = CoordinationState.IDLE
var coordination_timer: float = 0.0
var next_coordination_delay: float = 3.0

# Player tracking for coordination
var player_node: Node3D
var player_last_position: Vector3
var player_movement_vector: Vector3

# Coordination parameters
var max_simultaneous_attackers: int = 3
var coordination_range: float = 15.0
var formation_update_interval: float = 1.5

# Performance tracking
var coordination_calculations_per_frame: int = 0
var max_calculations_per_frame: int = 10

func _ready():
	# Find player reference
	_find_player_reference()
	
	# Setup coordination timer
	var timer = Timer.new()
	timer.timeout.connect(_update_coordination)
	timer.wait_time = formation_update_interval
	timer.autostart = true
	add_child(timer)
	
	print("🤖 EnemyAICoordinator: Sistema iniciado")

func _find_player_reference():
	"""Find player node in scene"""
	player_node = get_tree().get_first_node_in_group("player")
	
	if not player_node:
		# Try alternate paths
		player_node = get_node_or_null("/root/MainGameScene/Player")
		if not player_node:
			player_node = get_tree().current_scene.get_node_or_null("Player")
	
	if player_node:
		print("🎯 EnemyAICoordinator: Player encontrado - %s" % player_node.name)
		player_last_position = player_node.global_position
	else:
		push_error("EnemyAICoordinator: Player não encontrado!")

func register_enemy(enemy: Node, enemy_data: Dictionary):
	"""Register enemy with coordinator"""
	if enemy in registered_enemies:
		return
	
	registered_enemies.append(enemy)
	
	# Organize by AI role
	var ai_role = enemy_data.get("ai_role", "basic")
	if not ai_role in enemies_by_role:
		enemies_by_role[ai_role] = []
	
	enemies_by_role[ai_role].append(enemy)
	
	# Set up enemy coordination interface
	_setup_enemy_coordination(enemy, enemy_data)
	
	print("🤖 Registered enemy: %s (Role: %s)" % [enemy.name, ai_role])
	
	# Update formations when new enemy joins
	_trigger_formation_update()

func unregister_enemy(enemy: Node):
	"""Remove enemy from coordination"""
	if enemy in registered_enemies:
		registered_enemies.erase(enemy)
		
		# Remove from role groups
		for role in enemies_by_role.keys():
			if enemy in enemies_by_role[role]:
				enemies_by_role[role].erase(enemy)
		
		# Update formations after enemy leaves
		_trigger_formation_update()
		
		print("🤖 Unregistered enemy: %s" % enemy.name)

func _setup_enemy_coordination(enemy: Node, enemy_data: Dictionary):
	"""Setup coordination interface with enemy"""
	
	# Set coordination priority
	var priority = enemy_data.get("coordination_priority", "low")
	if enemy.has_method("set_coordination_priority"):
		enemy.set_coordination_priority(priority)
	
	# Connect to enemy signals if available
	if enemy.has_signal("attack_started"):
		enemy.attack_started.connect(_on_enemy_attack_started.bind(enemy))
	
	if enemy.has_signal("damage_taken"):
		enemy.damage_taken.connect(_on_enemy_damaged.bind(enemy))
	
	# Set initial coordination data
	if enemy.has_method("set_coordinator"):
		enemy.set_coordinator(self)

func _process(delta: float):
	coordination_calculations_per_frame = 0
	
	if not player_node:
		return
	
	# Track player movement
	var current_player_pos = player_node.global_position
	player_movement_vector = current_player_pos - player_last_position
	player_last_position = current_player_pos
	
	# Update coordination timer
	coordination_timer += delta
	
	# Process AI state machine
	_process_coordination_state(delta)

func _process_coordination_state(delta: float):
	"""Process AI coordination state machine"""
	
	match current_state:
		CoordinationState.IDLE:
			if _should_coordinate():
				_transition_to_state(CoordinationState.COORDINATING)
		
		CoordinationState.COORDINATING:
			if coordination_timer >= next_coordination_delay:
				_execute_coordination()
				coordination_timer = 0.0
		
		CoordinationState.ATTACKING:
			_monitor_attack_coordination()
		
		CoordinationState.RETREATING:
			_process_retreat_coordination()
		
		CoordinationState.FLANKING:
			_process_flanking_coordination()

func _should_coordinate() -> bool:
	"""Check if coordination should be triggered"""
	
	# Need at least 2 enemies
	if registered_enemies.size() < 2:
		return false
	
	# Check if player is in range
	var enemies_in_range = 0
	for enemy in registered_enemies:
		if is_instance_valid(enemy) and player_node:
			var distance = enemy.global_position.distance_to(player_node.global_position)
			if distance <= coordination_range:
				enemies_in_range += 1
	
	return enemies_in_range >= 2

func _execute_coordination():
	"""Execute coordinated behavior based on enemy composition"""
	
	var available_enemies = _get_available_enemies()
	if available_enemies.size() < 2:
		return
	
	# Analyze enemy composition
	var composition = _analyze_enemy_composition(available_enemies)
	
	# Choose coordination strategy
	var strategy = _choose_coordination_strategy(composition)
	
	# Execute strategy
	match strategy:
		"pincer_attack":
			_execute_pincer_attack(available_enemies)
		"tank_and_flank":
			_execute_tank_and_flank(available_enemies)
		"caster_protection":
			_execute_caster_protection(available_enemies)
		"swarm_rush":
			_execute_swarm_rush(available_enemies)
		"area_control":
			_execute_area_control(available_enemies)

func _analyze_enemy_composition(enemies: Array) -> Dictionary:
	"""Analyze enemy types for strategy selection"""
	
	var composition = {
		"tanks": [],
		"casters": [],
		"flankers": [],
		"supports": [],
		"total": enemies.size()
	}
	
	for enemy in enemies:
		if not enemy.has_method("get_ai_role"):
			continue
			
		var role = enemy.get_ai_role()
		match role:
			"tank_protector", "heavy_bruiser":
				composition.tanks.append(enemy)
			"caster_teleport", "debuffer_support":
				composition.casters.append(enemy)
			"fast_flanker", "stealth_assassin":
				composition.flankers.append(enemy)
			"ranged_support", "area_controller":
				composition.supports.append(enemy)
	
	return composition

func _choose_coordination_strategy(composition: Dictionary) -> String:
	"""Choose best coordination strategy based on composition"""
	
	# Priority order based on enemy types available
	if composition.casters.size() > 0 and composition.tanks.size() > 0:
		return "caster_protection"
	elif composition.flankers.size() >= 2:
		return "pincer_attack"
	elif composition.tanks.size() > 0 and composition.flankers.size() > 0:
		return "tank_and_flank"
	elif composition.flankers.size() >= 3:
		return "swarm_rush"
	elif composition.supports.size() > 0:
		return "area_control"
	else:
		return "pincer_attack"  # Default fallback

func _execute_pincer_attack(enemies: Array):
	"""Execute pincer attack coordination"""
	
	if not player_node or enemies.size() < 2:
		return
	
	var player_pos = player_node.global_position
	var selected_enemies = enemies.slice(0, min(3, enemies.size()))
	
	# Assign flanking positions
	for i in selected_enemies.size():
		var enemy = selected_enemies[i]
		if enemy.has_method("set_coordination_target"):
			var angle = (i * 120.0) - 60.0  # Spread enemies in arc
			var direction = Vector3(cos(deg_to_rad(angle)), 0, sin(deg_to_rad(angle)))
			var target_pos = player_pos + direction * 5.0
			
			enemy.set_coordination_target(target_pos, "flank")
	
	_transition_to_state(CoordinationState.FLANKING)
	coordinated_attack_triggered.emit("pincer_attack", selected_enemies)
	print("⚔️ Executing pincer attack with %d enemies" % selected_enemies.size())

func _execute_tank_and_flank(enemies: Array):
	"""Execute tank protection with flanking support"""
	
	var tanks = []
	var flankers = []
	
	for enemy in enemies:
		if enemy.has_method("get_ai_role"):
			var role = enemy.get_ai_role()
			if role in ["tank_protector", "heavy_bruiser"]:
				tanks.append(enemy)
			elif role in ["fast_flanker", "stealth_assassin"]:
				flankers.append(enemy)
	
	# Position tank in front
	if tanks.size() > 0 and player_node:
		var tank = tanks[0]
		if tank.has_method("set_coordination_target"):
			var direction = (player_node.global_position - tank.global_position).normalized()
			var tank_pos = player_node.global_position - direction * 3.0
			tank.set_coordination_target(tank_pos, "tank")
	
	# Send flankers to sides
	for i in flankers.size():
		var flanker = flankers[i]
		if flanker.has_method("set_coordination_target") and player_node:
			var side = 1 if i % 2 == 0 else -1
			var flank_direction = Vector3(side, 0, 0)
			var flank_pos = player_node.global_position + flank_direction * 4.0
			flanker.set_coordination_target(flank_pos, "flank")
	
	_transition_to_state(CoordinationState.ATTACKING)
	coordinated_attack_triggered.emit("tank_and_flank", enemies)

func _execute_caster_protection(enemies: Array):
	"""Execute caster protection formation"""
	
	var casters = []
	var protectors = []
	
	for enemy in enemies:
		if enemy.has_method("get_ai_role"):
			var role = enemy.get_ai_role()
			if role in ["caster_teleport", "debuffer_support", "ranged_support"]:
				casters.append(enemy)
			else:
				protectors.append(enemy)
	
	# Position casters at safe distance
	for caster in casters:
		if caster.has_method("set_coordination_target") and player_node:
			var safe_distance = 8.0
			var direction = (caster.global_position - player_node.global_position).normalized()
			var safe_pos = player_node.global_position + direction * safe_distance
			caster.set_coordination_target(safe_pos, "cast")
	
	# Position protectors between casters and player
	for protector in protectors:
		if protector.has_method("set_coordination_target") and player_node:
			var guard_pos = player_node.global_position + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
			protector.set_coordination_target(guard_pos, "guard")
	
	_transition_to_state(CoordinationState.ATTACKING)
	coordinated_attack_triggered.emit("caster_protection", enemies)

func _get_available_enemies() -> Array:
	"""Get enemies available for coordination"""
	
	var available = []
	for enemy in registered_enemies:
		if is_instance_valid(enemy):
			# Check if enemy is not already in critical state
			if enemy.has_method("can_coordinate") and enemy.can_coordinate():
				available.append(enemy)
			elif not enemy.has_method("can_coordinate"):
				available.append(enemy)  # Assume available if no method
	
	return available

func _transition_to_state(new_state: CoordinationState):
	"""Transition to new coordination state"""
	
	if current_state != new_state:
		var old_state_name = CoordinationState.keys()[current_state]
		var new_state_name = CoordinationState.keys()[new_state]
		
		current_state = new_state
		next_coordination_delay = randf_range(2.0, 5.0)  # Randomize timing
		
		ai_state_changed.emit(new_state_name)
		print("🤖 AI State: %s → %s" % [old_state_name, new_state_name])

func notify_enemy_damaged(enemy: Node, damage: float, source: Node):
	"""Handle enemy taking damage for coordination response"""
	
	if not enemy in registered_enemies:
		return
	
	# Trigger defensive coordination
	_trigger_defensive_response(enemy, source)

func _trigger_defensive_response(damaged_enemy: Node, attacker: Node):
	"""Trigger coordinated response to enemy damage"""
	
	# Find nearby allies
	var nearby_allies = []
	for ally in registered_enemies:
		if ally != damaged_enemy and is_instance_valid(ally):
			var distance = ally.global_position.distance_to(damaged_enemy.global_position)
			if distance <= coordination_range * 0.5:
				nearby_allies.append(ally)
	
	# Coordinate counter-attack
	if nearby_allies.size() > 0:
		for ally in nearby_allies:
			if ally.has_method("set_coordination_target") and attacker:
				ally.set_coordination_target(attacker.global_position, "counter_attack")
		
		coordinated_attack_triggered.emit("counter_attack", nearby_allies)

func _trigger_formation_update():
	"""Update enemy formations"""
	
	if registered_enemies.size() < 2:
		return
	
	# Basic formation update - more complex formations can be added
	var formation_type = "spread"
	formation_changed.emit(formation_type, registered_enemies)

func reset_for_new_room():
	"""Reset coordinator for new room"""
	
	registered_enemies.clear()
	enemies_by_role.clear()
	coordination_groups.clear()
	
	current_state = CoordinationState.IDLE
	coordination_timer = 0.0
	
	# Re-find player in new room
	_find_player_reference()
	
	print("🤖 EnemyAICoordinator: Reset para nova sala")

# Debug and performance methods
func get_coordination_metrics() -> Dictionary:
	return {
		"registered_enemies": registered_enemies.size(),
		"coordination_state": CoordinationState.keys()[current_state],
		"enemies_by_role": _get_role_counts(),
		"calculations_per_frame": coordination_calculations_per_frame,
		"player_found": player_node != null
	}

func _get_role_counts() -> Dictionary:
	var counts = {}
	for role in enemies_by_role.keys():
		counts[role] = enemies_by_role[role].size()
	return counts

# Event handlers
func _on_enemy_attack_started(enemy: Node):
	"""Handle enemy starting attack"""
	print("⚔️ Enemy attack started: %s" % enemy.name)

func _on_enemy_damaged(enemy: Node, damage: float, source: Node):
	"""Handle enemy taking damage"""
	notify_enemy_damaged(enemy, damage, source)

# Additional coordination methods for specific strategies
func _execute_swarm_rush(enemies: Array):
	"""Execute swarm rush coordination"""
	
	if not player_node:
		return
	
	var rushers = enemies.slice(0, min(4, enemies.size()))
	var player_pos = player_node.global_position
	
	for rusher in rushers:
		if rusher.has_method("set_coordination_target"):
			# Add slight randomization to prevent overlap
			var offset = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
			rusher.set_coordination_target(player_pos + offset, "rush")
	
	_transition_to_state(CoordinationState.ATTACKING)
	coordinated_attack_triggered.emit("swarm_rush", rushers)

func _execute_area_control(enemies: Array):
	"""Execute area control coordination"""
	
	if not player_node:
		return
	
	var controllers = []
	for enemy in enemies:
		if enemy.has_method("get_ai_role"):
			var role = enemy.get_ai_role()
			if role in ["area_controller", "ranged_support", "debuffer_support"]:
				controllers.append(enemy)
	
	# Position controllers to control key areas
	for i in controllers.size():
		var controller = controllers[i]
		if controller.has_method("set_coordination_target"):
			var angle = (i * (360.0 / controllers.size()))
			var direction = Vector3(cos(deg_to_rad(angle)), 0, sin(deg_to_rad(angle)))
			var control_pos = player_node.global_position + direction * 6.0
			controller.set_coordination_target(control_pos, "control")
	
	_transition_to_state(CoordinationState.ATTACKING)
	coordinated_attack_triggered.emit("area_control", controllers)

func _monitor_attack_coordination():
	"""Monitor ongoing attack coordination"""
	
	# Check if attack is still valid
	var active_attackers = 0
	for enemy in registered_enemies:
		if is_instance_valid(enemy) and enemy.has_method("is_attacking"):
			if enemy.is_attacking():
				active_attackers += 1
	
	# Return to idle if no active attackers
	if active_attackers == 0:
		_transition_to_state(CoordinationState.IDLE)

func _process_retreat_coordination():
	"""Process coordinated retreat"""
	# Implementation for retreat coordination
	pass

func _process_flanking_coordination():
	"""Process coordinated flanking"""
	# Check if flanking is complete
	var flankers_in_position = 0
	for enemy in registered_enemies:
		if is_instance_valid(enemy) and enemy.has_method("is_in_position"):
			if enemy.is_in_position():
				flankers_in_position += 1
	
	# Transition to attack if flankers are in position
	if flankers_in_position >= 2:
		_transition_to_state(CoordinationState.ATTACKING)

func _update_coordination():
	"""Update coordination timer callback - triggered by Timer"""
	
	# Update formation if needed
	if registered_enemies.size() >= 2:
		_trigger_formation_update()
	
	# Check if coordination is needed
	if current_state == CoordinationState.IDLE and _should_coordinate():
		_transition_to_state(CoordinationState.COORDINATING)