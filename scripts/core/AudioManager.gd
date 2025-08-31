extends Node
## Gerenciador de áudio para Sands of Duat
## Responsável por SFX, música dinâmica e voice acting

signal audio_settings_changed
signal music_track_changed(track_name)

# Audio buses (configurados no Godot)
enum AudioBus {
	MASTER = 0,
	MUSIC = 1,
	SFX = 2,
	VOICE = 3
}

# Estados de música dinâmica
enum MusicState {
	SILENCE,
	EXPLORATION,
	COMBAT_LOW,
	COMBAT_HIGH,
	BOSS_FIGHT,
	VICTORY,
	DEFEAT
}

# Configurações de volume (0.0 a 1.0)
var master_volume: float = 0.7
var music_volume: float = 0.6
var sfx_volume: float = 0.8
var voice_volume: float = 0.9

# Estado atual de música
var current_music_state: MusicState = MusicState.SILENCE
var current_track: AudioStreamPlayer = null
var fade_tween: Tween = null

# Pools de audio players para performance
var sfx_pool: Array[AudioStreamPlayer] = []
var voice_pool: Array[AudioStreamPlayer] = []
const MAX_SFX_PLAYERS = 32
const MAX_VOICE_PLAYERS = 4

# Configurações de fade
const EXPLORATION_FADE_TIME = 2.0
const COMBAT_FADE_TIME = 0.5

func _ready():
	print("🎵 AudioManager initialized")
	
	# Cria pools de audio players
	create_audio_pools()
	
	# Configura volumes iniciais
	apply_volume_settings()
	
	# Carrega configurações salvas
	load_audio_settings()

func create_audio_pools():
	"""Cria pools de AudioStreamPlayer para performance otimizada"""
	# Pool de SFX
	for i in MAX_SFX_PLAYERS:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		sfx_pool.append(player)
	
	# Pool de Voice
	for i in MAX_VOICE_PLAYERS:
		var player = AudioStreamPlayer.new()
		player.bus = "Voice"
		add_child(player)
		voice_pool.append(player)
	
	print("🔊 Audio pools created - SFX: %d, Voice: %d" % [MAX_SFX_PLAYERS, MAX_VOICE_PLAYERS])

func play_sfx(audio_stream: AudioStream, pitch_variation: float = 0.1, volume_db: float = 0.0):
	"""Reproduz efeito sonoro com pitch variation e pooling"""
	var player = get_available_sfx_player()
	if not player:
		print("⚠️  No available SFX player - audio dropped")
		return
	
	player.stream = audio_stream
	player.volume_db = volume_db
	
	# Adiciona variação de pitch para naturalidade
	if pitch_variation > 0:
		var pitch_range = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
		player.pitch_scale = pitch_range
	else:
		player.pitch_scale = 1.0
	
	player.play()

func play_voice_line(audio_stream: AudioStream, interrupt_current: bool = false):
	"""Reproduz linha de voz com controle de interrupção"""
	var player = get_available_voice_player()
	
	if not player and interrupt_current:
		# Para voice line atual se necessário
		stop_all_voice_lines()
		player = voice_pool[0]
	
	if not player:
		print("⚠️  No available voice player")
		return
	
	player.stream = audio_stream
	player.volume_db = 0.0
	player.pitch_scale = 1.0
	player.play()
	
	print("🗣️  Playing voice line: ", audio_stream.resource_path if audio_stream else "Unknown")

func change_music_state(new_state: MusicState, force: bool = false):
	"""Muda o estado da música com transições suaves"""
	if current_music_state == new_state and not force:
		return
	
	var old_state = current_music_state
	current_music_state = new_state
	
	print("🎼 Music state: ", MusicState.keys()[old_state], " → ", MusicState.keys()[new_state])
	
	# Determina tempo de fade baseado no tipo de transição
	var fade_time = EXPLORATION_FADE_TIME
	if new_state in [MusicState.COMBAT_LOW, MusicState.COMBAT_HIGH, MusicState.BOSS_FIGHT]:
		fade_time = COMBAT_FADE_TIME
	
	# Aplica transição
	transition_to_track(get_track_for_state(new_state), fade_time)

func get_track_for_state(state: MusicState) -> String:
	"""Retorna o nome da track apropriada para cada estado"""
	match state:
		MusicState.SILENCE:
			return ""
		MusicState.EXPLORATION:
			return "exploration_base"
		MusicState.COMBAT_LOW:
			return "combat_low"
		MusicState.COMBAT_HIGH:
			return "combat_high"
		MusicState.BOSS_FIGHT:
			return "boss_battle"
		MusicState.VICTORY:
			return "victory"
		MusicState.DEFEAT:
			return "defeat"
		_:
			return ""

func transition_to_track(track_name: String, fade_time: float):
	"""Faz transição suave entre tracks musicais"""
	if fade_tween:
		fade_tween.kill()
	
	fade_tween = create_tween()
	fade_tween.set_parallel(true)
	
	# Fade out da track atual
	if current_track and current_track.playing:
		fade_tween.tween_property(current_track, "volume_db", -60.0, fade_time)
		fade_tween.tween_callback(current_track.stop).set_delay(fade_time)
	
	# Fade in da nova track
	if track_name != "":
		var new_track = load_music_track(track_name)
		if new_track:
			current_track = new_track
			current_track.volume_db = -60.0
			current_track.play()
			fade_tween.tween_property(current_track, "volume_db", 0.0, fade_time)
			
			music_track_changed.emit(track_name)

func load_music_track(track_name: String) -> AudioStreamPlayer:
	"""Carrega track musical do disco (placeholder - implementar no Sprint 8)"""
	# TODO: Implementar carregamento real de arquivos de áudio
	print("🎶 Loading music track: ", track_name)
	
	# Placeholder - retorna um AudioStreamPlayer vazio por enquanto
	var player = AudioStreamPlayer.new()
	player.bus = "Music"
	add_child(player)
	
	return player

func get_available_sfx_player() -> AudioStreamPlayer:
	"""Encontra um AudioStreamPlayer disponível no pool de SFX"""
	for player in sfx_pool:
		if not player.playing:
			return player
	return null

func get_available_voice_player() -> AudioStreamPlayer:
	"""Encontra um AudioStreamPlayer disponível no pool de voice"""
	for player in voice_pool:
		if not player.playing:
			return player
	return null

func stop_all_sfx():
	"""Para todos os efeitos sonoros"""
	for player in sfx_pool:
		if player.playing:
			player.stop()

func stop_all_voice_lines():
	"""Para todas as voice lines"""
	for player in voice_pool:
		if player.playing:
			player.stop()

func stop_music():
	"""Para música atual"""
	change_music_state(MusicState.SILENCE)

func set_master_volume(volume: float):
	"""Define volume master (0.0 a 1.0)"""
	master_volume = clamp(volume, 0.0, 1.0)
	apply_volume_settings()

func set_music_volume(volume: float):
	"""Define volume da música (0.0 a 1.0)"""
	music_volume = clamp(volume, 0.0, 1.0)
	apply_volume_settings()

func set_sfx_volume(volume: float):
	"""Define volume dos SFX (0.0 a 1.0)"""
	sfx_volume = clamp(volume, 0.0, 1.0)
	apply_volume_settings()

func set_voice_volume(volume: float):
	"""Define volume das voices (0.0 a 1.0)"""
	voice_volume = clamp(volume, 0.0, 1.0)
	apply_volume_settings()

func apply_volume_settings():
	"""Aplica configurações de volume aos buses de áudio"""
	AudioServer.set_bus_volume_db(AudioBus.MASTER, linear_to_db(master_volume))
	AudioServer.set_bus_volume_db(AudioBus.MUSIC, linear_to_db(music_volume))
	AudioServer.set_bus_volume_db(AudioBus.SFX, linear_to_db(sfx_volume))
	AudioServer.set_bus_volume_db(AudioBus.VOICE, linear_to_db(voice_volume))
	
	audio_settings_changed.emit()

func save_audio_settings():
	"""Salva configurações de áudio"""
	var config = ConfigFile.new()
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "voice_volume", voice_volume)
	
	config.save("user://audio_settings.cfg")
	print("🔧 Audio settings saved")

func load_audio_settings():
	"""Carrega configurações de áudio salvas"""
	var config = ConfigFile.new()
	var err = config.load("user://audio_settings.cfg")
	
	if err != OK:
		print("📁 No audio settings found - using defaults")
		return
	
	master_volume = config.get_value("audio", "master_volume", 0.7)
	music_volume = config.get_value("audio", "music_volume", 0.6)
	sfx_volume = config.get_value("audio", "sfx_volume", 0.8)
	voice_volume = config.get_value("audio", "voice_volume", 0.9)
	
	apply_volume_settings()
	print("📁 Audio settings loaded")

# Funções de conveniência para diferentes tipos de SFX
func play_hit_sound(damage_type: String = "physical"):
	"""Reproduz som de hit baseado no tipo de dano"""
	# TODO: Implementar sons específicos no Sprint 5
	print("🗡️  Hit sound: ", damage_type)

func play_movement_sound(movement_type: String = "footstep"):
	"""Reproduz som de movimento"""
	# TODO: Implementar sons de movimento no Sprint 5
	print("👟 Movement sound: ", movement_type)

func play_ui_sound(ui_action: String = "click"):
	"""Reproduz som de interface"""
	# TODO: Implementar sons de UI no Sprint 6
	print("🖱️  UI sound: ", ui_action)

func play_ambient_loop(biome: String = "cavernas_esquecidos"):
	"""Inicia loop de áudio ambiente para bioma"""
	# TODO: Implementar ambiente sonoro no Sprint 8
	print("🌬️  Ambient loop: ", biome)
