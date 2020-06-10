extends Node2D



var Forcefield = preload("res://GameContent/Forcefield.tscn");
var player;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	player = get_parent();
	$Forcefield_Timer.connect("timeout", self, "_forcefield_timer_ended");
	pass # Replace with function body.

func _process(delta):
	$Forcefield_Timer.wait_time = float(get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("forcefieldCooldown"))/1000.0;

func _input(event):
	if Globals.is_typing_in_chat:
		return;
	if player.control:
		if event is InputEventKey and event.pressed:
			if event.scancode == KEY_E:
				# If were not holding a flag, create forcefield
				# This is now disabled. You can place forcefield whenever you please kiddo
				if true || player.get_node("Flag_Holder").get_child_count() == 0:
					if $Forcefield_Timer.time_left == 0:
						forcefield_placed();



# Called when the player attempts to place a forcefield
# This function will either place it in the appropriate spot or deny it (bad location or something)
func forcefield_placed():
	rpc("spawn_forcefield", player.position, player.team_id);
	$Forcefield_Timer.start();
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
