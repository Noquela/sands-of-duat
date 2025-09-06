class_name VoiceSystem
extends Node

## 🎭 VOICE & NARRATIVE AUDIO SYSTEM - SANDS OF DUAT
## Sistema completo de voice acting com timing preciso e localização
##
## Features:
## - Character voice line triggering
## - Subtitle system com timing automático
## - Voice interruption handling
## - Language localization ready
## - Egyptian cultural audio adaptation

signal voice_line_started(character: String, line_id: String)
signal voice_line_finished(character: String, line_id: String)
signal subtitle_updated(text: String, duration: float)

@export var master_volume: float = 1.0
@export var voice_volume: float = 0.8
@export var subtitle_enabled: bool = true
@export var current_language: String = "pt_BR"
@export var auto_advance_dialogues: bool = false

# Voice line categories and priorities
enum VoiceCategory {
	COMBAT_BARK,      # Highest priority - combat sounds
	STORY_DIALOGUE,   # High priority - main story
	FLAVOR_TEXT,      # Medium priority - boon pickup, discovery
	TUTORIAL_HINT,    # Medium priority - tutorial hints
	AMBIENT_CHATTER,  # Low priority - background flavor
	DEATH_CRY,        # Highest priority - death reactions
	VICTORY_SHOUT     # High priority - victory celebration
}

enum VoicePriority {
	LOWEST = 0,
	LOW = 1,
	MEDIUM = 2,
	HIGH = 3,
	HIGHEST = 4,
	INTERRUPT = 5  # Can interrupt anything
}

# Character voice data structure
class VoiceCharacterData:
	var character_name: String
	var voice_pitch: float = 1.0
	var voice_speed: float = 1.0
	var cultural_accent: String = "egyptian"
	var dialogue_style: String = "formal"  # formal, casual, divine, warrior
	
	func _init(name: String):
		character_name = name

# Voice line data structure  
class VoiceLine:
	var line_id: String
	var character: String
	var category: VoiceCategory
	var priority: VoicePriority
	var audio_file: String
	var subtitle_text: String
	var duration: float
	var language: String
	var cultural_context: String = ""
	var emotional_state: String = "neutral"
	var can_interrupt: bool = false
	var fade_in_time: float = 0.1
	var fade_out_time: float = 0.2
	
	func _init(id: String, char: String, cat: VoiceCategory):
		line_id = id
		character = char
		category = cat
		priority = _get_category_priority(cat)
	
	func _get_category_priority(cat: VoiceCategory) -> VoicePriority:
		match cat:
			VoiceCategory.COMBAT_BARK, VoiceCategory.DEATH_CRY:
				return VoicePriority.HIGHEST
			VoiceCategory.STORY_DIALOGUE, VoiceCategory.VICTORY_SHOUT:
				return VoicePriority.HIGH
			VoiceCategory.FLAVOR_TEXT, VoiceCategory.TUTORIAL_HINT:
				return VoicePriority.MEDIUM
			VoiceCategory.AMBIENT_CHATTER:
				return VoicePriority.LOW
		return VoicePriority.MEDIUM

# Internal audio management
var audio_players: Array[AudioStreamPlayer2D] = []
var available_players: Array[AudioStreamPlayer2D] = []
var active_voices: Dictionary = {}  # line_id -> AudioStreamPlayer2D
var voice_queue: Array[VoiceLine] = []
var current_voice: VoiceLine = null

# Voice line database
var voice_lines: Dictionary = {}  # line_id -> VoiceLine
var character_data: Dictionary = {}  # character_name -> VoiceCharacterData

# Language and localization
var subtitle_display: Control = null
var current_subtitles: Array[String] = []
var localization_data: Dictionary = {}

# Egyptian cultural voice mapping
const EGYPTIAN_VOICE_THEMES = {
	"khenti": {
		"style": "royal_determined",
		"pitch": 0.95,
		"speed": 1.0,
		"accent": "upper_egyptian"
	},
	"thoth": {
		"style": "wise_ancient",
		"pitch": 0.85,
		"speed": 0.9,
		"accent": "divine_formal"
	},
	"bastet": {
		"style": "maternal_fierce",
		"pitch": 1.1,
		"speed": 1.05,
		"accent": "protective_warm"
	},
	"khnum": {
		"style": "craftsman_practical", 
		"pitch": 0.9,
		"speed": 1.0,
		"accent": "working_class"
	},
	"osiris": {
		"style": "judge_ancient",
		"pitch": 0.7,
		"speed": 0.85,
		"accent": "divine_authority"
	},
	"enemy_generic": {
		"style": "hostile_grunt",
		"pitch": 0.8,
		"speed": 1.1,
		"accent": "corrupted"
	}
}

func _ready():
	print("🎭 VoiceSystem initialized for Sands of Duat")
	setup_audio_players()
	setup_character_data()
	load_voice_database()
	setup_subtitle_system()
	
	# Connect to game events
	if GameEvents:
		GameEvents.combat_started.connect(_on_combat_started)
		GameEvents.combat_ended.connect(_on_combat_ended)
		GameEvents.player_death.connect(_on_player_death)
		GameEvents.boon_collected.connect(_on_boon_collected)
		GameEvents.boss_defeated.connect(_on_boss_defeated)

func setup_audio_players():
	"""Cria pool de AudioStreamPlayers para reprodução simultânea"""
	
	# Create 8 audio players for simultaneous voice lines
	for i in range(8):
		var player = AudioStreamPlayer2D.new()
		player.name = "VoicePlayer_%d" % i
		add_child(player)
		
		player.volume_db = linear_to_db(voice_volume * master_volume)
		player.finished.connect(_on_audio_finished.bind(player))
		
		audio_players.append(player)
		available_players.append(player)
	
	print("✅ Audio players created: ", audio_players.size())

func setup_character_data():
	"""Inicializa dados de personagens com temas culturais egípcios"""
	
	for char_name in EGYPTIAN_VOICE_THEMES.keys():
		var char_data = VoiceCharacterData.new(char_name)
		var theme = EGYPTIAN_VOICE_THEMES[char_name]
		
		char_data.voice_pitch = theme.pitch
		char_data.voice_speed = theme.speed
		char_data.cultural_accent = theme.accent
		char_data.dialogue_style = theme.style
		
		character_data[char_name] = char_data
	
	print("✅ Character voice data loaded: ", character_data.size())

func load_voice_database():
	"""Carrega database de voice lines egípcias"""
	
	# Combat barks - 20 per character type
	create_combat_barks()
	
	# Story dialogue - 200+ lines
	create_story_dialogues()
	
	# Flavor text - 100+ lines  
	create_flavor_texts()
	
	# Tutorial hints - 30 lines
	create_tutorial_hints()
	
	print("✅ Voice database loaded: ", voice_lines.size(), " lines")

func create_combat_barks():
	"""Cria combat barks egípcios autênticos"""
	
	# Khenti combat barks
	var khenti_barks = [
		"Por Ra! Vocês pagarão!",
		"A justiça de Maat me guia!",
		"Pelos deuses do Alto Egito!",
		"Minha lâmina bebe o sangue dos traidores!",
		"Anubis me dará forças!",
		"Isto é pela minha honra!",
		"Você mancha o nome dos faraós!",
		"Ra ilumina meu khopesh!",
		"Pela memória de meu pai!",
		"Nefertari... eu voltarei!",
		# Pain/hit reactions
		"Argh! Minha alma... resiste!",
		"Não... não aqui!",
		"Pelos deuses... ainda não!",
		# Victory shouts
		"Que Ra abençoe esta vitória!",
		"A justiça prevalece!",
		"Para a glória do Egito!",
		"Maat sorri para mim!",
		"Isto é apenas o começo!",
		"Meu pai... vê minha vingança!",
		"Um passo mais próximo da verdade!"
	]
	
	for i in range(khenti_barks.size()):
		var line = VoiceLine.new("khenti_combat_%d" % i, "khenti", VoiceCategory.COMBAT_BARK)
		line.subtitle_text = khenti_barks[i]
		line.audio_file = "res://assets/audio/voice/khenti/combat/bark_%02d.ogg" % i
		line.duration = 2.0 + randf() * 1.0  # 2-3 seconds
		line.emotional_state = "determined"
		line.cultural_context = "egyptian_royal"
		voice_lines[line.line_id] = line
	
	# Enemy combat barks
	var enemy_barks = [
		"Destruir o intruso!",
		"Ele não deve passar!",
		"Set nos comanda!",
		"Morte ao príncipe!",
		"O Duat é eterno!",
		"Sua alma será devorada!",
		"Ammit espera por você!",
		"Não há escape!",
		"Você não pertence aqui!",
		"O julgamento chegou!"
	]
	
	for i in range(enemy_barks.size()):
		var line = VoiceLine.new("enemy_combat_%d" % i, "enemy_generic", VoiceCategory.COMBAT_BARK)
		line.subtitle_text = enemy_barks[i]
		line.audio_file = "res://assets/audio/voice/enemies/bark_%02d.ogg" % i
		line.duration = 1.5 + randf() * 0.8
		line.emotional_state = "hostile"
		line.cultural_context = "corrupted_egyptian"
		voice_lines[line.line_id] = line

func create_story_dialogues():
	"""Cria diálogos principais da história"""
	
	# Thoth introduction
	var thoth_intro = [
		"Assim... o príncipe desperta no Duat. Interessante.",
		"Você não deveria estar aqui, Khenti-Ka-Nefer. Os mortos devem aceitar seu destino.",
		"Mas vejo em seus olhos a chama da determinação... e algo mais. Injustiça.",
		"Muito bem. Se insiste em desafiar a ordem natural, precisará de sabedoria.",
		"Aceite meus boons, jovem príncipe. O caminho à frente é traiçoeiro.",
		"Lembre-se: no Duat, a verdade é mais afiada que qualquer khopesh.",
	]
	
	for i in range(thoth_intro.size()):
		var line = VoiceLine.new("thoth_intro_%d" % i, "thoth", VoiceCategory.STORY_DIALOGUE)
		line.subtitle_text = thoth_intro[i]
		line.audio_file = "res://assets/audio/voice/thoth/intro_%02d.ogg" % i
		line.duration = 3.0 + (thoth_intro[i].length() * 0.05)
		line.emotional_state = "wise_contemplative"
		line.cultural_context = "divine_egyptian"
		voice_lines[line.line_id] = line
	
	# Bastet encouragement
	var bastet_encourage = [
		"Meu jovem guerreiro... posso sentir sua dor.",
		"A injustiça que sofreu ecoa através dos reinos divinos.",
		"Uma mãe protege seus filhotes. Eu protegerei você.",
		"Aceite minha força, Khenti. Sua jornada apenas começou.",
		"Que suas garras sejam afiadas e seus reflexos, rápidos como os meus.",
	]
	
	for i in range(bastet_encourage.size()):
		var line = VoiceLine.new("bastet_encourage_%d" % i, "bastet", VoiceCategory.STORY_DIALOGUE)
		line.subtitle_text = bastet_encourage[i]
		line.audio_file = "res://assets/audio/voice/bastet/encourage_%02d.ogg" % i
		line.duration = 3.5 + (bastet_encourage[i].length() * 0.04)
		line.emotional_state = "maternal_protective"
		line.cultural_context = "divine_egyptian"
		voice_lines[line.line_id] = line

func create_flavor_texts():
	"""Cria flavor text para boons, discoveries, etc"""
	
	# Boon pickup lines
	var boon_pickups = [
		"O poder dos deuses flui através de mim!",
		"Sinto a benção divina em minhas veias!",
		"Que este boon ilumine meu caminho!",
		"Os deuses ainda me favorecem...",
		"Mais forte... devo ficar mais forte!",
		"Por Nefertari... por minha vingança!",
		"O Duat não me deterá!",
		"Maat guide meus passos!",
		"Ra, empreste-me sua força!",
		"Que Anubis proteja minha jornada!",
		"A sabedoria de Thoth me guia!",
		"Bastet, empreste-me seus reflexos!",
		"Khnum, fortaleça minhas armas!",
		"Horus, aguçe minha visão!",
		"Isis, cure minhas feridas!"
	]
	
	for i in range(boon_pickups.size()):
		var line = VoiceLine.new("boon_pickup_%d" % i, "khenti", VoiceCategory.FLAVOR_TEXT)
		line.subtitle_text = boon_pickups[i]
		line.audio_file = "res://assets/audio/voice/khenti/boon_%02d.ogg" % i
		line.duration = 2.5
		line.emotional_state = "empowered"
		voice_lines[line.line_id] = line
	
	# Discovery lines
	var discoveries = [
		"Que lugar é este?",
		"Os hieróglifos... eles contam uma história sombria.",
		"Sinto presenças antigas aqui...",
		"Este lugar ecoa com memórias do passado.",
		"As paredes sussurram segredos do Duat.",
		"Que mistérios este lugar esconde?",
		"A arquitetura... é diferente do meu tempo.",
		"Posso sentir o poder divino impregnado aqui.",
		"Cuidado... algo observa das sombras.",
		"Os deuses caminharam por estes corredores."
	]
	
	for i in range(discoveries.size()):
		var line = VoiceLine.new("discovery_%d" % i, "khenti", VoiceCategory.FLAVOR_TEXT)
		line.subtitle_text = discoveries[i]
		line.audio_file = "res://assets/audio/voice/khenti/discovery_%02d.ogg" % i
		line.duration = 2.8
		line.emotional_state = "curious"
		voice_lines[line.line_id] = line

func create_tutorial_hints():
	"""Cria dicas de tutorial culturalmente apropriadas"""
	
	var tutorial_lines = [
		"Use WASD para mover-se pelos corredores do Duat.",
		"Clique para atacar com sua arma divina.",
		"A barra de vida representa sua força espiritual.",
		"Colete boons dos deuses para fortalecer sua alma.",
		"Cada morte o traz de volta - seu curse é eterno.",
		"Explore todos os cantos - segredos aguardam os corajosos.",
		"Use Space para dash e evitar ataques inimigos.",
		"Armas diferentes têm estilos de combate únicos.",
		"Boons podem ser combinados para efeitos poderosos.",
		"O Duat muda a cada jornada - adapte-se e sobreviva.",
		"Ouça os deuses - seus conselhos são valiosos.",
		"Sua determinação é sua maior arma.",
		"Lembre-se: você luta pela justiça e pelo amor.",
		"O caminho é longo, mas seu coração é forte.",
		"Cada inimigo derrotado o leva mais perto da verdade."
	]
	
	for i in range(tutorial_lines.size()):
		var line = VoiceLine.new("tutorial_%d" % i, "khenti", VoiceCategory.TUTORIAL_HINT)
		line.subtitle_text = tutorial_lines[i]
		line.audio_file = "res://assets/audio/voice/khenti/tutorial_%02d.ogg" % i
		line.duration = 3.0
		line.emotional_state = "instructional"
		voice_lines[line.line_id] = line

func setup_subtitle_system():
	"""Configura sistema de legendas"""
	
	# Create subtitle UI if not exists
	if not subtitle_display:
		subtitle_display = preload("res://ui/SubtitleDisplay.tscn").instantiate()
		get_tree().current_scene.add_child(subtitle_display)
	
	print("✅ Subtitle system ready")

# Public interface methods

func play_voice_line(line_id: String, force_interrupt: bool = false) -> bool:
	"""Reproduz uma voice line específica"""
	
	if not voice_lines.has(line_id):
		print("⚠️ Voice line not found: ", line_id)
		return false
	
	var voice_line = voice_lines[line_id]
	
	# Check if can interrupt current voice
	if current_voice and not force_interrupt:
		if voice_line.priority <= current_voice.priority and not voice_line.can_interrupt:
			# Queue for later if lower priority
			voice_queue.append(voice_line)
			return true
	
	return _play_voice_line_immediate(voice_line, force_interrupt)

func play_random_voice_from_category(character: String, category: VoiceCategory, force_interrupt: bool = false) -> bool:
	"""Reproduz voice line aleatória de uma categoria"""
	
	var matching_lines: Array[String] = []
	
	for line_id in voice_lines.keys():
		var voice_line = voice_lines[line_id]
		if voice_line.character == character and voice_line.category == category:
			matching_lines.append(line_id)
	
	if matching_lines.is_empty():
		print("⚠️ No voice lines found for ", character, " category ", category)
		return false
	
	var random_line = matching_lines[randi() % matching_lines.size()]
	return play_voice_line(random_line, force_interrupt)

func interrupt_current_voice():
	"""Interrompe voice line atual imediatamente"""
	
	if current_voice and active_voices.has(current_voice.line_id):
		var player = active_voices[current_voice.line_id]
		_stop_voice_player(player)

func set_voice_volume(volume: float):
	"""Define volume das vozes (0.0 - 1.0)"""
	
	voice_volume = clamp(volume, 0.0, 1.0)
	var db_volume = linear_to_db(voice_volume * master_volume)
	
	for player in audio_players:
		player.volume_db = db_volume

func set_subtitle_enabled(enabled: bool):
	"""Ativa/desativa legendas"""
	
	subtitle_enabled = enabled
	if subtitle_display:
		subtitle_display.visible = enabled

func set_language(language: String):
	"""Muda idioma das vozes"""
	
	current_language = language
	# Reload voice database for new language
	load_voice_database()

# Internal methods

func _play_voice_line_immediate(voice_line: VoiceLine, force_interrupt: bool) -> bool:
	"""Reproduz voice line imediatamente"""
	
	# Stop current voice if forcing interrupt
	if force_interrupt and current_voice:
		interrupt_current_voice()
	
	# Get available audio player
	var player = _get_available_player()
	if not player:
		print("⚠️ No audio players available")
		return false
	
	# Load audio stream
	var audio_stream = load(voice_line.audio_file)
	if not audio_stream:
		print("⚠️ Could not load audio file: ", voice_line.audio_file)
		return false
	
	# Configure player based on character
	var char_data = character_data.get(voice_line.character)
	if char_data:
		player.pitch_scale = char_data.voice_pitch
	
	# Play audio
	player.stream = audio_stream
	player.play()
	
	# Track active voice
	active_voices[voice_line.line_id] = player
	current_voice = voice_line
	
	# Show subtitles
	if subtitle_enabled:
		_show_subtitle(voice_line.subtitle_text, voice_line.duration)
	
	# Emit signals
	voice_line_started.emit(voice_line.character, voice_line.line_id)
	
	print("🎭 Playing voice: ", voice_line.character, " - ", voice_line.subtitle_text)
	return true

func _get_available_player() -> AudioStreamPlayer2D:
	"""Retorna player disponível ou null se todos ocupados"""
	
	if available_players.is_empty():
		return null
	
	return available_players.pop_front()

func _stop_voice_player(player: AudioStreamPlayer2D):
	"""Para um player específico e o marca como disponível"""
	
	player.stop()
	
	# Find and remove from active voices
	for line_id in active_voices.keys():
		if active_voices[line_id] == player:
			active_voices.erase(line_id)
			break
	
	# Return to available pool
	if player not in available_players:
		available_players.append(player)

func _show_subtitle(text: String, duration: float):
	"""Mostra legenda com timing"""
	
	if subtitle_display:
		subtitle_display.show_subtitle(text, duration)
	
	subtitle_updated.emit(text, duration)

func _on_audio_finished(player: AudioStreamPlayer2D):
	"""Callback quando áudio termina"""
	
	# Find the voice line that just finished
	var finished_line_id = ""
	for line_id in active_voices.keys():
		if active_voices[line_id] == player:
			finished_line_id = line_id
			break
	
	if finished_line_id != "":
		var voice_line = voice_lines[finished_line_id]
		voice_line_finished.emit(voice_line.character, finished_line_id)
		
		# Clear current voice if this was it
		if current_voice and current_voice.line_id == finished_line_id:
			current_voice = null
	
	# Return player to available pool
	_stop_voice_player(player)
	
	# Process voice queue
	_process_voice_queue()

func _process_voice_queue():
	"""Processa fila de voice lines esperando"""
	
	if voice_queue.is_empty() or current_voice:
		return
	
	var next_voice = voice_queue.pop_front()
	_play_voice_line_immediate(next_voice, false)

# Game event callbacks

func _on_combat_started():
	"""Callback quando combate inicia"""
	play_random_voice_from_category("khenti", VoiceCategory.COMBAT_BARK)

func _on_combat_ended():
	"""Callback quando combate termina"""
	play_random_voice_from_category("khenti", VoiceCategory.VICTORY_SHOUT)

func _on_player_death():
	"""Callback quando player morre"""
	play_random_voice_from_category("khenti", VoiceCategory.DEATH_CRY, true)

func _on_boon_collected(_boon_data):
	"""Callback quando boon é coletado"""
	play_random_voice_from_category("khenti", VoiceCategory.FLAVOR_TEXT)

func _on_boss_defeated(_boss_name):
	"""Callback quando boss é derrotado"""
	play_random_voice_from_category("khenti", VoiceCategory.VICTORY_SHOUT)

# Debug and utility

func get_voice_statistics() -> Dictionary:
	"""Retorna estatísticas do sistema de voice"""
	
	var stats = {
		"total_lines": voice_lines.size(),
		"active_voices": active_voices.size(),
		"queued_voices": voice_queue.size(),
		"available_players": available_players.size(),
		"current_language": current_language,
		"subtitle_enabled": subtitle_enabled
	}
	
	# Count by category
	var category_counts = {}
	for voice_line in voice_lines.values():
		var cat_name = VoiceCategory.keys()[voice_line.category]
		category_counts[cat_name] = category_counts.get(cat_name, 0) + 1
	
	stats["category_breakdown"] = category_counts
	return stats

func debug_play_all_lines_for_character(character: String):
	"""Debug: reproduz todas as linhas de um personagem"""
	
	print("🎭 Debug: Playing all lines for ", character)
	
	for voice_line in voice_lines.values():
		if voice_line.character == character:
			play_voice_line(voice_line.line_id)
			await get_tree().create_timer(voice_line.duration + 0.5).timeout