extends Node2D

# Whether the flag is in its home position
var is_at_home = true;
# Where this flag's home is
var home_position = Vector2(25, 25);
# What team the flag is for. 0 = Blue, 1 = Red.
var team_id = -1;
# The ID of this flag determined by the Server
var flag_id = -1;

func _ready():
	pass

func _process(delta):
	z_index = global_position.y;

# Sets the team id and flag color of this flag using the given id
func set_team(id):
	team_id = id;
	$Blue_Sprite.visible = false;
	$Red_Sprite.visible = false;
	if id == 0:
		$Blue_Sprite.visible = true;
	elif id == 1:
		$Red_Sprite.visible=  true;

# Called by the server to return the flag back to its home position
remotesync func return_home():
	is_at_home = true;
	position = home_position;
	re_parent(get_tree().get_root().get_node("MainScene"));
	if !get_tree().is_network_server():
		var color = "blue" if team_id == 0 else "red";
		var team_name = "BLUE TEAM" if team_id == 0 else "RED TEAM";
		if get_tree().get_root().get_node("MainScene/NetworkController").players[Globals.localPlayerID]["team_id"] == team_id:
			team_name = "YOUR TEAM";
		get_tree().get_root().get_node("MainScene/UI_Layer").set_alert_text("[center][color=" + color + "]" + team_name + "'s[color=black] flag has been returned!");
	# Check if this flag's flag_home is colliding with another player since it has now just gotten its flag back
	var flag_home = null;
	for home in get_tree().get_nodes_in_group("Flag_Homes"):
		if home.flag_id == flag_id:
			flag_home = home;
	assert(flag_home != null)
	# If we're the server check if there is already a player in the flag_home and then recall the collision
	if get_tree().is_network_server():
		for area in flag_home.get_node("Area2D").get_overlapping_areas():
			if area.is_in_group("Player_Bodies"): # If it's a player
				area.collided_with_flag_home(flag_home);

# Reparents this flag so its parent is the given node
func re_parent(new_parent):
	get_parent().call_deferred("remove_child", self);
	new_parent.call_deferred("add_child", self);
