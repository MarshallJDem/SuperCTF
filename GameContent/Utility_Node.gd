extends Node2D

var Grenade = preload("res://GameContent/Grenade.tscn");
var Landmine = preload("res://GameContent/Utilities/Landmine.tscn");

var player;

# Whether the grenade weapon is currently being aimed
var aiming_grenade = false;

# The number of landmines this player has placed. Used for naming
var landmines_placed = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_parent();
	Globals.connect("utility_changed", self, "_utility_changed");

func _utility_changed():
	pass;

func utility_pressed():
	if $Cooldown_Timer.time_left == 0:
		if Globals.current_utility == Globals.Utilities.Grenade:
			aiming_grenade = true;

func utility_released(pos):
	if Globals.current_utility == Globals.Utilities.Grenade:
		if aiming_grenade:
			# Fire grenade on right mouse up
			if Globals.testing:
				shoot_grenade(pos, OS.get_system_time_msecs());
			else:
				rpc("shoot_grenade",pos, OS.get_system_time_msecs() - Globals.match_start_time);
	elif Globals.current_utility == Globals.Utilities.Landmine:
		if $Cooldown_Timer.time_left == 0:
			if Globals.active_landmines < 3:
				if Globals.testing:
					place_landmine(player.position,landmines_placed);
				else:
					rpc("place_landmine",player.position,landmines_placed);
			else:
				get_tree().get_root().get_node("MainScene/UI_Layer").set_alert_text("[center][color=red]Active landmine limit reached!");


func _process(delta):
	if !player.alive:
		$Cooldown_Timer.stop();
	if !player.control:
		return;
	update();
	if Globals.is_typing_in_chat:
		return;
	if Input.is_action_just_pressed("clickR"):
		utility_pressed();
	if Input.is_action_pressed("clickR"):
		pass;
	if Input.is_action_just_released("clickR"):
		utility_released(get_global_mouse_position());
func _draw():
	if aiming_grenade and Globals.control_scheme != Globals.Control_Schemes.touchscreen:
		draw_circle(get_local_mouse_position(), get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("grenadeRadius"), Color(0,0,0,0.2));
		draw_circle(get_local_mouse_position(), get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("grenadeRadius")/10, Color(0,0,0,0.2));

func _input(event):
	if !player.control:
		return;
	if Globals.is_typing_in_chat:
		return;

remotesync func place_landmine(pos, mines_placed):
	$Cooldown_Timer.wait_time = float(get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("landmineCooldown"))/1000.0;
	$Cooldown_Timer.start();
	var mine = Landmine.instance();
	mine.position = pos;
	mine.position.y += 13;
	mine.team_id = player.team_id;
	mine.player_id = player.player_id;
	mine.name = mine.name + "-" + str(player.player_id) + "-" + str(mines_placed);
	landmines_placed += 1;
	if Globals.testing or player.player_id == Globals.localPlayerID:
		Globals.active_landmines += 1;
	get_tree().get_root().get_node("MainScene").call_deferred("add_child", mine);

remotesync func shoot_grenade(target_pos, time_shot):
	aiming_grenade = false;
	$Cooldown_Timer.wait_time = float(get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("grenadeCooldown"))/1000.0;
	$Cooldown_Timer.start();
	var node = Grenade.instance();
	node.initial_real_pos = player.position;
	node.target_pos = target_pos;
	node.initial_time_shot = time_shot;
	node.player_id = player.player_id;
	node.team_id = player.team_id;
	get_tree().get_root().get_node("MainScene").call_deferred("add_child", node);
