extends Node2D



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$CanvasLayer/Button.connect("button_up", self, "_button_clicked");

func _button_clicked():
	Globals.toggle_options_menu();


