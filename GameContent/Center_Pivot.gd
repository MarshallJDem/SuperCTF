extends Position2D
	
func _process(delta):
	rotate_to_mouse();
	update_camera_offset();

# Rotates this pivot point to look at the mouse position
func rotate_to_mouse():
	var mpos = get_global_mouse_position();
	look_at(mpos);

# Determines how far the camera should be offset depending on how far the mouse is from center of viewport
func update_camera_offset():
	var mpos2 = get_viewport().get_mouse_position();
	var distance = sqrt(pow(mpos2.x - get_viewport_rect().size.x/2,2) + pow(mpos2.y - get_viewport_rect().size.y/2,2));
	$'..'.camera_ref.position.x = distance * 0.1;
	

