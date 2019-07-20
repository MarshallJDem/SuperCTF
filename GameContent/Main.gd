extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
	if !Globals.testing:
		$Test_Player.queue_free();
