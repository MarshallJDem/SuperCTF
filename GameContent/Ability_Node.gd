extends Node2D

var Forcefield = preload("res://GameContent/Forcefield.tscn");
var Ghost_Trail = preload("res://GameContent/Ghost_Trail.tscn");
var player;
var reduced_cooldown_enabled = false;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_parent();
	set_ability(Globals.current_ability);
	$Camo_Timer.connect("timeout", self, "_camo_timer_ended")

func _process(delta):
	
	if $Camo_Timer.time_left != 0:
		if !player.alive:
			$Camo_Timer.stop();
		else:
			if player.control:
				var m = (sin($Camo_Timer.time_left * 2 * PI * 6) + 1.0)/12.0;
				m += 0.1;
				player.modulate = Color(1,1,1,m);
			var count = 4;
			var spacing = $Camo_Timer.wait_time/count;
			var start = spacing/2.0;
			if int((($Camo_Timer.wait_time - $Camo_Timer.time_left) + start ) / spacing) > camo_flashes_completed:
				camo_flashes_completed += 1;
				spawn_camo_flash();

func _input(event):
	if Globals.is_typing_in_chat or Globals.displaying_loadout:
		return;
	if player.control:
		if event is InputEventKey and event.pressed:
			if event.scancode == KEY_E:
				if $Cooldown_Timer.time_left == 0:
					if Globals.current_ability == Globals.Abilities.Forcefield:
						place_forcefield();
					elif Globals.current_ability == Globals.Abilities.Camo:
						activate_camo();

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
	node.look_direction = player.look_direction;
	node.scale = player.get_node("Sprite_Body").scale
	node.get_node("Sprite_Gun").texture = player.get_node("Sprite_Gun").texture
	node.get_node("Sprite_Gun").z_index = player.get_node("Sprite_Gun").z_index
	node.get_node("Sprite_Head").texture = player.get_node("Sprite_Head").texture
	node.get_node("Sprite_Head").z_index = player.get_node("Sprite_Head").z_index
	node.get_node("Sprite_Body").texture = player.get_node("Sprite_Body").texture
	node.get_node("Sprite_Body").z_index = player.get_node("Sprite_Body").z_index
	node.get_node("Sprite_Legs").texture = player.get_node("Sprite_Legs").texture
	node.get_node("Sprite_Legs").frame = player.get_node("Sprite_Legs").frame
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
	rpc("spawn_forcefield", player.position, player.team_id);
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
remotesync func spawn_forcefield(pos, team_id):
	var forcefield = Forcefield.instance();
	forcefield.position = pos;
	forcefield.player_id = player.player_id;
	forcefield.team_id = team_id;
	get_tree().get_root().get_node("MainScene").add_child(forcefield);
