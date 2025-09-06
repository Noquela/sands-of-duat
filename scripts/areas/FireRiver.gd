extends Node3D
class_name FireRiver

signal boss_reached()
signal hazard_triggered(hazard_type: String, damage: int)
signal weapon_station_activated(station_type: String)

@export_group("Biome Settings")
@export var biome_radius: float = 100.0
@export var lava_damage_per_second: float = 25.0
@export var heat_wave_intensity: float = 0.3
@export var fire_immunity_duration: float = 10.0

# Visual Palette
@export_group("Visual Settings") 
@export var primary_color: Color = Color(0.8, 0.2, 0.1, 1.0)      # Deep red
@export var secondary_color: Color = Color(1.0, 0.4, 0.0, 1.0)     # Bright orange
@export var accent_color: Color = Color(1.0, 0.8, 0.2, 1.0)        # Incandescent gold

# Environment Components
@onready var layout_manager: Node3D = $LayoutManager
@onready var hazard_system: Node3D = $HazardSystem
@onready var enemy_spawner: Node3D = $EnemySpawner
@onready var environmental_fx: Node3D = $EnvironmentalFX
@onready var weapon_stations: Node3D = $WeaponStations

# Systems
var biome_generator: BiomeGenerator
var player: Node3D
var active_hazards: Array[Node3D] = []
var active_immunity_effects: Array[Node3D] = []
var current_layout_index: int = 0

# Biome State
var is_active: bool = false
var boss_spawned: bool = false
var lava_flows: Array[Area3D] = []
var fire_immunity_zones: Array[Area3D] = []
var phoenix_platforms: Array[Node3D] = []

func _ready():
	setup_fire_river_biome()
	find_system_references()
	initialize_environmental_systems()

func setup_fire_river_biome():
	add_to_group("fire_river_biome")
	add_to_group("biomes")
	print("Fire River Biome initialized - Purification through flame")

func find_system_references():
	biome_generator = get_tree().get_first_node_in_group("biome_generator")
	player = get_tree().get_first_node_in_group("player")

func initialize_environmental_systems():
	# Create biome environment
	create_fire_river_environment()
	
	# Generate initial layout
	generate_layout(0)
	
	# Setup hazard systems
	setup_hazard_systems()
	
	# Create weapon upgrade stations (Forjas de Khnum)
	create_khnum_forges()

func create_fire_river_environment():
	# Main lava river flowing through center
	create_central_lava_flow()
	
	# Rocky canyon walls
	create_canyon_environment()
	
	# Atmospheric effects
	create_heat_distortion_effects()
	
	# Ambient fire lighting
	create_fire_lighting()

func create_central_lava_flow():
	var lava_river = Area3D.new()
	lava_river.name = "CentralLavaFlow"
	lava_river.position = Vector3.ZERO
	hazard_system.add_child(lava_river)
	
	# Lava river mesh (elongated cylinder)
	var mesh_instance = MeshInstance3D.new()
	var river_mesh = BoxMesh.new()
	river_mesh.size = Vector3(biome_radius * 0.3, 0.5, biome_radius * 2)
	mesh_instance.mesh = river_mesh
	lava_river.add_child(mesh_instance)
	
	# Lava material with emission and movement
	var lava_material = StandardMaterial3D.new()
	lava_material.albedo_color = primary_color
	lava_material.emission_enabled = true
	lava_material.emission = secondary_color
	lava_material.metallic = 0.1
	lava_material.roughness = 0.8
	lava_material.rim_enabled = true
	lava_material.rim = accent_color
	mesh_instance.material_override = lava_material
	
	# Collision for damage detection
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(biome_radius * 0.3, 0.5, biome_radius * 2)
	collision.shape = shape
	lava_river.add_child(collision)
	
	# Connect damage signal
	lava_river.body_entered.connect(_on_lava_entered)
	lava_flows.append(lava_river)

func create_canyon_environment():
	# Left canyon wall
	var left_wall = create_canyon_wall(Vector3(-biome_radius * 0.6, 5, 0), Vector3(5, 10, biome_radius * 2))
	
	# Right canyon wall  
	var right_wall = create_canyon_wall(Vector3(biome_radius * 0.6, 5, 0), Vector3(5, 10, biome_radius * 2))
	
	# Rocky platforms and ledges
	create_fire_platforms()

func create_canyon_wall(pos: Vector3, size: Vector3) -> MeshInstance3D:
	var wall = MeshInstance3D.new()
	wall.name = "CanyonWall"
	wall.position = pos
	environmental_fx.add_child(wall)
	
	var wall_mesh = BoxMesh.new()
	wall_mesh.size = size
	wall.mesh = wall_mesh
	
	# Rocky canyon material
	var rock_material = StandardMaterial3D.new()
	rock_material.albedo_color = Color(0.3, 0.15, 0.1, 1.0)  # Dark red rock
	rock_material.metallic = 0.0
	rock_material.roughness = 0.9
	rock_material.normal_enabled = true
	wall.material_override = rock_material
	
	return wall

func create_fire_platforms():
	var platform_positions = [
		Vector3(-20, 2, -30), Vector3(20, 2, -30),
		Vector3(-25, 4, 0), Vector3(25, 4, 0),
		Vector3(-15, 3, 30), Vector3(15, 3, 30)
	]
	
	for pos in platform_positions:
		create_phoenix_platform(pos)

func create_phoenix_platform(pos: Vector3):
	var platform = StaticBody3D.new()
	platform.name = "PhoenixPlatform"
	platform.position = pos
	environmental_fx.add_child(platform)
	
	# Platform mesh
	var mesh_instance = MeshInstance3D.new()
	var platform_mesh = CylinderMesh.new()
	platform_mesh.radius_top = 3.0
	platform_mesh.radius_bottom = 3.0
	platform_mesh.height = 0.5
	mesh_instance.mesh = platform_mesh
	platform.add_child(mesh_instance)
	
	# Phoenix material (golden with fire effects)
	var phoenix_material = StandardMaterial3D.new()
	phoenix_material.albedo_color = accent_color
	phoenix_material.emission_enabled = true
	phoenix_material.emission = secondary_color * 0.5
	phoenix_material.metallic = 0.7
	phoenix_material.roughness = 0.3
	mesh_instance.material_override = phoenix_material
	
	# Collision
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.height = 0.5
	shape.radius = 3.0
	collision.shape = shape
	platform.add_child(collision)
	
	# Phoenix respawn system metadata
	platform.set_meta("respawn_time", 5.0)
	platform.set_meta("destruction_health", 100)
	platform.add_to_group("phoenix_platforms")
	
	phoenix_platforms.append(platform)

func create_heat_distortion_effects():
	# Heat wave shader effect (placeholder - would use custom shader)
	var heat_effect = Node3D.new()
	heat_effect.name = "HeatDistortion"
	environmental_fx.add_child(heat_effect)
	
	# Create tween for heat wave animation
	var heat_tween = create_tween()
	heat_tween.set_loops()
	heat_tween.tween_method(_animate_heat_waves, 0.0, 2.0 * PI, 3.0)

func create_fire_lighting():
	# Main fire ambience
	var fire_light = OmniLight3D.new()
	fire_light.name = "FireAmbience"
	fire_light.position = Vector3(0, 8, 0)
	fire_light.light_energy = 1.5
	fire_light.light_color = secondary_color
	fire_light.omni_range = biome_radius
	environmental_fx.add_child(fire_light)
	
	# Lava glow spots
	var lava_positions = [Vector3(0, 1, -20), Vector3(0, 1, 0), Vector3(0, 1, 20)]
	for pos in lava_positions:
		var lava_glow = SpotLight3D.new()
		lava_glow.position = pos
		lava_glow.rotation_degrees = Vector3(-90, 0, 0)
		lava_glow.light_energy = 2.0
		lava_glow.light_color = primary_color
		lava_glow.spot_range = 15.0
		lava_glow.spot_angle = 60.0
		environmental_fx.add_child(lava_glow)

func setup_hazard_systems():
	# Fire geysers
	create_fire_geysers()
	
	# Collapsing bridges
	create_collapsing_bridges()
	
	# Fire immunity pickups
	create_fire_immunity_zones()

func create_fire_geysers():
	var geyser_positions = [
		Vector3(-10, 0, -15), Vector3(10, 0, -15),
		Vector3(-10, 0, 15), Vector3(10, 0, 15)
	]
	
	for pos in geyser_positions:
		var geyser = Area3D.new()
		geyser.name = "FireGeyser"
		geyser.position = pos
		hazard_system.add_child(geyser)
		
		# Geyser warning indicator
		var indicator = MeshInstance3D.new()
		var indicator_mesh = CylinderMesh.new()
		indicator_mesh.radius_top = 2.0
		indicator_mesh.radius_bottom = 2.0
		indicator_mesh.height = 0.1
		indicator.mesh = indicator_mesh
		geyser.add_child(indicator)
		
		# Warning material
		var warning_material = StandardMaterial3D.new()
		warning_material.albedo_color = Color(1.0, 0.5, 0.0, 0.7)
		warning_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		warning_material.emission_enabled = true
		warning_material.emission = secondary_color
		indicator.material_override = warning_material
		
		# Collision
		var collision = CollisionShape3D.new()
		var shape = CylinderShape3D.new()
		shape.radius = 2.0
		shape.height = 8.0
		collision.shape = shape
		collision.position = Vector3(0, 4, 0)
		geyser.add_child(collision)
		
		# Geyser metadata
		geyser.set_meta("eruption_interval", randf_range(5.0, 8.0))
		geyser.set_meta("damage", 40)
		geyser.add_to_group("fire_geysers")
		
		# Start eruption timer
		start_geyser_cycle(geyser)
		active_hazards.append(geyser)

func create_collapsing_bridges():
	var bridge_positions = [
		Vector3(0, 3, -40),  # Bridge across northern lava
		Vector3(0, 3, 40)    # Bridge across southern lava
	]
	
	for pos in bridge_positions:
		var bridge = StaticBody3D.new()
		bridge.name = "CollapsingBridge"
		bridge.position = pos
		hazard_system.add_child(bridge)
		
		# Bridge segments (3 segments that collapse sequentially)
		for i in range(3):
			var segment = create_bridge_segment(Vector3(i * 6 - 6, 0, 0))
			bridge.add_child(segment)
		
		bridge.set_meta("collapse_time", 3.0)
		bridge.set_meta("segment_count", 3)
		bridge.add_to_group("collapsing_bridges")
		active_hazards.append(bridge)

func create_bridge_segment(offset: Vector3) -> MeshInstance3D:
	var segment = MeshInstance3D.new()
	segment.name = "BridgeSegment"
	segment.position = offset
	
	var segment_mesh = BoxMesh.new()
	segment_mesh.size = Vector3(5, 0.5, 2)
	segment.mesh = segment_mesh
	
	# Stone bridge material
	var bridge_material = StandardMaterial3D.new()
	bridge_material.albedo_color = Color(0.6, 0.5, 0.4, 1.0)
	bridge_material.roughness = 0.8
	segment.material_override = bridge_material
	
	return segment

func create_fire_immunity_zones():
	var immunity_positions = [
		Vector3(-30, 1, 0), Vector3(30, 1, 0),
		Vector3(0, 1, -50), Vector3(0, 1, 50)
	]
	
	for pos in immunity_positions:
		var immunity_zone = Area3D.new()
		immunity_zone.name = "FireImmunityZone"
		immunity_zone.position = pos
		hazard_system.add_child(immunity_zone)
		
		# Visual indicator (blue flame)
		var indicator = MeshInstance3D.new()
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 1.5
		indicator.mesh = sphere_mesh
		immunity_zone.add_child(indicator)
		
		# Immunity material (cool blue)
		var immunity_material = StandardMaterial3D.new()
		immunity_material.albedo_color = Color(0.2, 0.6, 1.0, 0.8)
		immunity_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		immunity_material.emission_enabled = true
		immunity_material.emission = Color(0.4, 0.8, 1.0, 1.0)
		indicator.material_override = immunity_material
		
		# Collision
		var collision = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = 1.5
		collision.shape = shape
		immunity_zone.add_child(collision)
		
		# Connect pickup signal
		immunity_zone.body_entered.connect(_on_immunity_pickup.bind(immunity_zone))
		fire_immunity_zones.append(immunity_zone)

func create_khnum_forges():
	var forge_positions = [
		Vector3(-40, 2, -20),  # Left forge
		Vector3(40, 2, -20),   # Right forge
		Vector3(0, 2, 60)      # Central forge (boss area)
	]
	
	var forge_types = ["was_scepter_forge", "khopesh_forge", "divine_aspect_forge"]
	
	for i in range(forge_positions.size()):
		var forge = create_weapon_forge(forge_positions[i], forge_types[i])
		weapon_stations.add_child(forge)

func create_weapon_forge(pos: Vector3, forge_type: String) -> Node3D:
	var forge = StaticBody3D.new()
	forge.name = "KhnumForge_" + forge_type
	forge.position = pos
	
	# Forge anvil structure
	var anvil = MeshInstance3D.new()
	var anvil_mesh = BoxMesh.new()
	anvil_mesh.size = Vector3(2, 1, 1)
	anvil.mesh = anvil_mesh
	anvil.position = Vector3(0, 0.5, 0)
	forge.add_child(anvil)
	
	# Khnum forge material (divine bronze)
	var forge_material = StandardMaterial3D.new()
	forge_material.albedo_color = Color(0.8, 0.6, 0.2, 1.0)  # Divine bronze
	forge_material.metallic = 0.9
	forge_material.roughness = 0.1
	forge_material.emission_enabled = true
	forge_material.emission = accent_color * 0.3
	anvil.material_override = forge_material
	
	# Forge fire (constant flame)
	var fire_source = OmniLight3D.new()
	fire_source.position = Vector3(0, 2, 0)
	fire_source.light_energy = 1.5
	fire_source.light_color = accent_color
	fire_source.omni_range = 8.0
	forge.add_child(fire_source)
	
	# Interaction area
	var interaction = Area3D.new()
	var interaction_collision = CollisionShape3D.new()
	var interaction_shape = SphereShape3D.new()
	interaction_shape.radius = 3.0
	interaction_collision.shape = interaction_shape
	interaction.add_child(interaction_collision)
	forge.add_child(interaction)
	
	# Store forge metadata
	forge.set_meta("forge_type", forge_type)
	forge.set_meta("upgrade_cost", 150)  # Golden scarabs cost
	forge.add_to_group("khnum_forges")
	
	# Connect interaction
	interaction.body_entered.connect(_on_forge_approached.bind(forge))
	
	return forge

# Layout generation for 20 unique configurations
func generate_layout(layout_index: int):
	current_layout_index = layout_index % 20  # Cycle through 20 layouts
	
	match current_layout_index:
		0: create_straight_river_layout()
		1: create_winding_river_layout()
		2: create_split_path_layout()
		3: create_circular_arena_layout()
		4: create_vertical_climb_layout()
		5: create_bridge_crossing_layout()
		6: create_island_hopping_layout()
		7: create_narrow_canyon_layout()
		8: create_lava_falls_layout()
		9: create_forge_chamber_layout()
		10: create_geyser_field_layout()
		11: create_spiral_descent_layout()
		12: create_twin_rivers_layout()
		13: create_platform_maze_layout()
		14: create_collapsing_cavern_layout()
		15: create_phoenix_nest_layout()
		16: create_sekhmet_approach_layout()
		17: create_trial_chambers_layout()
		18: create_molten_core_layout()
		19: create_final_purification_layout()  # Boss arena
	
	print("Generated Fire River layout: ", current_layout_index)

func create_straight_river_layout():
	# Simple straight lava flow with platforms on sides
	pass  # Central lava flow already created

func create_winding_river_layout():
	# S-curve lava path with strategic platforms
	pass

func create_split_path_layout():
	# River splits into two paths, reconverges
	pass

func create_winding_river_layout():
	# S-curve lava path with strategic platforms
	clear_current_layout()
	var curve_points = [
		Vector3(-20, 1, -40), Vector3(20, 1, -20), 
		Vector3(-20, 1, 0), Vector3(20, 1, 20), Vector3(0, 1, 40)
	]
	create_curved_lava_path(curve_points)

func create_split_path_layout():
	# River splits into two paths, reconverges
	clear_current_layout()
	create_split_lava_streams(Vector3(0, 1, -30), Vector3(0, 1, 30))

func create_circular_arena_layout():
	# Central lava pool with circular platforms
	clear_current_layout()
	create_circular_lava_arena(Vector3.ZERO, 15.0)
	create_circular_platforms(Vector3.ZERO, 20.0, 8)

func create_vertical_climb_layout():
	# Ascending platforms over lava canyon
	clear_current_layout()
	create_lava_canyon_floor()
	create_ascending_platform_sequence()

func create_bridge_crossing_layout():
	# Multiple collapsing bridges over wide lava flow
	clear_current_layout()
	create_wide_lava_flow()
	create_multiple_bridges(5)

func create_island_hopping_layout():
	# Small platforms in lava lake
	clear_current_layout()
	create_lava_lake()
	create_island_chain(8)

func create_narrow_canyon_layout():
	# Tight canyon with wall-mounted platforms
	clear_current_layout()
	create_narrow_canyon_walls()
	create_wall_mounted_platforms()

func create_lava_falls_layout():
	# Waterfalls of lava from heights
	clear_current_layout()
	create_elevated_lava_sources()
	create_lava_waterfall_effects()

func create_forge_chamber_layout():
	# Central chamber with multiple forges
	clear_current_layout()
	create_forge_chamber_arena()
	create_multiple_khnum_forges()

func create_geyser_field_layout():
	# Dense field of fire geysers
	clear_current_layout()
	create_geyser_field(12)

func create_spiral_descent_layout():
	# Spiral path descending into lava pit
	clear_current_layout()
	create_spiral_lava_pit()
	create_spiral_platform_path()

func create_twin_rivers_layout():
	# Two parallel lava streams
	clear_current_layout()
	create_parallel_lava_streams()

func create_platform_maze_layout():
	# Phoenix platforms in maze configuration
	clear_current_layout()
	create_platform_maze_structure()

func create_collapsing_cavern_layout():
	# Cavern with unstable ceiling
	clear_current_layout()
	create_cavern_environment()
	create_falling_debris_hazards()

func create_phoenix_nest_layout():
	# Central phoenix nest with radiating platforms
	clear_current_layout()
	create_phoenix_nest_center()
	create_radiating_phoenix_platforms()

func create_sekhmet_approach_layout():
	# Path leading to boss arena
	clear_current_layout()
	create_boss_approach_path()
	create_intimidation_elements()

func create_trial_chambers_layout():
	# Three chambers testing different skills
	clear_current_layout()
	create_trial_chamber_sequence()

func create_molten_core_layout():
	# Central molten core with extreme heat
	clear_current_layout()
	create_molten_core_hazard()
	create_heat_shield_mechanics()

func create_final_purification_layout():
	# Boss arena - Sekhmet's domain
	clear_current_layout()
	create_sekhmet_boss_arena()

# Layout utility functions
func clear_current_layout():
	# Clear dynamic layout elements (keep base environment)
	for child in layout_manager.get_children():
		child.queue_free()

func create_curved_lava_path(points: Array[Vector3]):
	for i in range(points.size() - 1):
		var start_pos = points[i]
		var end_pos = points[i + 1]
		create_lava_segment(start_pos, end_pos)

func create_lava_segment(start_pos: Vector3, end_pos: Vector3):
	var lava_segment = Area3D.new()
	lava_segment.name = "LavaSegment"
	lava_segment.position = (start_pos + end_pos) * 0.5
	layout_manager.add_child(lava_segment)
	
	# Calculate segment size and rotation
	var direction = (end_pos - start_pos).normalized()
	var distance = start_pos.distance_to(end_pos)
	
	var mesh_instance = MeshInstance3D.new()
	var segment_mesh = BoxMesh.new()
	segment_mesh.size = Vector3(3.0, 0.5, distance)
	mesh_instance.mesh = segment_mesh
	lava_segment.add_child(mesh_instance)
	
	# Apply lava material
	var lava_material = StandardMaterial3D.new()
	lava_material.albedo_color = primary_color
	lava_material.emission_enabled = true
	lava_material.emission = secondary_color
	mesh_instance.material_override = lava_material
	
	# Collision
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(3.0, 0.5, distance)
	collision.shape = shape
	lava_segment.add_child(collision)
	
	lava_segment.body_entered.connect(_on_lava_entered)
	lava_flows.append(lava_segment)

func create_split_lava_streams(start_pos: Vector3, end_pos: Vector3):
	var mid_pos = (start_pos + end_pos) * 0.5
	var left_mid = mid_pos + Vector3(-15, 0, 0)
	var right_mid = mid_pos + Vector3(15, 0, 0)
	
	# Left stream
	create_curved_lava_path([start_pos, left_mid, end_pos])
	# Right stream  
	create_curved_lava_path([start_pos, right_mid, end_pos])

func create_circular_lava_arena(center: Vector3, radius: float):
	var lava_pool = Area3D.new()
	lava_pool.name = "CircularLavaArena"
	lava_pool.position = center
	layout_manager.add_child(lava_pool)
	
	var mesh_instance = MeshInstance3D.new()
	var pool_mesh = CylinderMesh.new()
	pool_mesh.radius_top = radius
	pool_mesh.radius_bottom = radius
	pool_mesh.height = 1.0
	mesh_instance.mesh = pool_mesh
	lava_pool.add_child(mesh_instance)
	
	# Lava material
	var lava_material = StandardMaterial3D.new()
	lava_material.albedo_color = primary_color
	lava_material.emission_enabled = true
	lava_material.emission = secondary_color
	mesh_instance.material_override = lava_material
	
	# Collision
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = radius
	shape.height = 1.0
	collision.shape = shape
	lava_pool.add_child(collision)
	
	lava_pool.body_entered.connect(_on_lava_entered)
	lava_flows.append(lava_pool)

func create_circular_platforms(center: Vector3, radius: float, count: int):
	for i in range(count):
		var angle = (i * 2 * PI) / count
		var pos = center + Vector3(cos(angle) * radius, 2, sin(angle) * radius)
		create_phoenix_platform(pos)

func create_sekhmet_boss_arena():
	# Large circular arena for boss fight
	create_circular_lava_arena(Vector3.ZERO, 25.0)
	
	# Boss platform in center
	var boss_platform = StaticBody3D.new()
	boss_platform.name = "SekhmetPlatform"
	boss_platform.position = Vector3(0, 5, 0)
	layout_manager.add_child(boss_platform)
	
	var platform_mesh = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.radius_top = 8.0
	mesh.radius_bottom = 8.0
	mesh.height = 1.0
	platform_mesh.mesh = mesh
	boss_platform.add_child(platform_mesh)
	
	# Divine platform material
	var divine_material = StandardMaterial3D.new()
	divine_material.albedo_color = accent_color
	divine_material.metallic = 0.8
	divine_material.emission_enabled = true
	divine_material.emission = accent_color * 0.5
	platform_mesh.material_override = divine_material
	
	# Player platforms around arena edge
	create_circular_platforms(Vector3.ZERO, 30.0, 6)
	
	# Boss entrance effects
	create_boss_arena_effects()

func start_geyser_cycle(geyser: Area3D):
	var interval = geyser.get_meta("eruption_interval", 6.0)
	var timer = Timer.new()
	timer.wait_time = interval
	timer.timeout.connect(_trigger_geyser_eruption.bind(geyser))
	timer.autostart = true
	geyser.add_child(timer)

func _animate_heat_waves(angle: float):
	# Create heat distortion effect
	if environmental_fx:
		environmental_fx.position.y = sin(angle) * heat_wave_intensity

# Signal handlers
func _on_lava_entered(body: Node3D):
	if body == player and player.has_method("take_damage"):
		# Check for fire immunity
		if not has_fire_immunity():
			player.take_damage(lava_damage_per_second)
			hazard_triggered.emit("lava_damage", lava_damage_per_second)
		
		# Apply visual fire effect
		apply_fire_effect_to_player()

func _on_immunity_pickup(immunity_zone: Area3D, body: Node3D):
	if body == player:
		grant_fire_immunity()
		# Hide pickup temporarily
		immunity_zone.visible = false
		# Respawn after cooldown
		var respawn_timer = Timer.new()
		respawn_timer.wait_time = 30.0
		respawn_timer.timeout.connect(_respawn_immunity_pickup.bind(immunity_zone))
		respawn_timer.autostart = true
		add_child(respawn_timer)

func _on_forge_approached(forge: Node3D, body: Node3D):
	if body == player:
		var forge_type = forge.get_meta("forge_type", "")
		weapon_station_activated.emit(forge_type)
		print("Approached Khnum Forge: ", forge_type)

func _trigger_geyser_eruption(geyser: Area3D):
	if not is_instance_valid(geyser):
		return
	
	var damage = geyser.get_meta("damage", 40)
	
	# Check if player is in geyser area
	var bodies = geyser.get_overlapping_bodies()
	for body in bodies:
		if body == player and body.has_method("take_damage"):
			if not has_fire_immunity():
				body.take_damage(damage)
				hazard_triggered.emit("fire_geyser", damage)
	
	# Visual eruption effect
	create_geyser_eruption_effect(geyser)

func create_geyser_eruption_effect(geyser: Area3D):
	# Create fire pillar effect
	var fire_pillar = MeshInstance3D.new()
	var pillar_mesh = CylinderMesh.new()
	pillar_mesh.radius_top = 0.5
	pillar_mesh.radius_bottom = 2.0
	pillar_mesh.height = 8.0
	fire_pillar.mesh = pillar_mesh
	fire_pillar.position = Vector3(0, 4, 0)
	
	# Fire material
	var fire_material = StandardMaterial3D.new()
	fire_material.albedo_color = secondary_color
	fire_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fire_material.emission_enabled = true
	fire_material.emission = secondary_color
	fire_pillar.material_override = fire_material
	
	geyser.add_child(fire_pillar)
	
	# Remove effect after 2 seconds
	var effect_timer = Timer.new()
	effect_timer.wait_time = 2.0
	effect_timer.timeout.connect(fire_pillar.queue_free)
	effect_timer.autostart = true
	fire_pillar.add_child(effect_timer)

func has_fire_immunity() -> bool:
	return active_immunity_effects.size() > 0

func grant_fire_immunity():
	print("Fire immunity granted for ", fire_immunity_duration, " seconds")
	
	# Create immunity effect node
	var immunity_effect = Node3D.new()
	immunity_effect.name = "FireImmunityEffect"
	add_child(immunity_effect)
	active_immunity_effects.append(immunity_effect)
	
	# Remove after duration
	var immunity_timer = Timer.new()
	immunity_timer.wait_time = fire_immunity_duration
	immunity_timer.timeout.connect(_remove_fire_immunity.bind(immunity_effect))
	immunity_timer.autostart = true
	immunity_effect.add_child(immunity_timer)

func _remove_fire_immunity(immunity_effect: Node3D):
	if immunity_effect in active_immunity_effects:
		active_immunity_effects.erase(immunity_effect)
	immunity_effect.queue_free()
	print("Fire immunity expired")

func _respawn_immunity_pickup(immunity_zone: Area3D):
	if is_instance_valid(immunity_zone):
		immunity_zone.visible = true

func apply_fire_effect_to_player():
	# Apply fire visual effect to player (screen tint, particle system)
	print("Player is burning - apply fire effects")

# Public API
func activate_biome():
	is_active = true
	print("Fire River biome activated - The purification begins")

func deactivate_biome():
	is_active = false
	# Clean up active effects
	for hazard in active_hazards:
		if is_instance_valid(hazard):
			hazard.queue_free()
	active_hazards.clear()

func get_biome_info() -> Dictionary:
	return {
		"name": "Rio de Fogo",
		"theme": "Purification through Fire",
		"active_layout": current_layout_index,
		"total_layouts": 20,
		"hazards_active": active_hazards.size(),
		"immunity_active": has_fire_immunity(),
		"boss_available": current_layout_index == 19
	}

func progress_to_boss():
	if current_layout_index < 19:
		generate_layout(19)  # Boss arena layout
		boss_reached.emit()

func spawn_sekhmet_boss():
	if not boss_spawned:
		boss_spawned = true
		print("Sekhmet, Lioness of Destruction, awakens...")
		# Boss spawning would be handled by boss system