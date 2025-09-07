# HitFlash.gd
# Hit feedback effect for enemies
# Shows red flash when enemy takes damage

extends Node3D

var target_mesh: MeshInstance3D
var original_material: Material

func setup(enemy_mesh: MeshInstance3D):
	target_mesh = enemy_mesh
	if target_mesh:
		original_material = target_mesh.get_surface_override_material(0)
		_flash_red()

func _flash_red():
	if not target_mesh:
		return
	
	# Create red flash material
	var flash_material = StandardMaterial3D.new()
	flash_material.albedo_color = Color(1.5, 0.2, 0.2, 1)  # Bright red
	flash_material.emission_enabled = true
	flash_material.emission = Color(1, 0.1, 0.1, 1)
	flash_material.flags_unshaded = true  # Make it pop
	
	# Apply flash material
	target_mesh.set_surface_override_material(0, flash_material)
	
	# Create timer to restore material and cleanup
	get_tree().create_timer(0.1).timeout.connect(_restore_material)
	get_tree().create_timer(0.2).timeout.connect(_cleanup)

func _restore_material():
	if target_mesh:
		target_mesh.set_surface_override_material(0, original_material)

func _cleanup():
	queue_free()