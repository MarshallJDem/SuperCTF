extends Node

# Whether to run in testing mode (for development uses)
var testing = false;
var experimental = false;

#Game Servers (Both clients and servers use these vars, but in different ways. overlapping would not work)
var serverIP = "";
var serverPublicToken;
var skirmishIPPrefix = "superctf.com:";
var port = 42402;
var serverPrivateToken;
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
var player_party_data;
var player_uid;
var knownPartyData;

enum Control_Schemes { touchscreen, keyboard, controller};
var control_scheme = Control_Schemes.keyboard;

# At the end of a match its hard to tell whether the current stored data for player MMR
# is from before or after the match results. This keeps track of what it was before.
var player_old_MMR = -1;

#Main Server
var mainServerIP = "https://www.superctf.com" + ":42401/";
 
var game_just_started = true;
var is_typing_in_chat = false;


# Result Screen Values
var result_winning_team_id = -1;
var result_team0_score = 0;
var result_team1_score = 0;
var result_match_id = -1;

# NOTES
# Layer mask 4 : Demo Bullet

signal class_changed();
signal ability_changed();
signal utility_changed();

enum Classes { Bullet, Laser, Demo};
var current_class = Classes.Bullet;

enum Abilities { Forcefield, Camo};
var current_ability = Abilities.Forcefield;

enum Utilities { Grenade, Landmine};
var current_utility = Utilities.Grenade;

var active_landmines = 0;

var options_menu_should_scale;
var displaying_loadout = false;

# ----- Constants -----
const game_var_defaults = {"playerSpeed" : 200, "playerLagTime" : 50,
	"bulletSpeed" : 350, "bulletCooldown" : 400, 
	"laserChargeTime" : 650, "laserCooldown" : 500, 
	"laserWidth" :15, "laserLength" : 1300,
	"dashDistance" : 3000, "dashCooldown" : 3000, 
	"forcefieldCooldown" : 8000,
	"scoreLimit" : 2,
	"grenadeRadius" : 50,"grenadeCooldown":5000,
	"camoCooldown" : 13000, "landmineCooldown" : 500};

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
var ping = 50.0;
# Whether or not lasers should destroy bullets
var lasers_destroy_bullets = true;
var lag_comp_headstart_dist = 15;

# ----- Quick Access global variables -----
var match_start_time = 0;

# ----- Functions -----

var HTTPRequest_PollPlayerStatus = HTTPRequest.new();
var HTTPRequest_GetMatchData = HTTPRequest.new();
var HTTPRequest_CancelQueue = HTTPRequest.new();
var HTTPRequest_ConfirmClientConnection = HTTPRequest.new();
var HTTPRequest_Logout = HTTPRequest.new();

onready var viewport = get_viewport()

func test():
	HTTPRequest_ConfirmClientConnection.queue_free();
	HTTPRequest_ConfirmClientConnection = HTTPRequest.new();
	add_child(HTTPRequest_ConfirmClientConnection);

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
		serverPrivateToken = "privatetoken" + str(port);
	if arguments.has("isServer"):
		isServer = true if arguments["isServer"] == "true" else false;
	if OS.has_feature("editor"):
		testing = true;
	experimental =  false;#OS.has_feature("debug") and !OS.has_feature("editor");
	if experimental:
		get_tree().change_scene("res://GameContent/Main.tscn");

func _ready():
	add_child(HTTPRequest_PollPlayerStatus);
	add_child(HTTPRequest_ConfirmClientConnection);
	add_child(HTTPRequest_GetMatchData);
	add_child(HTTPRequest_CancelQueue);
	add_child(HTTPRequest_Logout);
	HTTPRequest_PollPlayerStatus.connect("request_completed", self, "_HTTP_PollPlayerStatus_Completed");
	HTTPRequest_ConfirmClientConnection.connect("request_completed", self, "_HTTP_ConfirmClientStatus_Completed");
	HTTPRequest_GetMatchData.connect("request_completed", self, "_HTTP_GetMatchData_Completed");
	HTTPRequest_CancelQueue.connect("request_completed", self, "_HTTP_CancelQueue_Completed");
	HTTPRequest_Logout.connect("request_completed", self, "_HTTPRequest_Logout_Completed");
	if OS.has_touchscreen_ui_hint():
		control_scheme = Control_Schemes.touchscreen;
func _process(delta):
	if get_tree().get_root().has_node("MainScene/NetworkController"):
		Globals.player_lerp_time = get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("playerLagTime");
	if !isServer:
		if Globals.userToken != null:
			attempt_ConfirmClientConnection();
			attempt_PollPlayerStatus();

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

func logout(reload = false):
	userToken = null;
	write_save_data();
	
	if reload:
		JavaScript.eval("location.reload();", true);
	
	# Client data
	localPlayerID = null;
	localPlayerTeamID = null;
	#User data
	userToken = null;
	player_MMR = -1;
	player_rank = -1;
	player_status = 0;
	player_party_data = null;
	player_uid = null;
	knownPartyData = null;
	player_old_MMR = -1;
	
	HTTPRequest_PollPlayerStatus.queue_free();
	HTTPRequest_PollPlayerStatus = HTTPRequest.new();
	add_child(HTTPRequest_PollPlayerStatus);
	HTTPRequest_GetMatchData.queue_free();
	HTTPRequest_GetMatchData = HTTPRequest.new();
	add_child(HTTPRequest_GetMatchData);
	HTTPRequest_CancelQueue.queue_free();
	HTTPRequest_CancelQueue = HTTPRequest.new();
	add_child(HTTPRequest_CancelQueue);
	HTTPRequest_ConfirmClientConnection.queue_free();
	HTTPRequest_ConfirmClientConnection = HTTPRequest.new();
	add_child(HTTPRequest_ConfirmClientConnection);
	
	HTTPRequest_PollPlayerStatus.connect("request_completed", self, "_HTTP_PollPlayerStatus_Completed");
	HTTPRequest_ConfirmClientConnection.connect("request_completed", self, "_HTTP_ConfirmClientStatus_Completed");
	HTTPRequest_GetMatchData.connect("request_completed", self, "_HTTP_GetMatchData_Completed");
	HTTPRequest_CancelQueue.connect("request_completed", self, "_HTTP_CancelQueue_Completed");
	
	
	last_pollPlayerStatus_response = 0;
	last_confirmClientConnection_response = 0;
	get_tree().change_scene("res://TitleScreen.tscn");

func call_logout_http():
	if HTTPRequest_Logout.get_http_client_status() == 0:
		HTTPRequest_Logout.request(Globals.mainServerIP + "logoutUser", ["authorization: Bearer " + Globals.userToken]);

func _HTTPRequest_Logout_Completed(result, response_code, headers, body):
	if response_code == 200:
		logout(true);
	else:
		print("LOGOUT FAILED");
		return;

# Polls the player's status
func _HTTP_PollPlayerStatus_Completed(result, response_code, headers, body):
	last_pollPlayerStatus_response = OS.get_ticks_msec();
	if response_code == 401:
		logout(false);
		return;
	if response_code != 200:
		return;
	var json = JSON.parse(body.get_string_from_utf8())
	if json.result.has("logout") and json.result.logout:
		logout(true);
		return;
	if json.result.has("rank"):
		Globals.player_rank = int(json.result.rank);
	if json.result.has("uid"):
		Globals.player_uid = int(json.result.uid);
	if json.result.has("mmr"):
		if Globals.player_MMR == -1:
			Globals.player_MMR = int(json.result.mmr);
			Globals.player_old_MMR = int(json.result.mmr);
		elif int(json.result.mmr) != Globals.player_MMR:
			Globals.player_old_MMR = Globals.player_MMR;
			Globals.player_MMR = int(json.result.mmr);
	if json.result.has("partyData"):
		Globals.knownPartyData = json.result.partyData;
		Globals.player_party_data = json.result.partyData;
		Globals.player_party_data.players = Globals.player_party_data.players;
	if(player_status <= 1 and int(json.result.status) > 1):
		print("Found Match : " + str(json.result.status));
		var matchID = str(json.result.status);
		var query = "matchID=" + str(matchID) + "&authority=client";
		HTTPRequest_GetMatchData.request(Globals.mainServerIP + "getMatchData?" + query, ["authorization: Bearer " + Globals.userToken], false, HTTPClient.METHOD_GET);
	elif(player_status == 1 and int(json.result.status) == 0):
		get_tree().change_scene("res://TitleScreen.tscn");
	player_status = int(json.result.status);

func _HTTP_ConfirmClientStatus_Completed(result, response_code, headers, body):
	last_confirmClientConnection_response = OS.get_ticks_msec();
	# No need to really do anything

func _HTTP_GetMatchData_Completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	print(json.result)
	serverIP = json.result.matchData.serverIP;
	serverPublicToken = json.result.matchData.serverPublicToken;
	result_match_id = json.result.matchData.matchID;
	get_tree().change_scene("res://GameContent/Main.tscn");

var last_pollPlayerStatus_response = 0;
var last_confirmClientConnection_response = 0;

func attempt_PollPlayerStatus():
	if OS.get_ticks_msec() - last_pollPlayerStatus_response > 1000:
		# If were not already in the middle of a poll, poll it
		if HTTPRequest_PollPlayerStatus.get_http_client_status() == 0:
			var query = "?knownStatus=" + str(player_status) + "&knownMMR=" + str(player_MMR) + "&knownRank=" + str(player_rank) + "&knownPartyData=" + str(JSON.print(Globals.knownPartyData));
			HTTPRequest_PollPlayerStatus.request(Globals.mainServerIP + "pollPlayerStatus" + query, ["authorization: Bearer " + Globals.userToken]);
	
func attempt_ConfirmClientConnection():
	if OS.get_ticks_msec() - last_confirmClientConnection_response > 1000:
		# If were not already in the middle of a poll, poll it
		if HTTPRequest_ConfirmClientConnection.get_http_client_status() == 0:
			print("REQUESTING CONFIRM CLIENT CONNECTION");
			HTTPRequest_ConfirmClientConnection.request(Globals.mainServerIP + "confirmClientConnection", ["authorization: Bearer " + Globals.userToken], true, HTTPClient.METHOD_POST);

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
	#file.store_string(str(Global_Overlay.current_song));
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
	if userToken == null || userToken == "Null" || userToken == "null" || userToken.length() < 5:
		userToken = null;
	else:
		userToken = str(result["1"]);
	print("HERE IS THE I " + str(index) + " AND RETRIEVED TOKEN : " + str(userToken));
	if result.has("2"):
		AudioServer.set_bus_volume_db(0,float(result["2"]));
	if result.has("3"):
		AudioServer.set_bus_volume_db(1,float(result["3"]));
	if result.has("4") and result.has("5"):
		volume_sliders = Vector2(int(result["4"]), int(result["5"]));
	return;
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
