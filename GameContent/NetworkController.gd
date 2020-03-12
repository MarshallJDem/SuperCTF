extends Node

var		PORT			= 42402
const	MAX_PLAYERS	= 10
const	SCORE_LIMIT	= 2;
var		players		= {};
var		scores		= [];
var		round_num	= 0;

var server = null;
var client = null;


var round_is_ended = false;
var match_is_running = false;

# Player "Struct"
#	- name: string
#	- team_id: int
#	- user_id: int
#	- network_id: int
#	- position: Vector2D

func _ready():
	if Globals.testing:
		call_deferred("spawn_flag", 1, Vector2(-200, 0), 0);
		return;
	get_tree().connect("network_peer_connected",self, "_client_connected");
	get_tree().connect("network_peer_disconnected",self, "_client_disconnected");
	get_tree().connect("connected_to_server",self, "_connection_ok");
	get_tree().connect("connection_failed",self, "_connection_fail");
	get_tree().connect("server_disconnected",self, "_server_disconnect");
	var _err = $Round_End_Timer.connect("timeout", self, "_round_end_timer_ended");
	_err = $Round_Start_Timer.connect("timeout", self, "_round_start_timer_ended");
	_err = $Match_Start_Timer.connect("timeout", self, "_match_start_timer_ended");
	_err = $Timing_Sync_Timer.connect("timeout", self, "_timing_sync_timer_ended");
	_err = $Gameserver_Status_Timer.connect("timeout", self, "_gameserver_status_timer_ended");
	_err = $HTTPRequest_GameServerCheckUser.connect("request_completed", self, "_HTTP_GameServerCheckUser_Completed");
	_err = $HTTPRequest_GameServerPollStatus.connect("request_completed", self, "_HTTP_GameServerPollStatus_Completed");
	_err = $HTTPRequest_GameServerMakeAvailable.connect("request_completed", self, "_HTTP_GameServerMakeAvailable_Completed");
	_err = $HTTPRequest_GameServerEndMatch.connect("request_completed", self, "_HTTP_GameServerEndMatch_Completed");
	_err = $HTTPRequest_GetMatchData.connect("request_completed", self, "_HTTP_GetMatchData_Completed");
	_err = $HTTPRequest_GameServerUpdateStatus.connect("request_completed", self, "_HTTP_GameServerUpdateStatus_Completed");
	if(Globals.isServer):
		start_server();
	else:
		join_server();
	
		
func _process(delta):
	if server != null and server.is_listening():
		server.poll();
	if client != null and (client.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED || 
	client.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTING):
		client.poll();
	if $Round_Start_Timer.time_left != 0:
		get_tree().get_root().get_node("MainScene/UI_Layer/Countdown_Label").text = str(int($Round_Start_Timer.time_left) + 1);
	if pollServerStatus && $HTTPRequest_GameServerPollStatus.get_http_client_status() == 0:
		$HTTPRequest_GameServerPollStatus.request(Globals.mainServerIP + "pollGameServerStatus", ["authorization: Bearer " + (Globals.serverPrivateToken)], false);
	


# Resets all game data so that a new game can be started
func reset_game():
	players = {};
	scores = [];
	server = null;
	client = null;
	round_is_ended = false;
	match_is_running = false;
	get_tree().set_network_peer(null);
	reset_game_objects();
	Globals.allowedPlayers = [];
	Globals.matchID = null;
	get_tree().get_root().get_node("MainScene/UI_Layer").clear_big_label_text();

# Starts a server
func start_server():
	print("starting server");
	reset_game();
	server = WebSocketServer.new();
	if Globals.useSecure:
		server.private_key = load("res://HTTPS_Keys/linux_privkey.key");
		server.ssl_certificate = load("res://HTTPS_Keys/linux_cert.crt");
	server.listen(PORT, PoolStringArray(), true);
	get_tree().set_network_peer(server);
	print("Making Game Server Available");
	$HTTPRequest_GameServerMakeAvailable.request(Globals.mainServerIP + "makeGameServerAvailable?publicToken=" + str("RANDOMTOKEN"), ["authorization: Bearer " + (Globals.serverPrivateToken)], false);
	AudioServer.set_bus_volume_db(0, -500);
	updateGameServerStatus(1);
	$Gameserver_Status_Timer.start();
	$Timing_Sync_Timer.stop();

var pollServerStatus = false;

func _HTTP_GameServerUpdateStatus_Completed(result, response_code, headers, body):
	if get_tree().is_network_server():
		if(response_code == 200):
			var json = JSON.parse(body.get_string_from_utf8());
		else:
			pass;

func _HTTP_GameServerMakeAvailable_Completed(result, response_code, headers, body):
	if get_tree().is_network_server():
		if(response_code == 200):
			var json = JSON.parse(body.get_string_from_utf8());
			pollServerStatus = true;
		else:
			pass;

func _HTTP_GameServerPollStatus_Completed(result, response_code, headers, body):
	if get_tree().is_network_server():
		if(response_code == 200):
			var json = JSON.parse(body.get_string_from_utf8());
			var matchID = json.result.matchID;
			Globals.matchID = matchID;
			if matchID:
				pollServerStatus = false;
				print("Getting Match Data for MatchID = " + str(matchID));
				updateGameServerStatus(2);
				$HTTPRequest_GetMatchData.request(Globals.mainServerIP + "getMatchData?matchID=" + str(matchID), ["authorization: Bearer " + (Globals.serverPrivateToken)], false);
		else:
			pass;

func _HTTP_GetMatchData_Completed(result, response_code, headers, body):
	if get_tree().is_network_server():
		if(response_code == 200):
			var json = JSON.parse(body.get_string_from_utf8());
			# Have to parse again because players is stored as a JSON string
			Globals.allowedPlayers = JSON.parse(json.result.matchData.players).result;
			print("Found match and retrieved matchData.");
			var i = 0;
			# Go through each new allowed player and populate the players array
			for user_id in Globals.allowedPlayers:
				var team_id = 1;
				if(float(Globals.allowedPlayers.find_last(user_id) + 1)/float(Globals.allowedPlayers.size()) <= 0.5):
					team_id = 0;
				players[i] = {"name" : "Player" + str(i), "team_id" : team_id, "user_id": user_id, "network_id": 1, "position": Vector2(0,0)};
				i += 1;
			print(players);
			start_match();
		else: #If it failed, try repolling the server status.
			pollServerStatus = true;

func _gameserver_status_timer_ended():
	updateGameServerStatus();

func updateGameServerStatus(status = null):
	if status != null:
		Globals.gameserverStatus = status;
	if $HTTPRequest_GameServerUpdateStatus.get_http_client_status() == 0:
		$HTTPRequest_GameServerUpdateStatus.request(Globals.mainServerIP + "updateGameServerStatus?status=" + String(Globals.gameserverStatus), ["authorization: Bearer " + (Globals.serverPrivateToken)], false);
# Joins a server
func join_server():
	print("joining server");
	client = WebSocketClient.new();
	#client.trusted_ssl_certificate = load("res://HTTPSKeys/linux_fullchain.crt");
	
	var url = "ws://" + Globals.serverIP;
	if Globals.useSecure:
		url = "wss://" + Globals.serverIP;
	var error = client.connect_to_url(url, PoolStringArray(), true);
	
	if error == 0:
		get_tree().set_network_peer(client);
	else:
		print(error);
		# Infinetely attempt to reconnect
		# TODO : check user status. If we are no longer supposed to be connecting, then stop trying.
		yield(get_tree().create_timer(1.0), "timeout");
		join_server();

# Starts the match
func start_match():
	if get_tree().is_network_server():
		# Set each team's score to 0;
		scores = [0, 0];
		rpc("set_scores", scores);
		$Match_Start_Timer.start();
func _match_start_timer_ended():
	# Tell everybody to load a new round
	rpc("load_new_round");
	match_is_running = true;
	updateGameServerStatus(3);

# Sets the score of the game to the given score. This should only ever be called by the server
remotesync func set_scores(new_scores):
	scores = new_scores;
	Globals.result_team0_score = scores[0];
	Globals.result_team1_score = scores[1];
	get_tree().get_root().get_node("MainScene/UI_Layer").set_score_text(scores[0], scores[1]);
	print("current scores: " + str(scores));
	

# Spawns a new flag
remotesync func rpc_spawn_flag(team_id, position, flag_id):
	spawn_flag(team_id, position, flag_id);

func spawn_flag(team_id, position, flag_id):
	# Spawn Flag Home
	var flag_holder = load("res://GameContent/Flag_Home.tscn").instance();
	flag_holder.position = position;
	flag_holder.team_id = team_id;
	flag_holder.flag_id = flag_id;
	flag_holder.name = "Flag_Holder-" + str(flag_id);
	get_tree().get_root().get_node("MainScene").add_child(flag_holder);
	# Spawn Flag
	var flag = load("res://GameContent/Flag.tscn").instance();
	flag.position = position;
	flag.flag_id = flag_id;
	flag.set_team(team_id);
	flag.home_position = position;
	flag.name = "Flag-" + str(flag_id);
	get_tree().get_root().get_node("MainScene").add_child(flag);

# Called when the client's connection is ready, and then tells the server
func _connection_ok():
	print("Connection OK");
	rpc_id(1, "user_ready", get_tree().get_network_unique_id(), Globals.userToken);
remotesync func update_players_data(players_data):
	players = players_data;
	for player_id in players:
		if !get_tree().is_network_server() and players[player_id]["network_id"] == get_tree().get_network_unique_id():
			Globals.localPlayerID = player_id;
		if get_tree().get_root().get_node("MainScene/Players").has_node("P" + str(player_id)):
			var player_node = get_tree().get_root().get_node("MainScene/Players/P" + str(player_id));
			player_node.team_id = players[player_id]["team_id"];
			player_node.player_name = players[player_id]["name"];
			player_node.set_network_master(players[player_id]['network_id']);

# Resync the clocks between server and clients by using current server time elapsed 
remotesync func update_timing_sync(time_elapsed):
	if !get_tree().is_network_server():
		var new_start_time = OS.get_system_time_msecs() - time_elapsed;
		# If this new start time shows the match having started earlier, then it is more accurate
		if new_start_time < Globals.match_start_time:
			Globals.match_start_time = new_start_time;
func _timing_sync_timer_ended():
	if get_tree().is_network_server():
		rpc("update_timing_sync", OS.get_system_time_msecs() - Globals.match_start_time);
func _HTTP_GameServerCheckUser_Completed(result, response_code, headers, body):
	if get_tree().is_network_server():
		if(response_code == 200):
			var json = JSON.parse(body.get_string_from_utf8());
			var player_name = json.result.user.name;
			var user_id = json.result.user.uid;
			var network_id = int(json.result.networkID);
			# If the user is one of the players in the current match
			if(Globals.allowedPlayers.has(user_id)):
				# Get the player_id associated with this user_id
				for player_id in players:
					if players[player_id]['user_id'] == user_id:
						# Update the players array and give it to everyvbody so they can update player data and network masters etc.
						players[player_id]['name'] = player_name;
						if players[player_id]['network_id'] != 1:
							server.disconnect_peer(players[player_id]['network_id'], 1000, "A new computer has connected as this player");
						players[player_id]['network_id'] = network_id;
						print("Authenticated new connection and giving them control of player");
						print(players[player_id]);
						rpc("update_players_data", players);
						# If this user is joining mid match
						if match_is_running:
							rpc_id(network_id, "load_mid_round", players, scores, $Round_Start_Timer.time_left, round_num, OS.get_system_time_msecs() - Globals.match_start_time); 
			else:
				print("Disconnecting player " + str(network_id) + " because they are not in the allowed players list (they mightve connected before we got match data)");
				server.disconnect_peer(network_id, 1000, "You are not a player in this match")
		else:
			print("WE SHOULD BE DISCONNECTING A player because the checkUser backend call failed with a non 200 status BUT WE DON'T KNOW THEIR NETWORKID'");
			#server.disconnect_peer(player_check_queue[0]['networkID'], 1000, "An Unknown Error Occurred.")


# Client calls this on the server to notify that the client's connection is ready
remote func user_ready(id, userToken):
	print("User Ready");
	# Now if we are the server we will add this player to the queue of players to be checked
	if get_tree().is_network_server():
		var http = HTTPRequest.new()
		add_child(http);
		http.connect("request_completed", self, "_HTTP_GameServerCheckUser_Completed")
		http.request(Globals.mainServerIP + "gameServerCheckUser?" + "userToken=" + str(userToken) + "&networkID=" + str(id), ["authorization: Bearer " + Globals.serverPrivateToken], false);
		yield(http, "request_completed");
		print("Deleting httprequest object");
		http.call_deferred("queue_free");

# A test function for sending a ping
remotesync func test_ping():
	print("Test Ping");

# Spawns a new player
remotesync func rpc_spawn_player(id, position):
	spawn_player(id, position);

func spawn_player(id, position, current_pos = null):
	var player = load("res://GameContent/Player.tscn").instance();
	player.set_name("P" + str(id));
	player.set_network_master(players[id]["network_id"]);
	player.player_id = id;
	player.team_id = players[id]["team_id"];
	player.position = position;
	player.start_pos = position;
	player.player_name = players[id]["name"];
	if players[id]["network_id"] == get_tree().get_network_unique_id():
		player.control = true;
		player.activate_camera();
	if current_pos:
		player.position = current_pos;
	get_tree().get_root().get_node("MainScene/Players").add_child(player);
	

# Called when a new peer connects
func _client_connected(id):
	print("Client " + str(id) + " connected to Server");
	
	
# Called on when a client disconnects
func _client_disconnected(id):
	print("Client " + str(id) + " disconnected from the Server");

# Goes back to title screen and drops the socket connection and resets the game
func leave_match():
	print("Leave Match");
	get_tree().set_network_peer(null);
	reset_game()
	# Ideally I'd like to handle passing the variables to the scene here
	# But alas they are all over the place due to weird reasons
	get_tree().change_scene("res://Game_Results_Screen.tscn");

# Called when this client disconnects from the server
func server_disconnect():
	print("LOST CONNECTION WITH SERVER");
	get_tree().get_root().get_node("MainScene/UI_Layer").enable_leave_match_button();
	get_tree().change_scene("res://Game_Results_Screen.tscn");
	

# Called when a player scores a point
remotesync func round_ended(scoring_team_id, scoring_player_id):
	print("Player : " + str(scoring_player_id) + " won a point for team : " + str(scoring_team_id));
	get_tree().get_root().get_node("MainScene").slowdown_music();
	get_tree().get_root().get_node("MainScene/UI_Layer").set_big_label_text(str(players[scoring_player_id]['name']) + "\nSCORED!", scoring_team_id);
	get_tree().get_root().get_node("MainScene/Score_Audio").play();
	var scoring_player = get_tree().get_root().get_node("MainScene/Players/P" + str(scoring_player_id));
	round_is_ended = true;
	print("Round_is_ended");
	# If we are not the server
	if !get_tree().is_network_server():
		var local_player = get_tree().get_root().get_node("MainScene/Players/P" + str(get_tree().get_network_unique_id()));
		local_player.control = false;
		local_player.deactivate_camera();
		scoring_player.activate_camera();
	# Else if we are the server
	else:
		scores[scoring_team_id] = scores[scoring_team_id] + 1;
		rpc("set_scores", scores);
		$Round_End_Timer.start()

# Resets all objects in the game scene by deleting them
func reset_game_objects():
	# Remove any old player nodes
	for player in get_tree().get_root().get_node("MainScene/Players").get_children():
		get_tree().get_root().get_node("MainScene/Players").remove_child(player);
		player.queue_free();
	# Remove any old flags
	for flag in get_tree().get_nodes_in_group("Flags"):
		flag.get_parent().remove_child(flag);
		flag.queue_free();
	# Remove any old flag homes
	for flag_home in get_tree().get_nodes_in_group("Flag_Homes"):
		flag_home.get_parent().remove_child(flag_home);
		flag_home.queue_free();
	# Remove any old projectiles
	for projectile in get_tree().get_nodes_in_group("Projectiles"):
		projectile.get_parent().remove_child(projectile);
		projectile.queue_free();

# Loads up a new round but does not start it yet
# WARNING - you will likely need to make these edits in "load_mid_round" too
remotesync func load_new_round():
	print("Loading New Round" + str(round_num + 1));
	if round_num == 0:
		# Start syncing time with server. Game time elapse at this point would be 0
		Globals.match_start_time = OS.get_system_time_msecs();
		# If we aren't the server, account for a 1 way latency
		if !get_tree().is_network_server():
			Globals.match_start_time -= Globals.player_lerp_time/2;
		else:
			$Timing_Sync_Timer.start();
	round_num += 1;
	round_is_ended = false;
	reset_game_objects();
	get_tree().get_root().get_node("MainScene/Countdown_Audio").play();
	# If we're the server, instruct other to spawn game nodes
	if get_tree().is_network_server():
		# Spawn players
		for player in players:
			var spawn_pos = Vector2(0,0);
			if players[player]["team_id"] == 0:
				spawn_pos = Vector2(-1300, 0);
			elif players[player]["team_id"] == 1:
				spawn_pos = Vector2(1300, 0);
			rpc("rpc_spawn_player", player, spawn_pos);
		# Spawn flags
		rpc("rpc_spawn_flag", 0, Vector2(-1100, 0), 0);
		rpc("rpc_spawn_flag", 1, Vector2(1100, 0), 1);
		# Update score
		rpc("set_scores", scores);
	
	get_tree().get_root().get_node("MainScene/UI_Layer").clear_big_label_text();
	$Round_Start_Timer.set_wait_time(3);
	$Round_Start_Timer.start();

# For when a player joins mid round
remote func load_mid_round(players, scores, round_start_timer_timeleft, round_num, round_time_elapsed):
	print("Loading in the middle of a round" + str(round_num));
	
	Globals.match_start_time = OS.get_system_time_msecs() - round_time_elapsed;
	# Account for a 1 way of latency
	Globals.match_start_time -= Globals.player_lerp_time/2;
	
	self.round_num = round_num;
	round_is_ended = false;
	reset_game_objects();
	get_tree().get_root().get_node("MainScene/Countdown_Audio").play();
	self.players = players;
	self.scores = scores;
	# Spawn players
	for player in players:
		var spawn_pos = Vector2(0,0);
		if players[player]["team_id"] == 0:
			spawn_pos = Vector2(-1300, 0);
		elif players[player]["team_id"] == 1:
			spawn_pos = Vector2(1300, 0);
		spawn_player(player, spawn_pos, players[player]["position"]);
	# Spawn flags
	spawn_flag(0, Vector2(-1100, 0), 0);
	spawn_flag(1, Vector2(1100, 0), 1);
	
	
	Globals.result_team0_score = scores[0];
	Globals.result_team1_score = scores[1];
	get_tree().get_root().get_node("MainScene/UI_Layer").set_score_text(scores[0], scores[1]);
	
	get_tree().get_root().get_node("MainScene/UI_Layer").clear_big_label_text();
	# If we joined in the middle of the countdown timer, then account for that. Also account for latency
	if (round_start_timer_timeleft) > 0:
		$Round_Start_Timer.set_wait_time(round_start_timer_timeleft);
		$Round_Start_Timer.start();

# Starts the currently loaded round
remotesync func start_round():
	print("Starting Round");
	get_tree().get_root().get_node("MainScene").slowdown_music();
	# If we are not the server
	if !get_tree().is_network_server():
		var local_player = get_tree().get_root().get_node("MainScene/Players/P" + str(Globals.localPlayerID));
		local_player.control = true;
		local_player.activate_camera();

# Ends the match
remotesync func end_match(winning_team_id):
	print("Ending Match");
	if get_tree().is_network_server():
		$HTTPRequest_GameServerEndMatch.request(Globals.mainServerIP + "gameServerEndMatch?matchID=" + str(Globals.matchID) + "&winningTeamID=" + str(winning_team_id), ["authorization: Bearer " + (Globals.serverPrivateToken)]);
	else:
		match_is_running = false;
		var team_name = "NOBODY";
		if winning_team_id == 0:
			team_name = "BLUE TEAM";
		elif winning_team_id == 1:
			team_name = "RED TEAM"
		Globals.result_winning_team_id = winning_team_id;
		get_tree().get_root().get_node("MainScene/UI_Layer").set_big_label_text(team_name + " WINS!", winning_team_id);
		get_tree().get_root().get_node("MainScene/UI_Layer").enable_leave_match_button();

# Temporary storage of the winning_team_id to use since the call GameServerEndMatch may require multiple calls if it fails
var winning_team_id_to_use;
# Called when the HTTP request GameServerEndMatch completes. If successful, it will reset the server for next use after 5 seconds
func _HTTP_GameServerEndMatch_Completed(result, response_code, headers, body):
	if(response_code == 200):
		print("success");
		updateGameServerStatus(4);
		yield(get_tree().create_timer(5.0), "timeout")
		get_tree().set_network_peer(null);
		start_server();
	else:
		# Endlessly attempt to end the match until the server responds. It is important that this eventually works!
		print("failiure")
		yield(get_tree().create_timer(5.0), "timeout")
		$HTTPRequest_GameServerEndMatch.request(Globals.mainServerIP + "gameServerEndMatch?matchID=" + str(Globals.matchID) + "&winningTeamID=" + str(winning_team_id_to_use), ["authorization: Bearer " + (Globals.serverPrivateToken)]);

# Called when the Round_End_Timer ends
func _round_end_timer_ended():
	# Only run if we are the server
	if get_tree().is_network_server():
		var game_over = false;
		var winning_team_id = -1;
		for i in range(0, scores.size()):
			if scores[i] >= SCORE_LIMIT:
				game_over = true;
				winning_team_id = i;
		if game_over:
			rpc("end_match", winning_team_id);
		else:
			rpc("load_new_round");

# Called when the Round_Start_Timer ends
func _round_start_timer_ended():
	get_tree().get_root().get_node("MainScene/UI_Layer/Countdown_Label").text = "";
	# Only run if we are the server
	if get_tree().is_network_server():
		rpc("start_round");



#-----------------------------------------------------
#
#func _input(event):
#	if event is InputEventKey and event.pressed:
#		if event.scancode == KEY_2:
#			PORT = 42402;
#		if event.scancode == KEY_3:
#			PORT = 42403;
#		if event.scancode == KEY_H: # HOST
#			start_server();
#		if event.scancode == KEY_J: # JOIN
#			join_server();
#		if event.scancode == KEY_L: # LEAVE
#			leave_match();
#		if event.scancode == KEY_M: # START MATCH
#			start_match();
#		if event.scancode == KEY_F:
#			OS.window_fullscreen = !OS.window_fullscreen;






