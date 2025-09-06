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
	
	# Scale animation
	var scale_tween = create_tween()
	scale_tween.set_parallel(true)
	
	# Start small and grow
	scale = Vector3(0.1, 0.1, 0.1)
	scale_tween.tween_property(self, "scale", Vector3(1.0, 1.0, 1.0), 0.1)
	scale_tween.tween_property(self, "scale", Vector3(1.2, 1.2, 1.2), 0.2)
	scale_tween.tween_delay(0.1)
	
	# Fade out
	var material = mesh_instance.get_surface_override_material(0)
	if material:
		scale_tween.tween_property(material, "albedo_color:a", 0.0, 0.2)
		scale_tween.tween_delay(0.1)

func _on_timer_timeout():
	queue_free()