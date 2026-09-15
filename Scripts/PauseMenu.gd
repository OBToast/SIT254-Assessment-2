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
@onready var death_label: Label = $MarginContainer/VBoxContainer/DeathLabel
@onready var resume: Button = $MarginContainer/VBoxContainer/Resume
@onready var pixelation: HSlider = $MarginContainer/VBoxContainer/SettingsContainer/Pixelation/Pixelation
@onready var fps_counter: Label = $"../FPSCounter"
@onready var difficulty: OptionButton = $MarginContainer/VBoxContainer/SettingsContainer/Difficulty/Difficulty
@onready var level_complete_label: Label = $MarginContainer/VBoxContainer/LevelCompleteLabel
@onready var time: Label = $MarginContainer/VBoxContainer/Time
@onready var enemies_cleared: Label = $MarginContainer/VBoxContainer/EnemiesCleared
@onready var next_level: Button = $MarginContainer/VBoxContainer/NextLevel

var next_level_path: String = ""

const SETTINGS_FILE := "user://settings.cfg"

const DEFAULT_COLOUR_ONE = Color(0.724, 0.332, 0.09, 1.0)
const DEFAULT_COLOUR_TWO = Color(0.086, 0.026, 0.053, 1.0)

const DAMAGE_COLOR_ONE := Color(1.0, 0.0, 0.0, 1.0)
const DAMAGE_COLOR_TWO := Color(0.0, 0.0, 0.0, 1.0)
const HEAL_COLOR_ONE := Color(1.0, 0.683, 0.0, 1.0)

const PARRY_COLOUR_ONE = Color(1.0, 1.0, 1.0, 1.0)

const PIXELATION_REC_TIME = 3.0
const COLOR_REC_TIME = 1.0

static var mouse_sensitivity := 1.0

const DIFFICULTIES := ["Easy", "Medium", "Hard"]
static var difficulty_level := "Medium"

@onready var player: CharacterBody3D = $"../../Player"

var level_start_time: float = 0.0
var total_enemies: int = 0


func play_damage_visual():
	shader_material.set_shader_parameter("color_one", DAMAGE_COLOR_ONE)
	get_viewport().scaling_3d_scale = 0.01
	print("damage")


func play_heal_visual():
	shader_material.set_shader_parameter("color_one", HEAL_COLOR_ONE)
	get_viewport().scaling_3d_scale += 0.05
	print("heal")


func play_parry_visual():
	shader_material.set_shader_parameter("color_one", PARRY_COLOUR_ONE)
	print("parry")


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


func _on_difficulty_item_selected(index: int) -> void:
	difficulty_level = difficulty.get_item_text(index)


func _ready():
	self.visible = false

	# Make sure the menu can still be interacted with while the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS

	if difficulty.item_count == 0:
		for d in DIFFICULTIES:
			difficulty.add_item(d)

	load_settings()

	level_start_time = Time.get_ticks_msec() / 1000.0
	total_enemies = get_tree().get_nodes_in_group("enemies").size()


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
		var color = move_toward_color(
			current_color,
			color_picker_button.color,
			delta / COLOR_REC_TIME
		)
		shader_material.set_shader_parameter("color_one", color)

	if color_picker_button_2.color != current_color2:
		var color2 = move_toward_color(
			current_color2,
			color_picker_button_2.color,
			delta / COLOR_REC_TIME
		)
		shader_material.set_shader_parameter("color_two", color2)

	if current_pixelation != original_pixelation:
		get_viewport().scaling_3d_scale = move_toward(
			current_pixelation,
			original_pixelation,
			delta / PIXELATION_REC_TIME
		)

	if Input.is_action_just_pressed("Escape"):
		if get_tree().paused:
			if player != null:
				if player.is_dead != true:
					unpause()
			else:
				unpause()
		else:
			pause()


func pause():
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	crosshair.hide()
	self.show()


func unpause():
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	crosshair.show()
	save_settings()
	self.hide()


func save_settings() -> void:
	var config := ConfigFile.new()

	config.set_value(
		"settings",
		"volume",
		AudioServer.get_bus_volume_linear(0)
	)

	config.set_value(
		"settings",
		"number_of_colors",
		shader_material.get_shader_parameter("number_of_colors")
	)

	config.set_value(
		"settings",
		"color_one",
		color_picker_button.color
	)

	config.set_value(
		"settings",
		"color_two",
		color_picker_button_2.color
	)

	config.set_value(
		"settings",
		"pixelation",
		pixelation.value
	)

	config.set_value(
		"settings",
		"sensitivity",
		mouse_sensitivity
	)

	config.set_value(
		"settings",
		"difficulty",
		difficulty_level
	)

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
	shader_material.set_shader_parameter(
		"number_of_colors",
		number_of_colors
	)
	color_simplification.value = number_of_colors

	# Shader colour
	var color_one = config.get_value(
		"settings",
		"color_one",
		DEFAULT_COLOUR_ONE
	)

	shader_material.set_shader_parameter("color_one", color_one)
	color_picker_button.color = color_one

	var color_two = config.get_value(
		"settings",
		"color_two",
		DEFAULT_COLOUR_TWO
	)

	shader_material.set_shader_parameter("color_two", color_two)
	color_picker_button_2.color = color_two

	# Pixelation
	var pixelation_value = config.get_value(
		"settings",
		"pixelation",
		1.0
	)

	get_viewport().scaling_3d_scale = pixelation_value
	pixelation.value = pixelation_value

	# Sensitivity
	var sensitivity = config.get_value(
		"settings",
		"sensitivity",
		1.0
	)

	mouse_sensitivity = sensitivity
	sensitivity_slider.value = sensitivity

	# Difficulty
	var diff: String = config.get_value(
		"settings",
		"difficulty",
		"Medium"
	)

	difficulty_level = diff

	var diff_index := DIFFICULTIES.find(diff)

	if diff_index == -1:
		diff_index = DIFFICULTIES.find("Medium")

	difficulty.selected = diff_index


func _on_volume_reset_pressed() -> void:
	volume_slider.value = 1.0


func _on_sensitivity_reset_pressed() -> void:
	sensitivity_slider.value = 1.0
	_on_sensitivity_slider_value_changed(1.0)


func _on_color_steps_reset_pressed() -> void:
	color_simplification.value = 6.0
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


func _on_difficulty_reset_pressed() -> void:
	var default_index := DIFFICULTIES.find("Medium")
	difficulty.selected = default_index
	_on_difficulty_item_selected(default_index)


func _on_fps_button_toggled(toggled_on: bool) -> void:
	fps_counter.visible = toggled_on


func _on_quit_pressed() -> void:
	save_settings()
	get_tree().quit()


func _on_quit_to_menu_pressed() -> void:
	save_settings()

	get_tree().paused = false

	get_tree().change_scene_to_file(
		"res://Scenes/title_screen.tscn"
	)


func _on_resume_pressed() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	crosshair.show()
	save_settings()
	self.hide()


func _on_restart_pressed() -> void:
	save_settings()

	get_tree().paused = false

	get_tree().reload_current_scene()


func _on_next_level_pressed() -> void:
	if next_level_path.is_empty():
		print("No next level has been set.")
		return

	save_settings()

	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	get_tree().change_scene_to_file(next_level_path)


func set_death_label(value: bool):
	death_label.visible = value
	resume.visible = !value


func set_level_complete(value: bool):
	level_complete_label.visible = value
	time.visible = value
	enemies_cleared.visible = value
	next_level.visible = value

	if value:
		var elapsed_time := Time.get_ticks_msec() / 1000.0 - level_start_time

		var minutes := int(elapsed_time) / 60
		var seconds := int(elapsed_time) % 60

		time.text = "Time: %02d:%02d" % [minutes, seconds]

		var enemies_remaining := get_tree().get_nodes_in_group("enemies").size()
		var enemies_defeated := total_enemies - enemies_remaining

		enemies_cleared.text = "Enemies Cleared: %d/%d" % [
			enemies_defeated,
			total_enemies
		]
