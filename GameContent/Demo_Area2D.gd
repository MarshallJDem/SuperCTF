extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready():
	var _err = self.connect("area_entered",self, "_area_entered");

# Called when this area enters another area
func _area_entered(body):
	if body.is_in_group("Player_Bodies"):
		collided_with_player(body.get_parent());
	if body.is_in_group("Forcefield_Bodies"):
		return;
		#collided_with_forcefield(body.get_parent());

# Called when this node collides with a player
func collided_with_player(player):
	# If this bullet was shot by the same team, ignore it
	if get_parent().team_id == player.team_id:
		return;
	if get_tree().is_network_server():
		get_parent().rpc("detonate", true);
	else:
		pass;
		#get_parent().call_deferred("detonate");

# Called when this node collides with a forcefield
func collided_with_forcefield(forcefield):
	if Globals.testing:
		get_parent().detonate(true);
	if get_tree().is_network_server():
		get_parent().rpc("detonate", true);
