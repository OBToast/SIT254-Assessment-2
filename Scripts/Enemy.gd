extends CharacterBody3D
var player = null
const SPEED = 5.0
var health: int = 50
@export var player_path : NodePath
@export var attack_range: float = 2.0
@export var attack_damage: int = 10
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var blood_splashSFX: AudioStreamPlayer3D = $BloodSplashSFX
@onready var damageSFX: AudioStreamPlayer3D = $DamageSFX
@onready var sprite: AnimatedSprite3D = $Sprite
@onready var hit_particles: GPUParticles3D = $HitParticles
@onready var death_particles: GPUParticles3D = $DeathParticles
@export var hit_sounds: Array[AudioStream] = []
@onready var attack_sfx: AudioStreamPlayer3D = $AttackSFX

@onready var attack_visual = $AttackVisual
var flash_material: ShaderMaterial
var time_since_hit: float = 1000.0
var is_attacking: bool = false
var has_hit_this_swing: bool = false
var swing_in_progress: bool = false  # true once frame has advanced past 0 this swing

func _ready() -> void:
	player = get_node(player_path)
	var shader := load("res://Assets/Shaders/3dflash.gdshader")
	flash_material = ShaderMaterial.new()
	flash_material.shader = shader
	sprite.material_override = flash_material
	sprite.frame_changed.connect(_update_flash_texture)
	sprite.frame_changed.connect(_on_attack_frame_changed)
	_update_flash_texture()
	hit_particles.one_shot = true
	death_particles.one_shot = true
	attack_visual.visible = false

func _update_flash_texture() -> void:
	var tex := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	flash_material.set_shader_parameter("tex", tex)

func _process(delta: float) -> void:
	time_since_hit += delta
	flash_material.set_shader_parameter("elapsed", time_since_hit)

func _physics_process(delta: float) -> void:
	if is_attacking:
		# Locked into the attack until the animation itself ends it
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var distance_to_player = global_position.distance_to(player.global_position)

	if distance_to_player < attack_range:
		# Commit to a new attack
		is_attacking = true
		has_hit_this_swing = false
		swing_in_progress = false
		sprite.play("attack")
		_update_attack_visual_position()
		velocity = Vector3.ZERO
		move_and_slide()
	else:
		# Chase
		if sprite.animation != "walk":
			sprite.play("walk")
		nav_agent.set_target_position(player.global_position)
		var next_nav_point = nav_agent.get_next_path_position()
		velocity = (next_nav_point - global_position).normalized() * SPEED
		move_and_slide()

func _on_attack_frame_changed() -> void:
	if not is_attacking or sprite.animation != "attack":
		return

	var frame = sprite.frame
	if frame == 1:
		attack_sfx.play()

	attack_visual.visible = false
	# Raycast on frame 3 only, once per swing
	if frame == 3 and not has_hit_this_swing:
		attack_visual.visible = true
		has_hit_this_swing = true
		_try_attack_player()

	if frame != 0:
		swing_in_progress = true

	# Only end the attack once a full swing has actually played through
	# (prevents ending on the very first frame == 0 before anything happened)
	if frame == 0 and swing_in_progress:
		is_attacking = false
		swing_in_progress = false
		attack_visual.visible = false

func _update_attack_visual_position() -> void:
	var dir = player.global_position - global_position
	dir.y = 0  # keep it flat, don't tilt up/down
	if dir.length() > 0.001:
		var target_pos = global_position + dir.normalized() * (attack_range * 0.5)
		attack_visual.global_transform = attack_visual.global_transform.looking_at(
			target_pos + dir, Vector3.UP
		)
		attack_visual.global_position = target_pos

func _try_attack_player() -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player > attack_range:
		return 

	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position + Vector3.UP * 0.5,
		player.global_position + Vector3.UP * 0.5
	)
	query.exclude = [self]
	var result = space_state.intersect_ray(query)

	if result and result.collider == player:
		if result.collider.has_method("take_damage"):
			result.collider.take_damage(attack_damage, "enemy")

func take_damage(amount: int, source):
	damageSFX.stream = hit_sounds[randi() % hit_sounds.size()]
	damageSFX.play()
	time_since_hit = 0.0
	hit_particles.restart()
	hit_particles.emitting = true
	health -= amount
	if health <= 0:
		die()

func die():
	blood_splashSFX.play()
	blood_splashSFX.reparent(get_tree().current_scene)
	blood_splashSFX.finished.connect(damageSFX.queue_free)
	damageSFX.reparent(get_tree().current_scene)
	damageSFX.finished.connect(damageSFX.queue_free)
	death_particles.reparent(get_tree().current_scene)
	death_particles.amount = 65
	death_particles.restart()
	death_particles.emitting = true
	death_particles.finished.connect(death_particles.queue_free)
	queue_free()
