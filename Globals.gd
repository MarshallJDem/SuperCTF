extends Node

#Game Servers (Both clients and servers use these vars, but in different ways. overlapping would not work)
var serverIP;
var serverPublicToken;
var serverPrivateToken = "privatetoken42402";
var isServer = false;
var allowedPlayers = [];
var matchID;

#User data
var userToken;

#Main Server
var mainServerIP = "https://www.superctf.com:42401/";

var game_just_started = true;
var is_typing_in_chat = false;

# ----- Constants -----

# The amount of delay to lerp over for lag interpolation for players
var player_lerp_time = 100; # In millis
# Whether or not lasers should destroy bullets
var lasers_destroy_bullets = true;
# Whether to run in testing mode (for development uses)
var testing = true;
var forcefield_cooldown = 3;
var lag_comp_headstart_dist = 75;

# ----- Quick Access global variables -----
var match_start_time = 0;

func write_save_data():
	var file = File.new()
	var content = "";
	var err = file.open("user://save_data.dat", File.WRITE)
	if err:
		print(err);
		return;
	file.store_string(str(userToken));
	file.close()

func load_save_data():
	var result = {}
	var f = File.new()
	var err = f.open("user://save_data.dat", File.READ)
	if(err):
		print(err);
		return;
	var index = 1
	while (!f.eof_reached()):
		var line = f.get_line()
		result[str(index)] = line
		index += 1
	f.close();
	userToken = result["1"];

func _input(event):
	if event is InputEventKey and event.pressed:
		if is_typing_in_chat:
			return;
		if event.scancode == KEY_F:
			OS.window_fullscreen = !OS.window_fullscreen;
		if event.scancode == KEY_1:
			player_lerp_time = 100;
