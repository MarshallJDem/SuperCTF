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
var localPlayerTeamID;

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
var result_match_id = -1;



# ----- Constants -----
const game_var_defaults = {"playerSpeed" : 250, "playerLagTime" : 50,
	"bulletSpeed" : 400, "bulletCooldown" : 350, 
	"laserChargeTime" : 650, "laserCooldown" : 500, 
	"laserWidth" :15, "laserLength" : 1300,
	"dashDistance" : 2000, "dashCooldown" : 1000, 
	"forcefieldCooldown" : 3000,
	"scoreLimit" : 2,
	"grenadeRadius" : 50};

var game_var_limits = {"playerSpeed" : Vector2(50, 600), "playerLagTime" : Vector2(0, 250),
"bulletSpeed" : Vector2(100, 1000), "bulletCooldown" : Vector2(100, 2000), 
"laserChargeTime" : Vector2(50, 5000), "laserCooldown" : Vector2(100, 8000), 
"laserWidth" : Vector2(2, 50), "laserLength" : Vector2(10, 5000),
"dashDistance" : Vector2(100, 5000), "dashCooldown" : Vector2(100, 8000), 
"forcefieldCooldown" : Vector2(100, 6000),
"scoreLimit" : Vector2(1, 15),
"grenadeRadius" : Vector2(5,500)};


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
var PollPlayerStatus_Timer = Timer.new();

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
	PollPlayerStatus_Timer.one_shot = true;
	PollPlayerStatus_Timer.autostart = false;
	PollPlayerStatus_Timer.wait_time = 1;
	add_child(PollPlayerStatus_Timer);
	

func _process(delta):
	if get_tree().get_root().has_node("MainScene/NetworkController"):
		Globals.player_lerp_time = get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("playerLagTime");
	if !isServer:
		attempt_poll_player_status();

var volume_sliders = Vector2(50,50);
func toggle_options_menu():
	if get_tree().get_root().has_node("Options_Menu"):
		get_tree().get_root().get_node("Options_Menu").call_deferred("queue_free");
		write_save_data();
	else:
		load_save_data();
		var menu = load("res://GameContent/Options_Menu.tscn").instance();
		get_tree().get_root().add_child(menu);


func leave_MMQueue():
	if !get_tree().is_network_server():
		HTTPRequest_CancelQueue.request(Globals.mainServerIP + "leaveMMQueue", ["authorization: Bearer " + Globals.userToken]);

# Called when the Cancel Queue HTTP request completes
func _HTTP_CancelQueue_Completed(result, response_code, headers, body):
	if(response_code == 200):
		pass;

# Polls the player's status
func _HTTP_PollPlayerStatus_Completed(result, response_code, headers, body):
	PollPlayerStatus_Timer.start();
	if response_code != 200:
		return;
	var json = JSON.parse(body.get_string_from_utf8())
	if json.result.has("rank"):
		Globals.player_rank = int(json.result.rank);
	if json.result.has("mmr"):
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
	# Don't poll if we just recently polled
	if PollPlayerStatus_Timer.time_left > 0:
		return;
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
	file.store_string(str(userToken) + "\n");
	file.store_string(str(AudioServer.get_bus_volume_db(0)) + "\n");
	file.store_string(str(AudioServer.get_bus_volume_db(1)) + "\n");
	file.store_string(str(volume_sliders.x) + "\n");
	file.store_string(str(volume_sliders.y) + "\n");
	file.store_string(str(Global_Overlay.current_song));
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
	if result.has("2"):
		AudioServer.set_bus_volume_db(0,float(result["2"]));
	if result.has("3"):
		AudioServer.set_bus_volume_db(1,float(result["3"]));
	if result.has("4") and result.has("5"):
		volume_sliders = Vector2(int(result["4"]), int(result["5"]));
	if result.has("6"):
		Global_Overlay.saved_song_loaded(int(result["6"]));
	else:
		Global_Overlay.saved_song_loaded(-1);
		

func _input(event):
	if event is InputEventKey and event.pressed:
		if is_typing_in_chat:
			return;
		if event.scancode == KEY_F:
			#OS.window_fullscreen = !OS.window_fullscreen;
			pass;
