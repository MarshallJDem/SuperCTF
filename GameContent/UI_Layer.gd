extends CanvasLayer

func _ready():
	var _err = $Leave_Match_Button.connect("pressed", self, "_leave_match_button_pressed");

func _process(delta):
	if Globals.isServer:
		return;
	if Input.is_key_pressed(KEY_E):
		$"Ability_GUIs/Forcefield_GUI".frame = 1;
	else:
		$"Ability_GUIs/Forcefield_GUI".frame = 0;
	if Input.is_key_pressed(KEY_SPACE):
		$"Ability_GUIs/Teleport_GUI".frame = 1;
	else:
		$"Ability_GUIs/Teleport_GUI".frame = 0;
	
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		$"Ability_GUIs/Bullet_GUI".frame = 1;
	else:
		$"Ability_GUIs/Bullet_GUI".frame = 0;
	if Input.is_mouse_button_pressed(BUTTON_RIGHT):
		$"Ability_GUIs/Laser_GUI".frame = 1;
	else:
		$"Ability_GUIs/Laser_GUI".frame = 0;
	
	var local_player;
	if Globals.testing:
		local_player = get_tree().get_root().get_node("MainScene/Test_Player");
	else:
		local_player  = get_tree().get_root().get_node("MainScene/Players/" + str(get_tree().get_network_unique_id()));
	if local_player != null:
		# Teleport button
		var teleport_time_left = local_player.get_node("Teleport_Timer").time_left;
		var teleport_wait_time = local_player.get_node("Teleport_Timer").wait_time;
		if teleport_time_left == 0:
			$Ability_GUIs/Teleport_GUI_Text.text = "DASH";
			$Ability_GUIs/Teleport_GUI.modulate = Color(1,1,1,1);
		else:
			$Ability_GUIs/Teleport_GUI_Text.text = "%0.2f" % teleport_time_left;
			$Ability_GUIs/Teleport_GUI.modulate = Color(1,1,1,0.2 + 0.4 * ((teleport_wait_time - teleport_time_left) / teleport_wait_time) );
			
		# Forcefield button
		var ff_time_left = local_player.get_node("Forcefield_Timer").time_left;
		var ff_wait_time = local_player.get_node("Forcefield_Timer").wait_time;
		
		if ff_time_left == 0:
			$Ability_GUIs/Forcefield_GUI_Text.text = "BLOCKER";
			$Ability_GUIs/Forcefield_GUI.modulate = Color(1,1,1,1);
		else:
			$Ability_GUIs/Forcefield_GUI_Text.text = "%0.2f" % ff_time_left;
			$Ability_GUIs/Forcefield_GUI.modulate = Color(1,1,1,0.2 + 0.4 * ((ff_wait_time - ff_time_left) / ff_wait_time) );
		
		# Laser button
		var laser_time_left = local_player.get_node("Laser_Timer").time_left;
		var laser_wait_time = local_player.get_node("Laser_Timer").wait_time;
		if laser_time_left == 0:
			$Ability_GUIs/Laser_GUI_Text.text = "FIRE LASER";
			$Ability_GUIs/Laser_GUI.modulate = Color(1,1,1,1);
		else:
			$Ability_GUIs/Laser_GUI_Text.text = "%0.2f" % laser_time_left;
			$Ability_GUIs/Laser_GUI.modulate = Color(1,1,1,0.2 + 0.4 * ((laser_wait_time - laser_time_left) / laser_wait_time) );
		
		
		
		# If player is holding a flag
		if local_player.get_node("Flag_Holder").get_child_count() > 0:
			$Ability_GUIs/Teleport_GUI.modulate = Color(1,1,1,0.4);
			$Ability_GUIs/Forcefield_GUI.modulate = Color(1,1,1,0.4);

# Color 0 = blue, 1 = red
func set_big_label_text(text, color):
	clear_big_label_text();
	if color == 0:
		$Big_Label_Blue.text = text;
	if color == 1:
		$Big_Label_Red.text = text;
# Clears the text in the big labels
func clear_big_label_text():
	$Big_Label_Blue.text = "";
	$Big_Label_Red.text = "";
# Sets the score label values
func set_score_text(team0_score, team1_score):
	$Score_Label.bbcode_text = "[center]" + "[color=#4C70BA]" + str(team0_score) + "[/color]" + "-" + "[color=#FF0000]" + str(team1_score) + "[/color]" + "[/center]";
	
func enable_leave_match_button():
	$Leave_Match_Button.visible = true;

func _leave_match_button_pressed():
	print("pressed");
	get_tree().get_root().get_node("MainScene/NetworkController").leave_match();
	
