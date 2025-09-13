# ✨ FASE 4: POLISH & COMPLETION - Sprints 21-24

## 🏆 **VISÃO GERAL DA FASE**

**Objetivo Central:** Elevar Sands of Duat de um jogo completo para uma obra-prima indie AAA. Cada elemento deve atingir qualidade comercial premium, competindo com os melhores roguelikes do mercado.

**Filosofia:** O polish não é apenas correção de bugs - é a transformação de sistemas funcionais em experiências memoráveis. Cada tela, cada som, cada transição deve ser impecável.

**Success Criteria desta Fase:**
- UI/UX indistinguível de jogos AAA comerciais
- Narrativa completa com 4 endings únicos e satisfatórios
- Boss final (Osiris) como experiência climática definitiva  
- Performance otimizada para 60 FPS constante
- Sistema de QA que garante zero bugs críticos no release

---

## 🎨 **SPRINT 21: UI/UX COMPLETE**

### **🎯 Objetivos Principais**
1. **Menu Systems:** Interfaces principais com design profissional
2. **In-Game HUD:** UI responsiva e elegante durante gameplay
3. **Accessibility:** Suporte para diferentes necessidades de jogadores
4. **Controller Support:** Funcionalidade completa para gamepads
5. **Visual Polish:** Consistência visual em todas as telas
6. **Performance UI:** Interface que roda suave mesmo em hardware baixo

### **🏗️ Professional UI System**

#### **A. Main Menu System**
```gdscript
# MainMenuManager.gd - Sistema de menu principal profissional
extends Control
class_name MainMenuManager

@onready var title_logo: TextureRect = $TitleLogo
@onready var menu_container: VBoxContainer = $MenuContainer
@onready var background_video: VideoStreamPlayer = $BackgroundVideo
@onready var audio_manager: AudioStreamPlayer = $AudioManager
@onready var settings_panel: SettingsPanel = $SettingsPanel

var menu_tween: Tween
var is_transitioning: bool = false

signal menu_option_selected(option: String)

func _ready():
    _setup_animated_background()
    _initialize_menu_options()
    _setup_audio_atmosphere()
    _load_player_progress()

func _setup_animated_background():
    # Animated Egyptian-themed background
    var background_scenes = [
        "res://ui/backgrounds/duat_flowing.ogv",
        "res://ui/backgrounds/pyramid_sunset.ogv", 
        "res://ui/backgrounds/nile_reflection.ogv"
    ]
    
    var selected_bg = background_scenes[randi() % background_scenes.size()]
    background_video.stream = load(selected_bg)
    background_video.play()
    background_video.loop = true
    
    # Subtle parallax effect on logo
    _animate_logo_floating()

func _initialize_menu_options():
    var menu_options = [
        {"id": "new_game", "text": "Nova Jornada", "enabled": true},
        {"id": "continue", "text": "Continuar", "enabled": _has_save_data()},
        {"id": "heat_selection", "text": "Desafio Personalizado", "enabled": _has_completed_run()},
        {"id": "codex", "text": "Codex Egípcio", "enabled": true},
        {"id": "settings", "text": "Configurações", "enabled": true},
        {"id": "credits", "text": "Créditos", "enabled": true},
        {"id": "quit", "text": "Sair", "enabled": true}
    ]
    
    _build_menu_interface(menu_options)

func _build_menu_interface(options: Array):
    # Clear existing menu
    for child in menu_container.get_children():
        child.queue_free()
    
    for option in options:
        var menu_button = _create_styled_menu_button(option)
        menu_container.add_child(menu_button)
        
        if option.enabled:
            menu_button.pressed.connect(_on_menu_option_pressed.bind(option.id))
        else:
            menu_button.disabled = true
            menu_button.modulate.a = 0.5

func _create_styled_menu_button(option_data: Dictionary) -> Button:
    var button = Button.new()
    button.text = option_data.text
    button.custom_minimum_size = Vector2(300, 60)
    
    # Egyptian-themed styling
    var style_box = StyleBoxFlat.new()
    style_box.bg_color = Color(0.2, 0.1, 0.05, 0.8)  # Dark brown with transparency
    style_box.border_width_left = 2
    style_box.border_width_right = 2  
    style_box.border_width_top = 2
    style_box.border_width_bottom = 2
    style_box.border_color = Color.GOLD
    style_box.corner_radius_top_left = 10
    style_box.corner_radius_top_right = 10
    style_box.corner_radius_bottom_left = 10
    style_box.corner_radius_bottom_right = 10
    
    button.add_theme_stylebox_override("normal", style_box)
    
    # Hover effect
    var hover_style = style_box.duplicate()
    hover_style.bg_color = Color(0.3, 0.2, 0.1, 0.9)
    hover_style.border_color = Color.WHITE
    button.add_theme_stylebox_override("hover", hover_style)
    
    # Font styling
    button.add_theme_font_size_override("font_size", 24)
    button.add_theme_color_override("font_color", Color.GOLD)
    
    # Hover animations
    button.mouse_entered.connect(_animate_button_hover.bind(button, true))
    button.mouse_exited.connect(_animate_button_hover.bind(button, false))
    
    return button

func _animate_button_hover(button: Button, hovered: bool):
    if menu_tween:
        menu_tween.kill()
    menu_tween = create_tween()
    
    if hovered:
        menu_tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.1)
        _play_hover_sound()
    else:
        menu_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.1)

func _on_menu_option_pressed(option_id: String):
    if is_transitioning:
        return
        
    is_transitioning = true
    _play_selection_sound()
    
    match option_id:
        "new_game":
            _start_new_game_sequence()
        "continue":
            _continue_existing_game()
        "heat_selection":
            _open_heat_customization()
        "codex":
            _open_codex_system()
        "settings":
            _open_settings_panel()
        "credits":
            _show_credits_sequence()
        "quit":
            _quit_with_confirmation()

func _start_new_game_sequence():
    # Cinematic transition to character selection/intro
    var transition_overlay = ColorRect.new()
    transition_overlay.color = Color.BLACK
    transition_overlay.modulate.a = 0.0
    add_child(transition_overlay)
    
    var fade_tween = create_tween()
    fade_tween.tween_property(transition_overlay, "modulate:a", 1.0, 1.0)
    await fade_tween.finished
    
    # Play intro cinematic or go to character select
    if not GameManager.has_seen_intro_cinematic:
        SceneManager.change_scene("res://cinematics/IntroSequence.tscn")
    else:
        SceneManager.change_scene("res://scenes/hub/PoolOfMemories.tscn")
```

#### **B. In-Game HUD System**
```gdscript
# GameHUD.gd - HUD elegante e responsivo durante gameplay
extends Control
class_name GameHUD

@onready var health_bar: ProgressBar = $TopLeft/HealthBar
@onready var mana_bar: ProgressBar = $TopLeft/ManaBar  
@onready var boon_display: HBoxContainer = $TopRight/BoonDisplay
@onready var weapon_indicator: WeaponIndicator = $BottomLeft/WeaponIndicator
@onready var minimap: Minimap = $TopRight/Minimap
@onready var interaction_prompt: Label = $Center/InteractionPrompt
@onready var damage_overlay: Control = $DamageOverlay
@onready var boss_health_bar: BossHealthBar = $TopCenter/BossHealthBar

var hud_tween: Tween
var health_warning_active: bool = false
var boon_icons: Array[Control] = []

signal interaction_available(prompt_text: String)
signal boss_encounter_started(boss_name: String)

func _ready():
    _connect_to_game_systems()
    _setup_responsive_design()
    _initialize_health_warning_system()

func _connect_to_game_systems():
    # Connect to GameManager signals
    GameManager.player_health_changed.connect(_update_health_display)
    GameManager.player_mana_changed.connect(_update_mana_display)
    GameManager.boon_acquired.connect(_add_boon_to_display)
    GameManager.boon_removed.connect(_remove_boon_from_display)
    GameManager.weapon_changed.connect(_update_weapon_indicator)
    GameManager.boss_encounter_started.connect(_show_boss_health_bar)
    GameManager.interaction_available.connect(_show_interaction_prompt)

func _setup_responsive_design():
    # Adapt to different screen resolutions
    var viewport_size = get_viewport().size
    var scale_factor = min(viewport_size.x / 1920.0, viewport_size.y / 1080.0)
    
    # Scale UI elements appropriately
    scale = Vector2(scale_factor, scale_factor)
    
    # Adjust positions for different aspect ratios
    if viewport_size.x / viewport_size.y > 1.8:  # Ultra-wide
        _adjust_for_ultrawide()
    elif viewport_size.x / viewport_size.y < 1.6:  # 4:3 or similar
        _adjust_for_square_aspect()

func _update_health_display(current_health: float, max_health: float):
    var health_percentage = current_health / max_health
    
    # Smooth health bar animation
    if hud_tween:
        hud_tween.kill()
    hud_tween = create_tween()
    hud_tween.tween_property(health_bar, "value", health_percentage * 100, 0.3)
    
    # Health warning system
    if health_percentage <= 0.25 and not health_warning_active:
        _activate_health_warning()
    elif health_percentage > 0.25 and health_warning_active:
        _deactivate_health_warning()
    
    # Dynamic health bar color
    _update_health_bar_color(health_percentage)

func _update_health_bar_color(percentage: float):
    var health_color: Color
    
    if percentage > 0.6:
        health_color = Color.GREEN
    elif percentage > 0.3:
        health_color = Color.YELLOW  
    else:
        health_color = Color.RED
    
    # Smooth color transition
    var color_tween = create_tween()
    color_tween.tween_property(health_bar, "modulate", health_color, 0.2)

func _activate_health_warning():
    health_warning_active = true
    
    # Pulse effect on health bar
    var pulse_tween = create_tween()
    pulse_tween.set_loops()
    pulse_tween.tween_property(health_bar, "modulate:a", 0.5, 0.5)
    pulse_tween.tween_property(health_bar, "modulate:a", 1.0, 0.5)
    
    # Screen edge red tint
    damage_overlay.show()
    var overlay_tween = create_tween()
    overlay_tween.set_loops()
    overlay_tween.tween_property(damage_overlay, "modulate:a", 0.2, 0.8)
    overlay_tween.tween_property(damage_overlay, "modulate:a", 0.0, 0.8)

func _add_boon_to_display(boon_data: Dictionary):
    var boon_icon = _create_boon_icon(boon_data)
    boon_display.add_child(boon_icon)
    boon_icons.append(boon_icon)
    
    # Entrance animation
    boon_icon.modulate.a = 0.0
    boon_icon.scale = Vector2.ZERO
    
    var entrance_tween = create_tween()
    entrance_tween.parallel().tween_property(boon_icon, "modulate:a", 1.0, 0.3)
    entrance_tween.parallel().tween_property(boon_icon, "scale", Vector2.ONE, 0.3)
    
    # Reorganize layout
    _reorganize_boon_display()

func _create_boon_icon(boon_data: Dictionary) -> Control:
    var icon_container = Control.new()
    icon_container.custom_minimum_size = Vector2(48, 48)
    
    var background = NinePatchRect.new()
    background.texture = load("res://ui/boon_icon_background.png")
    background.anchors_preset = Control.PRESET_FULL_RECT
    icon_container.add_child(background)
    
    var icon = TextureRect.new()
    icon.texture = load(boon_data.icon_path)
    icon.anchors_preset = Control.PRESET_FULL_RECT
    icon.margin_left = 4
    icon.margin_right = -4
    icon.margin_top = 4
    icon.margin_bottom = -4
    icon_container.add_child(icon)
    
    # Rarity border color
    match boon_data.rarity:
        "Common":
            background.modulate = Color.WHITE
        "Rare":
            background.modulate = Color.BLUE
        "Epic":
            background.modulate = Color.PURPLE
        "Legendary":
            background.modulate = Color.GOLD
    
    # Tooltip on hover
    icon_container.mouse_entered.connect(_show_boon_tooltip.bind(boon_data))
    icon_container.mouse_exited.connect(_hide_boon_tooltip)
    
    return icon_container

func _show_boss_health_bar(boss_name: String, max_health: float):
    boss_health_bar.show()
    boss_health_bar.setup_boss_display(boss_name, max_health)
    
    # Dramatic entrance animation
    boss_health_bar.position.y = -100
    var entrance_tween = create_tween()
    entrance_tween.tween_property(boss_health_bar, "position:y", 0, 0.5)
    entrance_tween.tween_callback(_play_boss_health_bar_sound)

func _show_interaction_prompt(prompt_text: String):
    interaction_prompt.text = prompt_text
    interaction_prompt.show()
    
    # Subtle pulsing animation
    var pulse_tween = create_tween()
    pulse_tween.set_loops()
    pulse_tween.tween_property(interaction_prompt, "modulate:a", 0.7, 1.0)
    pulse_tween.tween_property(interaction_prompt, "modulate:a", 1.0, 1.0)
```

#### **C. Accessibility System**
```gdscript
# AccessibilityManager.gd - Suporte para diferentes necessidades
extends Node
class_name AccessibilityManager

var colorblind_support: bool = false
var high_contrast_mode: bool = false
var large_text_mode: bool = false
var reduced_motion: bool = false
var subtitle_enabled: bool = true
var controller_vibration: bool = true

@export var accessibility_settings: AccessibilitySettings

signal accessibility_setting_changed(setting_name: String, value: bool)

func _ready():
    _load_accessibility_preferences()
    _apply_accessibility_settings()

func _load_accessibility_preferences():
    var config = ConfigFile.new()
    if config.load("user://accessibility.cfg") == OK:
        colorblind_support = config.get_value("visual", "colorblind_support", false)
        high_contrast_mode = config.get_value("visual", "high_contrast", false)
        large_text_mode = config.get_value("visual", "large_text", false)
        reduced_motion = config.get_value("visual", "reduced_motion", false)
        subtitle_enabled = config.get_value("audio", "subtitles", true)
        controller_vibration = config.get_value("input", "vibration", true)

func enable_colorblind_support(support_type: String):
    colorblind_support = true
    
    # Apply colorblind-friendly palette
    match support_type:
        "deuteranopia":
            _apply_deuteranopia_colors()
        "protanopia":
            _apply_protanopia_colors()
        "tritanopia":
            _apply_tritanopia_colors()
    
    _save_accessibility_setting("colorblind_support", true)
    _save_accessibility_setting("colorblind_type", support_type)

func _apply_deuteranopia_colors():
    # Replace red-green problem colors
    var color_replacements = {
        Color.RED: Color.ORANGE,
        Color.GREEN: Color.BLUE,
        Color.YELLOW: Color.CYAN
    }
    
    _update_ui_colors(color_replacements)

func enable_high_contrast_mode(enabled: bool):
    high_contrast_mode = enabled
    
    if enabled:
        # High contrast color scheme
        var theme_override = Theme.new()
        theme_override.set_color("font_color", "Label", Color.WHITE)
        theme_override.set_color("bg_color", "Panel", Color.BLACK)
        theme_override.set_color("border_color", "StyleBoxFlat", Color.WHITE)
        
        # Apply to all UI elements
        _apply_theme_recursively(get_tree().root, theme_override)
    else:
        # Restore original theme
        _restore_original_theme()
    
    _save_accessibility_setting("high_contrast", enabled)

func enable_large_text_mode(enabled: bool):
    large_text_mode = enabled
    var scale_factor = 1.5 if enabled else 1.0
    
    # Scale all text elements
    _scale_fonts_recursively(get_tree().root, scale_factor)
    
    _save_accessibility_setting("large_text", enabled)

func enable_reduced_motion(enabled: bool):
    reduced_motion = enabled
    
    # Disable or reduce animations based on setting
    if enabled:
        Engine.time_scale = 1.0  # Ensure normal game speed
        _disable_non_essential_animations()
    else:
        _restore_all_animations()
    
    _save_accessibility_setting("reduced_motion", enabled)

func _disable_non_essential_animations():
    # Disable screen shake
    CombatJuiceManager.screen_shake_intensity = 0.0
    
    # Reduce particle effects
    CombatJuiceManager.particle_quality = "Low"
    
    # Disable UI animations
    var all_tweens = get_tree().get_nodes_in_group("ui_tweens")
    for tween in all_tweens:
        if tween.is_valid():
            tween.kill()

func setup_subtitle_system():
    if not subtitle_enabled:
        return
    
    # Create subtitle display
    var subtitle_ui = SubtitleDisplay.new()
    get_tree().root.add_child(subtitle_ui)
    
    # Connect to dialogue and audio systems
    DialogueSystem.dialogue_spoken.connect(subtitle_ui.show_subtitle)
    AudioManager.sound_played.connect(subtitle_ui.show_audio_description)

func enable_controller_vibration(enabled: bool):
    controller_vibration = enabled
    
    # Configure input system
    if enabled:
        Input.start_joy_vibration.connect(_on_vibration_request)
    else:
        # Disable all vibration
        for device in Input.get_connected_joypads():
            Input.stop_joy_vibration(device)
    
    _save_accessibility_setting("controller_vibration", enabled)

func _save_accessibility_setting(setting_name: String, value):
    var config = ConfigFile.new()
    config.load("user://accessibility.cfg")  # Load existing or create new
    
    var section = "visual"
    if setting_name in ["subtitles"]:
        section = "audio"
    elif setting_name in ["controller_vibration"]:
        section = "input"
    
    config.set_value(section, setting_name, value)
    config.save("user://accessibility.cfg")
    
    accessibility_setting_changed.emit(setting_name, value)
```

### **🎮 Controller Support System**
```gdscript
# ControllerSupport.gd - Suporte completo para gamepads
extends Node
class_name ControllerSupport

var active_controller: int = -1
var controller_type: String = ""
var input_mapping: Dictionary = {}
var vibration_enabled: bool = true

signal controller_connected(device_id: int, controller_name: String)
signal controller_disconnected(device_id: int)
signal input_method_changed(method: String)  # "keyboard" or "controller"

func _ready():
    _setup_controller_detection()
    _load_controller_preferences()
    _initialize_input_mapping()

func _setup_controller_detection():
    Input.joy_connection_changed.connect(_on_controller_connection_changed)
    
    # Check for already connected controllers
    for device_id in Input.get_connected_joypads():
        _on_controller_connected(device_id)

func _on_controller_connection_changed(device_id: int, connected: bool):
    if connected:
        _on_controller_connected(device_id)
    else:
        _on_controller_disconnected(device_id)

func _on_controller_connected(device_id: int):
    active_controller = device_id
    controller_type = Input.get_joy_name(device_id)
    
    print("Controller connected: ", controller_type)
    
    # Auto-detect controller type and load appropriate mapping
    _detect_and_load_controller_mapping()
    
    # Switch UI prompts to controller buttons
    _update_ui_button_prompts("controller")
    
    controller_connected.emit(device_id, controller_type)

func _detect_and_load_controller_mapping():
    var controller_name = controller_type.to_lower()
    
    if "xbox" in controller_name or "microsoft" in controller_name:
        _load_xbox_mapping()
    elif "playstation" in controller_name or "dualshock" in controller_name or "dualsense" in controller_name:
        _load_playstation_mapping()  
    elif "nintendo" in controller_name or "switch" in controller_name:
        _load_nintendo_mapping()
    else:
        # Generic controller mapping
        _load_generic_mapping()

func _load_xbox_mapping():
    input_mapping = {
        "move": "left_stick",
        "attack": "x_button",
        "special": "y_button", 
        "dash": "a_button",
        "interact": "b_button",
        "weapon_switch": "rb_button",
        "keepsake": "lb_button",
        "pause": "start_button",
        "codex": "back_button",
        "camera": "right_stick"
    }
    
    # Xbox-specific vibration patterns
    _setup_xbox_vibration_patterns()

func _load_playstation_mapping():
    input_mapping = {
        "move": "left_stick",
        "attack": "square_button",
        "special": "triangle_button",
        "dash": "x_button", 
        "interact": "circle_button",
        "weapon_switch": "r1_button",
        "keepsake": "l1_button",
        "pause": "options_button",
        "codex": "touchpad_button",
        "camera": "right_stick"
    }
    
    # PlayStation haptic feedback (DualSense)
    _setup_playstation_haptics()

func _setup_xbox_vibration_patterns():
    var vibration_patterns = {
        "hit_taken": {"weak": 0.7, "strong": 0.3, "duration": 0.1},
        "critical_hit": {"weak": 0.3, "strong": 0.8, "duration": 0.15},
        "death": {"weak": 1.0, "strong": 1.0, "duration": 0.5},
        "boss_attack": {"weak": 0.5, "strong": 0.9, "duration": 0.2}
    }
    
    GameManager.vibration_patterns = vibration_patterns

func handle_controller_input():
    if active_controller == -1:
        return
    
    # Movement
    var left_stick = Vector2(
        Input.get_joy_axis(active_controller, JOY_AXIS_LEFT_X),
        Input.get_joy_axis(active_controller, JOY_AXIS_LEFT_Y)
    )
    
    if left_stick.length() > 0.1:  # Deadzone
        GameManager.set_movement_input(left_stick)
    
    # Button inputs
    _handle_button_inputs()
    
    # Trigger inputs (for variable intensity actions)
    _handle_trigger_inputs()

func _handle_button_inputs():
    # Attack
    if Input.is_joy_button_pressed(active_controller, JOY_BUTTON_X):  # Xbox X
        GameManager.trigger_attack()
    
    # Special attack
    if Input.is_joy_button_pressed(active_controller, JOY_BUTTON_Y):  # Xbox Y
        GameManager.trigger_special_attack()
    
    # Dash  
    if Input.is_joy_button_pressed(active_controller, JOY_BUTTON_A):  # Xbox A
        GameManager.trigger_dash()
    
    # Interact
    if Input.is_joy_button_pressed(active_controller, JOY_BUTTON_B):  # Xbox B
        GameManager.trigger_interaction()

func _handle_trigger_inputs():
    # Variable intensity attacks using triggers
    var right_trigger = Input.get_joy_axis(active_controller, JOY_AXIS_TRIGGER_RIGHT)
    
    if right_trigger > 0.1:
        # Charge attack based on trigger pressure
        GameManager.charge_attack(right_trigger)
    
    var left_trigger = Input.get_joy_axis(active_controller, JOY_AXIS_TRIGGER_LEFT)
    
    if left_trigger > 0.1:
        # Defensive action (block/parry) based on trigger pressure
        GameManager.defensive_action(left_trigger)

func trigger_controller_vibration(pattern_name: String):
    if not vibration_enabled or active_controller == -1:
        return
    
    if not pattern_name in GameManager.vibration_patterns:
        return
    
    var pattern = GameManager.vibration_patterns[pattern_name]
    
    Input.start_joy_vibration(
        active_controller,
        pattern.weak,
        pattern.strong,
        pattern.duration
    )

func _update_ui_button_prompts(input_method: String):
    # Update all UI elements to show appropriate button prompts
    var ui_elements = get_tree().get_nodes_in_group("ui_elements")
    
    for element in ui_elements:
        if element.has_method("update_button_prompts"):
            element.update_button_prompts(input_method, input_mapping)
    
    input_method_changed.emit(input_method)
```

---

## 📖 **SPRINT 22: NARRATIVE COMPLETE**

### **🎯 Objetivos Principais**
1. **Full Dialogue System:** Diálogos completos para todos os NPCs
2. **Lore Integration:** Egyptian mythology integrada em cada elemento
3. **Character Development:** Arcs narrativos completos para personagens
4. **World Building:** Detalhamento completo do Duat e mitologia
5. **Voice Acting Prep:** Scripts finalizados para eventual dublagem
6. **Multiple Endings Setup:** 4 endings distintos baseados em choices

### **🏗️ Complete Narrative System**

#### **A. Full Dialogue Database**
```gdscript
# NarrativeDatabase.gd - Database completo de diálogos e lore
extends Resource
class_name NarrativeDatabase

@export var character_dialogues: Dictionary = {}
@export var lore_entries: Dictionary = {}
@export var story_branches: Dictionary = {}
@export var ending_conditions: Dictionary = {}

func _init():
    _initialize_character_dialogues()
    _initialize_lore_database()
    _setup_story_branches()
    _define_ending_conditions()

func _initialize_character_dialogues():
    # Khenti-Ka-Nefer (Protagonist) - Internal monologue
    character_dialogues["Khenti"] = {
        "intro": {
            "first_death": "Então... é assim que a morte se sente. Fria. Vazia. Mas por que ainda estou consciente?",
            "understanding_duat": "O Duat... o submundo dos meus antepassados. Preciso encontrar um caminho de volta.",
            "discovering_powers": "Esta força que flui através de mim... é a mesma que os deuses possuem?"
        },
        "progression": {
            "first_weapon": "A Was Scepter... símbolo da autoridade divina. Sinto seu poder resonar com minha linhagem real.",
            "first_boon": "Os deuses... eles me concedem seus dons. Mas por quê? O que esperam de mim?",
            "first_boss_encounter": "Khaemwaset... meu próprio irmão. Como chegamos a este ponto?"
        },
        "moral_reflections": {
            "vengeful_choice": "A vingança queima em meu peito. Ele pagará pelo que fez comigo e com Nefertari.",
            "just_choice": "Não... não posso me tornar como aqueles que me traíram. Justiça, não vingança.",
            "conflicted": "O que é certo? O que meus antepassados fariam? O que Nefertari esperaria de mim?"
        }
    }
    
    # Anubis - Judge of the Dead
    character_dialogues["Anubis"] = {
        "introduction": {
            "first_meeting": "Khenti-Ka-Nefer... príncipe assassinado, coração pesado pela traição. Você não deveria estar aqui.",
            "explaining_duat": "Este é o Duat, jovem príncipe. Reino dos mortos, domínio de Osiris... e meu local de trabalho.",
            "offering_guidance": "Posso ensinar-lhe sobre justiça verdadeira, se estiver disposto a ouvir."
        },
        "relationship_progression": {
            "level_1": "Vejo potencial em você, Khenti. Mas o caminho da justiça é árduo.",
            "level_3": "Suas ações começam a refletir sabedoria. Ma'at sorri com suas escolhas.",
            "level_5": "Você compreende agora. Justiça não é apenas punir o mal, mas proteger o bem.",
            "level_8": "Poucos mortais alcançam tal entendimento. Você honra sua linhagem real.",
            "level_10": "Khenti... você transcendeu sua mortalidade. Você se tornou um verdadeiro guardião da justiça."
        },
        "moral_responses": {
            "heavy_heart": "Sua sede de vingança escurece seu ka, príncipe. Cuidado para não se perder nas trevas.",
            "balanced_heart": "Vejo conflito em seu espírito. Isto é natural - a justiça perfeita é difícil de alcançar.",
            "light_heart": "Seu coração brilha com justiça verdadeira. Os ancestrais se orgulham de você."
        },
        "story_revelations": {
            "khaemwaset_truth": "Seu irmão... há mais nessa história do que você sabe. A verdade nem sempre é o que parece.",
            "divine_conspiracy": "Forças maiores movem as peças neste jogo, Khenti. Nem todos os deuses desejam seu sucesso.",
            "final_judgment": "O momento se aproxima. Sua jornada pelo Duat terminará, mas sua verdadeira prova apenas começará."
        }
    }
    
    # Nefertari - Beloved Echo
    character_dialogues["Nefertari"] = {
        "romantic_progression": {
            "level_1": "Khenti... mesmo na morte, meu coração se aquece ao vê-lo. Você é minha luz na escuridão.",
            "level_3": "Nossa conexão transcende a morte. Sinto sua dor, sua determinação... sua amor.",
            "level_5": "Lembra-se dos jardins do palácio? Das promessas que fizemos sob as estrelas?",
            "level_7": "Você luta não apenas por vingança, mas por nosso futuro. Por um amor que nem a morte pode destruir.",
            "level_10": "Meu amado... nossa conexão é eterna. Juntos, superaremos qualquer desafio."
        },
        "moral_guidance": {
            "vengeful_path": "Khenti, a vingança está mudando você. Não é assim que me lembro do homem que amei.",
            "just_path": "Vejo o príncipe justo que conheci... aquele por quem me apaixonei.",
            "redemption_possible": "Todos merecem uma chance de redenção, meu amor. Até mesmo seu irmão."
        },
        "story_memories": {
            "childhood_with_khaemwaset": "Lembro-me quando vocês eram crianças... inseparáveis. O que aconteceu?",
            "royal_duties": "Você levava seus deveres como príncipe tão seriamente. O Egito precisa de você.",
            "final_separation": "Nossa última noite juntos... se soubéssemos que seria a última..."
        }
    }
    
    # Continue for all other NPCs...
    _initialize_remaining_character_dialogues()

func _initialize_lore_database():
    lore_entries["egyptian_mythology"] = {
        "duat_geography": {
            "title": "Geografia do Duat",
            "content": "O Duat é dividido em doze regiões, cada uma correspondendo às horas da noite. Khenti navega através das três primeiras: Areias do Duat (primeira hora), Rio de Fogo (sexta hora), e Salão do Julgamento (décima segunda hora).",
            "unlock_condition": "explore_all_biomes"
        },
        "weighing_of_heart": {
            "title": "A Pesagem do Coração",
            "content": "Após a morte, o coração do falecido é pesado contra a pena de Ma'at. Corações pesados demais pela culpa são devorados por Ammit. Mas Khenti vive este processo repetidamente, cada escolha alterando o peso de seu ka.",
            "unlock_condition": "encounter_ammit"
        },
        "royal_lineage": {
            "title": "Linhagem Real Egípcia",
            "content": "Khenti-Ka-Nefer descende da linha de faraós que remonta a Narmer. Seu nome significa 'O Que Vai à Frente é Perfeito', uma profecia sobre seu destino de unir justiça e poder.",
            "unlock_condition": "unlock_royal_heritage_upgrades"
        }
    }
    
    lore_entries["characters_backstory"] = {
        "khaemwaset_tragedy": {
            "title": "A Tragédia de Khaemwaset",
            "content": "Khaemwaset, irmão mais velho de Khenti, foi manipulado pelos sacerdotes corrompidos de Set. Ameaçaram não apenas Nefertari, mas todo o reino se ele não eliminasse o irmão mais carismático.",
            "unlock_condition": "complete_khaemwaset_boss_encounter"
        },
        "nefertari_love": {
            "title": "O Amor de Nefertari",
            "content": "Nefertari, cujo nome significa 'A Mais Bela das Belas', não era apenas consorte real, mas conselheira política e sacerdotisa de Ísis. Sua conexão com Khenti transcende o físico, sendo uma verdadeira união de almas.",
            "unlock_condition": "max_relationship_nefertari"
        }
    }

func _setup_story_branches():
    story_branches["main_narrative"] = {
        "discovery_phase": {
            "description": "Khenti descobre suas habilidades e a natureza do Duat",
            "key_events": ["first_death", "first_boon", "hub_discovery"],
            "branching_points": ["first_moral_choice"]
        },
        "revelation_phase": {
            "description": "Verdades sobre o assassinato são reveladas",
            "key_events": ["khaemwaset_encounter", "divine_conspiracy_hint"],
            "branching_points": ["khaemwaset_fate_choice", "divine_alliance_choice"]
        },
        "judgment_phase": {
            "description": "Julgamento final e resolução do conflito",
            "key_events": ["ammit_encounter", "final_choice"],
            "branching_points": ["ending_determination"]
        }
    }
    
    story_branches["relationship_arcs"] = {
        "anubis_mentor": {
            "progression": ["distrust", "respect", "understanding", "alliance", "transcendence"],
            "key_unlocks": ["justice_wisdom", "divine_authority", "judgment_power"]
        },
        "nefertari_love": {
            "progression": ["separation_grief", "connection_restored", "eternal_bond", "unified_purpose"],
            "key_unlocks": ["love_strength", "emotional_healing", "resurrection_possibility"]
        }
    }

func _define_ending_conditions():
    ending_conditions["justice_ending"] = {
        "name": "O Caminho da Justiça",
        "requirements": {
            "moral_alignment": {"min": 0.3, "max": 1.0},
            "khaemwaset_choice": "forgiveness_or_justice",
            "divine_trial_outcomes": "passed_with_wisdom",
            "relationship_anubis": {"min": 7}
        },
        "description": "Khenti retorna como guardião divino da justiça, protegendo o Egito das sombras.",
        "epilogue": "Khenti torna-se uma figura lendária, aparecendo em momentos cruciais para guiar futuros líderes do Egito."
    }
    
    ending_conditions["love_ending"] = {
        "name": "O Poder do Amor Eterno",
        "requirements": {
            "moral_alignment": {"min": 0.1, "max": 1.0},
            "nefertari_relationship": {"min": 8},
            "sacrifice_choice": "choose_love_over_power",
            "resurrection_ritual": "completed"
        },
        "description": "O amor de Khenti e Nefertari transcende a morte, permitindo que ambos retornem à vida.",
        "epilogue": "Khenti e Nefertari governam o Egito juntos, inaugurando uma era dourada de paz e prosperidade."
    }
    
    ending_conditions["vengeance_ending"] = {
        "name": "A Coroa das Trevas",
        "requirements": {
            "moral_alignment": {"min": -1.0, "max": -0.3},
            "khaemwaset_choice": "execution_or_domination",
            "dark_power_accepted": true,
            "divine_authority_rejected": true
        },
        "description": "Khenti retorna como um faraó sombrio, governando através do medo e poder.",
        "epilogue": "O Egito prospera materialmente sob Khenti, mas a um custo moral terrível. Sua dinastia se torna lenda sinistra."
    }
    
    ending_conditions["transcendence_ending"] = {
        "name": "Ascensão Divina",
        "requirements": {
            "moral_alignment": {"min": 0.7, "max": 1.0},
            "all_relationships": {"min": 6},
            "divine_trials": "all_passed_perfectly",
            "ultimate_sacrifice": "divine_ascension_chosen"
        },
        "description": "Khenti transcende a mortalidade, tornando-se uma divindade menor do panteão egípcio.",
        "epilogue": "Khenti junta-se ao panteão como deus da Justiça Restaurada, sendo invocado por aqueles que buscam redenção."
    }
```

#### **B. Advanced Dialogue System**
```gdscript
# AdvancedDialogueSystem.gd - Sistema sofisticado de diálogos
extends Node
class_name AdvancedDialogueSystem

var current_dialogue: DialogueSequence = null
var dialogue_history: Array[DialogueEntry] = []
var character_voices: Dictionary = {}
var subtitle_display: SubtitleDisplay = null

signal dialogue_sequence_started(character_name: String)
signal dialogue_choice_made(choice_id: String, choice_text: String)
signal dialogue_sequence_completed(character_name: String, outcome: String)

class DialogueSequence:
    var character_name: String
    var sequence_id: String
    var nodes: Array[DialogueNode] = []
    var current_node_index: int = 0
    var context: Dictionary = {}
    var voice_actor: String = ""

class DialogueNode:
    var node_id: String
    var speaker: String
    var text: String
    var audio_file: String
    var emotion: String
    var choices: Array[DialogueChoice] = []
    var conditions: Array[String] = []
    var effects: Array[Dictionary] = []
    var camera_direction: String = ""
    var animation_trigger: String = ""

class DialogueChoice:
    var choice_id: String
    var choice_text: String
    var requirements: Array[String] = []
    var consequences: Array[Dictionary] = []
    var next_node_id: String = ""
    var moral_weight: float = 0.0

func _ready():
    _setup_voice_system()
    _initialize_subtitle_display()
    _connect_to_game_systems()

func _setup_voice_system():
    # Voice actor assignments for future dubbing
    character_voices["Khenti"] = {
        "voice_actor": "TBD_Brazilian_Male_Lead",
        "voice_characteristics": "Noble, conflicted, determined",
        "age_range": "25-35",
        "accent": "Educated Brazilian Portuguese"
    }
    
    character_voices["Anubis"] = {
        "voice_actor": "TBD_Brazilian_Male_Authority",
        "voice_characteristics": "Ancient wisdom, divine authority, patient",
        "age_range": "40-60 (sounds)",
        "accent": "Neutral Brazilian Portuguese with gravitas"
    }
    
    character_voices["Nefertari"] = {
        "voice_actor": "TBD_Brazilian_Female_Lead",
        "voice_characteristics": "Loving, wise, ethereal",
        "age_range": "22-32",
        "accent": "Refined Brazilian Portuguese"
    }

func start_dialogue_sequence(character_name: String, sequence_id: String, context: Dictionary = {}):
    # Load dialogue sequence from database
    var sequence_data = NarrativeDatabase.get_dialogue_sequence(character_name, sequence_id)
    
    if not sequence_data:
        push_error("Dialogue sequence not found: " + character_name + "." + sequence_id)
        return
    
    # Build contextual dialogue
    current_dialogue = _build_contextual_sequence(sequence_data, context)
    
    dialogue_sequence_started.emit(character_name)
    
    # Setup dialogue UI
    _setup_dialogue_ui()
    
    # Start first node
    _process_dialogue_node()

func _build_contextual_sequence(base_sequence: Dictionary, context: Dictionary) -> DialogueSequence:
    var sequence = DialogueSequence.new()
    sequence.character_name = base_sequence.character_name
    sequence.sequence_id = base_sequence.sequence_id
    sequence.context = context
    
    # Filter nodes based on context and conditions
    for node_data in base_sequence.nodes:
        if _evaluate_node_conditions(node_data.conditions, context):
            var node = _create_dialogue_node(node_data)
            sequence.nodes.append(node)
    
    # Contextual modifications to dialogue text
    _apply_contextual_modifications(sequence, context)
    
    return sequence

func _apply_contextual_modifications(sequence: DialogueSequence, context: Dictionary):
    # Modify dialogue based on context
    var moral_alignment = context.get("moral_alignment", 0.0)
    var relationship_level = context.get("relationship_level", 0)
    var story_progress = context.get("story_progress", {})
    
    for node in sequence.nodes:
        # Adjust tone based on moral alignment
        if moral_alignment < -0.3:
            node.text = _apply_tone_modification(node.text, "disappointed_or_concerned")
        elif moral_alignment > 0.3:
            node.text = _apply_tone_modification(node.text, "proud_or_approving")
        
        # Add relationship-specific content
        if relationship_level >= 5:
            node.text = _add_intimate_elements(node.text, sequence.character_name)
        
        # Reference recent events
        node.text = _add_story_references(node.text, story_progress)

func _process_dialogue_node():
    if not current_dialogue or current_dialogue.current_node_index >= current_dialogue.nodes.size():
        _end_dialogue_sequence()
        return
    
    var current_node = current_dialogue.nodes[current_dialogue.current_node_index]
    
    # Apply visual effects
    if current_node.camera_direction != "":
        _adjust_dialogue_camera(current_node.camera_direction)
    
    if current_node.animation_trigger != "":
        _trigger_character_animation(current_node.animation_trigger)
    
    # Display text and play audio
    _display_dialogue_text(current_node)
    
    if current_node.audio_file != "":
        _play_dialogue_audio(current_node.audio_file)
    
    # Setup choices or continue
    if current_node.choices.size() > 0:
        _setup_dialogue_choices(current_node.choices)
    else:
        # Auto-continue after delay
        await get_tree().create_timer(2.0).timeout
        _advance_to_next_node()

func _setup_dialogue_choices(choices: Array[DialogueChoice]):
    var dialogue_ui = get_tree().get_first_node_in_group("dialogue_ui")
    
    var valid_choices: Array[DialogueChoice] = []
    
    # Filter choices based on requirements
    for choice in choices:
        if _evaluate_choice_requirements(choice.requirements):
            valid_choices.append(choice)
    
    # Display available choices
    dialogue_ui.display_choices(valid_choices)
    dialogue_ui.choice_selected.connect(_on_dialogue_choice_made)

func _on_dialogue_choice_made(choice: DialogueChoice):
    dialogue_choice_made.emit(choice.choice_id, choice.choice_text)
    
    # Apply choice consequences
    _apply_choice_consequences(choice.consequences)
    
    # Update moral alignment
    if choice.moral_weight != 0.0:
        GameManager.modify_moral_alignment(choice.moral_weight)
    
    # Move to next node or end sequence
    if choice.next_node_id != "":
        _jump_to_node(choice.next_node_id)
    else:
        _advance_to_next_node()

func _apply_choice_consequences(consequences: Array[Dictionary]):
    for consequence in consequences:
        match consequence.type:
            "relationship_change":
                RelationshipTracker.modify_relationship(
                    consequence.character,
                    consequence.amount
                )
            "unlock_content":
                GameManager.unlock_content(consequence.content_id)
            "grant_boon":
                GameManager.grant_special_boon(
                    consequence.boon_id,
                    consequence.source
                )
            "story_flag":
                GameManager.set_story_flag(
                    consequence.flag_name,
                    consequence.flag_value
                )
            "start_quest":
                QuestManager.start_quest(consequence.quest_id)

func _display_dialogue_text(node: DialogueNode):
    var dialogue_ui = get_tree().get_first_node_in_group("dialogue_ui")
    
    # Type writer effect for text
    dialogue_ui.display_text_with_typewriter(
        node.speaker,
        node.text,
        _get_typing_speed_for_emotion(node.emotion)
    )
    
    # Show subtitles if enabled
    if subtitle_display and AccessibilityManager.subtitle_enabled:
        subtitle_display.show_subtitle(node.text, node.speaker, 3.0)

func _get_typing_speed_for_emotion(emotion: String) -> float:
    match emotion:
        "angry", "urgent":
            return 0.03  # Fast typing
        "sad", "contemplative":
            return 0.08  # Slow typing
        "excited", "surprised":
            return 0.02  # Very fast typing
        _:
            return 0.05  # Normal typing speed
```

---

## 👑 **SPRINT 23: FINAL BOSS & ENDINGS**

### **🎯 Objetivos Principais**
1. **Osiris Final Boss:** Boss fight épico multi-fase como clímax definitivo
2. **4 Distinct Endings:** Endings únicos baseados em player choices
3. **Ending Cinematics:** Sequências finais polidas e emocionais
4. **Post-Game Content:** New Game+ com conteúdo adicional
5. **Achievement System:** Conquistas que recompensam diferentes playstyles
6. **Credits Sequence:** Créditos integrados com música e arte finais

### **🏗️ Osiris Final Boss System**

#### **A. Osiris Boss Implementation**
```gdscript
# OsirisBoss.gd - Boss final épico com múltiplas fases
extends Boss
class_name OsirisBoss

enum OsirisPhase {
    JUDGE_OF_THE_DEAD,    # Phase 1: Traditional judgment
    KING_OF_THE_AFTERLIFE, # Phase 2: Royal power unleashed  
    DIVINE_RESURRECTION,   # Phase 3: Death and rebirth cycle
    ULTIMATE_TRUTH,       # Phase 4: Reality-bending powers
    FINAL_JUDGMENT        # Phase 5: Player's moral reckoning
}

var current_phase: OsirisPhase = OsirisPhase.JUDGE_OF_THE_DEAD
var player_moral_weight_final: float = 0.0
var ending_path_determined: String = ""
var divine_allies_present: Array[String] = []

@export var judgment_attacks: Array[AttackPattern] = []
@export var royal_attacks: Array[AttackPattern] = []
@export var resurrection_mechanics: Array[ResurrectionCycle] = []
@export var truth_manifestations: Array[TruthAttack] = []
@export var final_judgment_scenarios: Array[JudgmentScenario] = []

signal ending_path_revealed(ending_type: String)
signal divine_intervention(ally_name: String)
signal final_choice_presented(choice_data: Dictionary)

func _ready():
    super._ready()
    boss_name = "Osiris, Senhor dos Mortos"
    base_health = 5000.0  # Ultimate boss
    
    # Prepare final boss context
    player_moral_weight_final = GameManager.get_moral_alignment()
    divine_allies_present = _determine_divine_allies()
    
    _setup_osiris_phases()
    _prepare_ending_determination()

func _setup_osiris_phases():
    # Osiris adapts completely to player's journey
    match _categorize_player_journey():
        "path_of_justice":
            _setup_justice_focused_encounter()
        "path_of_love":
            _setup_love_focused_encounter()
        "path_of_vengeance":
            _setup_vengeance_focused_encounter()
        "path_of_transcendence":
            _setup_transcendence_encounter()

func _categorize_player_journey() -> String:
    var moral_score = player_moral_weight_final
    var relationships = RelationshipTracker.get_all_relationship_levels()
    var story_choices = NarrativePersistence.get_major_choices()
    
    # Complex algorithm to determine primary path
    if moral_score > 0.7 and relationships.get("Anubis", 0) >= 8:
        return "path_of_transcendence"
    elif relationships.get("Nefertari", 0) >= 8 and "love_priority" in story_choices:
        return "path_of_love"
    elif moral_score < -0.3:
        return "path_of_vengeance"
    else:
        return "path_of_justice"

func _setup_justice_focused_encounter():
    # Osiris tests player's understanding of true justice
    judgment_attacks = _load_justice_attack_patterns()
    
    # Phase-specific mechanics
    phases_data = {
        OsirisPhase.JUDGE_OF_THE_DEAD: {
            "test_type": "moral_consistency",
            "mechanics": ["truth_detection", "hypocrisy_punishment"],
            "dialogue_theme": "justice_philosophy"
        },
        OsirisPhase.FINAL_JUDGMENT: {
            "test_type": "ultimate_justice_choice",
            "choice": "personal_justice_vs_greater_good",
            "consequences": "determines_justice_ending_variant"
        }
    }

func execute_attack():
    match current_phase:
        OsirisPhase.JUDGE_OF_THE_DEAD:
            _execute_judgment_phase()
        OsirisPhase.KING_OF_THE_AFTERLIFE:
            _execute_royal_phase()
        OsirisPhase.DIVINE_RESURRECTION:
            _execute_resurrection_phase()
        OsirisPhase.ULTIMATE_TRUTH:
            _execute_truth_phase()
        OsirisPhase.FINAL_JUDGMENT:
            _execute_final_judgment_phase()

func _execute_judgment_phase():
    # Osiris summons shades of player's past victims/allies
    var moral_echoes = _summon_moral_echoes()
    
    for echo in moral_echoes:
        # Each echo represents a major moral choice
        echo.confront_player(_get_echo_accusation(echo))
    
    # Player must defend their choices while fighting
    _start_moral_defense_mechanic()

func _execute_final_judgment_phase():
    # The ultimate choice that determines ending
    _pause_combat_for_final_choice()
    
    var final_choice_data = _build_final_choice()
    final_choice_presented.emit(final_choice_data)
    
    # Show final choice UI
    var final_choice_ui = FinalChoiceUI.new()
    add_child(final_choice_ui)
    final_choice_ui.setup_ultimate_choice(final_choice_data)
    final_choice_ui.choice_made.connect(_handle_ultimate_choice)

func _build_final_choice() -> Dictionary:
    var choice_data = {
        "scenario": "Osiris oferece escolha final sobre destino de Khenti",
        "context": {
            "moral_weight": player_moral_weight_final,
            "relationships": RelationshipTracker.get_all_relationship_levels(),
            "story_progress": GameManager.get_story_completion(),
            "divine_allies": divine_allies_present
        }
    }
    
    # Different choices available based on player's journey
    choice_data.options = _generate_contextual_final_choices()
    
    return choice_data

func _generate_contextual_final_choices() -> Array[Dictionary]:
    var choices = []
    
    # Always available: Return to life with mission
    choices.append({
        "id": "return_with_mission",
        "text": "Retornar à vida para proteger o Egito",
        "description": "Aceitar responsabilidade como guardião mortal",
        "ending": "justice_ending",
        "requirements": []
    })
    
    # Available if high relationship with Nefertari
    if RelationshipTracker.get_level("Nefertari") >= 8:
        choices.append({
            "id": "resurrect_together",
            "text": "Encontrar forma de retornar com Nefertari",
            "description": "Sacrificar poder divino pelo amor verdadeiro",
            "ending": "love_ending",
            "requirements": ["nefertari_max_relationship", "love_priority_choices"]
        })
    
    # Available if negative moral alignment
    if player_moral_weight_final < -0.3:
        choices.append({
            "id": "claim_divine_throne",
            "text": "Desafiar Osiris e tomar o trono do submundo",
            "description": "Usar poder adquirido para governar vida e morte",
            "ending": "vengeance_ending",
            "requirements": ["dark_power_accumulated"]
        })
    
    # Available if transcendent path
    if player_moral_weight_final > 0.7 and RelationshipTracker.average_level() >= 6:
        choices.append({
            "id": "divine_ascension",
            "text": "Ascender como divindade da justiça restaurada",
            "description": "Transcender mortalidade para servir equilíbrio cósmico",
            "ending": "transcendence_ending",
            "requirements": ["perfect_moral_score", "all_relationships_high"]
        })
    
    return choices

func _handle_ultimate_choice(choice_id: String, choice_data: Dictionary):
    ending_path_determined = choice_data.ending
    ending_path_revealed.emit(choice_data.ending)
    
    # Immediate consequences of choice
    match choice_id:
        "return_with_mission":
            _execute_justice_ending_sequence()
        "resurrect_together":
            _execute_love_ending_sequence()
        "claim_divine_throne":
            _execute_vengeance_ending_sequence()
        "divine_ascension":
            _execute_transcendence_ending_sequence()

func _execute_justice_ending_sequence():
    dialogue_system.play_dialogue("osiris_justice_ending_approval")
    
    # Osiris grants blessing for return
    var justice_blessings = [
        "divine_authority_blessing",
        "protection_of_innocents",
        "wisdom_of_ages",
        "connection_to_divine_will"
    ]
    
    for blessing in justice_blessings:
        GameManager.grant_permanent_blessing(blessing)
    
    # Transition to justice ending cinematic
    _start_ending_cinematic("justice")

func _execute_love_ending_sequence():
    # Nefertari appears as divine intervention
    dialogue_system.play_dialogue("nefertari_love_ending_intervention")
    
    # Complex resurrection ritual
    var resurrection_ui = ResurrectionRitualUI.new()
    add_child(resurrection_ui)
    
    resurrection_ui.setup_love_resurrection({
        "khenti_sacrifice": "divine_power_for_mortality",
        "nefertari_sacrifice": "eternal_rest_for_life",
        "combined_power": "transcendent_love_energy",
        "osiris_blessing": "granted_reluctantly_but_respectfully"
    })
    
    resurrection_ui.ritual_completed.connect(_complete_love_ending)

func _complete_love_ending():
    # Both Khenti and Nefertari return to life
    dialogue_system.play_dialogue("love_ending_reunion")
    _start_ending_cinematic("love")
```

#### **B. Four Distinct Endings System**
```gdscript
# EndingManager.gd - Sistema completo de endings
extends Node
class_name EndingManager

var ending_data: Dictionary = {}
var current_ending: String = ""
var ending_cinematics: Dictionary = {}
var post_ending_unlocks: Dictionary = {}

signal ending_started(ending_type: String)
signal ending_completed(ending_type: String, unlocks: Array)

func _ready():
    _initialize_ending_data()
    _setup_ending_cinematics()
    _define_post_ending_content()

func _initialize_ending_data():
    ending_data["justice"] = {
        "name": "O Caminho da Justiça",
        "subtitle": "Guardião Eterno do Equilíbrio",
        "description": "Khenti retorna à vida como agente divino da justiça, protegendo o Egito das sombras por gerações.",
        "key_moments": [
            "osiris_blessing_ceremony",
            "return_to_mortal_world",
            "first_act_of_divine_justice",
            "recognition_as_legend"
        ],
        "epilogue_scenes": [
            "khenti_as_shadowy_protector",
            "future_pharaohs_seeking_guidance",
            "eternal_vigil_over_egypt"
        ],
        "unlocks": ["justice_new_game_plus", "anubis_mentor_mode", "divine_weapons"],
        "achievement": "achievement_perfect_justice"
    }
    
    ending_data["love"] = {
        "name": "O Poder do Amor Eterno",
        "subtitle": "Juntos Contra a Eternidade",
        "description": "Khenti e Nefertari transcendem a morte através do amor verdadeiro, retornando juntos à vida para governar em harmonia.",
        "key_moments": [
            "resurrection_ritual_sacrifice",
            "reunion_in_mortal_world",
            "coronation_as_divine_couple",
            "golden_age_establishment"
        ],
        "epilogue_scenes": [
            "khenti_nefertari_ruling_together",
            "egypt_golden_age_prosperity",
            "love_inspiring_future_generations"
        ],
        "unlocks": ["love_new_game_plus", "nefertari_co_op_mode", "harmony_weapons"],
        "achievement": "achievement_eternal_love"
    }
    
    ending_data["vengeance"] = {
        "name": "A Coroa das Trevas",
        "subtitle": "Poder Através do Medo",
        "description": "Khenti abraça o poder sombrio, retornando como um faraó temido que governa através da força absoluta.",
        "key_moments": [
            "osiris_throne_usurpation",
            "dark_powers_manifestation",
            "egypt_conquest_through_fear",
            "dark_dynasty_establishment"
        ],
        "epilogue_scenes": [
            "khenti_as_dark_pharaoh",
            "egypt_prosperity_through_oppression",
            "legacy_of_feared_ruler"
        ],
        "unlocks": ["vengeance_new_game_plus", "dark_powers_mode", "cursed_weapons"],
        "achievement": "achievement_dark_pharaoh"
    }
    
    ending_data["transcendence"] = {
        "name": "Ascensão Divina",
        "subtitle": "Além da Mortalidade",
        "description": "Khenti transcende completamente a mortalidade, ascendendo como divindade menor do panteão egípcio.",
        "key_moments": [
            "divine_transformation_ritual",
            "pantheon_acceptance_ceremony",
            "first_divine_intervention",
            "cosmic_balance_restoration"
        ],
        "epilogue_scenes": [
            "khenti_as_minor_deity",
            "worship_temples_establishment",
            "guidance_of_future_heroes"
        ],
        "unlocks": ["transcendence_new_game_plus", "divine_powers_mode", "celestial_weapons"],
        "achievement": "achievement_divine_ascension"
    }

func trigger_ending(ending_type: String):
    current_ending = ending_type
    ending_started.emit(ending_type)
    
    # Save ending achievement
    GameManager.unlock_achievement(ending_data[ending_type].achievement)
    
    # Start cinematic sequence
    _play_ending_cinematic(ending_type)

func _play_ending_cinematic(ending_type: String):
    var cinematic_sequence = ending_cinematics[ending_type]
    
    # Fade to black transition
    SceneManager.fade_to_black(1.0)
    await SceneManager.fade_completed
    
    # Load ending scene
    SceneManager.change_scene("res://cinematics/endings/" + ending_type + "_ending.tscn")
    await SceneManager.scene_loaded
    
    # Play ending sequence
    var ending_scene = get_tree().get_first_node_in_group("ending_scene")
    ending_scene.play_ending_sequence(cinematic_sequence)
    ending_scene.sequence_completed.connect(_on_ending_cinematic_completed)

func _on_ending_cinematic_completed():
    # Show ending epilogue
    _show_ending_epilogue()

func _show_ending_epilogue():
    var epilogue_data = ending_data[current_ending]
    
    # Create epilogue UI
    var epilogue_ui = EpilogueUI.new()
    add_child(epilogue_ui)
    
    epilogue_ui.setup_epilogue({
        "ending_name": epilogue_data.name,
        "subtitle": epilogue_data.subtitle,
        "description": epilogue_data.description,
        "epilogue_scenes": epilogue_data.epilogue_scenes,
        "unlocked_content": epilogue_data.unlocks
    })
    
    epilogue_ui.epilogue_completed.connect(_show_credits_sequence)

func _show_credits_sequence():
    # Transition to credits
    var credits_scene = preload("res://ui/CreditsSequence.tscn").instantiate()
    get_tree().root.add_child(credits_scene)
    
    credits_scene.setup_credits({
        "ending_achieved": current_ending,
        "player_stats": GameManager.get_final_stats(),
        "completion_percentage": GameManager.get_completion_percentage()
    })
    
    credits_scene.credits_completed.connect(_return_to_main_menu_with_unlocks)

func _return_to_main_menu_with_unlocks():
    # Apply post-ending unlocks
    var unlocks = ending_data[current_ending].unlocks
    
    for unlock in unlocks:
        GameManager.unlock_content(unlock)
    
    ending_completed.emit(current_ending, unlocks)
    
    # Return to main menu
    SceneManager.change_scene("res://ui/MainMenu.tscn")
    
    # Show unlock notification
    var unlock_ui = UnlockNotificationUI.new()
    unlock_ui.show_ending_unlocks(current_ending, unlocks)
```

#### **C. New Game Plus System**
```gdscript
# NewGamePlusManager.gd - Sistema de New Game Plus
extends Node
class_name NewGamePlusManager

var ng_plus_level: int = 0
var carried_over_content: Dictionary = {}
var ending_bonuses: Dictionary = {}
var unlock_conditions_met: Dictionary = {}

func _ready():
    _initialize_ng_plus_benefits()
    _load_ng_plus_progress()

func _initialize_ng_plus_benefits():
    # Different NG+ benefits based on ending achieved
    ending_bonuses["justice"] = {
        "starting_boons": ["divine_authority", "protection_blessing"],
        "unique_dialogue": "anubis_recognizes_champion",
        "special_rooms": ["divine_tribunal_rooms"],
        "weapon_aspects": ["scales_of_justice_aspects"],
        "story_variations": "justice_path_remembered"
    }
    
    ending_bonuses["love"] = {
        "starting_boons": ["nefertari_blessing", "eternal_bond"],
        "unique_dialogue": "nefertari_deeper_connection",
        "special_rooms": ["memory_shrine_rooms"],
        "weapon_aspects": ["unity_aspects"],
        "story_variations": "love_transcendent_memories"
    }
    
    ending_bonuses["vengeance"] = {
        "starting_boons": ["dark_authority", "fear_aura"],
        "unique_dialogue": "npcs_remember_dark_rule",
        "special_rooms": ["shadow_throne_rooms"],
        "weapon_aspects": ["tyrant_aspects"],
        "story_variations": "darkness_acknowledged"
    }
    
    ending_bonuses["transcendence"] = {
        "starting_boons": ["divine_insight", "cosmic_awareness"],
        "unique_dialogue": "recognition_as_former_deity",
        "special_rooms": ["celestial_trial_rooms"],
        "weapon_aspects": ["transcendent_aspects"],
        "story_variations": "divine_perspective_retained"
    }

func start_new_game_plus(ending_completed: String):
    ng_plus_level += 1
    
    # Carry over specific content based on ending
    _setup_carry_over_content(ending_completed)
    
    # Apply NG+ bonuses
    _apply_ng_plus_bonuses(ending_completed)
    
    # Start new run with bonuses
    GameManager.start_ng_plus_run(ng_plus_level, carried_over_content)

func _setup_carry_over_content(ending_type: String):
    carried_over_content = {
        "ending_achieved": ending_type,
        "ng_plus_level": ng_plus_level,
        "memorial_weapons": _get_memorial_weapons(ending_type),
        "relationship_memories": _get_relationship_echoes(),
        "story_knowledge": _get_retained_story_knowledge(),
        "divine_recognition": _get_divine_recognition_level(),
        "unlocked_heat_modifiers": _get_extreme_heat_options()
    }

func _get_memorial_weapons(ending_type: String) -> Array[Dictionary]:
    # Special weapons that commemorate previous run
    var memorial_weapons = []
    
    match ending_type:
        "justice":
            memorial_weapons.append({
                "id": "memorial_scales",
                "name": "Balança da Justiça Eterna",
                "description": "Eco da autoridade divina do run anterior",
                "special_ability": "judge_enemy_morality",
                "flavor_text": "Lembra do peso da verdadeira justiça."
            })
        "love":
            memorial_weapons.append({
                "id": "memorial_lotus",
                "name": "Lótus do Amor Eterno",  
                "description": "Símbolo da conexão transcendente com Nefertari",
                "special_ability": "heal_through_compassion",
                "flavor_text": "O amor verdadeiro ecoa através de todas as vidas."
            })
        # Continue for other endings...
    
    return memorial_weapons

func _apply_ng_plus_bonuses(ending_type: String):
    var bonuses = ending_bonuses[ending_type]
    
    # Starting boons
    for boon_id in bonuses.starting_boons:
        GameManager.grant_starting_boon(boon_id)
    
    # Unlock special dialogue options
    DialogueSystem.unlock_ng_plus_dialogues(bonuses.unique_dialogue)
    
    # Enable special rooms
    BiomeManager.enable_special_rooms(bonuses.special_rooms)
    
    # Unlock weapon aspects
    WeaponAspectSystem.unlock_ng_plus_aspects(bonuses.weapon_aspects)
    
    # Apply story variations
    NarrativePersistence.apply_ng_plus_variations(bonuses.story_variations)

func get_ng_plus_completion_bonus() -> float:
    # Each NG+ level provides increasing bonuses
    return 1.0 + (ng_plus_level * 0.15)  # 15% bonus per NG+ level

func is_content_unlocked(content_id: String) -> bool:
    # Check if specific NG+ content is unlocked
    return unlock_conditions_met.get(content_id, false)

func unlock_extreme_content():
    # Unlock content only available in NG+
    var extreme_unlocks = [
        "heat_level_30_plus",
        "secret_biome_access",
        "developer_commentary_mode",
        "concept_art_gallery",
        "behind_scenes_content"
    ]
    
    for unlock in extreme_unlocks:
        unlock_conditions_met[unlock] = true
        GameManager.unlock_content(unlock)
```

---

## 🚀 **SPRINT 24: PERFORMANCE & RELEASE**

### **🎯 Objetivos Principais**
1. **Performance Optimization:** 60 FPS constante em todas as situações
2. **Memory Management:** Zero vazamentos de memória
3. **Loading Time Optimization:** Carregamento <3 segundos para qualquer tela
4. **Quality Assurance:** Sistema de QA automatizado
5. **Release Preparation:** Build pipeline otimizado para distribuição
6. **Platform Compatibility:** Teste em diferentes configurações de hardware

### **🏗️ Performance Optimization System**

#### **A. Performance Manager**
```gdscript
# PerformanceManager.gd - Sistema central de otimização
extends Node
class_name PerformanceManager

var target_fps: int = 60
var current_fps: float = 0.0
var frame_time_budget: float = 16.67  # milliseconds for 60fps
var performance_metrics: Dictionary = {}
var optimization_strategies: Dictionary = {}

@export var enable_profiling: bool = false
@export var auto_quality_adjustment: bool = true
@export var performance_targets: Dictionary = {}

signal performance_warning(metric_name: String, current_value: float, target_value: float)
signal fps_dropped_below_target(current_fps: float)
signal memory_usage_high(memory_mb: float)

func _ready():
    _initialize_performance_targets()
    _setup_performance_monitoring()
    _load_optimization_strategies()

func _initialize_performance_targets():
    performance_targets = {
        "target_fps": 60,
        "min_acceptable_fps": 55,
        "max_frame_time_ms": 16.67,
        "max_memory_usage_mb": 1024,
        "max_loading_time_s": 3.0,
        "max_gc_pause_ms": 5.0,
        "target_draw_calls": 500,
        "max_particles": 1000
    }

func _process(_delta):
    if enable_profiling:
        _collect_performance_metrics()
        _analyze_performance()
        
        if auto_quality_adjustment:
            _auto_adjust_quality_settings()

func _collect_performance_metrics():
    current_fps = Engine.get_frames_per_second()
    performance_metrics["fps"] = current_fps
    performance_metrics["frame_time"] = 1000.0 / current_fps if current_fps > 0 else 0.0
    performance_metrics["memory_usage"] = OS.get_static_memory_usage_by_type()["total"] / 1048576.0  # MB
    performance_metrics["draw_calls"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TYPE_VISIBLE, RenderingServer.RENDERING_INFO_DRAW_CALLS_IN_FRAME)
    performance_metrics["vertices"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TYPE_VISIBLE, RenderingServer.RENDERING_INFO_VERTICES_IN_FRAME)
    
    # Game-specific metrics
    performance_metrics["active_enemies"] = len(get_tree().get_nodes_in_group("enemies"))
    performance_metrics["active_particles"] = len(get_tree().get_nodes_in_group("particle_systems"))
    performance_metrics["active_audio_sources"] = len(get_tree().get_nodes_in_group("audio_sources"))

func _analyze_performance():
    # Check FPS target
    if current_fps < performance_targets.min_acceptable_fps:
        fps_dropped_below_target.emit(current_fps)
        _trigger_performance_emergency_mode()
    
    # Check memory usage
    var memory_mb = performance_metrics.memory_usage
    if memory_mb > performance_targets.max_memory_usage_mb:
        memory_usage_high.emit(memory_mb)
        _trigger_memory_cleanup()
    
    # Check frame time budget
    var frame_time = performance_metrics.frame_time
    if frame_time > performance_targets.max_frame_time_ms:
        performance_warning.emit("frame_time", frame_time, performance_targets.max_frame_time_ms)

func _auto_adjust_quality_settings():
    var performance_score = _calculate_performance_score()
    
    if performance_score < 0.7:  # Below 70% performance target
        _reduce_quality_settings()
    elif performance_score > 0.9:  # Above 90% performance target
        _increase_quality_settings()

func _calculate_performance_score() -> float:
    var fps_score = min(current_fps / performance_targets.target_fps, 1.0)
    var memory_score = 1.0 - min(performance_metrics.memory_usage / performance_targets.max_memory_usage_mb, 1.0)
    var draw_call_score = 1.0 - min(performance_metrics.draw_calls / performance_targets.target_draw_calls, 1.0)
    
    return (fps_score + memory_score + draw_call_score) / 3.0

func _reduce_quality_settings():
    # Particle quality
    CombatJuiceManager.particle_quality = "Medium"
    CombatJuiceManager.max_particles_per_pool = 25
    
    # Shadow quality
    var viewport = get_viewport()
    if viewport.render_world_3d:
        viewport.render_world_3d.environment.ssao_enabled = false
        viewport.render_world_3d.environment.sdfgi_enabled = false
    
    # Audio quality
    AudioManager.reduce_audio_quality()
    
    # AI update frequency
    EnemyManager.reduce_ai_update_frequency()
    
    print("Performance: Quality settings reduced to maintain target FPS")

func _increase_quality_settings():
    # Only increase if we have performance headroom
    if current_fps > performance_targets.target_fps * 1.1:
        CombatJuiceManager.particle_quality = "High"
        CombatJuiceManager.max_particles_per_pool = 50
        
        var viewport = get_viewport()
        if viewport.render_world_3d:
            viewport.render_world_3d.environment.ssao_enabled = true
        
        print("Performance: Quality settings increased due to performance headroom")

func _trigger_performance_emergency_mode():
    # Emergency measures for severe performance drops
    print("Performance: Emergency mode activated!")
    
    # Drastically reduce all effects
    CombatJuiceManager.screen_shake_intensity = 0.0
    CombatJuiceManager.particle_quality = "Low"
    
    # Reduce enemy count
    EnemyManager.emergency_cull_enemies()
    
    # Disable non-essential audio
    AudioManager.emergency_audio_reduction()
    
    # Force garbage collection
    System.request_garbage_collection()

func get_performance_report() -> Dictionary:
    return {
        "current_fps": current_fps,
        "target_fps": performance_targets.target_fps,
        "memory_usage_mb": performance_metrics.memory_usage,
        "draw_calls": performance_metrics.draw_calls,
        "performance_score": _calculate_performance_score(),
        "quality_level": _get_current_quality_level(),
        "emergency_mode_active": _is_emergency_mode_active()
    }

func optimize_for_platform(platform: String):
    match platform:
        "desktop_high_end":
            _apply_high_end_optimizations()
        "desktop_mid_range":
            _apply_mid_range_optimizations()
        "desktop_low_end":
            _apply_low_end_optimizations()
        "steam_deck":
            _apply_steam_deck_optimizations()

func _apply_low_end_optimizations():
    # Aggressive optimizations for low-end hardware
    performance_targets.target_fps = 30  # Lower target for stability
    performance_targets.max_memory_usage_mb = 512
    
    # Reduce all quality settings
    CombatJuiceManager.particle_quality = "Low"
    CombatJuiceManager.max_particles_per_pool = 15
    AudioManager.max_concurrent_sounds = 8
    EnemyManager.max_enemies_per_room = 6
    
    # Disable expensive effects
    var viewport = get_viewport()
    if viewport.render_world_3d:
        viewport.render_world_3d.environment.ssao_enabled = false
        viewport.render_world_3d.environment.sdfgi_enabled = false
        viewport.render_world_3d.environment.volumetric_fog_enabled = false
```

#### **B. Memory Management System**
```gdscript
# MemoryManager.gd - Sistema avançado de gerenciamento de memória
extends Node
class_name MemoryManager

var memory_pools: Dictionary = {}
var cached_resources: Dictionary = {}
var memory_usage_history: Array[float] = []
var gc_thresholds: Dictionary = {}

@export var enable_resource_caching: bool = true
@export var max_cached_resources: int = 100
@export var memory_warning_threshold_mb: float = 800.0

signal memory_warning(current_usage_mb: float)
signal resource_cache_cleared(freed_mb: float)
signal memory_leak_detected(leak_source: String)

func _ready():
    _initialize_memory_pools()
    _setup_gc_thresholds()
    _start_memory_monitoring()

func _initialize_memory_pools():
    # Object pools for frequently created/destroyed objects
    memory_pools["particles"] = ObjectPool.new(GPUParticles3D, 50)
    memory_pools["damage_numbers"] = ObjectPool.new(DamageNumber, 30)
    memory_pools["audio_sources"] = ObjectPool.new(AudioStreamPlayer3D, 20)
    memory_pools["projectiles"] = ObjectPool.new(Projectile, 100)
    memory_pools["enemies"] = ObjectPool.new(Enemy, 25)

func _setup_gc_thresholds():
    gc_thresholds = {
        "minor_gc_mb": 200.0,  # Trigger minor collection
        "major_gc_mb": 500.0,  # Trigger major collection
        "emergency_gc_mb": 750.0  # Emergency collection
    }

func _start_memory_monitoring():
    var monitor_timer = Timer.new()
    monitor_timer.wait_time = 1.0  # Check every second
    monitor_timer.timeout.connect(_monitor_memory_usage)
    add_child(monitor_timer)
    monitor_timer.start()

func _monitor_memory_usage():
    var current_usage = OS.get_static_memory_usage_by_type()["total"] / 1048576.0  # MB
    memory_usage_history.append(current_usage)
    
    # Keep only last 60 seconds of history
    if memory_usage_history.size() > 60:
        memory_usage_history.pop_front()
    
    # Check for memory issues
    if current_usage > memory_warning_threshold_mb:
        memory_warning.emit(current_usage)
        _handle_memory_pressure()
    
    # Check for memory leaks
    _detect_memory_leaks()
    
    # Trigger GC if needed
    _check_gc_thresholds(current_usage)

func _handle_memory_pressure():
    print("Memory Manager: High memory usage detected, applying pressure relief")
    
    # Clear resource caches
    var freed_memory = _clear_resource_caches()
    
    # Force object pool cleanup
    _cleanup_object_pools()
    
    # Request garbage collection
    System.request_garbage_collection()
    
    # Notify other systems to reduce memory usage
    _notify_systems_memory_pressure()

func _clear_resource_caches() -> float:
    var initial_usage = OS.get_static_memory_usage_by_type()["total"] / 1048576.0
    
    # Clear texture cache
    for resource_path in cached_resources.keys():
        cached_resources[resource_path] = null
    cached_resources.clear()
    
    # Clear other engine caches
    ResourceLoader.clear_cache()
    
    var final_usage = OS.get_static_memory_usage_by_type()["total"] / 1048576.0
    var freed_mb = initial_usage - final_usage
    
    resource_cache_cleared.emit(freed_mb)
    return freed_mb

func _detect_memory_leaks():
    if memory_usage_history.size() < 30:  # Need enough history
        return
    
    # Check for steady memory growth over time
    var recent_average = 0.0
    var older_average = 0.0
    
    for i in range(memory_usage_history.size() - 15, memory_usage_history.size()):
        recent_average += memory_usage_history[i]
    recent_average /= 15
    
    for i in range(memory_usage_history.size() - 30, memory_usage_history.size() - 15):
        older_average += memory_usage_history[i]
    older_average /= 15
    
    # If memory consistently growing over 30 seconds, potential leak
    if recent_average > older_average * 1.2:
        _investigate_potential_leak()

func _investigate_potential_leak():
    # Get current object counts
    var current_objects = _count_game_objects()
    
    # Compare with expected counts
    var suspicious_objects = []
    
    if current_objects.get("enemies", 0) > 50:
        suspicious_objects.append("enemies")
    if current_objects.get("particles", 0) > 100:
        suspicious_objects.append("particles")
    if current_objects.get("audio_sources", 0) > 30:
        suspicious_objects.append("audio_sources")
    
    for obj_type in suspicious_objects:
        memory_leak_detected.emit(obj_type)
        print("Memory Manager: Potential leak detected in ", obj_type)

func get_pooled_object(pool_name: String) -> Node:
    if pool_name in memory_pools:
        return memory_pools[pool_name].get_object()
    return null

func return_pooled_object(pool_name: String, obj: Node):
    if pool_name in memory_pools:
        memory_pools[pool_name].return_object(obj)

func preload_critical_resources():
    # Preload resources that are used frequently
    var critical_resources = [
        "res://scenes/enemies/BasicEnemy.tscn",
        "res://effects/particles/HitSpark.tscn", 
        "res://audio/weapons/sword_hit.ogg",
        "res://ui/DamageNumber.tscn"
    ]
    
    for resource_path in critical_resources:
        if not resource_path in cached_resources:
            cached_resources[resource_path] = load(resource_path)
    
    print("Memory Manager: Critical resources preloaded")

func get_memory_report() -> Dictionary:
    var current_usage = OS.get_static_memory_usage_by_type()["total"] / 1048576.0
    
    return {
        "current_usage_mb": current_usage,
        "cached_resources_count": cached_resources.size(),
        "object_pool_status": _get_pool_status(),
        "memory_trend": _analyze_memory_trend(),
        "gc_recommendations": _get_gc_recommendations()
    }

class ObjectPool:
    var object_type: Script
    var pool: Array = []
    var max_size: int
    var created_count: int = 0
    
    func _init(type: Script, size: int):
        object_type = type
        max_size = size
    
    func get_object() -> Node:
        if pool.size() > 0:
            return pool.pop_back()
        else:
            created_count += 1
            return object_type.new()
    
    func return_object(obj: Node):
        if pool.size() < max_size:
            obj.reset()  # Assume objects have reset method
            pool.append(obj)
        else:
            obj.queue_free()
```

#### **C. Quality Assurance System**
```gdscript
# QASystem.gd - Sistema automatizado de Quality Assurance
extends Node
class_name QASystem

var test_results: Dictionary = {}
var automated_tests: Array[QATest] = []
var regression_tests: Array[RegressionTest] = []
var performance_benchmarks: Array[BenchmarkTest] = []

signal test_completed(test_name: String, result: bool, details: Dictionary)
signal full_qa_completed(overall_result: bool, failed_tests: Array)
signal critical_bug_detected(bug_description: String, severity: String)

func _ready():
    _initialize_automated_tests()
    _setup_regression_tests()
    _create_performance_benchmarks()

func _initialize_automated_tests():
    # Core gameplay tests
    automated_tests.append(QATest.new(
        "combat_system_functionality",
        "Verify all weapons deal damage correctly",
        _test_combat_system
    ))
    
    automated_tests.append(QATest.new(
        "boon_system_integrity",
        "Verify boons apply effects correctly",
        _test_boon_system
    ))
    
    automated_tests.append(QATest.new(
        "save_load_system",
        "Verify save/load preserves game state",
        _test_save_load_system
    ))
    
    automated_tests.append(QATest.new(
        "ui_responsiveness", 
        "Verify UI responds to input within acceptable time",
        _test_ui_responsiveness
    ))
    
    automated_tests.append(QATest.new(
        "memory_leak_check",
        "Verify no memory leaks during extended play",
        _test_memory_leaks
    ))

func run_full_qa_suite() -> bool:
    print("QA System: Starting full quality assurance suite...")
    
    var all_tests_passed = true
    var failed_tests = []
    
    # Run automated tests
    for test in automated_tests:
        var result = test.execute()
        test_results[test.name] = result
        
        if not result.passed:
            all_tests_passed = false
            failed_tests.append(test.name)
            
            if result.severity == "Critical":
                critical_bug_detected.emit(result.description, result.severity)
        
        test_completed.emit(test.name, result.passed, result.details)
    
    # Run regression tests
    for test in regression_tests:
        var result = test.execute()
        test_results[test.name] = result
        
        if not result.passed:
            all_tests_passed = false
            failed_tests.append(test.name)
    
    # Run performance benchmarks
    for benchmark in performance_benchmarks:
        var result = benchmark.execute()
        test_results[benchmark.name] = result
        
        if not result.meets_target:
            all_tests_passed = false
            failed_tests.append(benchmark.name)
    
    full_qa_completed.emit(all_tests_passed, failed_tests)
    return all_tests_passed

func _test_combat_system() -> Dictionary:
    var result = {
        "passed": true,
        "details": {},
        "severity": "Medium"
    }
    
    # Spawn test enemy
    var test_enemy = preload("res://scenes/enemies/BasicEnemy.tscn").instantiate()
    get_tree().root.add_child(test_enemy)
    
    # Test each weapon type
    var weapons_to_test = ["khopesh", "was_scepter", "staff", "bow", "claws"]
    
    for weapon_name in weapons_to_test:
        var initial_health = test_enemy.current_health
        
        # Simulate weapon attack
        GameManager.set_current_weapon(weapon_name)
        GameManager.trigger_attack()
        
        # Wait for damage processing
        await get_tree().create_timer(0.1).timeout
        
        # Verify damage was dealt
        if test_enemy.current_health >= initial_health:
            result.passed = false
            result.details[weapon_name] = "No damage dealt"
            result.severity = "Critical"
        else:
            result.details[weapon_name] = "Damage dealt correctly"
    
    test_enemy.queue_free()
    return result

func _test_boon_system() -> Dictionary:
    var result = {
        "passed": true,
        "details": {},
        "severity": "Medium"
    }
    
    # Test boon application
    var test_boons = ["ra_blessing", "anubis_justice", "thoth_wisdom"]
    
    for boon_id in test_boons:
        var initial_stats = GameManager.get_player_stats()
        
        # Apply boon
        GameManager.apply_boon(boon_id)
        
        # Check if stats changed appropriately
        var new_stats = GameManager.get_player_stats()
        
        if initial_stats == new_stats:
            result.passed = false
            result.details[boon_id] = "Boon had no effect"
            result.severity = "High"
        else:
            result.details[boon_id] = "Boon applied correctly"
        
        # Remove boon for next test
        GameManager.remove_boon(boon_id)
    
    return result

func _test_save_load_system() -> Dictionary:
    var result = {
        "passed": true,
        "details": {},
        "severity": "Critical"
    }
    
    # Create test save state
    var original_state = {
        "level": GameManager.player_level,
        "health": GameManager.player_health,
        "equipped_weapon": GameManager.current_weapon,
        "boons": GameManager.active_boons.duplicate()
    }
    
    # Modify state
    GameManager.player_level += 5
    GameManager.player_health = 50.0
    GameManager.set_current_weapon("staff")
    
    # Save
    var save_success = GameManager.save_game("qa_test_save")
    
    if not save_success:
        result.passed = false
        result.details["save"] = "Save operation failed"
        return result
    
    # Load
    var load_success = GameManager.load_game("qa_test_save")
    
    if not load_success:
        result.passed = false
        result.details["load"] = "Load operation failed"
        return result
    
    # Verify state restoration
    if GameManager.player_level != original_state.level:
        result.passed = false
        result.details["level"] = "Level not restored correctly"
    
    if GameManager.player_health != original_state.health:
        result.passed = false
        result.details["health"] = "Health not restored correctly"
    
    return result

func _test_ui_responsiveness() -> Dictionary:
    var result = {
        "passed": true,
        "details": {},
        "severity": "Medium"
    }
    
    # Test menu response time
    var menu_response_time = _measure_ui_response_time("main_menu")
    if menu_response_time > 100:  # 100ms threshold
        result.passed = false
        result.details["main_menu"] = "Response time too slow: " + str(menu_response_time) + "ms"
    
    # Test in-game UI response time
    var hud_response_time = _measure_ui_response_time("game_hud")
    if hud_response_time > 16:  # One frame at 60fps
        result.passed = false
        result.details["game_hud"] = "HUD response time too slow: " + str(hud_response_time) + "ms"
    
    return result

func _test_memory_leaks() -> Dictionary:
    var result = {
        "passed": true,
        "details": {},
        "severity": "High"
    }
    
    var initial_memory = OS.get_static_memory_usage_by_type()["total"]
    
    # Simulate extended gameplay
    for i in range(100):  # 100 iterations
        # Spawn and destroy enemies
        var enemy = preload("res://scenes/enemies/BasicEnemy.tscn").instantiate()
        get_tree().root.add_child(enemy)
        enemy.queue_free()
        
        # Create and destroy particles
        var particles = GPUParticles3D.new()
        get_tree().root.add_child(particles)
        particles.queue_free()
        
        # Force process queue
        await get_tree().process_frame
    
    # Force garbage collection
    System.request_garbage_collection()
    await get_tree().create_timer(1.0).timeout
    
    var final_memory = OS.get_static_memory_usage_by_type()["total"]
    var memory_growth = final_memory - initial_memory
    
    # Allow 10MB growth tolerance
    if memory_growth > 10485760:  # 10MB in bytes
        result.passed = false
        result.details["memory_growth"] = "Excessive memory growth: " + str(memory_growth / 1048576.0) + "MB"
    
    return result

func generate_qa_report() -> String:
    var report = "=== SANDS OF DUAT - QA REPORT ===\n\n"
    
    var total_tests = test_results.size()
    var passed_tests = 0
    
    for test_name in test_results.keys():
        var result = test_results[test_name]
        if result.passed or result.get("meets_target", false):
            passed_tests += 1
    
    report += "Overall Result: " + str(passed_tests) + "/" + str(total_tests) + " tests passed\n\n"
    
    # Detailed results
    for test_name in test_results.keys():
        var result = test_results[test_name]
        report += "Test: " + test_name + "\n"
        report += "Status: " + ("PASS" if result.get("passed", result.get("meets_target", false)) else "FAIL") + "\n"
        
        if "details" in result:
            for detail_key in result.details.keys():
                report += "  - " + detail_key + ": " + str(result.details[detail_key]) + "\n"
        
        report += "\n"
    
    return report

class QATest:
    var name: String
    var description: String
    var test_function: Callable
    
    func _init(test_name: String, test_desc: String, test_func: Callable):
        name = test_name
        description = test_desc
        test_function = test_func
    
    func execute() -> Dictionary:
        return await test_function.call()
```

---

## ✅ **FINAL INTEGRATION CHECKLIST - SPRINTS 21-24**

### **Sprint 21: UI/UX Complete**
- [ ] **Main menu polished** with Egyptian theme and smooth animations
- [ ] **In-game HUD responsive** and scales to different resolutions
- [ ] **Controller support complete** for Xbox, PlayStation, and generic gamepads  
- [ ] **Accessibility features** implemented (colorblind, large text, reduced motion)
- [ ] **UI performance optimized** with <16ms response time
- [ ] **Visual consistency** maintained across all screens
- [ ] **Settings persistence** working for all UI preferences

### **Sprint 22: Narrative Complete**
- [ ] **Full dialogue system** with 1000+ lines of contextual dialogue
- [ ] **Character development arcs** complete for all major NPCs
- [ ] **Egyptian mythology integration** authentic and respectful
- [ ] **Voice acting scripts** finalized for future dubbing
- [ ] **Lore database complete** with 50+ entries unlockable through gameplay
- [ ] **Multiple story branches** leading to 4 distinct endings
- [ ] **Narrative consistency** maintained across all playthroughs

### **Sprint 23: Final Boss & Endings**
- [ ] **Osiris boss battle** with 5 phases and moral adaptation
- [ ] **4 distinct endings** implemented with unique cinematics
- [ ] **Ending determination system** based on player moral choices
- [ ] **New Game Plus content** with ending-specific bonuses
- [ ] **Achievement system** tracking all major accomplishments
- [ ] **Credits sequence** polished with ending-specific variations
- [ ] **Post-game content** accessible and rewarding

### **Sprint 24: Performance & Release**
- [ ] **60 FPS performance** maintained in all scenarios
- [ ] **Memory management** preventing leaks and excessive usage
- [ ] **Loading times optimized** to <3 seconds for all transitions  
- [ ] **Quality assurance** automated system with 95% test pass rate
- [ ] **Platform optimization** for various hardware configurations
- [ ] **Build pipeline** ready for distribution
- [ ] **Zero critical bugs** remaining in release candidate

---

## 🎯 **SUCCESS CRITERIA - PHASE 4 COMPLETE**

**Polish & Completion Achieved When:**
- UI/UX quality matches or exceeds commercial indie standards
- Narrative provides satisfying emotional journey with meaningful endings
- Final boss battle serves as worthy climax to entire experience
- Performance optimized to run smoothly on mid-range hardware
- Quality assurance system catches and prevents regressions

**Technical Excellence Markers:**
- 60 FPS locked on recommended hardware specifications
- Loading screens never exceed 3 seconds on SSD
- Memory usage stable with zero detectable leaks
- UI response time under 16ms for all interactions
- Save/load system 100% reliable across all game states

**Player Experience Goals:**
- "This feels like a professionally published game"
- "The ending made the entire journey feel meaningful"
- "Osiris boss fight was an incredible climax"
- "UI is intuitive and beautiful throughout"
- "I want to immediately start New Game Plus"

---

## 🏆 **PROJETO FINAL COMPLETO**

**Ao final da Fase 4, Sands of Duat será:**

✨ **Um ARPG roguelike completo** com 50+ horas de conteúdo

🎮 **Experiência de combat premium** rivalizando com Hades

🏛️ **Narrativa egípcia autêntica** com 4 endings únicos

⚡ **Performance otimizada** para 60 FPS constante

🎨 **Polish visual/audio** de qualidade AAA indie

🔄 **Rejogabilidade infinita** através de 150+ builds viáveis

---

*"Nas areias do Duat, Khenti-Ka-Nefer forjou não apenas sua redenção, mas uma lenda que ecoará pela eternidade. Sua jornada da morte para a transcendência agora está completa."*

**🎉 SANDS OF DUAT - MASTERPIECE READY FOR RELEASE 🎉**