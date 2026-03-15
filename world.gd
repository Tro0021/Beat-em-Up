extends Node2D

@onready var player: CharacterBody2D = $ActorsContainer/Player
@onready var camera: Camera2D = $Camera

var camera_locked := false
 
func _ready() -> void:
	StageManager.checkpoint_start.connect(on_checkpoint_start.bind())
	StageManager.checkpoint_end.connect(on_checkpoint_end.bind())

func _process(_delta: float) -> void:
	if not camera_locked and player.position.x > camera.position.x:
		camera.position.x = player.position.x

func on_checkpoint_start() -> void:
	camera_locked = true

func on_checkpoint_end() -> void:
	camera_locked = false
