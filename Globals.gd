extends Node

# Whether to run in testing mode (for development uses)
var testing = false;

#Game Servers (Both clients and servers use these vars, but in different ways. overlapping would not work)
var serverIP = "";
var serverPublicToken;
var skirmishIP = "superctf.com:42402";
var port = 42403;
var serverPrivateToken = "privatetoken" + str(port);
var isServer = false;
var allowedPlayers = [];
var matchID;
var allowCommands = true;
var useSecure = true;
var gameserverStatus = 0;

# Client data
var localPlayerID;

#User data
var userToken;
var player_MMR = -1;
var player_rank = -1;
var player_status = 0;

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
var player_lerp_time = 50; # In millis
# Whether or not lasers should destroy bullets
var lasers_destroy_bullets = true;
var lag_comp_headstart_dist = 15;

# ----- Quick Access global variables -----
var match_start_time = 0;

# ----- Functions -----

var HTTPRequest_PollPlayerStatus = HTTPRequest.new();
var HTTPRequest_GetMatchData = HTTPRequest.new();
var HTTPRequest_CancelQueue = HTTPRequest.new();

func _enter_tree():
	var arguments = {}
	for argument in OS.get_cmdline_args():
		print(argument);
		# Parse valid command-line arguments into a dictionary
		if argument.find("=") > -1:
			var key_value = argument.split("=")
			arguments[key_value[0].lstrip("--")] = key_value[1]
	
	if arguments.has("port"):
		port = int(arguments["port"]);
	if arguments.has("isServer"):
		isServer = true if arguments["isServer"] == "true" else false;
	if arguments.has("testing"):
		testing = true if arguments["testing"] == "true" else false;

func _ready():
	
	
	add_child(HTTPRequest_PollPlayerStatus);
	add_child(HTTPRequest_GetMatchData);
	add_child(HTTPRequest_CancelQueue);
	HTTPRequest_PollPlayerStatus.connect("request_completed", self, "_HTTP_PollPlayerStatus_Completed")
	HTTPRequest_GetMatchData.connect("request_completed", self, "_HTTP_GetMatchData_Completed")
	HTTPRequest_CancelQueue.connect("request_completed", self, "_HTTP_CancelQueue_Completed");

func _process(delta):
	if get_tree().get_root().has_node("MainScene/NetworkController"):
		Globals.player_lerp_time = get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("playerLagTime");
	if !isServer:
		attempt_poll_player_status();
	
func leave_MMQueue():
	if !get_tree().is_network_server():
		HTTPRequest_CancelQueue.request(Globals.mainServerIP + "leaveMMQueue", ["authorization: Bearer " + Globals.userToken]);

# Called when the Cancel Queue HTTP request completes
func _HTTP_CancelQueue_Completed(result, response_code, headers, body):
	if(response_code == 200):
		pass;

# Polls the player's status
func _HTTP_PollPlayerStatus_Completed(result, response_code, headers, body):
	if response_code != 200:
		return;
	var json = JSON.parse(body.get_string_from_utf8())
	if json.result.rank || json.result.rank == 0:
		Globals.player_rank = int(json.result.rank);
	if json.result.mmr || json.result.mmr == 0:
		Globals.player_MMR = int(json.result.mmr);
	if( player_status <= 1 and int(json.result.status) > 1):
		print("Found Match : " + json.result.status);
		var matchID = json.result.status;
		var query = "matchID=" + matchID;
		HTTPRequest_GetMatchData.request(Globals.mainServerIP + "getMatchData?" + query, ["authorization: Bearer " + Globals.userToken], false, HTTPClient.METHOD_GET);
	elif(player_status == 1 and int(json.result.status) == 0):
		get_tree().change_scene("res://TitleScreen.tscn");
	player_status = int(json.result.status);

func _HTTP_GetMatchData_Completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	print(json.result)
	serverIP = json.result.matchData.serverIP;
	serverPublicToken = json.result.matchData.serverPublicToken;
	result_match_id = json.result.matchData.matchID;
	get_tree().change_scene("res://GameContent/Main.tscn");

func attempt_poll_player_status():
	# If we are logged in
	if Globals.userToken:
		# If were not already in the middle of a poll, poll it
		if HTTPRequest_PollPlayerStatus.get_http_client_status() == 0:
			HTTPRequest_PollPlayerStatus.request(Globals.mainServerIP + "pollPlayerStatus", ["authorization: Bearer " + Globals.userToken]);

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
			#OS.window_fullscreen = !OS.window_fullscreen;
			pass;
