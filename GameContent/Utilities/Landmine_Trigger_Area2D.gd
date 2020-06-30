extends Area2D

# Called when the node enters the scene tree for the first time.
func _ready():
	var _err = self.connect("area_entered",self, "_area_entered");

# Called when this area enters another area
func _area_entered(body):
	# if we aren't the server, ignore
	if !Globals.testing and !get_tree().is_network_server():
		return;
	if body.is_in_group("Player_Bodies"):
		collided_with_player(body.get_parent());

# Called when this bullet collides with a wall
func collided_with_player(player):
	var mine = get_parent();
	# If mine and player are on same team, ignore
	if mine.team_id == player.team_id:
		return;
	if Globals.testing:
		mine.start_detonation();
	mine.rpc("start_detonation");
