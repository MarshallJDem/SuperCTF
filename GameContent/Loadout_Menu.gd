extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

onready var Menu = $CanvasLayer/Control/ColorRect;

# Called when the node enters the scene tree for the first time.
func _ready():
	for i in range(1,4):
		Menu.get_node("Weapon" + str(i) + "_Button").connect("button_up", self, "set_weapon_selection", [i]);
	for i in range(1,3):
		Menu.get_node("Ability" + str(i) + "_Button").connect("button_up", self, "set_ability_selection", [i]);
	for i in range(1,3):
		Menu.get_node("Utility" + str(i) + "_Button").connect("button_up", self, "set_utility_selection", [i]);
	
	get_tree().connect("screen_resized", self, "_screen_resized");
	_screen_resized();
	set_weapon_selection(1);
	set_ability_selection(1);
	set_utility_selection(1);

func set_weapon_selection(w):
	for i in range(1,4):
		var alpha = 1.0 if i == w else 0.0;
		Menu.get_node("Weapon" + str(i) + "_Indicator").color = Color(0.35, 0.8, 0.32, alpha);
	if w == 1:
		Globals.current_class = Globals.Classes.Bullet;
	elif w == 2:
		Globals.current_class = Globals.Classes.Laser;
	elif w == 3:
		Globals.current_class = Globals.Classes.Demo;
	Globals.emit_signal("class_changed");

func set_ability_selection(w):
	for i in range(1,3):
		var alpha = 1.0 if i == w else 0.0;
		Menu.get_node("Ability" + str(i) + "_Indicator").color = Color(0.35, 0.8, 0.32, alpha);
	if w == 1:
		Globals.current_ability = Globals.Abilities.Forcefield;
	elif w == 2:
		Globals.current_ability = Globals.Abilities.Camo;
	Globals.emit_signal("ability_changed");

func set_utility_selection(w):
	for i in range(1,3):
		var alpha = 1.0 if i == w else 0.0;
		Menu.get_node("Utility" + str(i) + "_Indicator").color = Color(0.35, 0.8, 0.32, alpha);
	if w == 1:
		Globals.current_utility = Globals.Utilities.Grenade;
	elif w == 2:
		Globals.current_utility = Globals.Utilities.Landmine;
	Globals.emit_signal("utility_changed");

func _screen_resized():
	var window_size = OS.get_window_size();
	var s;
	# More horizontal than usual
	if window_size.x / window_size.y > 1920.0/1080.0:
		# Clip to height
		s = window_size.y / 1080;
	else:
		s = window_size.x / 1920;
	$CanvasLayer/Control.rect_scale = Vector2(s,s);

