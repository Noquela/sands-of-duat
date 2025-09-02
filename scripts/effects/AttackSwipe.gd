extends MeshInstance3D
class_name AttackSwipe

@export var animation_duration: float = 0.15

func _ready():
	# Start invisible by modifying the material
	var material = get_surface_override_material(0)
	if material:
		material.albedo_color.a = 0.0
	
	# Animate the swipe
	animate_swipe()

func animate_swipe():
	var material = get_surface_override_material(0)
	if not material:
		return
	
	# Fade in quickly
	var tween = create_tween()
	tween.parallel().tween_method(set_material_alpha, 0.0, 0.8, 0.05)
	tween.parallel().tween_property(self, "scale", Vector3(1.2, 1.2, 1.2), 0.05)
	
	# Hold briefly
	await tween.finished
	await get_tree().create_timer(0.05).timeout
	
	# Fade out
	tween = create_tween()
	tween.parallel().tween_method(set_material_alpha, 0.8, 0.0, 0.1)
	tween.parallel().tween_property(self, "scale", Vector3(1.5, 1.5, 1.5), 0.1)
	
	await tween.finished
	queue_free()

func set_material_alpha(alpha: float):
	var material = get_surface_override_material(0)
	if material:
		material.albedo_color.a = alpha

func setup_swipe(attack_direction: Vector3, swipe_range: float):
	# Orient the swipe to face attack direction
	if attack_direction != Vector3.ZERO:
		look_at(global_position + attack_direction, Vector3.UP)
	
	# Scale based on weapon range
	scale = Vector3(swipe_range * 0.5, 1.0, swipe_range * 0.5)
