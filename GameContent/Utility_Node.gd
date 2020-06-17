extends Node2D

var Grenade = preload("res://GameContent/Grenade.tscn");
var Landmine = preload("res://GameContent/Utilities/Landmine.tscn");

# Utilities
enum Utilities {Grenade, Landmine};
var utility = Utilities.Landmine;

var player;

# Whether the grenade weapon is currently being aimed
var aiming_grenade = false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_parent();

func _process(delta):
	if !player.control:
		return;
	if Input.is_action_just_pressed("clickR"):
		if $Cooldown_Timer.time_left == 0:
			if utility == Utilities.Grenade:
				aiming_grenade = true;
	if Input.is_action_pressed("clickR"):
		pass;
	if Input.is_action_just_released("clickR"):
		if utility == Utilities.Grenade:
			if aiming_grenade:
				# Fire grenade on right mouse up
				if Globals.testing:
					shoot_grenade(get_global_mouse_position(), OS.get_system_time_msecs());
				else:
					rpc("shoot_grenade",get_global_mouse_position(), OS.get_system_time_msecs() - Globals.match_start_time);
		elif utility == Utilities.Landmine:
			if Globals.testing:
				place_landmine();
			else:
				rpc("place_landmine");
			
	update();

func _draw():
	if aiming_grenade:
		draw_circle(get_local_mouse_position(), get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("grenadeRadius"), Color(0,0,0,0.2));
		draw_circle(get_local_mouse_position(), get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("grenadeRadius")/10, Color(0,0,0,0.2));

func _input(event):
	if !player.control:
		return;
	if Globals.is_typing_in_chat:
		return;

remotesync func place_landmine():
	$Cooldown_Timer.start();
	var mine = Landmine.instance();
	mine.position = player.position;
	mine.team_id = 1;
	mine.player_id = 1;
	get_tree().get_root().get_node("MainScene").call_deferred("add_child", mine);

remotesync func shoot_grenade(target_pos, time_shot):
	aiming_grenade = false;
	$Cooldown_Timer.start();
	var node = Grenade.instance();
	node.initial_real_pos = player.position;
	node.target_pos = target_pos;
	node.initial_time_shot = time_shot;
	node.player_id = player.player_id;
	node.team_id = player.team_id;
	get_tree().get_root().get_node("MainScene").call_deferred("add_child", node);
