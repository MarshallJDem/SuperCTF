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

var arrow_animation_t = 0.0;

func _update_arrow(player_position, home_position, delta):
	
	# Animate bounce
	arrow_animation_t += delta;
	player_boundary = 40 + (sin(2 * PI * arrow_animation_t) * 2);
	
	# Determine pos
	var angle = player_position.angle_to_point(home_position);
	self.position = -Vector2(cos(angle)*player_boundary, sin(angle)*player_boundary);
	
	# Determine alpha
	var total_dist = (home_position - player_position).length()
	var alpha = 1.0;
	if total_dist > 175:
		alpha = 1.0;
	elif total_dist <= 125:
		alpha = 0.0;
	else:
		alpha = (total_dist - 125)/50;
	if alpha > 0.8:
		alpha = 0.8
	self.modulate = Color(1.0,1.0,1.0,alpha);
	
