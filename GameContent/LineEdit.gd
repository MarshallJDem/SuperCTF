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
					rpc_id(0, "send_message", self.text, get_tree().get_network_unique_id());
					add_message(self.text, get_tree().get_network_unique_id());
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

remote func send_message(message, sender_id):
	if get_tree().is_network_server():
		rpc("receive_message", message, sender_id);

remotesync func receive_message(message, sender_id):
	if get_tree().get_network_unique_id() == sender_id:
		return;
	add_message(message, sender_id);

func add_message(message, sender_id):
	var player_name = get_tree().get_root().get_node("MainScene/NetworkController").players[sender_id]["name"];
	var color = "#ff0000";
	if get_tree().get_root().get_node("MainScene/NetworkController").players[sender_id]["team_id"] == 0:
		color = "#4C70BA";
	get_parent().get_node("Chat_Box").bbcode_text = get_parent().get_node("Chat_Box").bbcode_text + "[color=" + color + "]" + str(player_name) + "[/color][color=#3F4A4D]: " + message + "[/color]" + "\n";