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
	$HTTPRequest_GetLeaderboard.connect("request_completed", self, "_HTTP_GetLeaderboard_Completed");
	$Leaderboard_Refresh_Timer.connect("timeout", self, "_Leaderboard_Refresh_Ended");
	
	$Player_Status_Poll_Timer.connect("timeout", self, "_Player_Status_Poll_Timer_Ended");
	$Headline_Update_Timer.connect("timeout", self, "_Headline_Update_Timer_Ended");
	
	Globals.load_save_data();
	print(Globals.userToken);
	if Globals.game_just_started:
		Globals.game_just_started = false;
		$UI_Layer.set_view($UI_Layer.VIEW_SPLASH);
	else:
		start();
	if Globals.isServer:
		get_tree().change_scene("res://GameContent/Main.tscn");
	$HTTPRequest_GetLeaderboard.request(Globals.mainServerIP + "getLeaderboardData", ["authorization: Bearer " + Globals.userToken]);

var stat = 0;
func _Player_Status_Poll_Timer_Ended():
	# Attempt to poll the player status. Called every 5 seconds.
	attempt_poll_player_status();
func _Headline_Update_Timer_Ended():
	var text = $UI_Layer/Headline_Rect/Headline_Text.bbcode_text;
	var first = text.substr(0,1);
	text = text.substr(1, len(text) - 1);
	$UI_Layer/Headline_Rect/Headline_Text.bbcode_text = text + first;
func attempt_poll_player_status():
	# IF were not already in the middle of a poll, poll it
	if $HTTPRequest_PollPlayerStatus.get_http_client_status() == 0:
		$HTTPRequest_PollPlayerStatus.request(Globals.mainServerIP + "pollPlayerStatus", ["authorization: Bearer " + Globals.userToken]);
func _process(delta):
	# If there is an active player and we havn't received their rank / mmr yet
	if Globals.userToken and (Globals.player_MMR == -1 or Globals.player_rank == -1):
		attempt_poll_player_status();
	# If were in queue, poll player status if we're not already polling it
	if(isInMMQueue):
		attempt_poll_player_status();
	$UI_Layer.update_title_color($Titlemusic_Audio.get_playback_position() + 3.7);
	if stat != $HTTPRequest_CreateGuest.get_http_client_status():
		stat = $HTTPRequest_CreateGuest.get_http_client_status();
		print(stat);

func create_guest():
	var name = $UI_Layer/UsernameLineEdit.text;
	if name != null && name != "":
		$HTTPRequest_CreateGuest.request(Globals.mainServerIP + "createGuest?" + "name=" + String(name));
	else:
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
var leaderboard_parent;
func load_leaderboard(leaderboard_data):
	var origin = Vector2(30,190);
	if leaderboard_parent:
		leaderboard_parent.call_deferred("queue_free");
	leaderboard_parent = Node2D.new();
	leaderboard_parent.position = origin;
	call_deferred("add_child", leaderboard_parent);
	var cell_size = Vector2(206, 33);
	var rows = 10;
	var columns = 5;
	for i in range(50):
		var data = leaderboard_data[i];
		var cell = load("res://LeaderboardCell.tscn").instance();
		cell.mmr = data.mmr;
		cell.player_name = data.name;
		cell.player_id = data.uid;
		cell.rank = i + 1;
		var row = i % rows;
		var col = int( i / rows);
		cell.position = Vector2(cell_size.x * col, cell_size.y * row);
		leaderboard_parent.add_child(cell);

func _HTTP_GetLeaderboard_Completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	print(json.result);
	if(response_code == 200 and json.result):
		load_leaderboard(json.result);

func _Leaderboard_Refresh_Ended():
	if $HTTPRequest_GetLeaderboard.get_http_client_status() == 0:
		$HTTPRequest_GetLeaderboard.request(Globals.mainServerIP + "getLeaderboardData", ["authorization: Bearer " + Globals.userToken]);
	
	
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
	print(json.result);
	if json.result.rank || json.result.rank == 0:
		Globals.player_rank = int(json.result.rank);
	if json.result.mmr || json.result.mmr == 0:
		Globals.player_MMR = int(json.result.mmr);
	$UI_Layer.set_mmr_and_rank_labels(Globals.player_rank, Globals.player_MMR);
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


