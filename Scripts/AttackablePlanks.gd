extends StaticBody3D

@export var health: int = 30
@export var flash_duration: float = 0.15
@export var hit_particle_amount: int = 3
@export var death_particle_amount: int = 65

@onready var damage_particles: GPUParticles3D = $"../DamageParticles"
@onready var death_particles: GPUParticles3D = $"../DeathParticles"
@onready var break_sfx: AudioStreamPlayer3D = $BreakSFX
@onready var damageSFX: AudioStreamPlayer3D = $DamageSFX
@onready var plank_1: MeshInstance3D = $plank1
@onready var plank_2: MeshInstance3D = $plank2
@onready var plank_3: MeshInstance3D = $plank3

var mesh_parts: Array[MeshInstance3D] = []
var flash_material: StandardMaterial3D

func _ready() -> void:
	mesh_parts = [plank_1, plank_2, plank_3]

	flash_material = StandardMaterial3D.new()
	flash_material.albedo_color = Color.WHITE

func take_damage(amount: int, source) -> void:
	damage_particles.restart()
	damage_particles.emitting = true

	damageSFX.play()
	health -= amount
	_flash_white()

	if health <= 0:
		die()

func _flash_white() -> void:
	for part in mesh_parts:
		part.material_override = flash_material

	await get_tree().create_timer(flash_duration).timeout

	for part in mesh_parts:
		part.material_override = null

func die() -> void:
	var parent := get_parent()

	death_particles.restart()
	death_particles.emitting = true

	break_sfx.reparent(parent)
	break_sfx.global_position = global_position
	break_sfx.play()
	break_sfx.finished.connect(break_sfx.queue_free)

	queue_free()
