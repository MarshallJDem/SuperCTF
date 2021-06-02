extends LineEdit

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass;

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_ENTER:
			# Send message / cancel
			if Globals.is_typing_in_chat:
				if self.text != "":
					rpc("receive_message", self.text, Globals.localPlayerID);
					add_message(self.text, Globals.localPlayerID);
				self.text = "";
				self.release_focus();
				Globals.is_typing_in_chat = false;
				self.mouse_filter = Control.MOUSE_FILTER_IGNORE;
			else:
				Globals.is_typing_in_chat = true;
				self.grab_focus();
				self.mouse_filter = Control.MOUSE_FILTER_STOP;
		if event.scancode == KEY_ESCAPE:
			self.text = "";
			self.release_focus();
			Globals.is_typing_in_chat = false;
			self.mouse_filter = Control.MOUSE_FILTER_IGNORE;

remotesync func receive_message(message, sender_id):
	if Globals.localPlayerID == sender_id:
		return;
	if message.left(1) == "/":
		if Globals.allowCommands and get_tree().is_network_server():
			process_command(message);
			add_message(message, sender_id);
	else:
		add_message(message, sender_id);
func process_command(command):
	if command == "/endmatch 0":
		get_tree().get_root().get_node("MainScene/NetworkController").rpc("end_match",0);
		return;
	if command == "/endmatch 1":
		get_tree().get_root().get_node("MainScene/NetworkController").rpc("end_match",1);
		return;
	if command == "/shutdown" and get_tree().is_network_server():
		get_tree().quit();
	var first_space = command.findn(" ", 0);
	var verb = command.substr(1, first_space-1);
	var second_space = command.findn(" ", first_space+1);
	var noun = command.substr(first_space+1, (second_space-first_space) - 1).strip_edges();
	var value = command.substr(second_space+1).strip_edges();
	
	if !Globals.game_var_defaults.has(noun) or !value.is_valid_integer():
		rpc("receive_message", "[color=red] > Invalid Command < [/color]", -1);
		return; 
	
	var val = clamp(int(value), Globals.game_var_limits[noun].x, Globals.game_var_limits[noun].y);
	
	if verb == "set":
		rpc("receive_message", "[color=green] > Successfully set " + noun + " = " + str(val) + "< [/color]", -1);
		get_tree().get_root().get_node("MainScene/NetworkController").rpc("set_game_var", noun, int(val));
	
func add_message(message, sender_id):
	var player_name = "BOB";
	var color = "red";
	if !Globals.testing and sender_id != -1:
		player_name = get_tree().get_root().get_node("MainScene/NetworkController").players[sender_id]["name"];
		if get_tree().get_root().get_node("MainScene/NetworkController").players[sender_id]["team_id"] == 0:
			color = "blue";
	if sender_id == -1:
		get_parent().get_parent().get_node("Chat_Layer/Chat_Box").bbcode_text = get_parent().get_parent().get_node("Chat_Layer/Chat_Box").bbcode_text + message + "\n";
	else:
		get_parent().get_parent().get_node("Chat_Layer/Chat_Box").bbcode_text = get_parent().get_parent().get_node("Chat_Layer/Chat_Box").bbcode_text + "[color=" + color + "]" + str(player_name) + "[/color][color=#000000]: " + message + "[/color]" + "\n";
