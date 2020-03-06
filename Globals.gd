extends Node

# Whether to run in testing mode (for development uses)
var testing = false;

#Game Servers (Both clients and servers use these vars, but in different ways. overlapping would not work)
var serverIP;
var serverPublicToken;
var serverPrivateToken = "privatetoken42402";
var isServer = true;
var allowedPlayers = [];
var matchID;
var allowCommands = true;
var useSecure = true;
var gameserverStatus = 0;

#User data
var userToken;
var player_MMR = -1;
var player_rank = -1;

#Main Server
var mainServerIP = "https://www.superctf.com" + ":42401/";

var game_just_started = true;
var is_typing_in_chat = false;

# Result Screen Values
var result_winning_team_id = -1;
var result_team0_score = 0;
var result_team1_score = 0;
var result_player_team_id = -1;
var result_match_id = -1;

# ----- Constants -----

# The amount of delay to lerp over for lag interpolation for players and various other things
var player_lerp_time = 100; # In millis
# Whether or not lasers should destroy bullets
var lasers_destroy_bullets = true;
var forcefield_cooldown = 3;
var lag_comp_headstart_dist = 15;

# ----- Quick Access global variables -----
var match_start_time = 0;

# ----- Functions -----
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
