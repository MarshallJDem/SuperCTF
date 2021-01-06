extends Node2D

export var arrow_speed = 2000
#the minimum distance the arrow can be to the flag home
export var flag_home_boundary = 40
#the minimum distance the arrow can be to the player
export var player_boundary = 40
#export var distance_to_home = 0
var Arrow 

#Position that the arrow moves towards
var target_position = Vector2(0,0);


func _ready() -> void:
	#set home pointer to its starting point
	Arrow = $Home_Pointer


#Points towards flag home using: player position Vec2, flag home position Vec2
func _point_at_home(player_position, home_position):
	#rotate the arrow towards the home position
	#the -PI/2 makes the end of the arrow face the flag home
	Arrow.rotation = player_position.angle_to_point(home_position) - PI/2;


func _move_arrow(player_position, home_position, delta, home_visible):
	
	if home_visible:
		#Target position is on top of the flag home
		target_position = (home_position - player_position);
		#minus a multiple of the normalized version of this vector so it stays flag_home_boundary pixels away
		target_position = target_position - (target_position.normalized()) * flag_home_boundary;
	else:
		var angle = player_position.angle_to_point(home_position);
		target_position = -Vector2(cos(angle)*player_boundary, sin(angle)*player_boundary);
	
	# Get the distance from where we are now to where we want to be
	var distance = (target_position - self.position).length();
	
	# Figure out what percentage of the distance we need to travel (basically our speed / the total distance gives us a percentage of the total distance we should travel)
	var t = 1.0;
	# Checking this makes sure that t will be 1.0 if we would have overshot
	if delta * arrow_speed < distance:
		t = (delta * arrow_speed)/distance;
	
	# Travel t percentage from where we are to where we want to go.
	var new_pos = lerp(self.position, target_position, t);
	self.position = new_pos;
