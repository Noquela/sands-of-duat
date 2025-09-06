extends Node3D
class_name PoolOfMemories

signal memory_upgrade_purchased(upgrade_id: String)
signal player_entered_hub()
signal player_exited_hub()

@export_group("Hub Settings")
@export var hub_radius: float = 20.0
@export var pool_reflection_intensity: float = 0.8
@export var memory_station_positions: Array[Vector3] = [
	Vector3(-8, 0, -8),   # Health station
	Vector3(8, 0, -8),    # Combat station  
	Vector3(-8, 0, 8),    # Divine station
	Vector3(8, 0, 8),     # Special station
	Vector3(0, 0, -12),   # Weapons station
	Vector3(-12, 0, 0),   # Speed station
	Vector3(12, 0, 0),    # Wealth station
	Vector3(0, 0, 12)     # Resilience station
]

# Node references
@onready var environment: Node3D = $Environment
@onready var pool_floor: MeshInstance3D = $Environment/PoolFloor
@onready var pool_reflection: MeshInstance3D = $Environment/PoolReflection
@onready var memory_stations: Node3D = $MemoryStations
@onready var memory_ui: Control = $MemoryUI

# Systems
var memory_system: MemorySystem
var weapon_aspect_system: WeaponAspectSystem
var player: Node3D
var camera: Camera3D

# Hub state
var is_hub_active: bool = false
var current_selected_station: Node3D
var station_categories: Array[String] = [
	"health", "damage", "boons", "special", "weapons", "speed", "wealth", "status"
]

func _ready():
	setup_pool_hub()
	find_system_references()
	create_hub_environment()

func setup_pool_hub():
	add_to_group("pool_of_memories")
	print("Pool of Memories hub initialized")

func find_system_references():
	memory_system = get_tree().get_first_node_in_group("memory_system")
	weapon_aspect_system = get_tree().get_first_node_in_group("weapon_aspect_system")
	player = get_tree().get_first_node_in_group("player")
	
	if memory_system:
		memory_system.memory_fragments_changed.connect(_on_fragments_changed)
		memory_system.memory_upgrade_purchased.connect(_on_upgrade_purchased)

func create_hub_environment():
	# Create pool floor (Egyptian blue marble)
	create_pool_floor()
	
	# Create reflective pool surface
	create_pool_reflection()
	
	# Create memory upgrade stations
	create_memory_stations()
	
	# Setup lighting
	create_hub_lighting()
	
	# Create NPCs (Echo spirits)
	create_echo_npcs()

func create_pool_floor():
	if not pool_floor:
		return
	
	# Create circular pool floor mesh
	var circle_mesh = CylinderMesh.new()
	circle_mesh.radius_top = hub_radius
	circle_mesh.radius_bottom = hub_radius
	circle_mesh.height = 0.2
	circle_mesh.radial_segments = 32
	
	pool_floor.mesh = circle_mesh
	pool_floor.position = Vector3(0, -0.1, 0)
	
	# Create Egyptian marble material
	var floor_material = StandardMaterial3D.new()
	floor_material.albedo_color = Color(0.2, 0.4, 0.8, 1.0)  # Egyptian blue
	floor_material.metallic = 0.3
	floor_material.roughness = 0.1
	floor_material.emission_enabled = true
	floor_material.emission = Color(0.1, 0.2, 0.4, 1.0)
	
	pool_floor.material_override = floor_material

func create_pool_reflection():
	if not pool_reflection:
		return
	
	# Create reflective water surface
	var water_mesh = CylinderMesh.new()
	water_mesh.radius_top = hub_radius * 0.9
	water_mesh.radius_bottom = hub_radius * 0.9
	water_mesh.height = 0.05
	water_mesh.radial_segments = 64
	
	pool_reflection.mesh = water_mesh
	pool_reflection.position = Vector3(0, 0.1, 0)
	
	# Create reflective water material
	var water_material = StandardMaterial3D.new()
	water_material.albedo_color = Color(0.0, 0.3, 0.8, 0.7)
	water_material.metallic = 1.0
	water_material.roughness = 0.05
	water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_material.emission_enabled = true
	water_material.emission = Color(0.0, 0.1, 0.3, 1.0)
	
	# Add magical ripple effect (placeholder)
	var tween = create_tween()
	tween.set_loops()
	tween.tween_method(_animate_water_surface, 0.0, 2.0 * PI, 4.0)
	
	pool_reflection.material_override = water_material

func create_memory_stations():
	if not memory_stations:
		return
	
	# Clear existing stations
	for child in memory_stations.get_children():
		child.queue_free()
	
	# Create upgrade stations for each category
	for i in range(station_categories.size()):
		if i < memory_station_positions.size():
			var category = station_categories[i]
			var position = memory_station_positions[i]
			create_upgrade_station(category, position, i)

func create_upgrade_station(category: String, position: Vector3, index: int):
	# Create station container
	var station = StaticBody3D.new()
	station.name = "MemoryStation_" + category.capitalize()
	station.position = position
	memory_stations.add_child(station)
	
	# Add to interaction group
	station.add_to_group("memory_stations")
	station.set_meta("category", category)
	station.set_meta("station_index", index)
	
	# Create station mesh (Egyptian obelisk style)
	var mesh_instance = MeshInstance3D.new()
	var obelisk_mesh = BoxMesh.new()
	obelisk_mesh.size = Vector3(1.5, 3.0, 1.5)
	mesh_instance.mesh = obelisk_mesh
	mesh_instance.position = Vector3(0, 1.5, 0)
	station.add_child(mesh_instance)
	
	# Create collision
	var collision = CollisionShape3D.new()
	var collision_shape = BoxShape3D.new()
	collision_shape.size = Vector3(1.5, 3.0, 1.5)
	collision.shape = collision_shape
	collision.position = Vector3(0, 1.5, 0)
	station.add_child(collision)
	
	# Create station material with category color
	var station_material = StandardMaterial3D.new()
	station_material.albedo_color = get_category_color(category)
	station_material.metallic = 0.8
	station_material.roughness = 0.2
	station_material.emission_enabled = true
	station_material.emission = get_category_color(category) * 0.3
	mesh_instance.material_override = station_material
	
	# Add hieroglyphs/symbols (placeholder text)
	create_station_label(station, get_category_display_name(category))
	
	# Add interaction area
	var interaction_area = Area3D.new()
	var area_collision = CollisionShape3D.new()
	var area_shape = SphereShape3D.new()
	area_shape.radius = 2.5
	area_collision.shape = area_shape
	interaction_area.add_child(area_collision)
	station.add_child(interaction_area)
	
	# Connect interaction signals
	interaction_area.body_entered.connect(_on_station_entered.bind(station))
	interaction_area.body_exited.connect(_on_station_exited.bind(station))

func create_hub_lighting():
	# Main ambient light
	var ambient_light = DirectionalLight3D.new()
	ambient_light.name = "HubAmbientLight"
	ambient_light.position = Vector3(0, 15, 0)
	ambient_light.rotation_degrees = Vector3(-45, 45, 0)
	ambient_light.light_energy = 0.8
	ambient_light.light_color = Color(1.0, 0.9, 0.7, 1.0)  # Warm Egyptian light
	environment.add_child(ambient_light)
	
	# Pool mystical glow
	var pool_light = OmniLight3D.new()
	pool_light.name = "PoolGlow"
	pool_light.position = Vector3(0, 2, 0)
	pool_light.light_energy = 1.5
	pool_light.light_color = Color(0.3, 0.7, 1.0, 1.0)  # Mystical blue
	pool_light.omni_range = hub_radius * 1.5
	environment.add_child(pool_light)
	
	# Station accent lights
	for i in range(memory_station_positions.size()):
		if i < station_categories.size():
			var station_light = SpotLight3D.new()
			station_light.position = memory_station_positions[i] + Vector3(0, 5, 0)
			station_light.rotation_degrees = Vector3(-90, 0, 0)
			station_light.light_energy = 1.0
			station_light.light_color = get_category_color(station_categories[i])
			station_light.spot_range = 8.0
			station_light.spot_angle = 45.0
			environment.add_child(station_light)

func create_echo_npcs():
	# Create 3 echo spirits around the pool
	var echo_positions = [
		Vector3(-15, 1, 0),   # Left side
		Vector3(0, 1, -15),   # Far side
		Vector3(15, 1, 0)     # Right side
	]
	
	var echo_names = ["Echo of Nefertari", "Echo of Royal Scribe", "Echo of Palace Guard"]
	var echo_dialogues = [
		"My prince... your memories flow like the sacred Nile...",
		"The ancient wisdom awaits your touch, young Khenti...",
		"Your training serves you well in this realm of shadows..."
	]
	
	for i in range(echo_positions.size()):
		create_echo_spirit(echo_positions[i], echo_names[i], echo_dialogues[i])

func create_echo_spirit(pos: Vector3, spirit_name: String, dialogue: String):
	var echo = CharacterBody3D.new()
	echo.name = spirit_name
	echo.position = pos
	environment.add_child(echo)
	
	# Visual representation (glowing orb)
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.8
	mesh_instance.mesh = sphere_mesh
	echo.add_child(mesh_instance)
	
	# Ghostly material
	var ghost_material = StandardMaterial3D.new()
	ghost_material.albedo_color = Color(0.8, 0.9, 1.0, 0.6)
	ghost_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_material.emission_enabled = true
	ghost_material.emission = Color(0.4, 0.6, 1.0, 1.0)
	mesh_instance.material_override = ghost_material
	
	# Floating animation
	var float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(echo, "position:y", pos.y + 0.5, 2.0)
	float_tween.tween_property(echo, "position:y", pos.y - 0.5, 2.0)
	
	# Store dialogue
	echo.set_meta("dialogue", dialogue)
	echo.add_to_group("echo_spirits")

func create_station_label(station: StaticBody3D, label_text: String):
	# Create floating text label above station
	var label = Label3D.new()
	label.text = label_text
	label.position = Vector3(0, 4, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(1.0, 1.0, 1.0, 0.8)
	station.add_child(label)

func get_category_color(category: String) -> Color:
	match category:
		"health": return Color.RED
		"damage": return Color.ORANGE_RED
		"speed": return Color.CYAN
		"boons": return Color.GOLD
		"wealth": return Color.GREEN
		"special": return Color.PURPLE
		"weapons": return Color.SILVER
		"status": return Color.MAGENTA
		_: return Color.WHITE

func get_category_display_name(category: String) -> String:
	match category:
		"health": return "Vitality Memories"
		"damage": return "Combat Memories"
		"speed": return "Mobility Memories"
		"boons": return "Divine Memories"
		"wealth": return "Prosperity Memories"
		"special": return "Mystical Memories"
		"weapons": return "Arsenal Memories"
		"status": return "Resilience Memories"
		_: return category.capitalize() + " Memories"

func _animate_water_surface(angle: float):
	if pool_reflection and pool_reflection.material_override:
		var material = pool_reflection.material_override as StandardMaterial3D
		if material:
			# Create gentle ripple effect
			var ripple_strength = 0.1 + 0.05 * sin(angle * 2)
			material.emission = Color(0.0, 0.1, 0.3, 1.0) * ripple_strength

func enter_hub(entering_player: Node3D):
	if is_hub_active:
		return
	
	is_hub_active = true
	player = entering_player
	
	# Position player at hub center
	if player:
		player.global_position = Vector3(0, 0.5, 0)
		player_entered_hub.emit()
	
	# Setup hub camera if needed
	setup_hub_camera()
	
	print("Player entered Pool of Memories hub")

func exit_hub():
	if not is_hub_active:
		return
	
	is_hub_active = false
	current_selected_station = null
	
	player_exited_hub.emit()
	print("Player exited Pool of Memories hub")

func setup_hub_camera():
	# Find and setup isometric camera for hub
	camera = get_viewport().get_camera_3d()
	if camera:
		# Position camera for good hub overview
		camera.position = Vector3(0, 25, 20)
		camera.look_at(Vector3.ZERO, Vector3.UP)

func _on_station_entered(station: StaticBody3D, body: Node3D):
	if body != player:
		return
	
	current_selected_station = station
	var category = station.get_meta("category", "")
	
	# Show upgrade UI for this category
	if memory_ui and memory_system:
		show_category_upgrades(category)
	
	print("Player approached ", get_category_display_name(category))

func _on_station_exited(station: StaticBody3D, body: Node3D):
	if body != player:
		return
	
	if current_selected_station == station:
		current_selected_station = null
		
		# Hide upgrade UI
		if memory_ui:
			hide_upgrade_ui()

func show_category_upgrades(category: String):
	# This would integrate with the actual PoolOfMemoriesUI
	if memory_system:
		var category_upgrades = memory_system.get_upgrades_by_category(category)
		print("Available upgrades in ", category, ": ", category_upgrades.size())
		# Here we would show the actual UI

func hide_upgrade_ui():
	# Hide the upgrade interface
	print("Hiding upgrade UI")

func _on_fragments_changed(new_amount: int):
	# Update any UI displays
	print("Memory fragments updated: ", new_amount)

func _on_upgrade_purchased(upgrade_id: String, cost: int):
	memory_upgrade_purchased.emit(upgrade_id)
	
	# Visual feedback - could add particles, lights, etc.
	create_purchase_feedback()

func create_purchase_feedback():
	# Create visual/audio feedback for upgrade purchase
	print("Upgrade purchased - creating feedback effects")

# Public API
func get_hub_info() -> Dictionary:
	return {
		"is_active": is_hub_active,
		"total_stations": memory_stations.get_child_count(),
		"current_station": current_selected_station.name if current_selected_station else "",
		"available_categories": station_categories
	}

func force_show_category(category: String):
	show_category_upgrades(category)

func get_nearest_station() -> StaticBody3D:
	if not player or memory_stations.get_child_count() == 0:
		return null
	
	var nearest_station = null
	var shortest_distance = INF
	
	for station in memory_stations.get_children():
		if station is StaticBody3D:
			var distance = player.global_position.distance_to(station.global_position)
			if distance < shortest_distance:
				shortest_distance = distance
				nearest_station = station
	
	return nearest_station