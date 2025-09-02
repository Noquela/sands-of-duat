extends Node3D
class_name HealthSystem

signal health_changed(new_health: float, max_health: float)
signal health_depleted
signal damage_taken(damage: float)

@export var max_health: float = 100.0
@export var current_health: float
@export var regeneration_rate: float = 0.0
@export var can_regenerate: bool = false

func _ready():
	if current_health <= 0:
		current_health = max_health
	health_changed.emit(current_health, max_health)

func _process(delta):
	if can_regenerate and regeneration_rate > 0 and current_health < max_health:
		heal(regeneration_rate * delta)

func take_damage(damage: float):
	if current_health <= 0:
		return
	
	current_health = max(0, current_health - damage)
	damage_taken.emit(damage)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		die()

func heal(amount: float):
	if current_health >= max_health:
		return
	
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func die():
	health_depleted.emit()
	print(get_parent().name + " died!")

func get_health_percentage() -> float:
	return current_health / max_health if max_health > 0 else 0.0

func is_alive() -> bool:
	return current_health > 0