# HealthSystem.gd
# Health and Damage System for Sands of Duat
# Sprint 3: Health management for player and enemies

extends Node

signal health_changed(new_health: int, max_health: int)
signal health_depleted
signal damage_taken(amount: int, damage_type: String)
signal healed(amount: int)

# Health properties
@export var max_health: int = 100
@export var current_health: int
@export var regeneration_rate: float = 0.0  # HP per second
@export var damage_resistance: Dictionary = {}  # damage_type: resistance_percent

# Damage immunity
var is_invulnerable: bool = false
var invulnerability_timer: float = 0.0
const DAMAGE_IMMUNITY_DURATION = 0.5  # Brief immunity after taking damage

# Status effects affecting health
var poison_damage: int = 0
var poison_duration: float = 0.0
var heal_over_time: int = 0
var heal_duration: float = 0.0

func _ready():
	current_health = max_health
	print("❤️ Health System initialized: %d/%d HP" % [current_health, max_health])

func _process(delta):
	# Handle invulnerability timer
	if invulnerability_timer > 0:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0:
			is_invulnerable = false
	
	# Handle regeneration
	if regeneration_rate > 0 and current_health < max_health:
		heal(int(regeneration_rate * delta))
	
	# Handle poison damage over time
	if poison_duration > 0:
		poison_duration -= delta
		# Apply poison every 1 second
		if int(poison_duration) != int(poison_duration + delta):
			take_damage(poison_damage, "poison", false)  # No immunity from poison
	
	# Handle healing over time
	if heal_duration > 0:
		heal_duration -= delta
		# Apply healing every 1 second
		if int(heal_duration) != int(heal_duration + delta):
			heal(heal_over_time)

# Main damage function
func take_damage(amount: int, damage_type: String = "physical", apply_immunity: bool = true) -> bool:
	if is_invulnerable and apply_immunity:
		print("🛡️ Damage blocked by invulnerability")
		return false
	
	if amount <= 0:
		return false
	
	# Apply resistance
	var final_damage = amount
	if damage_type in damage_resistance:
		var resistance = damage_resistance[damage_type]
		final_damage = int(amount * (1.0 - resistance))
		print("🛡️ Damage reduced by %.1f%% resistance: %d -> %d" % [resistance * 100, amount, final_damage])
	
	# Apply damage
	current_health = max(0, current_health - final_damage)
	damage_taken.emit(final_damage, damage_type)
	health_changed.emit(current_health, max_health)
	
	print("💔 Took %d %s damage. Health: %d/%d" % [final_damage, damage_type, current_health, max_health])
	
	# Set damage immunity if applicable
	if apply_immunity:
		is_invulnerable = true
		invulnerability_timer = DAMAGE_IMMUNITY_DURATION
	
	# Check if health depleted
	if current_health <= 0:
		health_depleted.emit()
		print("💀 Health depleted!")
		return true
	
	return false

# Healing function
func heal(amount: int) -> int:
	if amount <= 0:
		return 0
	
	var old_health = current_health
	current_health = min(max_health, current_health + amount)
	var actual_heal = current_health - old_health
	
	if actual_heal > 0:
		healed.emit(actual_heal)
		health_changed.emit(current_health, max_health)
		print("💚 Healed for %d HP. Health: %d/%d" % [actual_heal, current_health, max_health])
	
	return actual_heal

# Set maximum health (can also increase current health proportionally)
func set_max_health(new_max: int, heal_to_full: bool = false):
	var old_max = max_health
	max_health = new_max
	
	if heal_to_full:
		current_health = max_health
	else:
		# Scale current health proportionally
		var health_ratio = float(current_health) / float(old_max)
		current_health = int(max_health * health_ratio)
	
	health_changed.emit(current_health, max_health)
	print("❤️ Max health changed: %d -> %d. Current: %d" % [old_max, max_health, current_health])

# Status effects
func apply_poison(damage_per_second: int, duration: float):
	poison_damage = damage_per_second
	poison_duration = duration
	print("☠️ Poison applied: %d DPS for %.1f seconds" % [damage_per_second, duration])

func apply_heal_over_time(heal_per_second: int, duration: float):
	heal_over_time = heal_per_second
	heal_duration = duration
	print("💚 Regeneration applied: %d HPS for %.1f seconds" % [heal_per_second, duration])

# Set resistance to damage type (0.0 = no resistance, 1.0 = immune)
func set_damage_resistance(damage_type: String, resistance: float):
	damage_resistance[damage_type] = clamp(resistance, 0.0, 1.0)
	print("🛡️ %s resistance set to %.1f%%" % [damage_type, resistance * 100])

# Getters for other systems
func get_health() -> int:
	return current_health

func get_max_health() -> int:
	return max_health

func get_health_percentage() -> float:
	return float(current_health) / float(max_health)

func is_alive() -> bool:
	return current_health > 0

func is_at_full_health() -> bool:
	return current_health >= max_health

# Get health stats for UI
func get_health_stats() -> Dictionary:
	return {
		"current_health": current_health,
		"max_health": max_health,
		"health_percentage": get_health_percentage(),
		"is_invulnerable": is_invulnerable,
		"invulnerability_timer": invulnerability_timer,
		"poison_damage": poison_damage,
		"poison_duration": poison_duration,
		"heal_over_time": heal_over_time,
		"heal_duration": heal_duration
	}