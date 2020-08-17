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
	# Else If this is this player's flag and it's away from home, return it home
	elif !flag.is_at_home and flag.team_id == player.team_id:
		flag.rpc("return_home");
		return;
	# Else if this is this player's enemy's flag
	elif flag.team_id != player.team_id:
		if Globals.testing:
			player.receive_take_flag(flag.flag_id);
		else:
			player.rpc("receive_take_flag", flag.flag_id);

