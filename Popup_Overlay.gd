extends Node2D

var text = "A serious error with code 0921 occurred. Please report this to us on discord!";

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var err = $CanvasLayer/Close_Button.connect("pressed", self, "_close_pressed");
	$CanvasLayer/Menu/Main_Text.bbcode_text = "[center][color=black]" + text;


func _close_pressed():
	self.queue_free();
