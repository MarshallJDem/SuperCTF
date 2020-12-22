extends TextureRect


#Takes player position Vec2, flag home position vec 2, turn_invisible a boolean 
func point_at_home(player_position, home_position, turn_invisible):
	#turn_invisible is a boolean on whether the arraow should be invisible or not
	self.visible = !turn_invisible
	#rotate the arrow towards the home position
	#the -90 makes the end of the arrow face the flag home
	rect_rotation = rad2deg(player_position.angle_to_point(home_position))-90
