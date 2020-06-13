extends Position2D
	
func _process(delta):
	if get_parent().IS_CONTROLLED_BY_MOUSE:
		rotate_to_mouse();
		update_camera_offset_from_mouse();
	else:
		rotate_to_arrow_keys();
		update_camera_offset_from_arrow_keys();

# Rotates this pivot point to look at the mouse position
func rotate_to_mouse():
	var mpos = get_global_mouse_position();
	look_at(mpos);

# Rotates this pivot point to look in the direction of the arrow keys
func rotate_to_arrow_keys():
	var input = Vector2(0,0);
	input.x = (1 if Input.is_key_pressed(KEY_RIGHT) else 0) - (1 if Input.is_key_pressed(KEY_LEFT) else 0)
	input.y = (1 if Input.is_key_pressed(KEY_DOWN) else 0) - (1 if Input.is_key_pressed(KEY_UP) else 0)
	var imaginary_mouse_pos = get_parent().position + input;
	look_at(imaginary_mouse_pos);

# Determines how far the camera should be offset depending on how far the mouse is from center of viewport
func update_camera_offset_from_mouse():
	var mpos2 = get_viewport().get_mouse_position();
	var distance = sqrt(pow(mpos2.x - get_viewport_rect().size.x/2,2) + pow(mpos2.y - get_viewport_rect().size.y/2,2));
	var modifier = 0.03;
	$'..'.camera_ref.smoothing_speed = 10;
	if Input.is_key_pressed(KEY_SHIFT):
		$'..'.camera_ref.smoothing_speed = 5;
		modifier *= 8;
	$'..'.camera_ref.position.x = distance * modifier;
	
func update_camera_offset_from_arrow_keys():
	var input = Vector2(0,0);
	input.x = (1 if Input.is_key_pressed(KEY_RIGHT) else 0) - (1 if Input.is_key_pressed(KEY_LEFT) else 0)
	input.y = (1 if Input.is_key_pressed(KEY_DOWN) else 0) - (1 if Input.is_key_pressed(KEY_UP) else 0)
	
	if input == Vector2.ZERO:
		$'..'.camera_ref.position.x = 0;
	else:
		$'..'.camera_ref.position.x = 100;
	
	# Override just disable this feature:
	$'..'.camera_ref.position.x = 0;
	
