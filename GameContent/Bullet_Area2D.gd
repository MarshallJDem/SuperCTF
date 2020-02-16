extends Area2D

var flagged_for_death = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	var _err = self.connect("area_entered",self, "_area_entered");

# Called when this area enters another area
func _area_entered(body):
	print("Bullet_ENTERED");
	if flagged_for_death:
		return;
	if body.is_in_group("Wall_Bodies"):
		collided_with_wall(body.get_parent());
	elif body.is_in_group("Bullet_Bodies"):
		collided_with_bullet(body.get_parent());
	elif body.is_in_group("Laser_Bodies"):
		collided_with_laser(body.get_parent());

# Called when this bullet collides with a wall
func collided_with_wall(_wall):
	if !Globals.testing && get_tree().is_network_server():
		get_parent().call_deferred("rpc", "receive_death");
		flagged_for_death = true;
	else:
		get_parent().call_deferred("preliminary_death");

# Called when this bullet collides with another bullet
func collided_with_bullet(bullet):
	# If this bullet was shot by the same team, ignore it
	if get_parent().team_id == bullet.team_id:
		return;
	if get_tree().is_network_server():
		get_parent().call_deferred("rpc", "receive_death");
		flagged_for_death = true;
	else:
		get_parent().call_deferred("preliminary_death");

# Called when the bullet collides with a laser
func collided_with_laser(laser):
	# If this laser was shot by anybody on the same team as this bullet, ignore the collision
	if laser.team_id == get_parent().team_id:
		return;
	if get_tree().is_network_server():
		flagged_for_death = true;
	else:
		get_parent().call_deferred("preliminary_death");

## Tells all clients to kill the bullet
#func call_death():
#	print("CALL_DEATH")
#	if get_tree().is_network_server():
#		get_parent().rpc("receive_death");
