extends Node3D
## Controller para a cena de teste do Sands of Duat
## Sistema completo com salas procedurais, controles e performance

# Referências aos nós importantes
@onready var camera: Camera3D = $IsometricCamera
@onready var debug_label: Label = $UI/DebugLabel
@onready var player: CharacterBody3D = $Player
@onready var ground: StaticBody3D = $Ground

# Sistema de salas
var room_system: Node
var room_manager: Node
var game_manager: Node

# Variáveis de teste
var fps_counter: float = 0.0
var fps_timer: float = 0.0
var current_fps: int = 0

# Configurações da câmera isométrica
const CAMERA_DISTANCE: float = 12.0
const CAMERA_ANGLE: float = 45.0  # Graus
const CAMERA_HEIGHT_OFFSET: float = 0.0

func _ready():
	print("🎬 Sprint 6 Test Scene initialized - Complete System")
	
	# Wait for AutoLoad systems
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Get system references
	get_system_references()
	
	# Remove old ground and setup procedural rooms
	setup_procedural_rooms()
	
	# Inicia monitoring de performance
	start_performance_monitoring()
	
	# Aplica configurações de rendering
	apply_rendering_settings()
	
	print("✅ Sprint 6 complete system ready")
	print("📊 Target FPS: ", Engine.max_fps)
	print("👑 Player controller: Khenti ready")
	print("📷 Smart camera follow system active")
	print("🏛️ Procedural room system active")
	print("🎮 Controls: WASD + Space (dash) + Click (attack)")


func get_system_references():
	"""Get references to room systems"""
	room_system = get_node("/root/RoomSystem")
	room_manager = get_node("/root/RoomManager")
	game_manager = get_node("/root/GameManager")
	
	if not room_system:
		print("❌ RoomSystem not found")
	if not room_manager:
		print("❌ RoomManager not found")
	if not game_manager:
		print("❌ GameManager not found")

func setup_procedural_rooms():
	"""Setup procedural room system"""
	# Remove old ground
	if ground:
		ground.queue_free()
	
	# Generate first floor
	if game_manager:
		var floor_data = game_manager.start_new_floor()
		if floor_data:
			print("✅ Test floor generated successfully")
			
			# Load starting room
			if room_manager and room_system:
				var starting_room = room_system.find_starting_room()
				if starting_room:
					room_manager.load_room(starting_room.id)
					print("🚪 Starting room loaded: ", starting_room.id)
		else:
			print("❌ Failed to generate test floor")

func apply_rendering_settings():
	"""Aplica configurações otimizadas de rendering"""
	# Configurações já estão no project.godot, mas podemos ajustar em runtime
	var viewport = get_viewport()
	
	# Força atualização das configurações
	if viewport:
		# As configurações de MSAA e SSAA estão no project.godot
		print("🎨 Rendering settings applied")
		print("   MSAA: Enabled (3D)")
		print("   SSAA: Screen Space AA")
		print("   Renderer: Forward Plus")

func start_performance_monitoring():
	"""Inicia monitoramento contínuo de performance"""
	var timer = Timer.new()
	timer.wait_time = 0.1  # Update a cada 100ms
	timer.timeout.connect(_update_performance_display)
	timer.autostart = true
	add_child(timer)
	
	print("📊 Performance monitoring started")

func _update_performance_display():
	"""Atualiza display de performance com info do player"""
	current_fps = Engine.get_frames_per_second()
	var target_fps = GameManager.target_fps if GameManager else 165
	
	var debug_text = "🏛️ SANDS OF DUAT - Sprint 2 Player Controller\n"
	debug_text += "FPS: %d / %d (target) - %.1f%% efficiency\n" % [current_fps, target_fps, (float(current_fps) / max(float(target_fps), 1.0)) * 100.0]
	debug_text += "Resolution: %dx%d (21:9 Ultrawide)\n" % [get_viewport().size.x, get_viewport().size.y]
	
	# Player info
	if player and player.has_method("get_movement_info"):
		var movement_info = player.get_movement_info()
		debug_text += "👑 Khenti - Health: %.0f/%.0f | Speed: %.1f\n" % [movement_info.get("health", 0), 100, movement_info.get("speed", 0)]
		debug_text += "📍 Position: (%.1f, %.1f) | Dash CD: %.1fs\n" % [movement_info.position.x, movement_info.position.z, movement_info.get("dash_cooldown", 0)]
	
	# Camera info
	if camera and camera.has_method("get_camera_info"):
		var camera_info = camera.get_camera_info()
		debug_text += "📷 Camera: FOV %.1f | Follow speed: %.1f\n" % [camera_info.get("fov", 0), camera_info.get("follow_speed", 0)]
	
	debug_text += "Memory: %.1f MB | Frame: %.2fms\n" % [OS.get_static_memory_usage() / 1024.0 / 1024.0, 1000.0 / max(current_fps, 1)]
	debug_text += "🎮 WASD: Move | Space: Dash | F1: Room+ | F2: Complete | F3: Floor+"
	
	debug_label.text = debug_text
	
	# Performance indicators for high refresh rates
	var fps_percentage = float(current_fps) / float(target_fps)
	if fps_percentage >= 0.95:  # 95%+ = Excellent
		debug_label.modulate = Color.LIME_GREEN
	elif fps_percentage >= 0.85:  # 85-94% = Good
		debug_label.modulate = Color.WHITE
	elif fps_percentage >= 0.70:  # 70-84% = Warning
		debug_label.modulate = Color.ORANGE
	else:  # <70% = Critical
		debug_label.modulate = Color.RED

func _input(event):
	"""Handles input para debug e testes"""
	if event.is_action_pressed("pause"):  # ESC key
		print_detailed_debug_info()
	
	if event.is_action_pressed("ui_accept"):  # Enter key
		test_performance_spike()
	
	# Room system controls (using dedicated F keys)
	if event.is_action_pressed("room_transition"):  # F1 - transition rooms
		test_room_transition()
	
	if event.is_action_pressed("room_complete"):  # F2 - complete room
		complete_current_room()
	
	if event.is_action_pressed("room_new_floor"):  # F3 - generate new floor
		generate_new_floor()

func print_detailed_debug_info():
	"""Imprime informações detalhadas de debug"""
	print("\n=== SANDS OF DUAT - DETAILED DEBUG INFO ===")
	print("Performance:")
	print("  FPS: ", current_fps, " / ", Engine.max_fps, " (target)")
	print("  Frame time: ", "%.2f" % (1000.0 / max(current_fps, 1)), "ms")
	print("  Memory usage: ", "%.1f" % (OS.get_static_memory_usage() / 1024.0 / 1024.0), "MB")
	
	print("\nCamera:")
	print("  Position: ", camera.position)
	print("  Rotation: ", camera.rotation_degrees)
	print("  FOV/Size: ", camera.size)
	print("  Projection: ", "Orthogonal" if camera.projection == Camera3D.PROJECTION_ORTHOGONAL else "Perspective")
	
	print("\nRendering:")
	print("  Renderer: Forward Plus")
	print("  MSAA: Enabled")
	print("  Viewport size: ", get_viewport().size)
	
	print("\nGameManager:")
	if GameManager:
		print("  State: ", GameManager.GameState.keys()[GameManager.current_state])
		print("  Run active: ", GameManager.is_run_active())
	
	print("\nAudioManager:")
	if AudioManager:
		print("  Master volume: ", "%.2f" % AudioManager.master_volume)
		print("  Music state: ", AudioManager.MusicState.keys()[AudioManager.current_music_state])
	
	print("==========================================\n")

func test_performance_spike():
	"""Testa performance sob carga (para debugging)"""
	print("🔥 Testing performance spike...")
	
	# Cria objetos temporários para testar performance
	var temp_objects = []
	for i in 100:
		var box = MeshInstance3D.new()
		var mesh = BoxMesh.new()
		mesh.size = Vector3(0.1, 0.1, 0.1)
		box.mesh = mesh
		box.position = Vector3(randf_range(-10, 10), randf_range(1, 5), randf_range(-10, 10))
		add_child(box)
		temp_objects.append(box)
	
	# Remove objetos após 2 segundos
	await get_tree().create_timer(2.0).timeout
	
	for obj in temp_objects:
		if is_instance_valid(obj):
			obj.queue_free()
	
	print("✅ Performance spike test completed")


func get_performance_report() -> Dictionary:
	"""Retorna relatório de performance para analytics"""
	return {
		"fps": current_fps,
		"target_fps": Engine.max_fps,
		"memory_mb": OS.get_static_memory_usage() / 1024.0 / 1024.0,
		"renderer": "Forward Plus",
		"msaa_enabled": true,
		"camera_distance": CAMERA_DISTANCE,
		"timestamp": Time.get_unix_time_from_system()
	}

# Room system control functions
func test_room_transition():
	"""Test room transition"""
	if not room_system or not room_manager:
		print("❌ Room systems not available")
		return
	
	var available_exits = room_system.get_available_exits()
	if available_exits.is_empty():
		print("❌ No available room exits")
		return
	
	var target_room_id = available_exits[0]
	print("🎯 Transitioning to room: ", target_room_id)
	room_manager.transition_to_room(target_room_id)

func complete_current_room():
	"""Complete current room"""
	if game_manager:
		game_manager.complete_room()
		print("✅ Room completion processed")
	else:
		print("❌ GameManager not available")

func generate_new_floor():
	"""Generate new floor"""
	if game_manager:
		var floor_data = game_manager.start_new_floor()
		if floor_data:
			print("✅ New floor generated with ", floor_data.total_rooms, " rooms")
		else:
			print("❌ Floor generation failed")
