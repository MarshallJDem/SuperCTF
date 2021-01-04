extends Control

#starting poistion from player 
export var starting_distance = Vector2(-5, -53)
export var arrow_speed = 3000
export var arrow_correction_speed = 150
#the minimum distance the arrow can be to the flag home
export var flag_home_boundary = 50
#the minimum distance the arrow can be to the player
export var player_boundary = 100
#export var distance_to_home = 0
var Arrow 
#angle from player to flag home in degrees
var angle_to_home = 0.0


func _ready() -> void:
	#set home pointer to its starting point
	Arrow = $Home_Pointer
	Arrow.rect_position = starting_distance


#Points towards flag home using: player position Vec2, flag home position Vec2
func _point_at_home(player_position, home_position):
	#rotate the arrow towards the home position
	#the -90 makes the end of the arrow face the flag home
	angle_to_home = rad2deg(player_position.angle_to_point(home_position))
	rect_rotation = angle_to_home-90
	


#moves the arrow by a distance along the arrows local y axis (positive is towards the flag home)
func _change_distance_from_player(distance_to_move):
	Arrow.rect_position.y -= distance_to_move
	
func _get_distance_to_home(player_position, home_position):
	print((home_position - player_position).length() + Arrow.rect_position.y)
	return((home_position - player_position).length() + Arrow.rect_position.y)

func _move_arrow(player_position, home_position, delta, towards_flag):
	var distance_to_home = _get_distance_to_home(player_position, home_position)
	if towards_flag:
		#if distance_to_home > flag_home_boundary:
		#	_change_distance_from_player(delta * arrow_correction_speed)
		#elif distance_to_home < flag_home_boundary -60:
		#	_change_distance_from_player(delta * arrow_speed * 10 * -1)
		#elif distance_to_home < flag_home_boundary -10:
		_change_distance_from_player(delta * arrow_speed * (distance_to_home) * 0.0025 -1)
		
	else:
		if Arrow.rect_position.length() > player_boundary:
			_change_distance_from_player(delta * arrow_speed * -1)
			
