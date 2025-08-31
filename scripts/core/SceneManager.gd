extends Node
## Gerenciador de cenas para Sands of Duat
## Responsável por transições, carregamento assíncrono e gerenciamento de salas

signal scene_change_started(scene_path)
signal scene_change_completed(scene_path)
signal room_loaded(room_data)

# Estados de carregamento
enum LoadingState {
	IDLE,
	LOADING,
	TRANSITIONING
}

var current_state: LoadingState = LoadingState.IDLE
var current_scene: Node = null
var loading_screen: Control = null

# Cache de cenas carregadas para performance
var scene_cache: Dictionary = {}
const MAX_CACHED_SCENES = 5

# Configurações de transição
const FADE_DURATION = 0.5
const MIN_LOADING_TIME = 1.0  # Tempo mínimo para evitar flash

func _ready():
	print("🎬 SceneManager initialized")
	
	# Referência à cena inicial
	current_scene = get_tree().current_scene
	
	# Conecta sinais importantes
	connect_signals()

func connect_signals():
	"""Conecta sinais de outros sistemas"""
	# Conecta ao GameManager quando necessário
	if GameManager:
		GameManager.room_entered.connect(_on_room_entered)

func change_scene(scene_path: String, transition_data: Dictionary = {}):
	"""Muda de cena com transição suave e loading screen"""
	if current_state != LoadingState.IDLE:
		print("⚠️  Scene change already in progress")
		return
	
	print("🎬 Changing scene to: ", scene_path)
	current_state = LoadingState.LOADING
	scene_change_started.emit(scene_path)
	
	# Inicia transição
	start_scene_transition(scene_path, transition_data)

func start_scene_transition(scene_path: String, transition_data: Dictionary):
	"""Inicia processo de transição entre cenas"""
	# Cria tween para fade out
	var fade_tween = create_tween()
	
	# TODO: Implementar loading screen visual no Sprint 6
	show_loading_screen()
	
	# Fade out atual
	fade_tween.tween_callback(func(): await load_and_switch_scene(scene_path, transition_data))
	fade_tween.tween_interval(FADE_DURATION)

func load_and_switch_scene(scene_path: String, transition_data: Dictionary):
	"""Carrega nova cena e faz a troca"""
	var start_time = Time.get_ticks_msec()
	
	# Tenta carregar da cache primeiro
	var new_scene = get_cached_scene(scene_path)
	
	if not new_scene:
		# Carrega do disco se não estiver em cache
		var resource = load(scene_path)
		if resource and resource is PackedScene:
			new_scene = resource.instantiate()
			cache_scene(scene_path, new_scene)
		else:
			print("❌ Failed to load scene: ", scene_path)
			current_state = LoadingState.IDLE
			hide_loading_screen()
			return
	
	# Garante tempo mínimo de loading (evita flash)
	var loading_time = Time.get_ticks_msec() - start_time
	if loading_time < MIN_LOADING_TIME * 1000:
		await get_tree().create_timer((MIN_LOADING_TIME * 1000 - loading_time) / 1000.0).timeout
	
	# Remove cena atual
	if current_scene:
		current_scene.queue_free()
	
	# Adiciona nova cena
	get_tree().root.add_child(new_scene)
	get_tree().current_scene = new_scene
	current_scene = new_scene
	
	# Aplica dados de transição
	apply_transition_data(transition_data)
	
	# Finaliza transição
	complete_scene_transition(scene_path)

func complete_scene_transition(scene_path: String):
	"""Completa processo de transição"""
	current_state = LoadingState.IDLE
	
	# Fade in
	var fade_tween = create_tween()
	fade_tween.tween_callback(hide_loading_screen)
	fade_tween.tween_interval(FADE_DURATION)
	
	print("✅ Scene change completed: ", scene_path)
	scene_change_completed.emit(scene_path)

func apply_transition_data(data: Dictionary):
	"""Aplica dados específicos da transição (posição do player, etc)"""
	if data.has("player_position") and current_scene.has_method("set_player_position"):
		current_scene.set_player_position(data.player_position)
	
	if data.has("room_type") and GameManager:
		GameManager.room_entered.emit(data.room_type)

func show_loading_screen():
	"""Mostra tela de carregamento"""
	# TODO: Implementar loading screen visual no Sprint 6
	print("📺 Loading screen shown")

func hide_loading_screen():
	"""Esconde tela de carregamento"""
	# TODO: Implementar loading screen visual no Sprint 6
	print("📺 Loading screen hidden")

func cache_scene(scene_path: String, scene_instance: Node):
	"""Adiciona cena ao cache"""
	# Remove cenas antigas se cache estiver cheio
	if scene_cache.size() >= MAX_CACHED_SCENES:
		var oldest_key = scene_cache.keys()[0]
		scene_cache[oldest_key].queue_free()
		scene_cache.erase(oldest_key)
	
	scene_cache[scene_path] = scene_instance
	print("💾 Scene cached: ", scene_path, " (Cache size: ", scene_cache.size(), ")")

func get_cached_scene(scene_path: String) -> Node:
	"""Recupera cena do cache se disponível"""
	if scene_cache.has(scene_path):
		print("⚡ Scene loaded from cache: ", scene_path)
		var cached_scene = scene_cache[scene_path]
		scene_cache.erase(scene_path)  # Remove do cache pois será usado
		return cached_scene
	return null

func clear_scene_cache():
	"""Limpa cache de cenas (útil para liberar memória)"""
	for scene in scene_cache.values():
		if is_instance_valid(scene):
			scene.queue_free()
	
	scene_cache.clear()
	print("🗑️  Scene cache cleared")

func preload_scene(scene_path: String):
	"""Pré-carrega cena em background para transições mais rápidas"""
	if scene_cache.has(scene_path):
		print("⚠️  Scene already cached: ", scene_path)
		return
	
	print("⏳ Preloading scene: ", scene_path)
	
	# TODO: Implementar carregamento assíncrono no Sprint 13
	var resource = load(scene_path)
	if resource and resource is PackedScene:
		var scene_instance = resource.instantiate()
		cache_scene(scene_path, scene_instance)
	else:
		print("❌ Failed to preload scene: ", scene_path)

func get_current_scene_path() -> String:
	"""Retorna path da cena atual"""
	if current_scene and current_scene.scene_file_path:
		return current_scene.scene_file_path
	return ""

func is_scene_loading() -> bool:
	"""Verifica se há carregamento de cena em andamento"""
	return current_state != LoadingState.IDLE

# Funções específicas para salas do jogo
func load_room(room_type: String, biome: String = "cavernas_esquecidos", layout_id: int = -1):
	"""Carrega sala específica do jogo"""
	var room_path = get_room_path(room_type, biome, layout_id)
	
	var transition_data = {
		"room_type": room_type,
		"biome": biome,
		"layout_id": layout_id
	}
	
	change_scene(room_path, transition_data)

func get_room_path(room_type: String, biome: String, layout_id: int) -> String:
	"""Constrói path para sala baseado nos parâmetros"""
	var base_path = "res://scenes/rooms/"
	
	# Layout específico ou aleatório
	var layout_suffix = ""
	if layout_id >= 0:
		layout_suffix = "_" + str(layout_id).pad_zeros(2)
	else:
		# TODO: Implementar seleção aleatória no Sprint 6
		layout_suffix = "_01"
	
	return base_path + biome + "/" + room_type + layout_suffix + ".tscn"

func _on_room_entered(room_type: String):
	"""Callback quando player entra em nova sala"""
	print("🚪 Room entered: ", room_type)
	room_loaded.emit({"type": room_type, "timestamp": Time.get_unix_time_from_system()})

# Funções de conveniência para diferentes tipos de transição
func goto_hub():
	"""Vai para área hub (Pool of Memories)"""
	change_scene("res://scenes/rooms/pool_of_memories.tscn")

func goto_menu():
	"""Volta ao menu principal"""
	change_scene("res://scenes/ui/MainMenu.tscn")

func start_new_run():
	"""Inicia nova run do jogo"""
	# Reset dados no GameManager
	if GameManager:
		GameManager.reset_run_data()
		GameManager.change_state(GameManager.GameState.PLAYING)
	
	# Carrega primeira sala
	load_room("tutorial", "cavernas_esquecidos", 0)

func continue_run():
	"""Continua run salva"""
	# TODO: Implementar sistema de save/load no Sprint 12
	print("🔄 Continue run - Not implemented yet")