extends Node2D

@export var speed: float = 200.0
@export var thrum_intensity: float = 0.0

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Camera2D

func _physics_process(delta: float) -> void:
	var input_vector = Vector2.ZERO
	if Input.is_action_pressed("ui_right"):
		input_vector.x += 1
	if Input.is_action_pressed("ui_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("ui_down"):
		input_vector.y += 1
	if Input.is_action_pressed("ui_up"):
		input_vector.y -= 1
	
	if player != null:
		player.velocity = input_vector.normalized() * speed
		player.move_and_slide()
		if camera != null:
			camera.position = player.position

func set_thrum(intensity: float) -> void:
	thrum_intensity = clamp(intensity, 0.0, 1.0)
