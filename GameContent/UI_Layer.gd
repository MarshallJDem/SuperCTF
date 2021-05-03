extends CanvasLayer

var start_time = OS.get_system_time_secs();
var show_move_gui = true;

var camo_HUD_B = preload("res://Assets/GUI/HUD/camo_HUD_B.png");
var camo_HUD_R = preload("res://Assets/GUI/HUD/camo_HUD_R.png");
var forcefield_HUD_B = preload("res://Assets/GUI/HUD/forcefield_HUD_B.png");
var forcefield_HUD_R = preload("res://Assets/GUI/HUD/forcefield_HUD_R.png");
var grenade_HUD_B = preload("res://Assets/GUI/HUD/grenade_HUD_B.png");
var grenade_HUD_R = preload("res://Assets/GUI/HUD/grenade_HUD_R.png");
var landmine_HUD_B = preload("res://Assets/GUI/HUD/landmine_HUD_B.png");
var landmine_HUD_R = preload("res://Assets/GUI/HUD/landmine_HUD_R.png");
var dash_HUD = preload("res://Assets/GUI/HUD/dash_HUD.png");
var ultimate_HUD_demo_B = preload("res://Assets/GUI/HUD/ultimate_HUD_demo_B.png");
var ultimate_HUD_demo_R = preload("res://Assets/GUI/HUD/ultimate_HUD_demo_R.png");
var ultimate_HUD_laser_B = preload("res://Assets/GUI/HUD/ultimate_HUD_laser_B.png");
var ultimate_HUD_laser_R = preload("res://Assets/GUI/HUD/ultimate_HUD_laser_R.png");
var ultimate_HUD_gunner_B = preload("res://Assets/GUI/HUD/ultimate_HUD_gunner_B.png");
var ultimate_HUD_gunner_R = preload("res://Assets/GUI/HUD/ultimate_HUD_gunner_R.png");
var camera_HUD_ON = preload("res://Assets/GUI/HUD/camera_HUD_ON.png");
var camera_HUD_OFF = preload("res://Assets/GUI/HUD/camera_HUD_OFF.png");


func _ready():
	if Globals.isServer:
		return;
	var _err = $Leave_Match_Button.connect("pressed", self, "_leave_match_button_pressed");
	_err = $Cancel_Button.connect("pressed", self, "_cancel_button_pressed");
	_err = $"../Chat_Layer/Options_Button".connect("button_up", self, "_options_button_clicked");
	get_tree().connect("screen_resized", self, "_screen_resized");
	_screen_resized();
	$Shoot_Stick.visible = false;
	$Move_Stick.visible = false;
	$Input_GUIs.visible = false;
	$Alert_Text.visible = false;
	if Globals.control_scheme == Globals.Control_Schemes.touchscreen:
		$Shoot_Stick.visible = true;
		$Move_Stick.visible = true;
	else:
		$Input_GUIs.visible = true;
		$Alert_Text.visible = true;
	show_move_gui = true;

func _process(delta):
	if Globals.isServer:
		return;
	# Show / Hide move gui 
	if show_move_gui:
		$Input_GUIs/Move_GUIs.modulate = Color(1,1,1,1);
		$Input_GUIs/Ability_GUIs.modulate = Color(0,0,0,0);
		$Shoot_Stick.modulate = Color(0,0,0,0);
	elif $Move_GUI_Fade_Timer.time_left > 0:
		var progress = 1 - ($Move_GUI_Fade_Timer.time_left / $Move_GUI_Fade_Timer.wait_time);
		$Input_GUIs/Move_GUIs.modulate = Color(1,1,1,1-progress);
		$Input_GUIs/Ability_GUIs.modulate = Color(1,1,1,progress);
		$Shoot_Stick.modulate = Color(1,1,1,progress);
	else:
		$Input_GUIs/Move_GUIs.modulate = Color(0,0,0,0);
		$Input_GUIs/Ability_GUIs.modulate = Color(1,1,1,1);
		$Shoot_Stick.modulate = Color(1,1,1,1);
		
	$Skirmish_Subtext.visible = false;
	if Globals.matchType == 0: # If this is a skirmish
		$Score_Label.bbcode_text = "[center][color=black]SEARCHING " + str(OS.get_system_time_secs() - start_time);
		$Time_Label.visible = false;
		$Skirmish_Subtext.visible = true;
		$Skirmish_Subtext.bbcode_text = "[center][color=black]"# "This is a skirmish lobby for waiting in matchmaking queue."
		$Cancel_Button.visible = true;
	else:
		$Cancel_Button.visible = false;
	if get_tree().get_root().get_node("MainScene/NetworkController").isSuddenDeath:
		$Score_Label.bbcode_text = "[center][color=red]SUDDEN DEATH";
		$Time_Label.visible = false;
		$Skirmish_Subtext.visible = true;
		$Skirmish_Subtext.bbcode_text = "[center][color=black]Flag cannot be recovered. You can score without your flag home."
	
	
	var time = get_tree().get_root().get_node("MainScene/NetworkController/Match_Time_Limit_Timer").time_left;
	var seconds = int(time) % 60;
	$Time_Label.bbcode_text = "[center]" + str(int(time)/int(60)) + ":" + ((str(seconds)) if seconds > 9 else ("0" + str(seconds)));
	
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
			$Input_GUIs/Ability_GUIs/Teleport_GUI_Text.text = "SPACE";
			$Input_GUIs/Ability_GUIs/SPACE_GUI.modulate = Color(1,1,1,1);
		else:
			$Input_GUIs/Ability_GUIs/Teleport_GUI_Text.text = "%0.0f" % (teleport_time_left + 0.5);
			$Input_GUIs/Ability_GUIs/SPACE_GUI.modulate = Color(1,1,1,0.2 + 0.4 * ((teleport_wait_time - teleport_time_left) / teleport_wait_time) );
			
		# Ability button
		var ability_time_left = local_player.get_node("Ability_Node/Cooldown_Timer").time_left;
		var ability_wait_time = local_player.get_node("Ability_Node/Cooldown_Timer").wait_time;
		
		if Globals.current_ability == Globals.Abilities.Forcefield:
			if local_player.team_id == 1:
				$Input_GUIs/Ability_GUIs/E_GUI.set_texture(forcefield_HUD_R);
			else:
				$Input_GUIs/Ability_GUIs/E_GUI.set_texture(forcefield_HUD_B);
		elif Globals.current_ability == Globals.Abilities.Camo:
			if local_player.team_id == 1:
				$Input_GUIs/Ability_GUIs/E_GUI.set_texture(camo_HUD_R);
			else:
				$Input_GUIs/Ability_GUIs/E_GUI.set_texture(camo_HUD_B);
		if ability_time_left == 0:
			$Input_GUIs/Ability_GUIs/Ability_GUI_Text.text = "E";
			$Input_GUIs/Ability_GUIs/E_GUI.modulate = Color(1,1,1,1);
		else:
			$Input_GUIs/Ability_GUIs/Ability_GUI_Text.text = "%0.0f" % (ability_time_left + 0.5);
			$Input_GUIs/Ability_GUIs/E_GUI.modulate = Color(1,1,1,0.2 + 0.4 * ((ability_wait_time - ability_time_left) / ability_wait_time) );
		var stacks = local_player.get_node("Ability_Node").ability_stacks;
		$Input_GUIs/Ability_GUIs/Ability_Sub_GUI_Text.text = ("+" + str(stacks)) if stacks > 0 else "";
		
		# Utility
		var utility_time_left = local_player.get_node("Utility_Node/Cooldown_Timer").time_left;
		var utility_wait_time = local_player.get_node("Utility_Node/Cooldown_Timer").wait_time;
		
			
		if Globals.current_utility == Globals.Utilities.Grenade:
			if local_player.team_id == 1:
				$Input_GUIs/Ability_GUIs/UTILITY_GUI.set_texture(grenade_HUD_R);
			else:
				$Input_GUIs/Ability_GUIs/UTILITY_GUI.set_texture(grenade_HUD_B);
		elif Globals.current_utility == Globals.Utilities.Landmine:
			if local_player.team_id == 1:
				$Input_GUIs/Ability_GUIs/UTILITY_GUI.set_texture(landmine_HUD_R);
			else:
				$Input_GUIs/Ability_GUIs/UTILITY_GUI.set_texture(landmine_HUD_B);
		if utility_time_left == 0:
			$Input_GUIs/Ability_GUIs/Utility_GUI_Text.text = "RCLICK";
			$Input_GUIs/Ability_GUIs/UTILITY_GUI.modulate = Color(1,1,1,1);
		else:
			$Input_GUIs/Ability_GUIs/Utility_GUI_Text.text = "%0.0f" % (utility_time_left + 0.5);
			$Input_GUIs/Ability_GUIs/UTILITY_GUI.modulate = Color(1,1,1,0.2 + 0.4 * ((utility_wait_time - utility_time_left) / utility_wait_time) );
		
		# If player is holding a flag
		if local_player.get_node("Flag_Holder").get_child_count() > 0:
			#$Input_GUIs/Ability_GUIs/UTILITY_GUI.modulate = Color(1,1,1,0.4);
			pass;
		
		# Camera Shift
		$Input_GUIs/Ability_GUIs/SHIFT_GUI.modulate = Color(1,1,1,1);
		if local_player.is_camera_extended():
			$Input_GUIs/Ability_GUIs/SHIFT_GUI.set_texture(camera_HUD_ON)
		else:
			$Input_GUIs/Ability_GUIs/SHIFT_GUI.set_texture(camera_HUD_OFF)
		
		
		# Ult 
		var charge = local_player.get_node("Ability_Node").ult_charge
		
		if Globals.current_class == Globals.Classes.Bullet:
			if local_player.team_id == 1:
				$Input_GUIs/Ability_GUIs/ULT_GUI.set_texture(ultimate_HUD_gunner_R);
			else:
				$Input_GUIs/Ability_GUIs/ULT_GUI.set_texture(ultimate_HUD_gunner_B);
		elif Globals.current_class == Globals.Classes.Demo:
			if local_player.team_id == 1:
				$Input_GUIs/Ability_GUIs/ULT_GUI.set_texture(ultimate_HUD_demo_R);
			else:
				$Input_GUIs/Ability_GUIs/ULT_GUI.set_texture(ultimate_HUD_demo_B);
		elif Globals.current_class == Globals.Classes.Laser:
			if local_player.team_id == 1:
				$Input_GUIs/Ability_GUIs/ULT_GUI.set_texture(ultimate_HUD_laser_R);
			else:
				$Input_GUIs/Ability_GUIs/ULT_GUI.set_texture(ultimate_HUD_laser_B);
		
		$Input_GUIs/Ability_GUIs/ULT_GUI.modulate = Color(1,1,1,0.5);
		if charge == 100:
			$Input_GUIs/Ability_GUIs/ULT_GUI.modulate = Color(1,1,1,1.0);
			#emit fire behind the ult button
			$Input_GUIs/Ability_GUIs/ULT_GUI/Fire_Particles.start(local_player.team_id) 
		else:
			#stop emitting the fire particles behind the ult button
			$Input_GUIs/Ability_GUIs/ULT_GUI/Fire_Particles.stop()
		$Input_GUIs/Ability_GUIs/ULT_Sub_GUI_Text.text = "%" + str(charge);
		$Input_GUIs/Ability_GUIs/ULT_GUI_Text.text = "Q";
	
	if !Globals.is_typing_in_chat:
		if Input.is_key_pressed(KEY_E):
			$"Input_GUIs/Ability_GUIs/E_GUI".modulate = $"Input_GUIs/Ability_GUIs/E_GUI".modulate.darkened(0.5);
		if Input.is_key_pressed(KEY_SPACE):
			$"Input_GUIs/Ability_GUIs/SPACE_GUI".modulate = $"Input_GUIs/Ability_GUIs/SPACE_GUI".modulate.darkened(0.5);
		if Input.is_key_pressed(KEY_W):
			attempt_hide_move_gui()
			$"Input_GUIs/Move_GUIs/W_GUI".modulate = $"Input_GUIs/Move_GUIs/W_GUI".modulate.darkened(0.5);
		if Input.is_key_pressed(KEY_A):
			attempt_hide_move_gui()
			$"Input_GUIs/Move_GUIs/A_GUI".modulate = $"Input_GUIs/Move_GUIs/A_GUI".modulate.darkened(0.5);
		if Input.is_key_pressed(KEY_S):
			attempt_hide_move_gui()
			$"Input_GUIs/Move_GUIs/S_GUI".modulate = $"Input_GUIs/Move_GUIs/S_GUI".modulate.darkened(0.5);
		if Input.is_key_pressed(KEY_D):
			attempt_hide_move_gui()
			$"Input_GUIs/Move_GUIs/D_GUI".modulate = $"Input_GUIs/Move_GUIs/D_GUI".modulate.darkened(0.5);
		if Input.is_key_pressed(KEY_E):
			$"Input_GUIs/Ability_GUIs/E_GUI".modulate = $"Input_GUIs/Ability_GUIs/E_GUI".modulate.darkened(0.5);
		if Input.is_key_pressed(KEY_SHIFT):
			$"Input_GUIs/Ability_GUIs/SHIFT_GUI".modulate = $"Input_GUIs/Ability_GUIs/SHIFT_GUI".modulate.darkened(0.5);
		if Input.is_action_pressed("clickR"):
			$"Input_GUIs/Ability_GUIs/UTILITY_GUI".modulate = $"Input_GUIs/Ability_GUIs/UTILITY_GUI".modulate.darkened(0.5);
		if Input.is_key_pressed(KEY_Q):
			$"Input_GUIs/Ability_GUIs/ULT_GUI".modulate = $"Input_GUIs/Ability_GUIs/ULT_GUI".modulate.darkened(0.5);
		if Input.is_action_pressed("score_board"):
			$ScoreBoard.visible = true
		else:
			$ScoreBoard.visible = false
			
func attempt_hide_move_gui():
	if show_move_gui == true:
		show_move_gui = false;
		$Move_GUI_Fade_Timer.start();
func _screen_resized():
	var window_size = OS.get_window_size();
	$"../Chat_Layer/Chat_Box".margin_bottom = window_size.y * (0.6);
	$"../Chat_Layer/Chat_Box".get_font("normal_font").size = 12;
	$"../Chat_Layer/Line_Edit".get_font("font").size = 12;
	$"../Chat_Layer/Line_Edit".rect_scale= Vector2(1,1);
	$"../Chat_Layer/Chat_Box".margin_top = 73;
	$"../Chat_Layer/Chat_Box".margin_right = 300;
	$"../Chat_Layer/Kill_Feed".get_font("normal_font").size = 16;
	$"../Chat_Layer/Options_Button".rect_scale = Vector2(0.5,0.5);
	$Cancel_Button.rect_scale = Vector2(0.5,0.5);
	if Globals.control_scheme == Globals.Control_Schemes.touchscreen:
		$"../Chat_Layer/Chat_Box".margin_top = 103;
		$"../Chat_Layer/Options_Button".rect_scale = Vector2(1,1);
		$Cancel_Button.rect_scale = Vector2(1,1);
	if window_size.x < 500 or window_size.y < 200:
		$Input_GUIs.rect_scale = Vector2(0.75,0.75);
		$Input_GUIs.margin_top = -60;
		$Alert_Text.get_font("normal_font").size =12;
		$Skirmish_Subtext.get_font("normal_font").size =12;
		$Alert_Text.margin_top = $Skirmish_Subtext.margin_top + 35;
	elif window_size.x <= 1920 or window_size.y <= 1080:
		$Input_GUIs.rect_scale = Vector2(1.5,1.5);
		$Alert_Text.get_font("normal_font").size =16;
		$Skirmish_Subtext.get_font("normal_font").size =24;
		$Input_GUIs.margin_top = -120;
		$"../Chat_Layer/Chat_Box".get_font("normal_font").size = 14;
		$"../Chat_Layer/Line_Edit".get_font("font").size = 14;
		$Alert_Text.margin_top = $Skirmish_Subtext.margin_top + 70;
	else:
		$Input_GUIs.rect_scale = Vector2(3,3);
		$Input_GUIs.margin_top = -240;
		$Alert_Text.get_font("normal_font").size =48;
		$Skirmish_Subtext.get_font("normal_font").size =20;
		$Alert_Text.margin_top = $Skirmish_Subtext.margin_top + 140;
		$"../Chat_Layer/Chat_Box".margin_right = 600;
		$"../Chat_Layer/Chat_Box".get_font("normal_font").size = 16;
		$"../Chat_Layer/Kill_Feed".get_font("normal_font").size = 24;
		$"../Chat_Layer/Line_Edit".rect_scale = Vector2(2,2);
		$"../Chat_Layer/Options_Button".rect_scale = Vector2(1,1);
		$Cancel_Button.rect_scale = Vector2(1,1);
		if Globals.control_scheme == Globals.Control_Schemes.touchscreen:
			$"../Chat_Layer/Options_Button".rect_scale = Vector2(2,2);
			$Cancel_Button.rect_scale = Vector2(2,2);
		$"../Chat_Layer/Chat_Box".margin_top = 160;
		
	var size = $"../Chat_Layer/Line_Edit".rect_size.y;
	$"../Chat_Layer/Line_Edit".margin_top = $"../Chat_Layer/Chat_Box".margin_bottom;
	$"../Chat_Layer/Line_Edit".margin_bottom = $"../Chat_Layer/Line_Edit".margin_top + size;


func _options_button_clicked():
	Globals.toggle_options_menu();
	$"../Chat_Layer/Options_Button".release_focus();

func add_to_kill_feed(string):
	$"../Chat_Layer/Kill_Feed".bbcode_text += string + "\n";
	var timer = Timer.new()
	timer.wait_time = 5.0;
	timer.one_shot = true;
	timer.connect("timeout",self,"remove_line_from_kill_feed", [timer]);
	add_child(timer);
	timer.start();

func remove_line_from_kill_feed(timer):
	var string = $"../Chat_Layer/Kill_Feed".bbcode_text;
	var index = string.find("\n");
	if index != -1:
		if index + 2 < string.length():
			string = string.substr(index + 1);
		else:
			string = "";
	$"../Chat_Layer/Kill_Feed".bbcode_text = string;
	timer.call_deferred("free");

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
	get_tree().get_root().get_node("MainScene/NetworkController").leave_match();

func _cancel_button_pressed():
	Globals.leave_MMQueue();
func disappear():
	$Score_Label.visible = false;
	$Time_Label.visible = false;
	$Countdown_Label.visible = false;
	$Big_Label_Blue.visible = false;
	$Big_Label_Red.visible = false;
	$Shoot_Stick.visible = false;
	$Move_Stick.visible = false;
	$Input_GUIs.visible = false;
	$Alert_Text.visible = false;
	$Skirmish_Subtext.visible = false;
	$"../Loadout_Menu".hidden = true;
func appear():
	$Score_Label.visible = true;
	$Time_Label.visible = true;
	$Countdown_Label.visible = true;
	$Big_Label_Blue.visible = true;
	$Big_Label_Red.visible = true;
	if Globals.control_scheme == Globals.Control_Schemes.touchscreen:
		$Shoot_Stick.visible = true;
		$Move_Stick.visible = true;
	else:
		$Input_GUIs.visible = true;
		$Alert_Text.visible = true;
	$Skirmish_Subtext.visible = true;
	$"../Loadout_Menu".hidden = false;
