extends Node2D




func _ready():
	$CanvasLayer/MasterVolume_Slider.connect("value_changed", self, "_master_volume_slider_changed");
	$CanvasLayer/MusicVolume_Slider.connect("value_changed", self, "_music_volume_slider_changed");
	$CanvasLayer/Close_Button.connect("button_up", self, "_close_button_pressed");

func _close_button_pressed():
	Globals.toggle_options_menu();

func _master_volume_slider_changed(v):
	var value = float(v)/100.0;
	if $CanvasLayer/MasterVolume_Slider.value < 5:
		AudioServer.set_bus_volume_db(0, -500);
	else:
		AudioServer.set_bus_volume_db(0, -21.5 + (value-0.5)*30);


