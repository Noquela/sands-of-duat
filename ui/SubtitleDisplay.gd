class_name SubtitleDisplay
extends Control

## 📺 SUBTITLE DISPLAY SYSTEM - SANDS OF DUAT
## Sistema avançado de legendas com timing preciso e acessibilidade
##
## Features:
## - Timing automático sincronizado com áudio
## - Suporte multi-idioma com RTL
## - Indicadores visuais de áudio para surdez
## - Modos de acessibilidade (dislexia, daltonismo)
## - Estilo cultural egípcio

signal subtitle_started(text: String)
signal subtitle_finished()
signal speaker_changed(speaker: String)

@export var default_duration: float = 3.0
@export var fade_in_time: float = 0.3
@export var fade_out_time: float = 0.5
@export var character_reveal_speed: float = 30.0  # characters per second
@export var auto_size_enabled: bool = true
@export var max_lines: int = 3

# UI Components
@onready var background_panel: Panel = $BackgroundPanel
@onready var subtitle_label: RichTextLabel = $BackgroundPanel/SubtitleContainer/SubtitleLabel
@onready var speaker_label: Label = $BackgroundPanel/SubtitleContainer/SpeakerLabel
@onready var sound_indicator: Control = $SoundIndicators
@onready var typing_timer: Timer = $TypingTimer

# Subtitle queue system
var subtitle_queue: Array[SubtitleData] = []
var current_subtitle: SubtitleData = null
var is_displaying: bool = false
var current_character_index: int = 0

# Accessibility and styling
var accessibility_mode: bool = false
var dyslexia_friendly: bool = false
var high_contrast_mode: bool = false
var visual_sound_indicators: bool = false
var is_rtl_language: bool = false

# Egyptian cultural styling
var egyptian_speaker_colors = {
	"Khenti": Color.GOLD,
	"Thoth": Color.CYAN,
	"Bastet": Color.ORANGE,
	"Khnum": Color.SADDLE_BROWN,
	"Osiris": Color.DARK_GREEN,
	"System": Color.WHITE
}

class SubtitleData:
	var text: String
	var speaker: String
	var duration: float
	var priority: int = 1
	var emotional_context: String = "neutral"
	var cultural_style: String = "egyptian"
	var show_sound_indicator: bool = false
	var character_reveal: bool = false
	
	func _init(subtitle_text: String, subtitle_duration: float):
		text = subtitle_text
		duration = subtitle_duration

func _ready():
	print("📺 SubtitleDisplay initialized")
	setup_ui_styling()
	connect_signals()
	hide_subtitle()

func setup_ui_styling():
	"""Configura estilo visual egípcio das legendas"""
	
	if not background_panel:
		return
	
	# Egyptian-themed background
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.05, 0.02, 0.08, 0.9)  # Dark purple-brown
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	style_box.border_color = Color.GOLD
	style_box.corner_radius_top_left = 12
	style_box.corner_radius_top_right = 12
	style_box.corner_radius_bottom_left = 12
	style_box.corner_radius_bottom_right = 12
	
	# Add subtle gradient
	style_box.bg_color_pattern = Color(0.1, 0.05, 0.12, 0.95)
	
	background_panel.add_theme_stylebox_override("panel", style_box)
	
	# Configure subtitle label
	if subtitle_label:
		subtitle_label.bbcode_enabled = true
		subtitle_label.fit_content = true
		subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		subtitle_label.add_theme_color_override("default_color", Color.WHITE)
		
		# Egyptian hieroglyph-inspired font (if available)
		var egyptian_font = load("res://assets/fonts/egyptian_subtitle.ttf")
		if egyptian_font:
			subtitle_label.add_theme_font_override("normal_font", egyptian_font)
	
	# Configure speaker label
	if speaker_label:
		speaker_label.add_theme_color_override("font_color", Color.GOLD)
		speaker_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

func connect_signals():
	"""Conecta sinais do sistema"""
	
	if typing_timer:
		typing_timer.timeout.connect(_on_typing_timer_timeout)
	
	# Connect to global audio events
	if GameEvents:
		GameEvents.voice_line_started.connect(_on_voice_started)
		GameEvents.voice_line_finished.connect(_on_voice_finished)

func show_subtitle(text: String, duration: float = 0.0, speaker: String = "", priority: int = 1) -> bool:
	"""Mostra legenda com configurações especificadas"""
	
	var subtitle_duration = duration if duration > 0.0 else default_duration
	var subtitle_data = SubtitleData.new(text, subtitle_duration)
	subtitle_data.speaker = speaker
	subtitle_data.priority = priority
	
	# Determine if should show character-by-character reveal
	subtitle_data.character_reveal = (subtitle_duration > 2.0 and text.length() > 20)
	
	# Add to queue or display immediately
	if not is_displaying or priority > (current_subtitle.priority if current_subtitle else 0):
		# High priority - interrupt current subtitle
		if is_displaying:
			_finish_current_subtitle()
		
		current_subtitle = subtitle_data
		_display_subtitle_immediate()
		return true
	else:
		# Queue for later
		subtitle_queue.append(subtitle_data)
		return false

func show_cultural_subtitle(text: String, character_name: String, emotional_context: String = "neutral", duration: float = 0.0):
	"""Mostra legenda com contexto cultural egípcio"""
	
	# Apply cultural styling based on character
	var styled_text = _apply_cultural_styling(text, character_name, emotional_context)
	
	# Get character-specific duration if not provided
	var subtitle_duration = duration
	if subtitle_duration <= 0.0:
		subtitle_duration = _calculate_duration_for_character(text, character_name)
	
	var subtitle_data = SubtitleData.new(styled_text, subtitle_duration)
	subtitle_data.speaker = character_name
	subtitle_data.emotional_context = emotional_context
	subtitle_data.cultural_style = "egyptian"
	subtitle_data.show_sound_indicator = visual_sound_indicators
	
	# Egyptian divine characters get higher priority
	if character_name in ["Thoth", "Bastet", "Osiris", "Khnum"]:
		subtitle_data.priority = 3
	elif character_name == "Khenti":
		subtitle_data.priority = 2
	
	_queue_or_display_subtitle(subtitle_data)

func _apply_cultural_styling(text: String, character: String, emotion: String) -> String:
	"""Aplica estilização cultural egípcia ao texto"""
	
	var styled_text = text
	
	# Character-specific styling
	match character:
		"Khenti":
			styled_text = "[color=gold][b]%s[/b][/color]" % styled_text
			if emotion == "determined":
				styled_text = "[shake rate=3.0 level=1.0]%s[/shake]" % styled_text
		
		"Thoth":
			styled_text = "[color=cyan]%s[/color]" % styled_text
			if emotion == "wise":
				styled_text = "[wave amp=20.0 freq=2.0]%s[/wave]" % styled_text
		
		"Bastet":
			styled_text = "[color=orange]%s[/color]" % styled_text
			if emotion == "protective":
				styled_text = "[pulse freq=1.5 ease=2.0]%s[/pulse]" % styled_text
		
		"Osiris":
			styled_text = "[color=dark_green][i]%s[/i][/color]" % styled_text
			if emotion == "authoritative":
				styled_text = "[tornado radius=2.0 freq=1.0]%s[/tornado]" % styled_text
	
	# Add Egyptian decorative elements for important lines
	if character in ["Thoth", "Osiris", "Bastet"]:
		styled_text = "𓂀 %s 𓂀" % styled_text  # Egyptian hieroglyphs
	
	return styled_text

func _calculate_duration_for_character(text: String, character: String) -> float:
	"""Calcula duração baseada no personagem e texto"""
	
	var base_duration = text.length() * 0.08  # 80ms per character
	
	# Character-specific modifiers
	match character:
		"Thoth":
			base_duration *= 1.3  # Speaks slowly and wisely
		"Osiris":
			base_duration *= 1.4  # Divine authority speaks deliberately
		"Bastet":
			base_duration *= 0.9  # Quick and protective
		"Khenti":
			base_duration *= 1.0  # Normal pace
		_:
			base_duration *= 1.1  # Slightly slower for other characters
	
	# Minimum and maximum durations
	return clamp(base_duration, 1.5, 8.0)

func _queue_or_display_subtitle(subtitle_data: SubtitleData):
	"""Decide se mostra imediatamente ou enfileira"""
	
	if not is_displaying:
		current_subtitle = subtitle_data
		_display_subtitle_immediate()
	elif subtitle_data.priority > current_subtitle.priority:
		# Interrupt current subtitle
		_finish_current_subtitle()
		current_subtitle = subtitle_data
		_display_subtitle_immediate()
	else:
		# Add to queue
		subtitle_queue.append(subtitle_data)
		# Sort queue by priority
		subtitle_queue.sort_custom(func(a, b): return a.priority > b.priority)

func _display_subtitle_immediate():
	"""Mostra legenda imediatamente"""
	
	if not current_subtitle:
		return
	
	is_displaying = true
	
	# Update speaker label
	if speaker_label:
		if current_subtitle.speaker != "":
			speaker_label.text = current_subtitle.speaker + ":"
			speaker_label.visible = true
			
			# Apply character color
			var color = egyptian_speaker_colors.get(current_subtitle.speaker, Color.WHITE)
			speaker_label.add_theme_color_override("font_color", color)
		else:
			speaker_label.visible = false
	
	# Show sound indicator if requested
	if current_subtitle.show_sound_indicator and sound_indicator:
		_show_sound_indicator()
	
	# Handle RTL languages
	if is_rtl_language and subtitle_label:
		subtitle_label.text = "[right]%s[/right]" % current_subtitle.text
	else:
		subtitle_label.text = current_subtitle.text
	
	# Character reveal or immediate display
	if current_subtitle.character_reveal:
		_start_character_reveal()
	else:
		subtitle_label.text = current_subtitle.text
	
	# Show with fade in
	_fade_in_subtitle()
	
	# Set auto-hide timer
	var hide_timer = get_tree().create_timer(current_subtitle.duration)
	hide_timer.timeout.connect(_on_subtitle_timeout)
	
	# Emit signals
	subtitle_started.emit(current_subtitle.text)
	if current_subtitle.speaker != "":
		speaker_changed.emit(current_subtitle.speaker)

func _start_character_reveal():
	"""Inicia revelação caractere por caractere"""
	
	if not subtitle_label or not current_subtitle:
		return
	
	current_character_index = 0
	subtitle_label.text = ""
	
	# Calculate typing speed
	var chars_per_second = character_reveal_speed
	var interval = 1.0 / chars_per_second
	
	typing_timer.wait_time = interval
	typing_timer.start()

func _on_typing_timer_timeout():
	"""Callback para revelação de caracteres"""
	
	if not current_subtitle or current_character_index >= current_subtitle.text.length():
		typing_timer.stop()
		return
	
	# Add next character (handling BBCode)
	var full_text = current_subtitle.text
	var display_text = ""
	var actual_char_count = 0
	
	# Parse text considering BBCode tags
	var i = 0
	while i < full_text.length() and actual_char_count <= current_character_index:
		if full_text[i] == '[':
			# Skip BBCode tag
			var tag_end = full_text.find(']', i)
			if tag_end != -1:
				display_text += full_text.substr(i, tag_end - i + 1)
				i = tag_end + 1
			else:
				display_text += full_text[i]
				i += 1
				actual_char_count += 1
		else:
			display_text += full_text[i]
			i += 1
			actual_char_count += 1
	
	subtitle_label.text = display_text
	current_character_index += 1

func _fade_in_subtitle():
	"""Fade in da legenda"""
	
	if not background_panel:
		return
	
	background_panel.modulate.a = 0.0
	background_panel.visible = true
	
	var tween = create_tween()
	tween.tween_property(background_panel, "modulate:a", 1.0, fade_in_time)

func _fade_out_subtitle():
	"""Fade out da legenda"""
	
	if not background_panel:
		return
	
	var tween = create_tween()
	tween.tween_property(background_panel, "modulate:a", 0.0, fade_out_time)
	tween.tween_callback(func(): background_panel.visible = false)

func _show_sound_indicator():
	"""Mostra indicador visual de som"""
	
	if not sound_indicator:
		return
	
	# Create sound wave effect
	var wave_label = Label.new()
	wave_label.text = "🎵"
	wave_label.add_theme_font_size_override("font_size", 32)
	wave_label.modulate = Color.CYAN
	
	sound_indicator.add_child(wave_label)
	
	# Animate indicator
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Pulse animation
	tween.tween_method(
		func(scale: float): wave_label.scale = Vector2.ONE * scale,
		1.0, 1.5, 0.5
	)
	tween.tween_method(
		func(scale: float): wave_label.scale = Vector2.ONE * scale,
		1.5, 1.0, 0.5
	).set_delay(0.5)
	
	# Fade out and remove
	tween.tween_property(wave_label, "modulate:a", 0.0, 0.3).set_delay(1.5)
	tween.tween_callback(func(): wave_label.queue_free()).set_delay(1.8)

func _on_subtitle_timeout():
	"""Callback quando tempo da legenda acaba"""
	
	_finish_current_subtitle()

func _finish_current_subtitle():
	"""Finaliza legenda atual"""
	
	typing_timer.stop()
	_fade_out_subtitle()
	
	# Emit finish signal
	if current_subtitle:
		subtitle_finished.emit()
	
	current_subtitle = null
	is_displaying = false
	
	# Process queue
	_process_subtitle_queue()

func _process_subtitle_queue():
	"""Processa fila de legendas"""
	
	if subtitle_queue.is_empty():
		return
	
	var next_subtitle = subtitle_queue.pop_front()
	current_subtitle = next_subtitle
	
	# Small delay before showing next subtitle
	await get_tree().create_timer(0.2).timeout
	_display_subtitle_immediate()

func hide_subtitle():
	"""Esconde legenda atual imediatamente"""
	
	if typing_timer:
		typing_timer.stop()
	
	if background_panel:
		background_panel.visible = false
		background_panel.modulate.a = 1.0
	
	current_subtitle = null
	is_displaying = false

func clear_subtitle_queue():
	"""Limpa fila de legendas"""
	
	subtitle_queue.clear()

func set_accessibility_mode(enabled: bool):
	"""Define modo de acessibilidade"""
	
	accessibility_mode = enabled
	
	if enabled:
		# Larger font
		if subtitle_label:
			subtitle_label.add_theme_font_size_override("normal_font_size", 20)
		
		# Higher contrast
		high_contrast_mode = true
		_apply_accessibility_styling()

func set_dyslexia_friendly_mode(enabled: bool):
	"""Define modo amigável para disléxicos"""
	
	dyslexia_friendly = enabled
	
	if enabled and subtitle_label:
		# OpenDyslexic font if available
		var dyslexic_font = load("res://assets/fonts/opendyslexic.ttf")
		if dyslexic_font:
			subtitle_label.add_theme_font_override("normal_font", dyslexic_font)
		
		# Disable character reveal (can be confusing for dyslexics)
		character_reveal_speed = 1000.0  # Effectively instant

func set_rtl_mode(enabled: bool):
	"""Define modo direita-para-esquerda"""
	
	is_rtl_language = enabled

func set_visual_sound_indicators(enabled: bool):
	"""Define indicadores visuais de som"""
	
	visual_sound_indicators = enabled

func _apply_accessibility_styling():
	"""Aplica estilos de acessibilidade"""
	
	if not background_panel or not subtitle_label:
		return
	
	if high_contrast_mode:
		# High contrast background
		var high_contrast_style = StyleBoxFlat.new()
		high_contrast_style.bg_color = Color.BLACK
		high_contrast_style.border_width_top = 3
		high_contrast_style.border_width_bottom = 3
		high_contrast_style.border_color = Color.WHITE
		background_panel.add_theme_stylebox_override("panel", high_contrast_style)
		
		# High contrast text
		subtitle_label.add_theme_color_override("default_color", Color.WHITE)

# Event callbacks
func _on_voice_started(character: String, line_id: String):
	"""Callback quando voice line inicia"""
	
	# This could trigger subtitle display if integrated with VoiceSystem
	pass

func _on_voice_finished(character: String, line_id: String):
	"""Callback quando voice line termina"""
	
	# Could be used to synchronize subtitle timing
	pass

# Public interface for external systems

func get_current_subtitle_info() -> Dictionary:
	"""Retorna informações da legenda atual"""
	
	if not current_subtitle:
		return {}
	
	return {
		"text": current_subtitle.text,
		"speaker": current_subtitle.speaker,
		"duration": current_subtitle.duration,
		"emotional_context": current_subtitle.emotional_context,
		"is_displaying": is_displaying
	}

func get_queue_length() -> int:
	"""Retorna tamanho da fila de legendas"""
	
	return subtitle_queue.size()

func is_subtitle_active() -> bool:
	"""Verifica se há legenda ativa"""
	
	return is_displaying

# Debug functions

func debug_test_subtitle_styles():
	"""Debug: testa diferentes estilos de legenda"""
	
	print("📺 Testing subtitle styles...")
	
	var test_characters = ["Khenti", "Thoth", "Bastet", "Osiris"]
	var test_emotions = ["determined", "wise", "protective", "authoritative"]
	
	for i in range(test_characters.size()):
		var character = test_characters[i]
		var emotion = test_emotions[i]
		var text = "Esta é uma linha de teste para %s em contexto %s." % [character, emotion]
		
		show_cultural_subtitle(text, character, emotion, 3.0)
		await get_tree().create_timer(4.0).timeout

func debug_show_queue_status():
	"""Debug: mostra status da fila"""
	
	print("📺 Subtitle Queue Status:")
	print("  Current: ", current_subtitle.text if current_subtitle else "None")
	print("  Queue length: ", subtitle_queue.size())
	print("  Is displaying: ", is_displaying)