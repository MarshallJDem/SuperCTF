extends CanvasLayer

var start_time = OS.get_system_time_secs();


func _ready():
	var _err = $Leave_Match_Button.connect("pressed", self, "_leave_match_button_pressed");
	_err = $Cancel_Button.connect("pressed", self, "_cancel_button_pressed");
	get_tree().connect("screen_resized", self, "_screen_resized");
	_screen_resized();

func _process(delta):
	if Globals.isServer:
		return;
	if get_tree().get_root().get_node("MainScene/NetworkController").isSkirmish:
		$Score_Label.bbcode_text = "[center][color=black]SEARCHING " + str(OS.get_system_time_secs() - start_time);
		$Skirmsh_Subtext.visible = true;
		$Cancel_Button.visible = true;
	if Globals.experimental:
		$Score_Label.bbcode_text = "";
		$Skirmsh_Subtext.visible = false;
		$Cancel_Button.visible = false;
	else:
		$Skirmsh_Subtext.visible = false;
	if !Globals.is_typing_in_chat:
		if Input.is_key_pressed(KEY_E):
			$"Ability_GUIs/E_GUI".frame = 1;
		else:
			$"Ability_GUIs/E_GUI".frame = 0;
		if Input.is_key_pressed(KEY_SPACE):
			$"Ability_GUIs/SPACE_GUI".frame = 1;
		else:
			$"Ability_GUIs/SPACE_GUI".frame = 0;
		if Input.is_key_pressed(KEY_W):
			$"Ability_GUIs/W_GUI".frame = 1;
		else:
			$"Ability_GUIs/W_GUI".frame = 0;
		if Input.is_key_pressed(KEY_A):
			$"Ability_GUIs/A_GUI".frame = 1;
		else:
			$"Ability_GUIs/A_GUI".frame = 0;
		if Input.is_key_pressed(KEY_S):
			$"Ability_GUIs/S_GUI".frame = 1;
		else:
			$"Ability_GUIs/S_GUI".frame = 0;
		if Input.is_key_pressed(KEY_D):
			$"Ability_GUIs/D_GUI".frame = 1;
		else:
			$"Ability_GUIs/D_GUI".frame = 0;
		if Input.is_key_pressed(KEY_E):
			$"Ability_GUIs/E_GUI".frame = 1;
		else:
			$"Ability_GUIs/E_GUI".frame = 0;
		if Input.is_key_pressed(KEY_Q):
			$"Ability_GUIs/Q_GUI".frame = 1;
		else:
			$"Ability_GUIs/Q_GUI".frame = 0;
		if Input.is_key_pressed(KEY_SHIFT):
			$"Ability_GUIs/SHIFT_GUI".frame = 1;
		else:
			$"Ability_GUIs/SHIFT_GUI".frame = 0;
	
	$Alert_Text.modulate = Color(1,1,1, ($Alert_Fade_Timer.time_left/$Alert_Fade_Timer.wait_time));
	
	var local_player;
	if Globals.testing:
		local_player = get_tree().get_root().get_node("MainScene/Test_Player");
	elif Globals.localPlayerID != null and get_tree().get_root().get_node("MainScene/Players").has_node("P" + str(Globals.localPlayerID)):
		local_player = get_tree().get_root().get_node("MainScene/Players/P" + str(Globals.localPlayerID));
	if local_player != null:
		# Teleport button
		var teleport_time_left = local_player.get_node("Teleport_Timer").time_left;
		var teleport_wait_time = local_player.get_node("Teleport_Timer").wait_time;
		if teleport_time_left == 0:
			$Ability_GUIs/Teleport_GUI_Text.text = "DASH";
			$Ability_GUIs/SPACE_GUI.modulate = Color(1,1,1,1);
		else:
			$Ability_GUIs/Teleport_GUI_Text.text = "%0.2f" % teleport_time_left;
			$Ability_GUIs/SPACE_GUI.modulate = Color(1,1,1,0.2 + 0.4 * ((teleport_wait_time - teleport_time_left) / teleport_wait_time) );
			
		# Forcefield button
		var ff_time_left = local_player.get_node("Ability_Node/Cooldown_Timer").time_left;
		var ff_wait_time = local_player.get_node("Ability_Node/Cooldown_Timer").wait_time;
		
		if ff_time_left == 0:
			$Ability_GUIs/Forcefield_GUI_Text.text = "FORCEFIELD";
			$Ability_GUIs/E_GUI.modulate = Color(1,1,1,1);
		else:
			$Ability_GUIs/Forcefield_GUI_Text.text = "%0.2f" % ff_time_left;
			$Ability_GUIs/E_GUI.modulate = Color(1,1,1,0.2 + 0.4 * ((ff_wait_time - ff_time_left) / ff_wait_time) );
		
		
		# Grenade
		var grenade_time_left = local_player.get_node("Utility_Node/Cooldown_Timer").time_left;
		if grenade_time_left == 0:
			$Ability_GUIs/Grenade_GUI_Text.text = "GRENADE";
		else:
			$Ability_GUIs/Grenade_GUI_Text.text = "%0.2f" % grenade_time_left;
		
		# If player is holding a flag
		if local_player.get_node("Flag_Holder").get_child_count() > 0:
			$Ability_GUIs/UP_GUI.modulate = Color(1,1,1,0.4);
			$Ability_GUIs/DOWN_GUI.modulate = Color(1,1,1,0.4);
			$Ability_GUIs/LEFT_GUI.modulate = Color(1,1,1,0.4);
			$Ability_GUIs/RIGHT_GUI.modulate = Color(1,1,1,0.4);
			$Ability_GUIs/Q_GUI.modulate = Color(1,1,1,0.4);

func _screen_resized():
	var window_size = OS.get_window_size();
	if window_size.x < 500 or window_size.y < 200:
		$Ability_GUIs.rect_scale = Vector2(0.5,0.5);
	else:
		$Ability_GUIs.rect_scale = Vector2(1,1);
	$Chat_Box.margin_bottom = window_size.y * (0.6);
	var size = $LineEdit.rect_size.y;
	$LineEdit.margin_top = $Chat_Box.margin_bottom;
	$LineEdit.margin_bottom = $LineEdit.margin_top + size;

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
func set_alert_text(text):
	$Alert_Text.bbcode_text = text;
	$Alert_Fade_Timer.start();
# Sets the score label values
func set_score_text(team0_score, team1_score, isSkirmish = false):
	if isSkirmish:
		$Score_Label.bbcode_text = "[center][color=black]SKIRMISH LOBBY";
	else:
		$Score_Label.bbcode_text = "[center]" + "[color=#4C70BA]" + str(team0_score) + "[/color]" + "-" + "[color=#FF0000]" + str(team1_score) + "[/color]" + "[/center]";
		
	
func enable_leave_match_button():
	$Leave_Match_Button.visible = true;

func _leave_match_button_pressed():
	print("pressed");
	get_tree().get_root().get_node("MainScene/NetworkController").leave_match();

func _cancel_button_pressed():
	Globals.leave_MMQueue();
