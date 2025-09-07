# AttackSwipe.gd
# Attack Visual Effect for Sands of Duat
# Sprint 3: Visual feedback for combat actions

extends Node3D

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var timer: Timer = $Timer

func _ready():
	# Connect timer to auto-destroy
	timer.timeout.connect(_on_timer_timeout)
	
	# Animate the swipe effect
	_animate_swipe()

func set_direction(direction: Vector3):
	# Orient the swipe effect toward the attack direction
	if direction.length() > 0.1:
		# Calculate rotation to face the direction
		var target_rotation = atan2(-direction.x, -direction.z)
		rotation.y = target_rotation

func _animate_swipe():
	if not mesh_instance:
		return
	
	# Enhanced animation - more visible and dramatic
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Start small and grow bigger
	scale = Vector3(0.2, 0.2, 0.2)
	tween.tween_property(self, "scale", Vector3(2.5, 2.5, 2.5), 0.15)
	
	# Rotate for dynamic effect
	var initial_rotation = rotation_degrees
	tween.tween_property(self, "rotation_degrees", initial_rotation + Vector3(0, 0, 180), 0.15)
	
	# Create fresh material glow effect every time
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.8, 0.2, 0.8)  # Golden color
	material.emission_enabled = true
	material.emission = Color(1, 0.6, 0.1, 1)  # Bright glow
	mesh_instance.set_surface_override_material(0, material)
	
	# Continue growing and fade out
	tween.tween_property(self, "scale", Vector3(3.0, 3.0, 3.0), 0.2)
	tween.tween_property(material, "albedo_color:a", 0.0, 0.15)

func _on_timer_timeout():
	queue_free()
