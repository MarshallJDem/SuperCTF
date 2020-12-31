extends CanvasLayer


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_tree().connect("screen_resized", self, "_screen_resized");
	_screen_resized();


func _screen_resized():
	var window_size = OS.get_window_size();
	var s;
	# More horizontal than usual
	if window_size.x / window_size.y > 1920.0/1080.0:
		# Clip to height
		s = window_size.y / 1080;
	else:
		s = window_size.x / 1920;
	$Main.rect_scale = Vector2(s,s);
