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

func _animate_swipe():
	if not mesh_instance:
		return
	
	# Scale animation - simple approach
	var tween = create_tween()
	
	# Start small and grow
	scale = Vector3(0.1, 0.1, 0.1)
	tween.tween_property(self, "scale", Vector3(1.2, 1.2, 1.2), 0.2)
	
	# Fade out material if available
	var material = mesh_instance.get_surface_override_material(0)
	if material:
		tween.tween_property(material, "albedo_color:a", 0.0, 0.1)

func _on_timer_timeout():
	queue_free()
