# GhostImage.gd
# Individual ghost/afterimage that fades over time
# Used by AfterimageEffect system

extends MeshInstance3D

var fade_duration: float = 0.3
var ghost_material: StandardMaterial3D

func _ready():
	# Setup the ghost appearance
	_create_ghost_material()
	_start_fade_animation()

func _create_ghost_material():
	# Create translucent ghost material
	ghost_material = StandardMaterial3D.new()
	ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_material.albedo_color = Color(0.2, 0.6, 1.0, 0.6)  # Blue ghost tint
	ghost_material.emission_enabled = true
	ghost_material.emission = Color(0.1, 0.3, 0.8, 1.0)  # Blue glow
	ghost_material.emission_energy = 1.5
	ghost_material.flags_unshaded = true  # No lighting for clean look
	ghost_material.no_depth_test = false
	ghost_material.flags_do_not_use_vertex_colors = true
	
	# Apply material
	material_override = ghost_material

func setup_ghost(target_mesh: Mesh):
	# Configure the ghost with target mesh
	if target_mesh:
		mesh = target_mesh
	else:
		# Fallback to default box mesh
		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(1, 2, 1)
		mesh = box_mesh

func _start_fade_animation():
	# Animate the ghost fading out
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Fade transparency
	tween.tween_method(_update_ghost_alpha, 0.6, 0.0, fade_duration)
	
	# Slight scale reduction for dissolve effect
	tween.tween_property(self, "scale", scale * 0.8, fade_duration)
	
	# Auto-cleanup when done
	tween.tween_callback(_cleanup).set_delay(fade_duration)

func _update_ghost_alpha(alpha: float):
	# Update material alpha during fade
	if ghost_material:
		var current_color = ghost_material.albedo_color
		ghost_material.albedo_color = Color(current_color.r, current_color.g, current_color.b, alpha)
		ghost_material.emission_energy = 1.5 * alpha  # Fade glow too

func _cleanup():
	# Remove the ghost from scene
	queue_free()