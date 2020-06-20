extends Node2D


func _ready():
	$CanvasLayer/Control/MasterVolume_Slider.connect("value_changed", self, "_master_volume_slider_changed");
	$CanvasLayer/Control/MusicVolume_Slider.connect("value_changed", self, "_music_volume_slider_changed");
	$CanvasLayer/Control/Close_Button.connect("button_up", self, "_close_button_pressed");
	$CanvasLayer/Control/MasterVolume_Slider.value = Globals.volume_sliders.x;
	$CanvasLayer/Control/MusicVolume_Slider.value = Globals.volume_sliders.y;
	get_tree().connect("screen_resized", self, "_screen_resized");
	_screen_resized();

func _screen_resized():
	if Globals.options_menu_should_scale:
		var window_size = OS.get_window_size();
		var s;
		# More horizontal than usual
		if window_size.x / window_size.y > 1920.0/1080.0:
			# Clip to height
			s = window_size.y / 1080;
		else:
			s = window_size.x / 1920;
		$CanvasLayer/Control.rect_scale = Vector2(s,s);

func _close_button_pressed():
	Globals.toggle_options_menu();

func _master_volume_slider_changed(v):
	var value = float(v)/100.0;
	
	Globals.volume_sliders.x =v;
	if v < 5:
		AudioServer.set_bus_volume_db(0, -500);
	else:
		AudioServer.set_bus_volume_db(0, -21.5 + (value-0.5)*30);
func _music_volume_slider_changed(v):
	var value = float(v)/100.0;
	Globals.volume_sliders.y =v;
	if v < 5:
		AudioServer.set_bus_volume_db(1, -500);
	else:
		AudioServer.set_bus_volume_db(1, (value-0.5)*30);


