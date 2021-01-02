extends TextureRect

#starting poistion from player 
export var starting_distance = Vector2(-5, -53)
export var arrow_speed = 10
#the minimum distance the arrow can be form the flag home
export var flag_home_boundary = Vector2(50, 50)
export var player_boundary = Vector2(50, 50)
#export var distance_to_home = 0

#angle from player to flag home in degrees
var angle_to_home = 0.0


func _ready() -> void:
	#set home pointer to its starting point
	rect_position = starting_distance


#Points towards flag home using: player position Vec2, flag home position Vec2
func _point_at_home(player_position, home_position):
	#rotate the arrow towards the home position
	#the -90 makes the end of the arrow face the flag home
	angle_to_home = rad2deg(player_position.angle_to_point(home_position))
	rect_rotation = angle_to_home-90
	


#moves the arrow by a distance along the arrows local y axis (positive is towards the flag home)
func _change_distance_from_player(distance_to_move):
	var vector_to_travel = Vector2(cos(angle_to_home) * distance_to_move, sin(angle_to_home) * distance_to_move)
	rect_position += vector_to_travel
	
func _get_distance_to_home(player_position, home_position):
	return((home_position - (player_position + rect_position)).length())

func _move_arrow(player_position, home_position, delta, towards_flag):
	var distance_to_home = _get_distance_to_home(player_position, home_position)
	if towards_flag:
		if distance_to_home > flag_home_boundary.length():
			_change_distance_from_player(delta * arrow_speed)
	else:
		if rect_position.length() > player_boundary.length()  :
			_change_distance_from_player(delta * arrow_speed * -1)
			
