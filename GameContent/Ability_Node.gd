extends Node2D

var Forcefield = preload("res://GameContent/Forcefield.tscn");
var Ghost_Trail = preload("res://GameContent/Ghost_Trail.tscn");
var player;
var reduced_cooldown_enabled = false;
# How many saved up ability uses this palyer has (No cooldown required after using one)
var ability_stacks = 0;
# 100 = %100
var ult_charge = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_parent();
	set_ability(Globals.current_ability);
	$Camo_Timer.connect("timeout", self, "_camo_timer_ended")
	$Ult_Charge_Timer.connect("timeout", self, "_ult_charge_timer_ended");
	$Ult_Timer.connect("timeout", self, "_ult_timer_ended");

func _process(delta):
	if !player.alive:
		$Camo_Timer.stop();
		$Cooldown_Timer.stop();
	
	if $Camo_Timer.time_left != 0:
		# If this is our local, in control player
		if player.control:
			var m = (sin($Camo_Timer.time_left * 2 * PI * 6) + 1.0)/24.0;
			#m += 0.1;
			player.modulate = Color(1,1,1,m);
		var count = 4;
		var spacing = $Camo_Timer.wait_time/count;
		var start = spacing/2.0;
		if int((($Camo_Timer.wait_time - $Camo_Timer.time_left) + start ) / spacing) > camo_flashes_completed:
			camo_flashes_completed += 1;
			spawn_camo_flash();
	
	if ult_charge > 100:
		ult_charge = 100;

func _input(event):
	if Globals.is_typing_in_chat:
		return;
	if player.control:
		if event is InputEventKey and event.pressed:
			if event.scancode == KEY_E:
				ability_pressed();
			if event.scancode == KEY_Q:
				ult_pressed();
			if event.scancode == KEY_P and (Globals.testing or Globals.allowCommands):
				#$Ult_Timer.start();
				ult_charge = 100;
				#player.get_node("Weapon_Node").ult_active = true;
func ability_pressed():
	if $Cooldown_Timer.time_left == 0 || ability_stacks > 0:
		if $Cooldown_Timer.time_left != 0 && ability_stacks > 0:
			ability_stacks += -1;
		if Globals.current_ability == Globals.Abilities.Forcefield:
			place_forcefield();
		elif Globals.current_ability == Globals.Abilities.Camo:
			activate_camo();
func ult_pressed():
	if ult_charge >= 100:
		$Ult_Timer.start();
		ult_charge = 0;
		player.get_node("Weapon_Node").ult_active = true;
		#emit fire behind player of the color of the player's team
		if Globals.testing:
			player.get_node("Fire_Particles")._start(player.team_id)
		else:
			player.get_node("Fire_Particles").rpc("_start", player.team_id)
		
func _ult_charge_timer_ended():
	var previous_charge = ult_charge;
	ult_charge += 1;
	if ult_charge >= 100:
		if previous_charge < 100:
			if player.player_id == Globals.localPlayerID:
				get_tree().get_root().get_node("MainScene/UI_Layer").set_alert_text("[center][rainbow]ULT READY");
		ult_charge = 100;
func _ult_timer_ended():
	player.get_node("Weapon_Node").ult_active = false;
	#stop fire behind player
	player.get_node("Fire_Particles").rpc("_stop")

func set_ability(a):
	Globals.current_ability = a;
	$Cooldown_Timer.stop();
	if Globals.current_ability == Globals.Abilities.Forcefield:
		$Cooldown_Timer.wait_time = float(get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("forcefieldCooldown"))/1000.0;
	elif Globals.current_ability == Globals.Abilities.Camo:
		$Cooldown_Timer.wait_time = 6;

func _camo_timer_ended():
	player.modulate = Color(1,1,1,1);

func spawn_camo_flash():
	var node = Ghost_Trail.instance();
	node.position = player.position;
	node.add_child(get_parent().get_node("Player_Visuals").duplicate());
	if player.has_flag():
		if player.team_id == 1:
			node.flag_team_id = 0;
		else:
			node.flag_team_id = 1;
	get_tree().get_root().get_node("MainScene").add_child(node);  
	node.get_node("Death_Timer").start((10) * 0.05 + 0.0001);

var camo_flashes_completed = 0;
func activate_camo():
	$Cooldown_Timer.wait_time = float(get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("camoCooldown"))/1000.0;
	if reduced_cooldown_enabled:
		$Cooldown_Timer.wait_time = $Cooldown_Timer.wait_time / 2.0;
	$Cooldown_Timer.start();
	if Globals.testing:
		__activate_camo();
	else:
		rpc("__activate_camo");


remotesync func __activate_camo():
	$Camo_Timer.start();
	if !player.control:
		player.modulate = Color(0,0,0,0);
	camo_flashes_completed = 0;



# Called when the player attempts to place a forcefield
# This function will either place it in the appropriate spot or deny it (bad location or something)
func place_forcefield():
	if !Globals.testing:
		rpc("spawn_forcefield", player.position, player.team_id, OS.get_system_time_msecs() - Globals.match_start_time);
	$Cooldown_Timer.wait_time = float(get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("forcefieldCooldown"))/1000.0;
	if reduced_cooldown_enabled:
		$Cooldown_Timer.wait_time = $Cooldown_Timer.wait_time / 2.0;
	$Cooldown_Timer.start();
	if Globals.testing:
		var forcefield = Forcefield.instance();
		forcefield.position = player.position;
		forcefield.team_id = player.team_id;
		get_tree().get_root().get_node("MainScene").add_child(forcefield);

# Called by client telling everyone to spawn a forcefield in a spot
# TODO - in future this should be handled by servers - not the client.
remotesync func spawn_forcefield(pos, team_id, time_placed):
	var forcefield = Forcefield.instance();
	forcefield.position = pos;
	forcefield.player_id = player.player_id;
	forcefield.team_id = team_id;
	forcefield.original_time_placed = time_placed;
	get_tree().get_root().get_node("MainScene").add_child(forcefield);
