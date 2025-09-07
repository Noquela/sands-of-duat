# RoomPortal.gd
# Interactive 3D portal that appears when rooms are cleared
# Sprint 6: Visual door selection system

extends Area3D

signal portal_activated(door_index: int)

# Portal properties
@export var door_index: int = 0
@export var door_symbol: String = "🚪"
@export var reward_description: String = "Unknown Destination"
@export var portal_color: Color = Color.CYAN

# Animation properties (sem rotação)
var glow_pulse_speed: float = 2.0
var particle_intensity_speed: float = 1.5
var original_position: Vector3

# Components
@onready var portal_mesh: MeshInstance3D = $PortalMesh
@onready var portal_collision: CollisionShape3D = $PortalCollision
@onready var portal_particles: GPUParticles3D = $PortalParticles
@onready var portal_label: Label3D = $PortalLabel

# Visual effects
var time_elapsed: float = 0.0
var is_active: bool = false
var player_nearby: bool = false

func _ready():
	print("🚪 Portal %d initialized: %s %s" % [door_index, door_symbol, reward_description])
	
	# Setup portal visualization
	_setup_portal_mesh()
	_setup_collision()
	
	# Connect area signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Store original position for animation
	original_position = global_position
	
	# Start as inactive
	set_active(false)

func _setup_portal_mesh():
	# Create a Hades-style arch portal (U inverted)
	var arch_mesh = _create_arch_mesh()
	portal_mesh.mesh = arch_mesh
	
	# Create glowing material
	var portal_material = StandardMaterial3D.new()
	portal_material.albedo_color = portal_color
	portal_material.emission = portal_color
	portal_material.emission_energy = 1.5
	portal_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	portal_material.albedo_color.a = 0.7
	portal_material.rim_enabled = true
	portal_material.rim_tint = 1.0
	portal_material.rim = 0.8
	portal_mesh.material_override = portal_material

func _create_arch_mesh() -> ArrayMesh:
	"""Create a U-shaped portal - two pillars with concave arch at top"""
	var array_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	# Portal dimensions
	var portal_width = 3.0
	var portal_height = 4.0
	var pillar_width = 0.3
	var pillar_depth = 0.4
	var arch_segments = 8  # For smooth curved arch
	
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	
	# Left pillar vertices (starts at ground Y=0)
	var left_x = -portal_width / 2.0
	# Front face
	vertices.append(Vector3(left_x - pillar_width/2, 0, -pillar_depth/2))           # 0 - bottom left
	vertices.append(Vector3(left_x + pillar_width/2, 0, -pillar_depth/2))           # 1 - bottom right
	vertices.append(Vector3(left_x + pillar_width/2, portal_height, -pillar_depth/2)) # 2 - top right
	vertices.append(Vector3(left_x - pillar_width/2, portal_height, -pillar_depth/2)) # 3 - top left
	
	# Back face
	vertices.append(Vector3(left_x - pillar_width/2, 0, pillar_depth/2))            # 4
	vertices.append(Vector3(left_x + pillar_width/2, 0, pillar_depth/2))            # 5
	vertices.append(Vector3(left_x + pillar_width/2, portal_height, pillar_depth/2)) # 6
	vertices.append(Vector3(left_x - pillar_width/2, portal_height, pillar_depth/2)) # 7
	
	# Right pillar vertices (starts at ground Y=0)
	var right_x = portal_width / 2.0
	# Front face
	vertices.append(Vector3(right_x - pillar_width/2, 0, -pillar_depth/2))          # 8
	vertices.append(Vector3(right_x + pillar_width/2, 0, -pillar_depth/2))          # 9
	vertices.append(Vector3(right_x + pillar_width/2, portal_height, -pillar_depth/2)) # 10
	vertices.append(Vector3(right_x - pillar_width/2, portal_height, -pillar_depth/2)) # 11
	
	# Back face
	vertices.append(Vector3(right_x - pillar_width/2, 0, pillar_depth/2))           # 12
	vertices.append(Vector3(right_x + pillar_width/2, 0, pillar_depth/2))           # 13
	vertices.append(Vector3(right_x + pillar_width/2, portal_height, pillar_depth/2)) # 14
	vertices.append(Vector3(right_x - pillar_width/2, portal_height, pillar_depth/2)) # 15
	
	# Create curved arch connecting the pillars (concave U shape)
	var arch_start_idx = vertices.size()
	var arch_radius = portal_width / 2.0
	var arch_center_y = portal_height - arch_radius * 0.3  # Lower the arch center for concave look
	
	# Generate arch vertices in a semi-circle (inverted U)
	for i in range(arch_segments + 1):
		var angle = PI * i / arch_segments  # From 0 to PI (half circle)
		var x = cos(angle) * arch_radius
		var y = arch_center_y + sin(angle) * arch_radius * 0.6  # Make it more concave
		
		# Front face arch vertices
		vertices.append(Vector3(x, y, -pillar_depth/2))
		# Back face arch vertices  
		vertices.append(Vector3(x, y, pillar_depth/2))
	
	# Add normals and UVs for all vertices
	for i in range(vertices.size()):
		normals.append(Vector3(0, 0, 1))
		uvs.append(Vector2(float(i % 4) / 4.0, float(i / 4) / 10.0))
	
	# Create faces for pillars
	var pillar_faces = [
		# Left pillar faces
		[0, 1, 2, 3],    # Front
		[4, 7, 6, 5],    # Back  
		[0, 4, 5, 1],    # Bottom
		[3, 2, 6, 7],    # Top
		[0, 3, 7, 4],    # Left
		[1, 5, 6, 2],    # Right
		
		# Right pillar faces
		[8, 9, 10, 11],  # Front
		[12, 15, 14, 13], # Back
		[8, 12, 13, 9],  # Bottom
		[11, 10, 14, 15], # Top
		[8, 11, 15, 12], # Left
		[9, 13, 14, 10]  # Right
	]
	
	# Add pillar faces
	for face in pillar_faces:
		indices.append(face[0])
		indices.append(face[1])
		indices.append(face[2])
		indices.append(face[0])
		indices.append(face[2])
		indices.append(face[3])
	
	# Add arch faces (connect arch segments)
	for i in range(arch_segments):
		var base_idx = arch_start_idx + i * 2
		var next_idx = arch_start_idx + (i + 1) * 2
		
		# Front face of arch
		indices.append(base_idx)      # Current front
		indices.append(next_idx)      # Next front
		indices.append(base_idx + 1)  # Current back
		
		indices.append(next_idx)      # Next front
		indices.append(next_idx + 1)  # Next back
		indices.append(base_idx + 1)  # Current back
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return array_mesh

func _setup_collision():
	# Create door collision shape 
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(3.0, 4.0, 1.0)  # Match door dimensions
	portal_collision.shape = box_shape

func _physics_process(delta):
	if not is_active:
		return
	
	time_elapsed += delta
	
	# Apenas pulsação do brilho - sem rotação (é uma porta)
	if portal_mesh and portal_mesh.material_override:
		var material = portal_mesh.material_override as StandardMaterial3D
		if player_nearby:
			# Brilho intenso quando player está próximo
			material.emission_energy = 2.0 + sin(time_elapsed * 6.0) * 0.3
		else:
			# Brilho suave constante
			material.emission_energy = 1.2 + sin(time_elapsed * glow_pulse_speed) * 0.2

func set_active(active: bool):
	is_active = active
	visible = active
	monitoring = active
	
	# Control particle emission
	if portal_particles:
		portal_particles.emitting = active
		if active:
			# Update particle color to match portal
			var particle_material = portal_particles.process_material as ParticleProcessMaterial
			if particle_material:
				particle_material.color = portal_color
	
	if active:
		print("🚪 Portal %d activated at position %s" % [door_index, global_position])
	else:
		print("🚪 Portal %d deactivated" % door_index)

func set_door_data(index: int, symbol: String, description: String, color: Color = Color.CYAN):
	door_index = index
	door_symbol = symbol
	reward_description = description
	portal_color = color
	
	# Update visual with new color
	if portal_mesh and portal_mesh.material_override:
		var material = portal_mesh.material_override as StandardMaterial3D
		material.albedo_color = portal_color
		material.emission = portal_color

func _on_body_entered(body):
	if body.is_in_group("player"):
		print("🚪 Player approaches portal %d: %s %s" % [door_index, door_symbol, reward_description])
		player_nearby = true
		
		# Show portal label and interaction hint
		_show_portal_label(true)
		_show_interaction_hint(true)

func _on_body_exited(body):
	if body.is_in_group("player"):
		print("🚪 Player leaves portal %d area" % door_index)
		player_nearby = false
		
		# Hide portal label and interaction hint
		_show_portal_label(false)
		_show_interaction_hint(false)

func _show_portal_label(show: bool):
	"""Show/hide portal label with room information"""
	if not portal_label:
		return
		
	if show:
		# Create descriptive text based on portal type
		var label_text = ""
		match door_symbol:
			"⚔️":
				label_text = "Câmara de Combate\n" + reward_description
			"🏺":
				label_text = "Tesouro Divino\n" + reward_description  
			"👑":
				label_text = "Encontro Elite\n" + reward_description
			"💀":
				label_text = "Chefe\n" + reward_description
			_:
				label_text = reward_description
		
		portal_label.text = label_text
		portal_label.modulate = Color(1, 1, 1, 1)
		
		# Animate label appearance
		var tween = create_tween()
		tween.tween_property(portal_label, "modulate:a", 1.0, 0.3)
	else:
		# Animate label disappearance
		var tween = create_tween()
		tween.tween_property(portal_label, "modulate:a", 0.0, 0.2)

func _show_interaction_hint(show: bool):
	"""Show interaction hint in console (could be UI later)"""
	if show:
		print("💡 Press E or F%d to enter %s portal" % [door_index + 1, door_symbol])

func activate_portal():
	"""Activate the portal (player interaction)"""
	if not is_active:
		print("⚠️ Portal %d is not active!" % door_index)
		return false
	
	print("🚪 Portal %d activated! Traveling to: %s %s" % [door_index, door_symbol, reward_description])
	portal_activated.emit(door_index)
	return true

func _input(event):
	if not is_active or not player_nearby:
		return
	
	if event is InputEventKey and event.pressed:
		# Accept E key or the corresponding F key
		if event.keycode == KEY_E or event.keycode == (KEY_F1 + door_index):
			activate_portal()
	
	# Also handle interact action
	if event.is_action_pressed("interact"):
		activate_portal()

# Visual feedback methods
func pulse_portal():
	"""Visual effect when portal is interacted with"""
	if portal_mesh and portal_mesh.material_override:
		var material = portal_mesh.material_override as StandardMaterial3D
		var tween = create_tween()
		tween.tween_property(material, "emission_energy", 3.0, 0.2)
		tween.tween_property(material, "emission_energy", 1.5, 0.3)

func get_portal_info() -> Dictionary:
	return {
		"door_index": door_index,
		"symbol": door_symbol,
		"description": reward_description,
		"position": global_position,
		"active": is_active,
		"player_nearby": player_nearby
	}
