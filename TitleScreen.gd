extends Node2D

var LeaderboardCell = preload("res://LeaderboardCell.tscn");

# Called when the node enters the scene tree for the first time.
func _ready():
	if Globals.testing:
		get_tree().change_scene("res://GameContent/Main.tscn");
	$HTTPRequest_FindMatch.connect("request_completed", self, "_HTTP_FindMatch_Completed");
	$HTTPRequest_CreateGuest.connect("request_completed", self, "_HTTP_CreateGuest_Completed");
	$HTTPRequest_GetLeaderboard.connect("request_completed", self, "_HTTP_GetLeaderboard_Completed");
	$Leaderboard_Refresh_Timer.connect("timeout", self, "_Leaderboard_Refresh_Ended");
	
	$Headline_Update_Timer.connect("timeout", self, "_Headline_Update_Timer_Ended");
	
	Globals.load_save_data();
	print(Globals.userToken);
	if Globals.game_just_started:
		Globals.game_just_started = false;
		$UI_Layer.set_view($UI_Layer.VIEW_SPLASH);
	else:
		start();
	if Globals.isServer:
		print("Checking is server");
		get_tree().change_scene("res://GameContent/Main.tscn");
	$HTTPRequest_GetLeaderboard.request(Globals.mainServerIP + "getLeaderboardData", ["authorization: Bearer " + Globals.userToken]);
	
	get_tree().set_screen_stretch(SceneTree.STRETCH_MODE_VIEWPORT, SceneTree.STRETCH_ASPECT_KEEP, Vector2(1920,1080));



func _Headline_Update_Timer_Ended():
	var text = $UI_Layer/Headline_Rect/Headline_Text.bbcode_text;
	var first = text.substr(0,1);
	text = text.substr(1, len(text) - 1);
	$UI_Layer/Headline_Rect/Headline_Text.bbcode_text = text + first;
func _process(delta):
	$UI_Layer.update_title_color($Titlemusic_Audio.get_playback_position() + 3.7);
	$UI_Layer.set_mmr_and_rank_labels(Globals.player_rank, Globals.player_MMR);
	if Globals.player_status == 1:
		get_tree().change_scene("res://GameContent/Main.tscn");

func create_guest():
	var name = $UI_Layer/UsernameLineEdit.text;
	if name != null && name != "":
		$HTTPRequest_CreateGuest.request(Globals.mainServerIP + "createGuest?" + "name=" + String(name));
	else:
		$HTTPRequest_CreateGuest.request(Globals.mainServerIP + "createGuest");
func join_MM_queue():
	print("Token : " + Globals.userToken);
	$HTTPRequest_FindMatch.request(Globals.mainServerIP + "joinMMQueue", ["authorization: Bearer " + Globals.userToken]);
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

var leaderboard_parent;
func load_leaderboard(leaderboard_data):
	var origin = Vector2(136,213);
	if leaderboard_parent:
		leaderboard_parent.call_deferred("queue_free");
	leaderboard_parent = Node2D.new();
	leaderboard_parent.position = origin;
	call_deferred("add_child", leaderboard_parent);
	var cell_size = Vector2(206, 33);
	var rows = 10;
	var columns = 8;
	for i in range(80):
		var data = leaderboard_data[i];
		var cell = LeaderboardCell.instance();
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
	if(response_code == 200 and json.result):
		load_leaderboard(json.result);

func _Leaderboard_Refresh_Ended():
	if $HTTPRequest_GetLeaderboard.get_http_client_status() == 0:
		$HTTPRequest_GetLeaderboard.request(Globals.mainServerIP + "getLeaderboardData", ["authorization: Bearer " + Globals.userToken]);
	
	
# Called when the find match HTTP request completes
func _HTTP_FindMatch_Completed(result, response_code, headers, body):
	var json = JSON.parse(body.get_string_from_utf8())
	if(response_code == 200):
		$UI_Layer.set_view($UI_Layer.VIEW_IN_QUEUE);
	else:
		$UI_Layer.set_view($UI_Layer.VIEW_MAIN);

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




