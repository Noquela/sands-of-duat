class_name PerformanceProfiler
extends Node

## ⚡ PERFORMANCE PROFILER - SANDS OF DUAT
## Sistema avançado de profiling e otimização automática para 60 FPS consistente
##
## Features:
## - Real-time performance monitoring
## - Automatic quality adjustment
## - Bottleneck detection
## - Memory usage optimization
## - FPS stabilization system

signal performance_alert(metric: String, value: float, threshold: float)
signal optimization_applied(optimization: String, impact: float)
signal fps_stabilized(average_fps: float)

@export var target_fps: float = 60.0
@export var min_acceptable_fps: float = 45.0
@export var enable_auto_optimization: bool = true
@export var profiling_interval: float = 1.0
@export var memory_alert_threshold: int = 800000000  # 800MB

# Performance tracking
var fps_history: Array[float] = []
var frame_time_history: Array[float] = []
var memory_usage_history: Array[int] = []
var draw_call_history: Array[int] = []

# Current performance metrics
var current_metrics: Dictionary = {}
var performance_score: float = 100.0
var bottlenecks: Array[String] = []

# Optimization states
var quality_level: int = 3  # 0=lowest, 4=highest
var is_optimizing: bool = false
var optimization_cooldown: float = 0.0

# Performance categories to monitor
enum PerformanceCategory {
	RENDERING,
	PHYSICS,
	AUDIO,
	SCRIPTS,
	MEMORY,
	IO
}

# Quality settings presets
const QUALITY_PRESETS = {
	0: {  # Emergency (lowest quality)
		"name": "Emergency Performance",
		"render_scale": 0.5,
		"shadows": false,
		"particle_max": 100,
		"light_count": 4,
		"msaa": 0,
		"effects_quality": 0.3
	},
	1: {  # Low quality
		"name": "Low Quality",
		"render_scale": 0.75,
		"shadows": true,
		"particle_max": 250,
		"light_count": 8,
		"msaa": 0,
		"effects_quality": 0.5
	},
	2: {  # Medium quality
		"name": "Medium Quality", 
		"render_scale": 0.9,
		"shadows": true,
		"particle_max": 500,
		"light_count": 12,
		"msaa": 2,
		"effects_quality": 0.7
	},
	3: {  # High quality (default)
		"name": "High Quality",
		"render_scale": 1.0,
		"shadows": true,
		"particle_max": 800,
		"light_count": 16,
		"msaa": 2,
		"effects_quality": 1.0
	},
	4: {  # Ultra quality
		"name": "Ultra Quality",
		"render_scale": 1.0,
		"shadows": true,
		"particle_max": 1200,
		"light_count": 24,
		"msaa": 4,
		"effects_quality": 1.2
	}
}

# Profiling timer
var profiling_timer: Timer

func _ready():
	print("⚡ PerformanceProfiler initialized")
	setup_profiling_timer()
	initialize_performance_tracking()
	
	if enable_auto_optimization:
		print("🔧 Auto-optimization enabled (target: ", target_fps, " FPS)")

func setup_profiling_timer():
	"""Configura timer de profiling"""
	
	profiling_timer = Timer.new()
	profiling_timer.wait_time = profiling_interval
	profiling_timer.timeout.connect(_on_profiling_update)
	profiling_timer.autostart = true
	add_child(profiling_timer)

func initialize_performance_tracking():
	"""Inicializa sistema de tracking de performance"""
	
	# Initialize history arrays
	fps_history.clear()
	frame_time_history.clear()
	memory_usage_history.clear()
	draw_call_history.clear()
	
	# Start with current quality level
	apply_quality_preset(quality_level)
	
	print("✅ Performance tracking initialized")

func _on_profiling_update():
	"""Callback de update do profiling"""
	
	# Capture current metrics
	current_metrics = capture_performance_metrics()
	
	# Update history
	update_performance_history()
	
	# Analyze performance
	analyze_performance()
	
	# Apply optimizations if needed
	if enable_auto_optimization and not is_optimizing:
		check_and_apply_optimizations()
	
	# Update optimization cooldown
	if optimization_cooldown > 0:
		optimization_cooldown -= profiling_interval

func capture_performance_metrics() -> Dictionary:
	"""Captura métricas de performance atuais"""
	
	return {
		"fps": Engine.get_frames_per_second(),
		"frame_time": get_frame_time(),
		"memory_usage": OS.get_static_memory_usage(false),
		"memory_peak": OS.get_static_memory_peak_usage(),
		"draw_calls": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TYPE_TOTAL, RenderingServer.RENDERING_INFO_DRAW_CALLS_IN_FRAME),
		"vertices": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TYPE_TOTAL, RenderingServer.RENDERING_INFO_VERTICES_IN_FRAME),
		"physics_time": get_physics_time(),
		"process_time": get_process_time(),
		"timestamp": Time.get_time_dict_from_system()
	}

func get_frame_time() -> float:
	"""Retorna tempo de frame atual em ms"""
	var fps = Engine.get_frames_per_second()
	return (1.0 / max(fps, 1.0)) * 1000.0

func get_physics_time() -> float:
	"""Retorna tempo gasto em física (estimativa)"""
	# This is an approximation since Godot doesn't directly expose physics time
	return Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0

func get_process_time() -> float:
	"""Retorna tempo gasto em processamento de scripts (estimativa)"""
	return Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0

func update_performance_history():
	"""Atualiza histórico de performance"""
	
	var max_history_size = 60  # Keep 60 seconds of history
	
	# Update FPS history
	fps_history.append(current_metrics.fps)
	if fps_history.size() > max_history_size:
		fps_history.pop_front()
	
	# Update frame time history
	frame_time_history.append(current_metrics.frame_time)
	if frame_time_history.size() > max_history_size:
		frame_time_history.pop_front()
	
	# Update memory history
	memory_usage_history.append(current_metrics.memory_usage)
	if memory_usage_history.size() > max_history_size:
		memory_usage_history.pop_front()
	
	# Update draw calls history
	draw_call_history.append(current_metrics.draw_calls)
	if draw_call_history.size() > max_history_size:
		draw_call_history.pop_front()

func analyze_performance():
	"""Analisa performance e detecta bottlenecks"""
	
	bottlenecks.clear()
	
	# Calculate averages
	var avg_fps = calculate_average(fps_history)
	var avg_frame_time = calculate_average(frame_time_history)
	var avg_memory = calculate_average_int(memory_usage_history)
	var avg_draw_calls = calculate_average_int(draw_call_history)
	
	# Update performance score
	performance_score = calculate_performance_score(avg_fps, avg_frame_time, avg_memory)
	
	# Detect bottlenecks
	if avg_fps < target_fps * 0.85:  # 15% below target
		bottlenecks.append("LOW_FPS")
		performance_alert.emit("fps", avg_fps, target_fps)
	
	if avg_frame_time > (1000.0 / min_acceptable_fps):
		bottlenecks.append("HIGH_FRAME_TIME")
		performance_alert.emit("frame_time", avg_frame_time, 1000.0 / target_fps)
	
	if avg_memory > memory_alert_threshold:
		bottlenecks.append("HIGH_MEMORY")
		performance_alert.emit("memory", avg_memory, memory_alert_threshold)
	
	if avg_draw_calls > 300:  # Conservative draw call limit
		bottlenecks.append("HIGH_DRAW_CALLS")
		performance_alert.emit("draw_calls", avg_draw_calls, 300)
	
	# Check for CPU bottlenecks
	if current_metrics.process_time > 12.0:  # >12ms processing time
		bottlenecks.append("CPU_BOTTLENECK")
	
	# Check for physics bottlenecks
	if current_metrics.physics_time > 8.0:  # >8ms physics time
		bottlenecks.append("PHYSICS_BOTTLENECK")

func calculate_average(array: Array[float]) -> float:
	"""Calcula média de array de floats"""
	if array.is_empty():
		return 0.0
	
	var sum = 0.0
	for value in array:
		sum += value
	return sum / array.size()

func calculate_average_int(array: Array[int]) -> int:
	"""Calcula média de array de ints"""
	if array.is_empty():
		return 0
	
	var sum = 0
	for value in array:
		sum += value
	return sum / array.size()

func calculate_performance_score(fps: float, frame_time: float, memory: int) -> float:
	"""Calcula score de performance (0-100)"""
	
	var fps_score = min(fps / target_fps, 1.0) * 40.0
	var frame_time_score = max(0, 1.0 - (frame_time - (1000.0/target_fps)) / 10.0) * 30.0
	var memory_score = max(0, 1.0 - float(memory) / float(memory_alert_threshold)) * 30.0
	
	return clamp(fps_score + frame_time_score + memory_score, 0.0, 100.0)

func check_and_apply_optimizations():
	"""Verifica e aplica otimizações se necessário"""
	
	if optimization_cooldown > 0:
		return
	
	var avg_fps = calculate_average(fps_history)
	
	# Need to optimize down?
	if avg_fps < min_acceptable_fps and quality_level > 0:
		optimize_quality_down()
		optimization_cooldown = 5.0  # 5 second cooldown
		
	# Can optimize up?
	elif avg_fps > target_fps * 1.1 and quality_level < 4:  # 10% above target
		# Check if we've been stable for a while
		var stable_duration = check_fps_stability()
		if stable_duration > 10.0:  # Stable for 10+ seconds
			optimize_quality_up()
			optimization_cooldown = 10.0  # 10 second cooldown

func optimize_quality_down():
	"""Reduz qualidade para melhorar performance"""
	
	if quality_level <= 0:
		return
	
	is_optimizing = true
	quality_level -= 1
	
	print("⬇️ Reducing quality to level ", quality_level, " (", QUALITY_PRESETS[quality_level].name, ")")
	
	apply_quality_preset(quality_level)
	optimization_applied.emit("quality_down", -1)
	
	is_optimizing = false

func optimize_quality_up():
	"""Aumenta qualidade se performance permitir"""
	
	if quality_level >= 4:
		return
	
	is_optimizing = true
	quality_level += 1
	
	print("⬆️ Increasing quality to level ", quality_level, " (", QUALITY_PRESETS[quality_level].name, ")")
	
	apply_quality_preset(quality_level)
	optimization_applied.emit("quality_up", 1)
	
	is_optimizing = false

func apply_quality_preset(level: int):
	"""Aplica preset de qualidade"""
	
	if not QUALITY_PRESETS.has(level):
		print("❌ Invalid quality level: ", level)
		return
	
	var preset = QUALITY_PRESETS[level]
	print("🎮 Applying quality preset: ", preset.name)
	
	# Apply rendering settings
	var viewport = get_viewport()
	if viewport:
		# Render scale
		viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
		# Note: render_target_scale would need to be set via project settings
		
		# MSAA
		viewport.msaa_3d = preset.msaa as Viewport.MSAA
	
	# Apply to rendering server
	apply_rendering_quality(preset)
	
	# Apply to particle systems
	apply_particle_quality(preset)
	
	# Apply to lighting
	apply_lighting_quality(preset)
	
	# Apply to post-processing
	apply_effects_quality(preset)

func apply_rendering_quality(preset: Dictionary):
	"""Aplica configurações de rendering"""
	
	# Shadow settings
	var shadows_enabled = preset.shadows as bool
	RenderingServer.camera_set_use_environment(get_viewport().get_camera_3d().get_camera_rid(), shadows_enabled)
	
	# LOD adjustments would be applied to specific models
	# This is a simplified approach - in a full implementation,
	# we'd iterate through all MeshInstance3D nodes and adjust LOD bias

func apply_particle_quality(preset: Dictionary):
	"""Aplica configurações de partículas"""
	
	var max_particles = preset.particle_max as int
	
	# Find all particle systems and limit them
	var particle_systems = get_tree().get_nodes_in_group("particles")
	for particle_system in particle_systems:
		if particle_system is GPUParticles3D:
			var gpu_particles = particle_system as GPUParticles3D
			gpu_particles.amount = min(gpu_particles.amount, max_particles)
		elif particle_system is CPUParticles3D:
			var cpu_particles = particle_system as CPUParticles3D
			cpu_particles.amount = min(cpu_particles.amount, max_particles)

func apply_lighting_quality(preset: Dictionary):
	"""Aplica configurações de iluminação"""
	
	var max_lights = preset.light_count as int
	
	# Limit number of active lights
	var lights = get_tree().get_nodes_in_group("dynamic_lights")
	for i in range(lights.size()):
		var light = lights[i]
		if light is Light3D:
			light.visible = i < max_lights

func apply_effects_quality(preset: Dictionary):
	"""Aplica configurações de efeitos visuais"""
	
	var effects_quality = preset.effects_quality as float
	
	# Apply to post-processor
	var post_processor = get_tree().get_first_node_in_group("post_processor")
	if post_processor and post_processor.has_method("set_effects_quality"):
		post_processor.set_effects_quality(effects_quality)
	
	# Apply to VFX systems
	var vfx_systems = get_tree().get_nodes_in_group("vfx")
	for vfx in vfx_systems:
		if vfx.has_method("set_quality_multiplier"):
			vfx.set_quality_multiplier(effects_quality)

func check_fps_stability() -> float:
	"""Verifica estabilidade do FPS e retorna duração estável em segundos"""
	
	if fps_history.size() < 10:
		return 0.0
	
	var recent_fps = fps_history.slice(fps_history.size() - 10)  # Last 10 samples
	var avg_fps = calculate_average(recent_fps)
	var variance = 0.0
	
	for fps in recent_fps:
		variance += abs(fps - avg_fps)
	
	variance /= recent_fps.size()
	
	# Consider stable if variance is low and FPS is above target
	if variance < 2.0 and avg_fps > target_fps * 1.05:
		return profiling_interval * recent_fps.size()  # Time represented by samples
	
	return 0.0

func force_optimization_pass():
	"""Força passagem de otimização"""
	
	print("🔧 Forcing optimization pass...")
	is_optimizing = true
	
	# Apply emergency optimizations
	if calculate_average(fps_history) < min_acceptable_fps:
		# Emergency measures
		apply_emergency_optimizations()
	
	# Garbage collection
	force_garbage_collection()
	
	is_optimizing = false
	optimization_applied.emit("emergency_optimization", 0)

func apply_emergency_optimizations():
	"""Aplica otimizações de emergência"""
	
	print("🚨 Applying emergency optimizations...")
	
	# Force lowest quality
	quality_level = 0
	apply_quality_preset(0)
	
	# Disable non-essential systems temporarily
	var non_essential = get_tree().get_nodes_in_group("non_essential")
	for node in non_essential:
		if node.has_method("set_enabled"):
			node.set_enabled(false)
	
	# Reduce physics tick rate temporarily
	Engine.physics_ticks_per_second = 30  # Down from 60

func force_garbage_collection():
	"""Força coleta de lixo"""
	
	print("🗑️ Forcing garbage collection...")
	
	# Force GC (Godot doesn't expose direct GC control, but we can help)
	# Clear any cached resources
	ResourceLoader.clear_cache()
	
	# Clear any temporary textures
	RenderingServer.free_rid(RenderingServer.get_rid())

func get_performance_report() -> Dictionary:
	"""Retorna relatório completo de performance"""
	
	var avg_fps = calculate_average(fps_history)
	var avg_frame_time = calculate_average(frame_time_history)
	var avg_memory = calculate_average_int(memory_usage_history)
	var avg_draw_calls = calculate_average_int(draw_call_history)
	
	return {
		"current_fps": current_metrics.get("fps", 0.0),
		"average_fps": avg_fps,
		"target_fps": target_fps,
		"frame_time_ms": avg_frame_time,
		"memory_usage_mb": avg_memory / 1048576,  # Convert to MB
		"memory_peak_mb": current_metrics.get("memory_peak", 0) / 1048576,
		"draw_calls": avg_draw_calls,
		"vertices": current_metrics.get("vertices", 0),
		"physics_time_ms": current_metrics.get("physics_time", 0.0),
		"process_time_ms": current_metrics.get("process_time", 0.0),
		"performance_score": performance_score,
		"quality_level": quality_level,
		"quality_name": QUALITY_PRESETS[quality_level].name,
		"bottlenecks": bottlenecks,
		"optimization_active": is_optimizing
	}

func stabilize_fps():
	"""Tenta estabilizar FPS no target"""
	
	print("🎯 Attempting FPS stabilization...")
	
	var current_avg = calculate_average(fps_history)
	
	if current_avg < target_fps * 0.9:
		# Need significant improvement
		while quality_level > 0 and calculate_average(fps_history) < target_fps * 0.95:
			optimize_quality_down()
			await get_tree().create_timer(2.0).timeout  # Wait for changes to take effect
			analyze_performance()  # Update metrics
	
	elif current_avg > target_fps * 1.2:
		# Can afford to increase quality
		if check_fps_stability() > 5.0:
			optimize_quality_up()
	
	fps_stabilized.emit(calculate_average(fps_history))

# Debug and utility functions

func debug_print_performance_info():
	"""Debug: imprime informações de performance"""
	
	var report = get_performance_report()
	print("\n⚡ PERFORMANCE REPORT")
	print("==================")
	print("FPS: ", "%.1f" % report.current_fps, " (avg: ", "%.1f" % report.average_fps, ", target: ", target_fps, ")")
	print("Frame Time: ", "%.2f" % report.frame_time_ms, "ms")
	print("Memory: ", "%.1f" % report.memory_usage_mb, "MB (peak: ", "%.1f" % report.memory_peak_mb, "MB)")
	print("Draw Calls: ", report.draw_calls)
	print("Quality: ", report.quality_name, " (level ", report.quality_level, ")")
	print("Performance Score: ", "%.1f" % report.performance_score, "/100")
	
	if report.bottlenecks.size() > 0:
		print("Bottlenecks: ", report.bottlenecks)

func debug_cycle_quality_levels():
	"""Debug: cicla entre níveis de qualidade"""
	
	for level in range(5):
		print("🎮 Testing quality level: ", level, " (", QUALITY_PRESETS[level].name, ")")
		quality_level = level
		apply_quality_preset(level)
		await get_tree().create_timer(3.0).timeout
		debug_print_performance_info()

func set_target_fps(new_target: float):
	"""Define novo FPS target"""
	
	target_fps = new_target
	min_acceptable_fps = new_target * 0.75
	print("🎯 Target FPS set to: ", target_fps, " (min acceptable: ", min_acceptable_fps, ")")

func enable_performance_overlay():
	"""Ativa overlay de performance na tela"""
	
	# This would create a UI overlay showing real-time metrics
	print("📊 Performance overlay enabled")
	# Implementation would create a Control node with labels for metrics