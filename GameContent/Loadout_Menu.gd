extends Node2D

var camo_R = preload("res://Assets/GUI/camo_GUI_R.png");
var camo_B = preload("res://Assets/GUI/camo_GUI_B.png");

var grenade_B = preload("res://Assets/Utilities/grenade_B.png");
var grenade_R = preload("res://Assets/Utilities/grenade_R.png");

var landmine_B = preload("res://Assets/Utilities/landmine_B.png");
var landmine_R = preload("res://Assets/Utilities/landmine_R.png");

var forcefield_B = preload("res://Assets/GUI/forcefield_B.png");
var forcefield_R = preload("res://Assets/GUI/forcefield_R.png");

var bullet_gun_B = preload("res://Assets/Player/gunner_gun_B.png");
var bullet_gun_R = preload("res://Assets/Player/gunner_gun_R.png");

var demo_gun_B = preload("res://Assets/Player/demo_gun_B.png");
var demo_gun_R = preload("res://Assets/Player/demo_gun_R.png");

var laser_gun_B = preload("res://Assets/Player/laser_gun_B.png");
var laser_gun_R = preload("res://Assets/Player/laser_gun_R.png");

onready var Menu = $CanvasLayer/Control/ColorRect;
var hidden = false;

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

func _process(delta):
	if Globals.localPlayerTeamID == 0:
		Menu.get_node("Weapon1").set_texture(bullet_gun_B);
		Menu.get_node("Weapon2").set_texture(laser_gun_B);
		Menu.get_node("Weapon3").set_texture(demo_gun_B);
		Menu.get_node("Ability1").set_texture(forcefield_B);
		Menu.get_node("Ability2").set_texture(camo_B);
		Menu.get_node("Utility1").set_texture(grenade_B);
		Menu.get_node("Utility2").set_texture(landmine_B);
	else:
		Menu.get_node("Weapon1").set_texture(bullet_gun_R);
		Menu.get_node("Weapon2").set_texture(laser_gun_R);
		Menu.get_node("Weapon3").set_texture(demo_gun_R);
		Menu.get_node("Ability1").set_texture(forcefield_R);
		Menu.get_node("Ability2").set_texture(camo_R);
		Menu.get_node("Utility1").set_texture(grenade_R);
		Menu.get_node("Utility2").set_texture(landmine_R);
	
	$CanvasLayer/Control.visible = !hidden and (Globals.displaying_loadout or Globals.testing);
	

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
	if !Globals.testing:
		get_tree().get_root().get_node("MainScene/NetworkController").rpc_id(1, "player_class_changed", Globals.current_class);
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

