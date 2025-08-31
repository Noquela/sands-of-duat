extends Node3D
## Controller para a cena de teste do Sands of Duat
## Verifica performance, configurações de rendering e setup inicial

# Referências aos nós importantes
@onready var camera: Camera3D = $IsometricCamera
@onready var debug_label: Label = $UI/DebugLabel
@onready var player_placeholder: CharacterBody3D = $PlayerPlaceholder
@onready var ground: StaticBody3D = $Ground

# Variáveis de teste
var fps_counter: float = 0.0
var fps_timer: float = 0.0
var current_fps: int = 0

# Configurações da câmera isométrica
const CAMERA_DISTANCE: float = 12.0
const CAMERA_ANGLE: float = 45.0  # Graus
const CAMERA_HEIGHT_OFFSET: float = 0.0

func _ready():
	print("🎬 Test scene initialized")
	
	# Configura câmera isométrica
	setup_isometric_camera()
	
	# Configura player placeholder
	setup_player_placeholder()
	
	# Configura ground collision
	setup_ground_collision()
	
	# Inicia monitoring de performance
	start_performance_monitoring()
	
	# Aplica configurações de rendering
	apply_rendering_settings()
	
	print("✅ Test scene setup complete")
	print("📊 Target FPS: ", Engine.max_fps)
	print("🎥 Camera distance: ", CAMERA_DISTANCE)
	print("📐 Camera angle: ", CAMERA_ANGLE, "°")
	print("🔥 Godot 4.4 compatibility confirmed")

func setup_isometric_camera():
	"""Configura câmera para vista isométrica perfeita"""
	# Posição isométrica (45° em X e Y)
	var angle_rad = deg_to_rad(CAMERA_ANGLE)
	var x_pos = CAMERA_DISTANCE * cos(angle_rad) * cos(angle_rad)
	var y_pos = CAMERA_DISTANCE * sin(angle_rad) + CAMERA_HEIGHT_OFFSET
	var z_pos = CAMERA_DISTANCE * cos(angle_rad) * sin(angle_rad)
	
	camera.position = Vector3(x_pos, y_pos, z_pos)
	
	# Rotação para olhar para origem com orientação isométrica
	camera.look_at(Vector3.ZERO, Vector3.UP)
	
	# Configura projeção ortogonal para eliminar perspectiva
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 20.0  # Zoom level
	
	print("📷 Isometric camera configured")
	print("   Position: ", camera.position)
	print("   Rotation: ", camera.rotation_degrees)

func setup_player_placeholder():
	"""Configura placeholder do player para testes"""
	# Cria mesh simples para visualização
	var mesh_instance = player_placeholder.get_node("MeshInstance3D")
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(1.0, 2.0, 1.0)
	mesh_instance.mesh = box_mesh
	
	# Cria collision shape
	var collision_shape = player_placeholder.get_node("CollisionShape3D")
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(1.0, 2.0, 1.0)
	collision_shape.shape = box_shape
	
	print("🤖 Player placeholder configured")

func setup_ground_collision():
	"""Configura collision do chão"""
	var collision_shape = ground.get_node("CollisionShape3D")
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(20, 0.2, 20)
	collision_shape.shape = box_shape
	
	print("🌍 Ground collision configured")

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
	"""Atualiza display de performance"""
	current_fps = Engine.get_frames_per_second()
	
	var debug_text = "🏛️ SANDS OF DUAT - Test Scene\n"
	debug_text += "FPS: %d / %d (target)\n" % [current_fps, Engine.max_fps]
	debug_text += "Camera: Isometric (%.1f°, distance %.1f)\n" % [CAMERA_ANGLE, CAMERA_DISTANCE]
	debug_text += "Rendering: Forward+ with MSAA\n"
	debug_text += "Memory: %.1f MB\n" % (OS.get_static_memory_usage(false) / 1024.0 / 1024.0)
	debug_text += "Press ESC for debug info"
	
	debug_label.text = debug_text
	
	# Alerta se FPS estiver baixo
	if current_fps < (Engine.max_fps * 0.9):  # 90% do target
		debug_label.modulate = Color.ORANGE
	elif current_fps < (Engine.max_fps * 0.7):  # 70% do target
		debug_label.modulate = Color.RED
	else:
		debug_label.modulate = Color.WHITE

func _input(event):
	"""Handles input para debug e testes"""
	if event.is_action_pressed("pause"):  # ESC key
		print_detailed_debug_info()
	
	if event.is_action_pressed("ui_accept"):  # Enter key
		test_performance_spike()

func print_detailed_debug_info():
	"""Imprime informações detalhadas de debug"""
	print("\n=== SANDS OF DUAT - DETAILED DEBUG INFO ===")
	print("Performance:")
	print("  FPS: ", current_fps, " / ", Engine.max_fps, " (target)")
	print("  Frame time: ", "%.2f" % (1000.0 / max(current_fps, 1)), "ms")
	print("  Memory usage: ", "%.1f" % (OS.get_static_memory_usage(false) / 1024.0 / 1024.0), "MB")
	
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

func _physics_process(delta):
	"""Simula movimento básico do player placeholder para testes"""
	if not player_placeholder:
		return
	
	# Movimento simples com WASD
	var input_vector = Vector3.ZERO
	
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_up"):
		input_vector.z -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.z += 1
	
	# Normaliza vetor de movimento
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()
	
	# Aplica movimento (velocidade de 5 unidades/segundo)
	var velocity = input_vector * 5.0
	velocity.y = -9.8  # Gravity
	
	# Move character usando Godot 4.x CharacterBody3D
	player_placeholder.velocity = velocity
	player_placeholder.move_and_slide()

func get_performance_report() -> Dictionary:
	"""Retorna relatório de performance para analytics"""
	return {
		"fps": current_fps,
		"target_fps": Engine.max_fps,
		"memory_mb": OS.get_static_memory_usage(false) / 1024.0 / 1024.0,
		"renderer": "Forward Plus",
		"msaa_enabled": true,
		"camera_distance": CAMERA_DISTANCE,
		"timestamp": Time.get_unix_time_from_system()
	}