extends Control

@onready var game_boy_shader: ColorRect = $"../GameBoyShader" 
@onready var shader_material: ShaderMaterial = game_boy_shader.material as ShaderMaterial
@onready var crosshair: TextureRect = $"../Crosshair"

@onready var volume_slider: HSlider = $MarginContainer/VBoxContainer/SettingsContainer/Volume/VolumeSlider
@onready var sensitivity_slider: HSlider = $MarginContainer/VBoxContainer/SettingsContainer/Sensitivity/SensitivitySlider
@onready var color_simplification: HSlider = $MarginContainer/VBoxContainer/SettingsContainer/ColorSteps/ColorSimplification
@onready var color_picker_button: ColorPickerButton = $MarginContainer/VBoxContainer/SettingsContainer/ShaderColor/ColorPickerButton
@onready var color_picker_button_2: ColorPickerButton = $MarginContainer/VBoxContainer/SettingsContainer/ShaderColor2/ColorPickerButton2
@onready var restart: Button = $MarginContainer/VBoxContainer/Restart

@onready var pixelation: HSlider = $MarginContainer/VBoxContainer/SettingsContainer/Pixelation/Pixelation
@onready var fps_counter: Label = $"../FPSCounter"

const DEFAULT_COLOUR_ONE = Color(0.724, 0.332, 0.09, 1.0)
const DEFAULT_COLOUR_TWO = Color(0.086, 0.026, 0.053, 1.0)

const DAMAGE_COLOR_ONE:= Color(1.0, 0.0, 0.0, 1.0)
const DAMAGE_COLOR_TWO:= Color(0.0, 0.0, 0.0, 1.0)
const HEAL_COLOR_ONE:= Color(1.0, 0.683, 0.0, 1.0)
const PIXELATION_REC_TIME = 3.0 # SECONDS
const COLOR_REC_TIME = 1.0
static var mouse_sensitivity := 1.0

func play_damage_visual():
	shader_material.set_shader_parameter("color_one", DAMAGE_COLOR_ONE)
	get_viewport().scaling_3d_scale = 0.01
	print("damage")

func play_heal_visual():
	shader_material.set_shader_parameter("color_one", HEAL_COLOR_ONE)
	get_viewport().scaling_3d_scale += 0.05
	print("heal")

func _on_volume_slider_value_changed(value: float) -> void:
	if value <= 0.0:
		AudioServer.set_bus_mute(0, true)
	else:
		AudioServer.set_bus_mute(0, false)
		AudioServer.set_bus_volume_db(0, linear_to_db(value))

func _on_sensitivity_slider_value_changed(value: float) -> void:
	mouse_sensitivity = value

func _on_color_simplification_value_changed(value: int) -> void:
	shader_material.set_shader_parameter("number_of_colors", value)

func _on_color_picker_button_color_changed(color: Color) -> void:
	shader_material.set_shader_parameter("color_one", color)

func _on_color_picker_button_2_color_changed(color: Color) -> void:
	shader_material.set_shader_parameter("color_two", color)

func _on_pixelation_value_changed(value: float) -> void:
	get_viewport().scaling_3d_scale = value

func _ready():
	self.visible = false
	load_settings()
	
func move_toward_color(from: Color, to: Color, max_step: float) -> Color:
	return Color(
		move_toward(from.r, to.r, max_step),
		move_toward(from.g, to.g, max_step),
		move_toward(from.b, to.b, max_step),
		move_toward(from.a, to.a, max_step)
	)

func _physics_process(delta: float) -> void:
	var current_color = shader_material.get_shader_parameter("color_one")
	var current_color2 = shader_material.get_shader_parameter("color_two")
	var original_pixelation = pixelation.value
	var current_pixelation = get_viewport().scaling_3d_scale
	
	if color_picker_button.color != current_color:
		var color = move_toward_color(current_color, color_picker_button.color, delta / COLOR_REC_TIME)
		shader_material.set_shader_parameter("color_one", color)
	
	if color_picker_button_2.color != current_color2:
		var color2 = move_toward_color(current_color2, color_picker_button_2.color, delta / COLOR_REC_TIME)
		shader_material.set_shader_parameter("color_two", color2)
	
	if current_pixelation != original_pixelation:
		get_viewport().scaling_3d_scale = move_toward(current_pixelation, original_pixelation, delta / PIXELATION_REC_TIME)
		
	if Input.is_action_just_pressed("Escape"):
		if get_tree().paused:
			# Resume game
			get_tree().paused = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			crosshair.show()
			save_settings()
			self.hide()
		else:
			# Pause game
			get_tree().paused = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			crosshair.hide()
			self.show()


const SETTINGS_FILE := "user://settings.cfg"

func save_settings() -> void:
	var config := ConfigFile.new()

	config.set_value("settings", "volume", AudioServer.get_bus_volume_linear(0))
	config.set_value("settings", "number_of_colors", shader_material.get_shader_parameter("number_of_colors"))
	config.set_value("settings", "color_one", shader_material.get_shader_parameter("color_one"))
	config.set_value("settings", "color_two", shader_material.get_shader_parameter("color_two"))
	config.set_value("settings", "pixelation", get_viewport().scaling_3d_scale)
	config.set_value("settings", "sensitivity", mouse_sensitivity)

	config.save(SETTINGS_FILE)


func load_settings() -> void:
	var config := ConfigFile.new()

	if config.load(SETTINGS_FILE) != OK:
		return

	# Volume
	var volume = config.get_value("settings", "volume", 1.0)
	AudioServer.set_bus_volume_linear(0, volume)
	volume_slider.value = volume

	# Number of colours
	var number_of_colors = config.get_value("settings", "number_of_colors", 5)
	shader_material.set_shader_parameter("number_of_colors", number_of_colors)
	color_simplification.value = number_of_colors

	# Shader colour
	var color_one = config.get_value("settings", "color_one", DEFAULT_COLOUR_ONE)
	shader_material.set_shader_parameter("color_one", color_one)
	color_picker_button.color = color_one

	var color_two = config.get_value("settings", "color_two",DEFAULT_COLOUR_TWO)
	shader_material.set_shader_parameter("color_two", color_two)
	color_picker_button_2.color = color_two

	# Pixelation
	var pixelation_value = config.get_value("settings", "pixelation", 1.0)
	get_viewport().scaling_3d_scale = pixelation_value
	pixelation.value = pixelation_value
	
	var sensitivity = config.get_value("settings", "sensitivity", 1.0)
	mouse_sensitivity = sensitivity
	sensitivity_slider.value = sensitivity

func _on_volume_reset_pressed() -> void:
	volume_slider.value = 1.0

func _on_sensitivity_reset_pressed() -> void:
	sensitivity_slider.value = 1.0
	_on_sensitivity_slider_value_changed(1.0)

func _on_color_steps_reset_pressed() -> void:
	color_simplification.value = 5.0
	_on_color_simplification_value_changed(5)

func _on_shader_color_reset_pressed() -> void:
	var default_color := DEFAULT_COLOUR_ONE
	color_picker_button.color = default_color
	_on_color_picker_button_color_changed(default_color)

func _on_shader_color_reset_2_pressed() -> void:
	var default_color := DEFAULT_COLOUR_TWO
	color_picker_button_2.color = default_color
	_on_color_picker_button_2_color_changed(default_color)

func _on_pixelation_reset_pressed() -> void:
	pixelation.value = 0.25
	_on_pixelation_value_changed(0.25)

func _on_fps_button_toggled(toggled_on: bool) -> void:
	fps_counter.visible=(toggled_on)


func _on_quit_pressed() -> void:
	save_settings()
	get_tree().quit()

func _on_quit_to_menu_pressed() -> void:
	save_settings()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")

func _on_resume_pressed() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	crosshair.show()
	save_settings()
	self.hide()


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
