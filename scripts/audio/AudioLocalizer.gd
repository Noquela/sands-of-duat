class_name AudioLocalizer
extends Node

## 🌍 AUDIO LOCALIZATION SYSTEM - SANDS OF DUAT
## Sistema completo de localização para voice acting multicultural
##
## Features:
## - Multi-language voice support
## - Subtitle synchronization
## - Cultural audio adaptation
## - Accessibility features (visual sound indicators)
## - Egyptian cultural authenticity

signal language_changed(new_language: String)
signal localization_loaded(language: String)
signal accessibility_mode_changed(enabled: bool)

@export var default_language: String = "pt_BR"
@export var fallback_language: String = "en_US"
@export var accessibility_mode: bool = false
@export var visual_sound_indicators: bool = false
@export var subtitle_size_multiplier: float = 1.0

# Supported languages with cultural context
const SUPPORTED_LANGUAGES = {
	"pt_BR": {
		"name": "Português (Brasil)",
		"cultural_context": "brazilian_portuguese",
		"subtitle_font": "res://assets/fonts/pt_br_subtitle.ttf",
		"voice_style": "warm_expressive"
	},
	"en_US": {
		"name": "English (US)",
		"cultural_context": "american_english",
		"subtitle_font": "res://assets/fonts/en_subtitle.ttf",
		"voice_style": "clear_articulated"
	},
	"es_ES": {
		"name": "Español (España)",
		"cultural_context": "iberian_spanish",
		"subtitle_font": "res://assets/fonts/es_subtitle.ttf",
		"voice_style": "melodic_formal"
	},
	"ar_EG": {
		"name": "العربية (مصر)",
		"cultural_context": "egyptian_arabic",
		"subtitle_font": "res://assets/fonts/ar_subtitle.ttf",
		"voice_style": "authentic_egyptian",
		"rtl": true  # Right-to-left text
	},
	"fr_FR": {
		"name": "Français",
		"cultural_context": "metropolitan_french",
		"subtitle_font": "res://assets/fonts/fr_subtitle.ttf",
		"voice_style": "elegant_refined"
	}
}

# Egyptian cultural voice adaptations
const EGYPTIAN_CULTURAL_ADAPTATIONS = {
	"names": {
		"khenti": {
			"ar_EG": "خنتي",
			"en_US": "Khenti",
			"pt_BR": "Khenti",
			"es_ES": "Jenti",
			"fr_FR": "Khenti"
		},
		"thoth": {
			"ar_EG": "تحوت",
			"en_US": "Thoth",
			"pt_BR": "Thoth",
			"es_ES": "Tot",
			"fr_FR": "Thot"
		},
		"bastet": {
			"ar_EG": "باستت",
			"en_US": "Bastet",
			"pt_BR": "Bastet",
			"es_ES": "Bastet",
			"fr_FR": "Bastet"
		}
	},
	"divine_titles": {
		"lord_of_the_dead": {
			"ar_EG": "سيد الموتى",
			"en_US": "Lord of the Dead",
			"pt_BR": "Senhor dos Mortos",
			"es_ES": "Señor de los Muertos",
			"fr_FR": "Seigneur des Morts"
		},
		"scribe_of_gods": {
			"ar_EG": "كاتب الآلهة",
			"en_US": "Scribe of the Gods", 
			"pt_BR": "Escriba dos Deuses",
			"es_ES": "Escriba de los Dioses",
			"fr_FR": "Scribe des Dieux"
		}
	},
	"cultural_exclamations": {
		"by_ra": {
			"ar_EG": "وا رع!",
			"en_US": "By Ra!",
			"pt_BR": "Por Ra!",
			"es_ES": "¡Por Ra!",
			"fr_FR": "Par Râ!"
		},
		"maat_guide": {
			"ar_EG": "معات تدلني",
			"en_US": "Maat guide me",
			"pt_BR": "Que Maat me guie",
			"es_ES": "Que Maat me guíe",
			"fr_FR": "Que Maât me guide"
		}
	}
}

# Voice line localization database
var localized_lines: Dictionary = {}  # language -> line_id -> localized_data
var current_language: String = ""
var subtitle_renderer: SubtitleRenderer = null
var sound_visualizer: SoundVisualizer = null

# Accessibility features
var hearing_impaired_mode: bool = false
var dyslexia_friendly_mode: bool = false
var color_blind_friendly: bool = false

class LocalizedVoiceLine:
	var line_id: String
	var language: String
	var audio_file: String
	var subtitle_text: String
	var cultural_adaptation: String
	var pronunciation_guide: String = ""
	var emotional_context: String = ""
	var speaker_identification: String = ""  # For accessibility
	
	func _init(id: String, lang: String):
		line_id = id
		language = lang

class SubtitleRenderer:
	var subtitle_label: RichTextLabel
	var background_panel: Panel
	var current_font: Font
	var is_rtl: bool = false
	
	func _init():
		setup_subtitle_ui()
	
	func setup_subtitle_ui():
		# Create subtitle container
		background_panel = Panel.new()
		background_panel.name = "SubtitlePanel"
		
		# Style the panel
		var style_box = StyleBoxFlat.new()
		style_box.bg_color = Color(0, 0, 0, 0.8)
		style_box.corner_radius_top_left = 8
		style_box.corner_radius_top_right = 8
		style_box.corner_radius_bottom_left = 8
		style_box.corner_radius_bottom_right = 8
		background_panel.add_theme_stylebox_override("panel", style_box)
		
		# Create subtitle label
		subtitle_label = RichTextLabel.new()
		subtitle_label.name = "SubtitleText"
		subtitle_label.bbcode_enabled = true
		subtitle_label.fit_content = true
		subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
		background_panel.add_child(subtitle_label)
	
	func show_subtitle(text: String, duration: float, speaker: String = ""):
		if not subtitle_label:
			return
		
		# Format subtitle with speaker identification
		var formatted_text = text
		if speaker != "":
			formatted_text = "[color=gold][b]%s:[/b][/color] %s" % [speaker, text]
		
		# Handle RTL languages
		if is_rtl:
			formatted_text = "[right]" + formatted_text + "[/right]"
		
		subtitle_label.text = formatted_text
		background_panel.visible = true
		
		# Auto-hide after duration
		var tween = create_tween()
		tween.tween_delay(duration)
		tween.tween_callback(hide_subtitle)
	
	func hide_subtitle():
		if background_panel:
			background_panel.visible = false
	
	func set_font(font_path: String):
		var font = load(font_path)
		if font and subtitle_label:
			subtitle_label.add_theme_font_override("normal_font", font)
			current_font = font
	
	func set_rtl_mode(enabled: bool):
		is_rtl = enabled

class SoundVisualizer:
	"""Visual indicators for hearing-impaired players"""
	
	var indicator_container: Control
	var active_indicators: Dictionary = {}  # sound_type -> IndicatorNode
	
	enum SoundType {
		VOICE_LINE,
		COMBAT_SOUND,
		FOOTSTEPS,
		ENVIRONMENTAL,
		MUSIC_CHANGE
	}
	
	func _init():
		setup_visual_indicators()
	
	func setup_visual_indicators():
		indicator_container = Control.new()
		indicator_container.name = "SoundVisualizers"
		indicator_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		indicator_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	func show_sound_indicator(sound_type: SoundType, direction: Vector2 = Vector2.ZERO, intensity: float = 1.0):
		"""Show visual indicator for sound"""
		
		var indicator = SoundIndicator.new()
		indicator.setup(sound_type, direction, intensity)
		indicator_container.add_child(indicator)
		
		active_indicators[sound_type] = indicator
		
		# Auto-remove after animation
		var tween = create_tween()
		tween.tween_delay(2.0)
		tween.tween_callback(func(): indicator.queue_free())

class SoundIndicator extends Control:
	"""Individual visual sound indicator"""
	
	var sound_type: SoundVisualizer.SoundType
	var direction: Vector2
	var intensity: float
	
	func setup(type: SoundVisualizer.SoundType, dir: Vector2, intens: float):
		sound_type = type
		direction = dir
		intensity = intens
		
		# Create visual representation based on sound type
		match sound_type:
			SoundVisualizer.SoundType.VOICE_LINE:
				create_voice_indicator()
			SoundVisualizer.SoundType.COMBAT_SOUND:
				create_combat_indicator()
			SoundVisualizer.SoundType.FOOTSTEPS:
				create_movement_indicator()
			SoundVisualizer.SoundType.ENVIRONMENTAL:
				create_ambient_indicator()
	
	func create_voice_indicator():
		var label = Label.new()
		label.text = "🗣️"
		label.add_theme_font_size_override("font_size", 24)
		label.modulate = Color.CYAN
		add_child(label)
		animate_indicator()
	
	func create_combat_indicator():
		var label = Label.new()
		label.text = "⚔️"
		label.add_theme_font_size_override("font_size", 28)
		label.modulate = Color.RED
		add_child(label)
		animate_indicator()
	
	func create_movement_indicator():
		var label = Label.new()
		label.text = "👣"
		label.add_theme_font_size_override("font_size", 20)
		label.modulate = Color.YELLOW
		add_child(label)
		animate_indicator()
	
	func create_ambient_indicator():
		var label = Label.new()
		label.text = "🌊"
		label.add_theme_font_size_override("font_size", 22)
		label.modulate = Color.BLUE
		add_child(label)
		animate_indicator()
	
	func animate_indicator():
		var tween = create_tween()
		tween.set_parallel(true)
		
		# Pulse animation
		tween.tween_method(
			func(scale_val: float): scale = Vector2.ONE * scale_val,
			1.0, 1.5, 0.3
		)
		tween.tween_method(
			func(scale_val: float): scale = Vector2.ONE * scale_val,
			1.5, 1.0, 0.3
		).set_delay(0.3)
		
		# Fade out
		tween.tween_property(self, "modulate:a", 0.0, 0.5).set_delay(1.5)

func _ready():
	print("🌍 AudioLocalizer initialized")
	current_language = default_language
	
	setup_localization_system()
	load_localized_voice_lines()
	setup_accessibility_features()

func setup_localization_system():
	"""Configura sistema de localização base"""
	
	# Create subtitle renderer
	subtitle_renderer = SubtitleRenderer.new()
	add_child(subtitle_renderer.background_panel)
	
	# Position subtitles at bottom of screen
	var viewport = get_viewport()
	if viewport:
		var screen_size = viewport.get_visible_rect().size
		subtitle_renderer.background_panel.position = Vector2(
			screen_size.x * 0.1,
			screen_size.y * 0.85
		)
		subtitle_renderer.background_panel.size = Vector2(
			screen_size.x * 0.8,
			screen_size.y * 0.1
		)
	
	# Setup sound visualizer for accessibility
	if visual_sound_indicators:
		sound_visualizer = SoundVisualizer.new()
		add_child(sound_visualizer.indicator_container)
	
	print("✅ Localization system setup complete")

func load_localized_voice_lines():
	"""Carrega voice lines localizadas"""
	
	# Load localization files for each language
	for language in SUPPORTED_LANGUAGES.keys():
		load_language_voice_lines(language)
	
	# Set current language
	set_language(current_language)
	
	print("✅ Localized voice lines loaded: ", localized_lines.size(), " languages")

func load_language_voice_lines(language: String):
	"""Carrega voice lines para idioma específico"""
	
	var lang_data = {}
	var lang_info = SUPPORTED_LANGUAGES.get(language, {})
	
	# Egyptian protagonist lines (Khenti)
	var khenti_lines = get_khenti_localized_lines(language)
	for line_id in khenti_lines.keys():
		lang_data[line_id] = khenti_lines[line_id]
	
	# Divine character lines (Thoth, Bastet, etc.)
	var divine_lines = get_divine_localized_lines(language)
	for line_id in divine_lines.keys():
		lang_data[line_id] = divine_lines[line_id]
	
	# System/UI lines
	var ui_lines = get_ui_localized_lines(language)
	for line_id in ui_lines.keys():
		lang_data[line_id] = ui_lines[line_id]
	
	localized_lines[language] = lang_data

func get_khenti_localized_lines(language: String) -> Dictionary:
	"""Retorna linhas localizadas do Khenti"""
	
	var lines = {}
	
	# Combat barks with cultural adaptation
	var combat_barks = {
		"pt_BR": [
			"Por Ra! Vocês pagarão!",
			"A justiça de Maat me guia!",
			"Pelos deuses do Alto Egito!",
			"Minha lâmina bebe o sangue dos traidores!",
			"Que Ra ilumine meu khopesh!"
		],
		"en_US": [
			"By Ra! You will pay!",
			"The justice of Maat guides me!",
			"By the gods of Upper Egypt!",
			"My blade drinks the blood of traitors!",
			"May Ra illuminate my khopesh!"
		],
		"es_ES": [
			"¡Por Ra! ¡Pagaréis!",
			"¡La justicia de Maat me guía!",
			"¡Por los dioses del Alto Egipto!",
			"¡Mi hoja bebe la sangre de los traidores!",
			"¡Que Ra ilumine mi jopesh!"
		],
		"ar_EG": [
			"وا رع! ستدفعون الثمن!",
			"عدالة معات تهديني!",
			"بآلهة مصر العليا!",
			"نصلي يشرب دم الخونة!",
			"ليضيء رع خبشي!"
		],
		"fr_FR": [
			"Par Râ ! Vous allez payer !",
			"La justice de Maât me guide !",
			"Par les dieux de Haute-Égypte !",
			"Ma lame boit le sang des traîtres !",
			"Que Râ illumine mon khépesh !"
		]
	}
	
	var lang_barks = combat_barks.get(language, combat_barks[fallback_language])
	
	for i in range(lang_barks.size()):
		var line = LocalizedVoiceLine.new("khenti_combat_%d" % i, language)
		line.audio_file = "res://assets/audio/voice/%s/khenti/combat/bark_%02d.ogg" % [language, i]
		line.subtitle_text = lang_barks[i]
		line.cultural_adaptation = "egyptian_royal"
		line.speaker_identification = "Khenti"
		line.emotional_context = "determined_anger"
		lines[line.line_id] = line
	
	return lines

func get_divine_localized_lines(language: String) -> Dictionary:
	"""Retorna linhas localizadas dos deuses"""
	
	var lines = {}
	
	# Thoth wisdom lines
	var thoth_lines = {
		"pt_BR": [
			"Assim... o príncipe desperta no Duat. Interessante.",
			"A sabedoria dos antigos flui através das eras.",
			"Jovem príncipe, aceite o conhecimento que ofereço.",
			"No Duat, a verdade é mais afiada que qualquer lâmina."
		],
		"en_US": [
			"So... the prince awakens in the Duat. Interesting.",
			"The wisdom of the ancients flows through the ages.",
			"Young prince, accept the knowledge I offer.",
			"In the Duat, truth is sharper than any blade."
		],
		"ar_EG": [
			"إذن... الأمير يستيقظ في دوات. مثير للاهتمام.",
			"حكمة القدماء تتدفق عبر العصور.",
			"أيها الأمير الشاب، اقبل المعرفة التي أقدمها.",
			"في دوات، الحقيقة أحد من أي نصل."
		]
	}
	
	var lang_thoth = thoth_lines.get(language, thoth_lines[fallback_language])
	
	for i in range(lang_thoth.size()):
		var line = LocalizedVoiceLine.new("thoth_intro_%d" % i, language)
		line.audio_file = "res://assets/audio/voice/%s/thoth/intro_%02d.ogg" % [language, i]
		line.subtitle_text = lang_thoth[i]
		line.cultural_adaptation = "divine_egyptian"
		line.speaker_identification = "Thoth"
		line.emotional_context = "wise_contemplative"
		line.pronunciation_guide = "THOTH (toht) - Ancient Egyptian god of wisdom"
		lines[line.line_id] = line
	
	return lines

func get_ui_localized_lines(language: String) -> Dictionary:
	"""Retorna linhas de interface localizadas"""
	
	var lines = {}
	
	# Tutorial hints
	var tutorial_lines = {
		"pt_BR": [
			"Use WASD para se mover pelos corredores do Duat.",
			"Clique para atacar com sua arma divina.",
			"Colete boons dos deuses para fortalecer sua alma."
		],
		"en_US": [
			"Use WASD to move through the corridors of the Duat.",
			"Click to attack with your divine weapon.",
			"Collect boons from the gods to strengthen your soul."
		],
		"ar_EG": [
			"استخدم WASD للتحرك عبر ممرات دوات.",
			"انقر للهجوم بسلاحك الإلهي.",
			"اجمع نعم الآلهة لتقوية روحك."
		]
	}
	
	var lang_tutorials = tutorial_lines.get(language, tutorial_lines[fallback_language])
	
	for i in range(lang_tutorials.size()):
		var line = LocalizedVoiceLine.new("tutorial_%d" % i, language)
		line.audio_file = "res://assets/audio/voice/%s/system/tutorial_%02d.ogg" % [language, i]
		line.subtitle_text = lang_tutorials[i]
		line.cultural_adaptation = "instructional"
		line.speaker_identification = "System"
		lines[line.line_id] = line
	
	return lines

func setup_accessibility_features():
	"""Configura recursos de acessibilidade"""
	
	# Load accessibility settings from user preferences
	var settings = GameSettings.get_accessibility_settings()
	
	hearing_impaired_mode = settings.get("hearing_impaired", false)
	dyslexia_friendly_mode = settings.get("dyslexia_friendly", false)
	color_blind_friendly = settings.get("color_blind_friendly", false)
	visual_sound_indicators = settings.get("visual_sound_indicators", false)
	subtitle_size_multiplier = settings.get("subtitle_size", 1.0)
	
	apply_accessibility_settings()
	
	print("✅ Accessibility features configured")

func apply_accessibility_settings():
	"""Aplica configurações de acessibilidade"""
	
	if subtitle_renderer:
		# Dyslexia-friendly font
		if dyslexia_friendly_mode:
			var dyslexic_font = load("res://assets/fonts/dyslexic_friendly.ttf")
			if dyslexic_font:
				subtitle_renderer.subtitle_label.add_theme_font_override("normal_font", dyslexic_font)
		
		# Larger text for vision impaired
		if subtitle_size_multiplier != 1.0:
			var base_size = 16
			var new_size = int(base_size * subtitle_size_multiplier)
			subtitle_renderer.subtitle_label.add_theme_font_size_override("normal_font_size", new_size)
		
		# High contrast mode for color blind users
		if color_blind_friendly:
			subtitle_renderer.subtitle_label.add_theme_color_override("default_color", Color.WHITE)
			var high_contrast_bg = StyleBoxFlat.new()
			high_contrast_bg.bg_color = Color.BLACK
			subtitle_renderer.background_panel.add_theme_stylebox_override("panel", high_contrast_bg)

# Public interface methods

func set_language(language: String) -> bool:
	"""Define idioma atual da localização"""
	
	if not SUPPORTED_LANGUAGES.has(language):
		print("⚠️ Language not supported: ", language)
		return false
	
	var old_language = current_language
	current_language = language
	
	# Configure subtitle renderer for language
	var lang_info = SUPPORTED_LANGUAGES[language]
	if subtitle_renderer:
		# Set appropriate font
		if lang_info.has("subtitle_font"):
			subtitle_renderer.set_font(lang_info.subtitle_font)
		
		# Handle RTL languages
		if lang_info.get("rtl", false):
			subtitle_renderer.set_rtl_mode(true)
		else:
			subtitle_renderer.set_rtl_mode(false)
	
	# Emit language changed signal
	language_changed.emit(language)
	localization_loaded.emit(language)
	
	print("🌍 Language changed: ", old_language, " → ", language)
	return true

func get_localized_voice_line(line_id: String, language: String = "") -> LocalizedVoiceLine:
	"""Retorna voice line localizada"""
	
	var target_language = language if language != "" else current_language
	
	# Try target language first
	if localized_lines.has(target_language) and localized_lines[target_language].has(line_id):
		return localized_lines[target_language][line_id]
	
	# Fall back to default language
	if target_language != fallback_language:
		if localized_lines.has(fallback_language) and localized_lines[fallback_language].has(line_id):
			return localized_lines[fallback_language][line_id]
	
	# Return null if not found
	return null

func adapt_cultural_text(text: String, target_language: String = "") -> String:
	"""Adapta texto com contexto cultural egípcio"""
	
	var lang = target_language if target_language != "" else current_language
	var adapted_text = text
	
	# Apply cultural name adaptations
	for name_key in EGYPTIAN_CULTURAL_ADAPTATIONS.names.keys():
		var adaptations = EGYPTIAN_CULTURAL_ADAPTATIONS.names[name_key]
		if adaptations.has(lang):
			var original = adaptations.get(fallback_language, name_key)
			var adapted = adaptations[lang]
			adapted_text = adapted_text.replace(original, adapted)
	
	# Apply divine title adaptations
	for title_key in EGYPTIAN_CULTURAL_ADAPTATIONS.divine_titles.keys():
		var adaptations = EGYPTIAN_CULTURAL_ADAPTATIONS.divine_titles[title_key]
		if adaptations.has(lang):
			var original = adaptations.get(fallback_language, title_key)
			var adapted = adaptations[lang]
			adapted_text = adapted_text.replace(original, adapted)
	
	# Apply cultural exclamation adaptations
	for excl_key in EGYPTIAN_CULTURAL_ADAPTATIONS.cultural_exclamations.keys():
		var adaptations = EGYPTIAN_CULTURAL_ADAPTATIONS.cultural_exclamations[excl_key]
		if adaptations.has(lang):
			var original = adaptations.get(fallback_language, excl_key)
			var adapted = adaptations[lang]
			adapted_text = adapted_text.replace(original, adapted)
	
	return adapted_text

func show_localized_subtitle(line_id: String, duration: float, speaker: String = ""):
	"""Mostra legenda localizada"""
	
	var voice_line = get_localized_voice_line(line_id)
	if not voice_line:
		print("⚠️ Localized voice line not found: ", line_id)
		return
	
	var subtitle_text = voice_line.subtitle_text
	var speaker_name = speaker
	
	# Adapt cultural context
	subtitle_text = adapt_cultural_text(subtitle_text)
	
	# Use speaker identification from voice line if not provided
	if speaker == "" and voice_line.speaker_identification != "":
		speaker_name = voice_line.speaker_identification
	
	# Show subtitle with accessibility features
	if subtitle_renderer:
		subtitle_renderer.show_subtitle(subtitle_text, duration, speaker_name)
	
	# Show visual sound indicator if accessibility mode enabled
	if visual_sound_indicators and sound_visualizer:
		sound_visualizer.show_sound_indicator(SoundVisualizer.SoundType.VOICE_LINE)

func set_accessibility_mode(mode: String, enabled: bool):
	"""Define modo de acessibilidade específico"""
	
	match mode:
		"hearing_impaired":
			hearing_impaired_mode = enabled
			visual_sound_indicators = enabled
		"dyslexia_friendly":
			dyslexia_friendly_mode = enabled
		"color_blind_friendly":
			color_blind_friendly = enabled
		"visual_sound_indicators":
			visual_sound_indicators = enabled
	
	apply_accessibility_settings()
	accessibility_mode_changed.emit(enabled)

func get_supported_languages() -> Array[String]:
	"""Retorna lista de idiomas suportados"""
	return SUPPORTED_LANGUAGES.keys()

func get_language_info(language: String) -> Dictionary:
	"""Retorna informações sobre idioma específico"""
	return SUPPORTED_LANGUAGES.get(language, {})

func get_localization_statistics() -> Dictionary:
	"""Retorna estatísticas da localização"""
	
	var stats = {
		"current_language": current_language,
		"supported_languages": SUPPORTED_LANGUAGES.size(),
		"total_localized_lines": 0,
		"accessibility_features_enabled": {
			"hearing_impaired": hearing_impaired_mode,
			"dyslexia_friendly": dyslexia_friendly_mode,
			"color_blind_friendly": color_blind_friendly,
			"visual_sound_indicators": visual_sound_indicators
		}
	}
	
	for language in localized_lines.keys():
		stats.total_localized_lines += localized_lines[language].size()
	
	return stats

# Debug functions

func debug_test_all_languages():
	"""Debug: testa todas as linguagens com linha de exemplo"""
	
	print("🌍 Testing all languages:")
	for language in SUPPORTED_LANGUAGES.keys():
		set_language(language)
		var test_line = get_localized_voice_line("khenti_combat_0")
		if test_line:
			print("  %s: %s" % [language, test_line.subtitle_text])
		await get_tree().create_timer(1.0).timeout

func debug_show_cultural_adaptations():
	"""Debug: mostra adaptações culturais"""
	
	print("🏛️ Cultural adaptations:")
	for category in EGYPTIAN_CULTURAL_ADAPTATIONS.keys():
		print("  Category: ", category)
		for key in EGYPTIAN_CULTURAL_ADAPTATIONS[category].keys():
			print("    ", key, ": ", EGYPTIAN_CULTURAL_ADAPTATIONS[category][key])