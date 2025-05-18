extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.play("Armature|Apatosaurus_Walk")
	$idle_timer.start(0.1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_idle_timer_timeout() -> void:
	$AnimationPlayer.play("Armature|Apatosaurus_Walk")
	$idle_timer.start(0.1)
