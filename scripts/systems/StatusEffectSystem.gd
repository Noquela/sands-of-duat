# StatusEffectSystem.gd
# Advanced status effect system for Sands of Duat
# Implements Burn, Chill, Weak, Vulnerable, and Egyptian-themed effects

extends Node
class_name StatusEffectSystem

# Status effect types with Egyptian theming
enum StatusType {
	NONE,
	BURN,           # Ra's fire - damage over time
	CHILL,          # Isis's ice - slows movement
	WEAK,           # Set's curse - reduces damage dealt
	VULNERABLE,     # Anubis's judgment - increases damage taken
	PHARAOHS_MIGHT, # Divine blessing - increases damage
	DIVINE_PROTECTION, # Bastet's shield - reduces damage taken
	CURSED_SLOW,    # Mummy's curse - movement penalty
	BLESSED_SPEED   # Thoth's wisdom - movement bonus
}

# Status effect data structure
class StatusEffect:
	var type: StatusType
	var duration: float
	var intensity: float
	var stacks: int = 1
	var source: String = ""
	var visual_effect: Node = null
	
	func _init(effect_type: StatusType, effect_duration: float, effect_intensity: float = 1.0):
		type = effect_type
		duration = effect_duration
		intensity = effect_intensity

# Active status effects per entity
var entity_effects: Dictionary = {}

func _ready():
	# Connect to game loop
	set_process(true)
	print("🌟 StatusEffectSystem initialized - Egyptian magical effects ready")

func _process(delta):
	# Update all active status effects
	for entity in entity_effects.keys():
		if is_instance_valid(entity):
			_update_entity_effects(entity, delta)
		else:
			# Clean up invalid entities
			entity_effects.erase(entity)

func apply_status_effect(target: Node, effect_type: StatusType, duration: float, intensity: float = 1.0, source: String = ""):
	"""Apply a status effect to target entity"""
	if not target:
		return false
	
	# Initialize entity effects if needed
	if not entity_effects.has(target):
		entity_effects[target] = []
	
	var effects = entity_effects[target] as Array
	
	# Check for existing effect of same type
	var existing_effect = _find_effect_by_type(effects, effect_type)
	
	if existing_effect:
		# Stack or refresh existing effect
		if _can_stack_effect(effect_type):
			existing_effect.stacks += 1
			existing_effect.intensity += intensity * 0.5  # Diminishing returns
		else:
			# Refresh duration if new duration is longer
			if duration > existing_effect.duration:
				existing_effect.duration = duration
				existing_effect.intensity = max(existing_effect.intensity, intensity)
	else:
		# Add new effect
		var new_effect = StatusEffect.new(effect_type, duration, intensity)
		new_effect.source = source
		effects.append(new_effect)
		
		# Apply initial effect
		_apply_effect_start(target, new_effect)
		
		# Create visual effect
		_create_visual_effect(target, new_effect)
	
	print("⚡ Applied %s to %s (Duration: %.1fs, Intensity: %.1f)" % [
		StatusType.keys()[effect_type], 
		target.name, 
		duration, 
		intensity
	])
	
	return true

func remove_status_effect(target: Node, effect_type: StatusType):
	"""Remove specific status effect from target"""
	if not entity_effects.has(target):
		return
	
	var effects = entity_effects[target] as Array
	
	for i in range(effects.size() - 1, -1, -1):
		var effect = effects[i] as StatusEffect
		if effect.type == effect_type:
			_remove_effect_end(target, effect)
			effects.remove_at(i)
			break

func clear_all_effects(target: Node):
	"""Remove all status effects from target"""
	if not entity_effects.has(target):
		return
	
	var effects = entity_effects[target] as Array
	
	for effect in effects:
		_remove_effect_end(target, effect)
	
	entity_effects.erase(target)

func has_status_effect(target: Node, effect_type: StatusType) -> bool:
	"""Check if target has specific status effect"""
	if not entity_effects.has(target):
		return false
	
	var effects = entity_effects[target] as Array
	return _find_effect_by_type(effects, effect_type) != null

func get_effect_intensity(target: Node, effect_type: StatusType) -> float:
	"""Get intensity of specific status effect"""
	if not entity_effects.has(target):
		return 0.0
	
	var effects = entity_effects[target] as Array
	var effect = _find_effect_by_type(effects, effect_type)
	
	return effect.intensity if effect else 0.0

func get_damage_multiplier(target: Node) -> float:
	"""Calculate damage multiplier based on status effects"""
	var multiplier = 1.0
	
	if not entity_effects.has(target):
		return multiplier
	
	var effects = entity_effects[target] as Array
	
	for effect in effects:
		match effect.type:
			StatusType.WEAK:
				multiplier *= (1.0 - effect.intensity * 0.3)  # Reduce damage dealt
			StatusType.PHARAOHS_MIGHT:
				multiplier *= (1.0 + effect.intensity * 0.5)  # Increase damage dealt
			StatusType.VULNERABLE:
				# This affects incoming damage, handled in damage calculation
				pass
	
	return multiplier

func get_damage_taken_multiplier(target: Node) -> float:
	"""Calculate damage taken multiplier based on status effects"""
	var multiplier = 1.0
	
	if not entity_effects.has(target):
		return multiplier
	
	var effects = entity_effects[target] as Array
	
	for effect in effects:
		match effect.type:
			StatusType.VULNERABLE:
				multiplier *= (1.0 + effect.intensity * 0.4)  # Increase damage taken
			StatusType.DIVINE_PROTECTION:
				multiplier *= (1.0 - effect.intensity * 0.3)  # Reduce damage taken
	
	return multiplier

func get_movement_multiplier(target: Node) -> float:
	"""Calculate movement speed multiplier based on status effects"""
	var multiplier = 1.0
	
	if not entity_effects.has(target):
		return multiplier
	
	var effects = entity_effects[target] as Array
	
	for effect in effects:
		match effect.type:
			StatusType.CHILL, StatusType.CURSED_SLOW:
				multiplier *= (1.0 - effect.intensity * 0.4)  # Reduce movement
			StatusType.BLESSED_SPEED:
				multiplier *= (1.0 + effect.intensity * 0.3)  # Increase movement
	
	return multiplier

func _update_entity_effects(entity: Node, delta: float):
	"""Update all effects for a specific entity"""
	var effects = entity_effects[entity] as Array
	
	# Update effect durations and apply per-tick effects
	for i in range(effects.size() - 1, -1, -1):
		var effect = effects[i] as StatusEffect
		
		# Apply per-tick effects
		_apply_effect_tick(entity, effect, delta)
		
		# Reduce duration
		effect.duration -= delta
		
		# Remove expired effects
		if effect.duration <= 0:
			_remove_effect_end(entity, effect)
			effects.remove_at(i)
	
	# Clean up if no effects remain
	if effects.is_empty():
		entity_effects.erase(entity)

func _apply_effect_start(target: Node, effect: StatusEffect):
	"""Apply initial effect when status is first applied"""
	match effect.type:
		StatusType.BURN:
			print("🔥 %s is burning with Ra's fire!" % target.name)
		StatusType.CHILL:
			print("❄️ %s is chilled by Isis's frost!" % target.name)
		StatusType.WEAK:
			print("💀 %s is weakened by Set's curse!" % target.name)
		StatusType.VULNERABLE:
			print("⚖️ %s is marked by Anubis's judgment!" % target.name)
		StatusType.PHARAOHS_MIGHT:
			print("👑 %s is blessed with Pharaoh's might!" % target.name)
		StatusType.DIVINE_PROTECTION:
			print("🛡️ %s is protected by Bastet's blessing!" % target.name)

func _apply_effect_tick(target: Node, effect: StatusEffect, delta: float):
	"""Apply per-frame effect updates"""
	match effect.type:
		StatusType.BURN:
			# Apply damage over time
			_apply_burn_damage(target, effect, delta)

func _remove_effect_end(target: Node, effect: StatusEffect):
	"""Clean up when effect expires"""
	# Remove visual effects
	if effect.visual_effect and is_instance_valid(effect.visual_effect):
		effect.visual_effect.queue_free()
	
	match effect.type:
		StatusType.BURN:
			print("🔥 %s is no longer burning" % target.name)
		StatusType.CHILL:
			print("❄️ %s warms up" % target.name)
		StatusType.WEAK:
			print("💀 %s recovers strength" % target.name)
		StatusType.VULNERABLE:
			print("⚖️ %s is no longer vulnerable" % target.name)

func _apply_burn_damage(target: Node, effect: StatusEffect, delta: float):
	"""Apply burn damage over time"""
	var damage_per_second = effect.intensity * 15.0 * effect.stacks
	var damage_this_tick = damage_per_second * delta
	
	# Apply damage if target has health system
	if target.has_method("take_damage"):
		target.take_damage(damage_this_tick, "burn")

func _find_effect_by_type(effects: Array, effect_type: StatusType) -> StatusEffect:
	"""Find existing effect of specific type"""
	for effect in effects:
		if (effect as StatusEffect).type == effect_type:
			return effect as StatusEffect
	return null

func _can_stack_effect(effect_type: StatusType) -> bool:
	"""Check if effect type can stack"""
	match effect_type:
		StatusType.BURN, StatusType.WEAK, StatusType.VULNERABLE:
			return true
		_:
			return false

func _create_visual_effect(target: Node, effect: StatusEffect):
	"""Create visual effect for status"""
	# TODO: Create particle effects for each status type
	# This will be enhanced when we add particle systems
	pass

# Quick access functions for common effects
func apply_burn(target: Node, duration: float = 5.0, intensity: float = 1.0):
	apply_status_effect(target, StatusType.BURN, duration, intensity, "Fire Magic")

func apply_chill(target: Node, duration: float = 3.0, intensity: float = 1.0):
	apply_status_effect(target, StatusType.CHILL, duration, intensity, "Ice Magic")

func apply_weak(target: Node, duration: float = 4.0, intensity: float = 1.0):
	apply_status_effect(target, StatusType.WEAK, duration, intensity, "Curse Magic")

func apply_vulnerable(target: Node, duration: float = 3.0, intensity: float = 1.0):
	apply_status_effect(target, StatusType.VULNERABLE, duration, intensity, "Judgment Magic")