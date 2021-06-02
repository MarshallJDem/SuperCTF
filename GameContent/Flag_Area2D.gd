extends Area2D

# The id of the player who dropped it last, used so that it doesn't pick back up right after dropping
var player_id_drop_buffer = -2;

# If true, ignores the next buffer reset
var ignore_next_buffer_reset = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	var _err = self.connect("area_entered",self, "_area_entered");
	_err = self.connect("area_exited",self, "_area_exited");

# Called when this area enters another area
func _area_entered(body):
	
	# If the round is not running, ignore collision
	if !Globals.testing and !get_tree().get_root().get_node("MainScene/NetworkController").round_is_running:
		return;
	# Only detect collisions if we are the server
	if Globals.testing or get_tree().is_network_server():
		if body.is_in_group("Player_Bodies"):
			collided_with_player(body.get_parent());

# Called when this area exits another area
func _area_exited(body):
	# Only detect collisions if we are the server
	if Globals.testing or get_tree().is_network_server():
		if body.is_in_group("Player_Bodies"):
			if body.get_parent().player_id == player_id_drop_buffer:
				if ignore_next_buffer_reset:
					ignore_next_buffer_reset = false;
					return;
				player_id_drop_buffer = -2;

# Called when this flag collides with a player
func collided_with_player(player):
	var flag = get_parent();
	# If this flag is already in another player's posession, ignore it
	if get_parent().get_parent().name == "Flag_Holder":
		return;
	# If the player just dropped this flag, ignore it
	if player.player_id == player_id_drop_buffer:
		return;
	# If the player is not alive, ignore it
	if !player.alive:
		return;
	# If this is this player's flag and it already safe, then ignore it
	if flag.is_at_home and flag.team_id == player.team_id:
		return
	# If the player is currently firing a laser. ignore it
	if player.get_node("Weapon_Node/Laser_Timer").time_left != 0:
		return;
	# If this is this player's flag and it's away from home, return it home
	if !flag.is_at_home and flag.team_id == player.team_id:
		# Do it only if this is not a sudden death
		if !get_tree().get_root().get_node("MainScene/NetworkController").isSuddenDeath:
			player.stats["recovers"] += 1;
			flag.rpc("return_home");
			return;
		else: # SUDDEN DEATH, you cannot recover. Give a warning
			flag.rpc("enable_warning" , "[center]Can't recover in\nSudden Death");
	# Else if this is this player's enemy's flag
	if flag.team_id != player.team_id:
		if Globals.testing:
			player.receive_take_flag(flag.flag_id);
		else:
			player.rpc("receive_take_flag", flag.flag_id);

