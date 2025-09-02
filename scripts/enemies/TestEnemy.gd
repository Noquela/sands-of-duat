extends CharacterBody3D

const HealthSystemClass = preload("res://scripts/combat/HealthSystem.gd")
var health_system: HealthSystemClass

func _ready():
	# Add to enemies group for collision detection
	add_to_group("enemies")
	
	# Setup health system
	health_system = HealthSystemClass.new()
	health_system.max_health = 50.0
	add_child(health_system)
	
	# Connect death signal
	health_system.health_depleted.connect(_on_death)

func take_damage(damage: float):
	if health_system:
		health_system.take_damage(damage)

func _on_death():
	# Add death effect here later
	queue_free()