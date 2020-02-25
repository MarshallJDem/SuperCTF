extends Node2D

var isInMMQueue = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	if Globals.testing:
		get_tree().change_scene("res://GameContent/Main.tscn");
	$HTTPRequest_FindMatch.connect("request_completed", self, "_HTTP_FindMatch_Completed");
	$HTTPRequest_CancelQueue.connect("request_completed", self, "_HTTP_CancelQueue_Completed");
	$HTTPRequest_PollPlayerStatus.connect("request_completed", self, "_HTTP_PollPlayerStatus_Completed");
	$HTTPRequest_GetMatchData.connect("request_completed", self, "_HTTP_GetMatchData_Completed");
	$HTTPRequest_CreateGuest.connect("request_completed", self, "_HTTP_CreateGuest_Completed");
	
	Globals.load_save_data();
	print(Globals.userToken);
	if Globals.game_just_started:
		Globals.game_just_started = false;
		$UI_Layer.set_view($UI_Layer.VIEW_SPLASH);
	else:
		start();
	if Globals.isServer:
		get_tree().change_scene("res://GameContent/Main.tscn");
		
var stat = 0;
func _process(delta):
	# If were in queue, poll player status if we're not already polling it
	if(isInMMQueue && $HTTPRequest_PollPlayerStatus.get_http_client_status() == 0):
		$HTTPRequest_PollPlayerStatus.request(Globals.mainServerIP + "pollPlayerStatus", ["authorization: Bearer " + Globals.userToken]);
	$UI_Layer.update_title_color($Titlemusic_Audio.get_playback_position() + 3.7);
	if stat != $HTTPRequest_CreateGuest.get_http_client_status():
		stat = $HTTPRequest_CreateGuest.get_http_client_status();
		print(stat);

func create_guest():
	$HTTPRequest_CreateGuest.request(Globals.mainServerIP + "createGuest");
func join_MM_queue():
	print("Token : " + Globals.userToken);
	$HTTPRequest_FindMatch.request(Globals.mainServerIP + "joinMMQueue", ["authorization: Bearer " + Globals.userToken]);
func leave_MM_queue():
	$HTTPRequest_CancelQueue.request(Globals.mainServerIP + "leaveMMQueue", ["authorization: Bearer " + Globals.userToken]);
func logout():
	Globals.userToken = "";
	Globals.write_save_data();
	$UI_Layer.set_view($UI_Layer.VIEW_START);
	
func start():
	# If there is a cached user token
	if(Globals.userToken):
		$UI_Layer.set_view($UI_Layer.VIEW_MAIN);
	else: # Else show them login
		$UI_Layer.set_view($UI_Layer.VIEW_START);
	
	$Titlemusic_Audio.play(0.0);
	#OS.window_fullscreen = true;
	

# Called when the find match HTTP request completes
func _HTTP_FindMatch_Completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	if(response_code == 200):
		isInMMQueue = true;
		$UI_Layer.set_view($UI_Layer.VIEW_IN_QUEUE);
	else:
		$UI_Layer.set_view($UI_Layer.VIEW_MAIN);

# Called when the GetMatchData HTTP request completes
func _HTTP_GetMatchData_Completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	Globals.serverIP = json.result.matchData.serverIP;
	Globals.serverPublicToken = json.result.matchData.serverPublicToken;
	Globals.result_match_id = json.result.matchData.matchID;
	get_tree().change_scene("res://GameContent/Main.tscn");

func _HTTP_CreateGuest_Completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	if(response_code == 200 && json.result):
		print(json.result);
		var token = json.result.token;
		if(token):
			Globals.userToken = token;
			Globals.write_save_data();
			$UI_Layer.set_view($UI_Layer.VIEW_MAIN);
		else:# TODO: - Handle error
			pass;
	else:
		pass;

# Polls the player's status
func _HTTP_PollPlayerStatus_Completed(result, response_code, headers, body):
	if response_code != 200:
		return;
	var json = JSON.parse(body.get_string_from_utf8())
	if(int(json.result.status) > 1):
		print("Found Match : " + json.result.status);
		var matchID = json.result.status;
		var query = "matchID=" + matchID;
		$HTTPRequest_GetMatchData.request(Globals.mainServerIP + "getMatchData?" + query, ["authorization: Bearer " + Globals.userToken], false, HTTPClient.METHOD_GET);
		isInMMQueue = false;

# Called when the Cancel Queue HTTP request completes
func _HTTP_CancelQueue_Completed(result, response_code, headers, body):
	if(response_code == 200):
		isInMMQueue = false;
		$UI_Layer.set_view($UI_Layer.VIEW_MAIN);
	else:
		$UI_Layer.set_view($UI_Layer.VIEW_IN_QUEUE);


func _input(event):
	if event is InputEventKey and event.pressed:
		if event.scancode == KEY_S:
			Globals.isServer = true;
			get_tree().change_scene("res://GameContent/Main.tscn");


