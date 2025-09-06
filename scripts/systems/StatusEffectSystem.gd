extends Node
class_name StatusEffectSystem

signal status_effect_applied(target: Node3D, effect_data: Dictionary)
signal status_effect_expired(target: Node3D, effect_data: Dictionary)
signal status_effect_tick(target: Node3D, effect_data: Dictionary, damage: float)

enum StatusType {
	POISON,      # Damage over time
	BURN,        # Fire damage over time 
	FREEZE,      # Movement slow, periodic stun
	SHOCK,       # Chain lightning to nearby enemies
	WEAK,        # Reduced damage output
	CHARM,       # Fight for player temporarily
	SLOW,        # Reduced movement/attack speed
	DOOM,        # Massive damage after duration
	VULNERABLE,  # Take increased damage
	REGENERATE   # Health over time
}

@export_group("Status Settings")
@export var max_status_effects_per_target: int = 8
@export var status_tick_interval: float = 1.0

# Status effect database
var status_database: Dictionary = {}
var active_effects: Dictionary = {} # target_node -> Array[Dictionary]
var status_timers: Dictionary = {} # unique_id -> Timer

func _ready():
	setup_status_system()
	initialize_status_database()

func setup_status_system():
	add_to_group("status_system")
	print("Status Effect System initialized")

func initialize_status_database():
	# Poison - Egyptian asp venom
	status_database[StatusType.POISON] = {
		"name": "Asp's Venom",
		"description": "Poisoned by deadly asp venom",
		"color": Color.GREEN,
		"icon": "res://icons/status/poison.png",
		"default_duration": 8.0,
		"tick_interval": 1.0,
		"damage_per_tick": 10,
		"can_stack": true,
		"max_stacks": 5,
		"effects": {
			"damage_over_time": true,
			"damage_type": "poison"
		}
	}
	
	# Burn - Ra's divine fire
	status_database[StatusType.BURN] = {
		"name": "Divine Flames",
		"description": "Burning with Ra's sacred fire",
		"color": Color.ORANGE,
		"icon": "res://icons/status/burn.png",
		"default_duration": 6.0,
		"tick_interval": 0.5,
		"damage_per_tick": 15,
		"can_stack": true,
		"max_stacks": 3,
		"effects": {
			"damage_over_time": true,
			"damage_type": "fire",
			"spread_chance": 25 # Can spread to nearby enemies
		}
	}
	
	# Freeze - Khnum's cold earth
	status_database[StatusType.FREEZE] = {
		"name": "Khnum's Chill",
		"description": "Frozen by the cold earth",
		"color": Color.CYAN,
		"icon": "res://icons/status/freeze.png", 
		"default_duration": 4.0,
		"tick_interval": 1.0,
		"damage_per_tick": 5,
		"can_stack": false,
		"max_stacks": 1,
		"effects": {
			"movement_speed_multiplier": 0.3,
			"attack_speed_multiplier": 0.5,
			"periodic_stun_chance": 20
		}
	}
	
	# Shock - Set's chaotic lightning
	status_database[StatusType.SHOCK] = {
		"name": "Set's Lightning",
		"description": "Crackling with chaotic energy",
		"color": Color.YELLOW,
		"icon": "res://icons/status/shock.png",
		"default_duration": 5.0,
		"tick_interval": 1.5,
		"damage_per_tick": 20,
		"can_stack": false,
		"max_stacks": 1,
		"effects": {
			"chain_lightning": true,
			"chain_range": 6.0,
			"chain_targets": 3
		}
	}
	
	# Weak - Reduced combat effectiveness
	status_database[StatusType.WEAK] = {
		"name": "Weakened",
		"description": "Combat effectiveness reduced",
		"color": Color.GRAY,
		"icon": "res://icons/status/weak.png",
		"default_duration": 10.0,
		"tick_interval": 0.0, # No ticking damage
		"damage_per_tick": 0,
		"can_stack": false,
		"max_stacks": 1,
		"effects": {
			"damage_multiplier": 0.6,
			"critical_chance_reduction": 50
		}
	}
	
	# Charm - Mind control by Hathor's beauty
	status_database[StatusType.CHARM] = {
		"name": "Hathor's Charm",
		"description": "Mesmerized by divine beauty",
		"color": Color.PINK,
		"icon": "res://icons/status/charm.png",
		"default_duration": 3.0,
		"tick_interval": 0.0,
		"damage_per_tick": 0,
		"can_stack": false,
		"max_stacks": 1,
		"effects": {
			"mind_control": true,
			"ai_target_switch": "player_ally"
		}
	}
	
	# Slow - Reduced speed
	status_database[StatusType.SLOW] = {
		"name": "Slowed",
		"description": "Movement and actions slowed",
		"color": Color.BLUE,
		"icon": "res://icons/status/slow.png",
		"default_duration": 8.0,
		"tick_interval": 0.0,
		"damage_per_tick": 0,
		"can_stack": true,
		"max_stacks": 3,
		"effects": {
			"movement_speed_multiplier": 0.7,
			"attack_speed_multiplier": 0.8,
			"ability_cooldown_multiplier": 1.4
		}
	}
	
	# Doom - Anubis' judgment
	status_database[StatusType.DOOM] = {
		"name": "Anubis' Judgment",
		"description": "Marked for inevitable death",
		"color": Color.PURPLE,
		"icon": "res://icons/status/doom.png",
		"default_duration": 15.0,
		"tick_interval": 0.0,
		"damage_per_tick": 0,
		"can_stack": false,
		"max_stacks": 1,
		"effects": {
			"doom_damage": 200, # Massive damage when expires
			"doom_is_percentage": false
		}
	}
	
	# Vulnerable - Take increased damage
	status_database[StatusType.VULNERABLE] = {
		"name": "Vulnerable", 
		"description": "Taking increased damage",
		"color": Color.RED,
		"icon": "res://icons/status/vulnerable.png",
		"default_duration": 12.0,
		"tick_interval": 0.0,
		"damage_per_tick": 0,
		"can_stack": true,
		"max_stacks": 2,
		"effects": {
			"damage_taken_multiplier": 1.5,
			"critical_damage_taken_multiplier": 2.0
		}
	}
	
	# Regenerate - Health over time (beneficial)
	status_database[StatusType.REGENERATE] = {
		"name": "Regenerating",
		"description": "Healing over time",
		"color": Color.GREEN,
		"icon": "res://icons/status/regenerate.png",
		"default_duration": 20.0,
		"tick_interval": 2.0,
		"damage_per_tick": -25, # Negative = healing
		"can_stack": true,
		"max_stacks": 3,
		"effects": {
			"heal_over_time": true
		}
	}
	
	print("Status Effect database initialized with ", status_database.size(), " effects")

# Main application function
func apply_status_effect(target: Node3D, status_type: StatusType, duration: float = 0.0, potency: float = 1.0, source: Node3D = null) -> bool:
	if not target or not target.is_valid():
		return false
	
	var status_data = status_database.get(status_type)
	if not status_data:
		print("Unknown status type: ", status_type)
		return false
	
	# Use default duration if not specified
	if duration <= 0.0:
		duration = status_data.default_duration
	
	# Check if target already has this effect
	var existing_effect = find_active_effect(target, status_type)
	if existing_effect:
		if status_data.can_stack and existing_effect.stacks < status_data.max_stacks:
			# Stack the effect
			existing_effect.stacks += 1
			existing_effect.potency = max(existing_effect.potency, potency)
			print("Stacked ", status_data.name, " on ", target.name, " (", existing_effect.stacks, "/", status_data.max_stacks, ")")
			return true
		else:
			# Refresh duration
			existing_effect.remaining_duration = duration
			existing_effect.potency = max(existing_effect.potency, potency)
			print("Refreshed ", status_data.name, " on ", target.name)
			return true
	
	# Check effect limit
	if target in active_effects:
		if active_effects[target].size() >= max_status_effects_per_target:
			print("Target ", target.name, " at max status effects")
			return false
	else:
		active_effects[target] = []
	
	# Create new effect instance
	var effect_instance = create_effect_instance(status_type, duration, potency, source)
	active_effects[target].append(effect_instance)
	
	# Apply immediate effects
	apply_immediate_effects(target, effect_instance)
	
	# Setup ticking effects
	if status_data.tick_interval > 0.0:
		setup_effect_timer(target, effect_instance)
	
	# Setup expiration timer
	setup_expiration_timer(target, effect_instance)
	
	# Emit signal
	status_effect_applied.emit(target, effect_instance)
	
	print("Applied ", status_data.name, " to ", target.name, " for ", duration, "s")
	return true

func create_effect_instance(status_type: StatusType, duration: float, potency: float, source: Node3D) -> Dictionary:
	var status_data = status_database[status_type]
	var unique_id = str(Time.get_ticks_msec()) + "_" + str(randi())
	
	return {
		"id": unique_id,
		"type": status_type,
		"name": status_data.name,
		"description": status_data.description,
		"color": status_data.color,
		"icon": status_data.icon,
		"duration": duration,
		"remaining_duration": duration,
		"potency": potency,
		"stacks": 1,
		"source": source,
		"effects": status_data.effects.duplicate(true),
		"tick_interval": status_data.tick_interval,
		"damage_per_tick": status_data.damage_per_tick,
		"last_tick_time": 0.0
	}

func find_active_effect(target: Node3D, status_type: StatusType) -> Dictionary:
	if not target in active_effects:
		return {}
	
	for effect in active_effects[target]:
		if effect.type == status_type:
			return effect
	
	return {}

func apply_immediate_effects(target: Node3D, effect_instance: Dictionary):
	var effects = effect_instance.effects
	
	# Apply stat modifiers
	if effects.has("movement_speed_multiplier"):
		target.set_meta("status_movement_multiplier", effects.movement_speed_multiplier)
	
	if effects.has("attack_speed_multiplier"):
		target.set_meta("status_attack_speed_multiplier", effects.attack_speed_multiplier)
	
	if effects.has("damage_multiplier"):
		target.set_meta("status_damage_multiplier", effects.damage_multiplier)
	
	if effects.has("damage_taken_multiplier"):
		target.set_meta("status_damage_taken_multiplier", effects.damage_taken_multiplier)
	
	# Mind control for charm
	if effects.has("mind_control") and effects.mind_control:
		if target.has_method("set_ai_target"):
			target.set_ai_target("player_ally")

func setup_effect_timer(target: Node3D, effect_instance: Dictionary):
	if effect_instance.tick_interval <= 0.0:
		return
	
	var timer = Timer.new()
	timer.wait_time = effect_instance.tick_interval
	timer.timeout.connect(_on_status_tick.bind(target, effect_instance))
	add_child(timer)
	timer.start()
	
	status_timers[effect_instance.id + "_tick"] = timer

func setup_expiration_timer(target: Node3D, effect_instance: Dictionary):
	var timer = Timer.new()
	timer.wait_time = effect_instance.duration
	timer.one_shot = true
	timer.timeout.connect(_on_status_expire.bind(target, effect_instance))
	add_child(timer)
	timer.start()
	
	status_timers[effect_instance.id + "_expire"] = timer

func _on_status_tick(target: Node3D, effect_instance: Dictionary):
	if not target or not target.is_valid():
		cleanup_effect_timers(effect_instance.id)
		return
	
	var damage = effect_instance.damage_per_tick * effect_instance.stacks * effect_instance.potency
	
	# Handle different tick effects
	match effect_instance.type:
		StatusType.POISON, StatusType.BURN:
			if damage > 0:
				deal_status_damage(target, damage, effect_instance)
		StatusType.REGENERATE:
			if damage < 0: # Negative damage = healing
				heal_target(target, -damage)
		StatusType.SHOCK:
			handle_shock_chain(target, effect_instance)
		StatusType.FREEZE:
			handle_freeze_effects(target, effect_instance)
	
	# Check for spread effects (burn)
	if effect_instance.effects.has("spread_chance"):
		attempt_spread_effect(target, effect_instance)
	
	status_effect_tick.emit(target, effect_instance, damage)

func deal_status_damage(target: Node3D, damage: float, effect_instance: Dictionary):
	if target.has_method("take_damage"):
		target.take_damage(damage, effect_instance.source)
	elif target.has_method("apply_damage"):
		target.apply_damage(damage)
	print(target.name, " takes ", damage, " ", effect_instance.name, " damage")

func heal_target(target: Node3D, heal_amount: float):
	if target.has_method("heal"):
		target.heal(heal_amount)
	elif target.has_method("add_health"):
		target.add_health(heal_amount)
	print(target.name, " heals for ", heal_amount)

func handle_shock_chain(target: Node3D, effect_instance: Dictionary):
	var chain_range = effect_instance.effects.get("chain_range", 6.0)
	var chain_targets = effect_instance.effects.get("chain_targets", 3)
	var chain_damage = effect_instance.damage_per_tick * effect_instance.potency
	
	# Find nearby enemies
	var nearby_targets = find_nearby_enemies(target, chain_range, chain_targets)
	
	for chain_target in nearby_targets:
		if chain_target != target:
			deal_status_damage(chain_target, chain_damage, effect_instance)
			# Visual effect could be added here
			print("Lightning chains to ", chain_target.name)

func handle_freeze_effects(target: Node3D, effect_instance: Dictionary):
	# Chance to stun
	var stun_chance = effect_instance.effects.get("periodic_stun_chance", 20)
	if randf() * 100 < stun_chance:
		# Apply brief stun
		if target.has_method("apply_stun"):
			target.apply_stun(1.0)
		print(target.name, " is stunned by freeze!")

func find_nearby_enemies(origin: Node3D, search_range: float, max_count: int) -> Array[Node3D]:
	var nearby: Array[Node3D] = []
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if enemy == origin or not enemy.is_valid():
			continue
		
		var distance = origin.global_position.distance_to(enemy.global_position)
		if distance <= search_range:
			nearby.append(enemy)
			if nearby.size() >= max_count:
				break
	
	return nearby

func attempt_spread_effect(target: Node3D, effect_instance: Dictionary):
	var spread_chance = effect_instance.effects.get("spread_chance", 0)
	if randf() * 100 < spread_chance:
		var nearby = find_nearby_enemies(target, 4.0, 2)
		for spread_target in nearby:
			apply_status_effect(spread_target, effect_instance.type, effect_instance.duration * 0.5, effect_instance.potency * 0.75, effect_instance.source)

func _on_status_expire(target: Node3D, effect_instance: Dictionary):
	# Handle doom damage
	if effect_instance.type == StatusType.DOOM:
		var doom_damage = effect_instance.effects.get("doom_damage", 200) * effect_instance.potency
		deal_status_damage(target, doom_damage, effect_instance)
		print(target.name, " takes ", doom_damage, " DOOM damage!")
	
	remove_status_effect(target, effect_instance.type)

func remove_status_effect(target: Node3D, status_type: StatusType) -> bool:
	if not target in active_effects:
		return false
	
	var effects_list = active_effects[target]
	for i in range(effects_list.size() - 1, -1, -1):
		var effect = effects_list[i]
		if effect.type == status_type:
			# Remove immediate effects
			remove_immediate_effects(target, effect)
			
			# Cleanup timers
			cleanup_effect_timers(effect.id)
			
			# Remove from list
			effects_list.remove_at(i)
			
			# Emit signal
			status_effect_expired.emit(target, effect)
			
			print("Removed ", effect.name, " from ", target.name)
			return true
	
	return false

func remove_immediate_effects(target: Node3D, effect_instance: Dictionary):
	# Remove stat modifiers by resetting to 1.0
	target.set_meta("status_movement_multiplier", 1.0)
	target.set_meta("status_attack_speed_multiplier", 1.0)
	target.set_meta("status_damage_multiplier", 1.0)
	target.set_meta("status_damage_taken_multiplier", 1.0)
	
	# Remove mind control
	if effect_instance.effects.has("mind_control") and effect_instance.effects.mind_control:
		if target.has_method("reset_ai_target"):
			target.reset_ai_target()

func cleanup_effect_timers(effect_id: String):
	var tick_key = effect_id + "_tick"
	var expire_key = effect_id + "_expire"
	
	if tick_key in status_timers:
		status_timers[tick_key].queue_free()
		status_timers.erase(tick_key)
	
	if expire_key in status_timers:
		status_timers[expire_key].queue_free()
		status_timers.erase(expire_key)

# Public API
func get_active_effects(target: Node3D) -> Array[Dictionary]:
	return active_effects.get(target, [])

func has_status_effect(target: Node3D, status_type: StatusType) -> bool:
	return not find_active_effect(target, status_type).is_empty()

func get_status_effect_count(target: Node3D) -> int:
	return active_effects.get(target, []).size()

func clear_all_status_effects(target: Node3D):
	if not target in active_effects:
		return
	
	var effects_to_remove = active_effects[target].duplicate()
	for effect in effects_to_remove:
		remove_status_effect(target, effect.type)

func get_status_multiplier(target: Node3D, stat_name: String) -> float:
	var multiplier = 1.0
	var effects = get_active_effects(target)
	
	for effect in effects:
		var effect_data = effect.effects
		match stat_name:
			"movement_speed":
				if effect_data.has("movement_speed_multiplier"):
					multiplier *= effect_data.movement_speed_multiplier
			"attack_speed":
				if effect_data.has("attack_speed_multiplier"):
					multiplier *= effect_data.attack_speed_multiplier
			"damage_output":
				if effect_data.has("damage_multiplier"):
					multiplier *= effect_data.damage_multiplier
			"damage_taken":
				if effect_data.has("damage_taken_multiplier"):
					multiplier *= effect_data.damage_taken_multiplier
	
	return multiplier

func get_system_info() -> Dictionary:
	var total_effects = 0
	for target in active_effects:
		total_effects += active_effects[target].size()
	
	return {
		"total_active_effects": total_effects,
		"affected_targets": active_effects.size(),
		"available_status_types": status_database.size(),
		"active_timers": status_timers.size()
	}