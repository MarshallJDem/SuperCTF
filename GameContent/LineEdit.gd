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
					rpc("send_message", self.text, Globals.localPlayerID if !get_tree().is_network_server() else 1);
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

# Called by a client on the server to verify a chat and then the server sends it to everyone
remotesync func send_message(message, sender_id):
	if !get_tree().is_network_server():
		return
	if message.left(1) == "/":
		if Globals.allowCommands:
			process_command(message);
			add_message(message, sender_id);
		return
	
	var http = HTTPRequest.new();
	add_child(http);
	http.connect("request_completed", self, "_HTTP_GameServerFilterChat_Completed")
	var message_query = message.http_escape()
	http.request(Globals.mainServerIP + "gameServerFilterChat?" + "chatString=" + str(message_query) + "&senderID=" + str(sender_id), ["authorization: Bearer " + Globals.serverPrivateToken], false);
	yield(http, "request_completed");
	http.call_deferred("free");

func _HTTP_GameServerFilterChat_Completed(result, response_code, headers, body):
	if(response_code == 200):
		# Extract vars from response
		var json = JSON.parse(body.get_string_from_utf8());
		var message = json.result.chatString;
		var filtered_message = json.result.filteredChatString;
		var sender_id = int(json.result.senderID);
		# Send filtered message to everyone
		rpc("receive_message", filtered_message, sender_id)
	else:
		# Extract vars from response
		var json = JSON.parse(body.get_string_from_utf8());
		var message = json.result.chatString;
		var sender_id = int(json.result.senderID);
		var fail_reason = json.result.failReason;
		print("FILTER CHAT FAILED FOR MESSAGE '" + str(message) + "' WITH RESPONSE_CODE " + str(response_code) + " AND FAIL REASON '" + str(fail_reason) + "'")
		rpc("receive_message", "[color=red]>> There was an error with the chat servers <<[/color]", -1)

remotesync func receive_message(message, sender_id):
	# Dont add this message for the player that sent it. They show it locally instantly
	if Globals.localPlayerID == sender_id:
		return;
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
	if command == "/addbot 0" and get_tree().is_network_server():
		get_tree().get_root().get_node("MainScene/NetworkController").add_bot(0)
		return
	if command == "/addbot 1" and get_tree().is_network_server():
		get_tree().get_root().get_node("MainScene/NetworkController").add_bot(1)
		return
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
		if get_tree().get_root().get_node("MainScene/NetworkController").players.has(sender_id):
			var player = get_tree().get_root().get_node("MainScene/NetworkController").players[sender_id]
			player_name = player["name"];
			if player["team_id"] == 0:
				color = "blue";
		else:
			print("ERROR: PLAYER ISNTANCE WAS NOT VALID")
			print_stack()
	if sender_id == -1:
		get_parent().get_parent().get_node("Chat_Layer/Chat_Box").bbcode_text = get_parent().get_parent().get_node("Chat_Layer/Chat_Box").bbcode_text + message + "\n";
	else:
		get_parent().get_parent().get_node("Chat_Layer/Chat_Box").bbcode_text = get_parent().get_parent().get_node("Chat_Layer/Chat_Box").bbcode_text + "[color=" + color + "]" + str(player_name) + "[/color][color=#000000]: " + message + "[/color]" + "\n";
