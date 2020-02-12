extends Node

var		PORT		= 42402
const	MAX_PLAYERS	= 10
const	SCORE_LIMIT	= 2;
var		players		= {}
var		player_name;
var		scores		= [];

var server = null;
var client = null;


var round_is_ended = false;

var match_is_running = false;

# Player "Struct"
#	- name: string
#	- team_id: int
#	- user_id: int

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
	_err = $HTTPRequest_GameServerCheckUser.connect("request_completed", self, "_HTTP_GameServerCheckUser_Completed");
	_err = $HTTPRequest_GameServerPollStatus.connect("request_completed", self, "_HTTP_GameServerPollStatus_Completed");
	_err = $HTTPRequest_GameServerMakeAvailable.connect("request_completed", self, "_HTTP_GameServerMakeAvailable_Completed");
	_err = $HTTPRequest_GameServerEndMatch.connect("request_completed", self, "_HTTP_GameServerEndMatch_Completed");
	_err = $HTTPRequest_GetMatchData.connect("request_completed", self, "_HTTP_GetMatchData_Completed");
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
	# If there are still players that need to be registered
	if players.size() < Globals.allowedPlayers.size():
		# And if there are players in the queue to check and we're not currently checking a player
		if player_check_queue.size() >= 1 && $HTTPRequest_GameServerCheckUser.get_http_client_status() == 0:
			$HTTPRequest_GameServerCheckUser.request(Globals.mainServerIP + "gameServerCheckUser?" + "userToken=" + str(player_check_queue[0]['userToken']), ["authorization: Bearer " + Globals.serverPrivateToken], false);
	# Else if there are no more players to register and the game is not empty
	elif players.size() > 0 && !match_is_running && get_tree().is_network_server():
		print("Match is ready to start!")
		start_match();


# Resets all game data so that a new game can be started
func reset_game():
	players = {};
	player_name = null;
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
	player_name = 'Server';
	server = WebSocketServer.new();
	server.private_key = load("res://HTTPS_Keys/linux_privkey.key");
	server.ssl_certificate = load("res://HTTPS_Keys/linux_cert.crt");
	server.listen(PORT, PoolStringArray(), true);
	get_tree().set_network_peer(server);
	print("Making Game Server Available");
	$HTTPRequest_GameServerMakeAvailable.request(Globals.mainServerIP + "makeGameServerAvailable?publicToken=" + str("RANDOMTOKEN"), ["authorization: Bearer " + (Globals.serverPrivateToken)], false);
	AudioServer.set_bus_volume_db(0, -500);

var pollServerStatus = false;
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
				$HTTPRequest_GetMatchData.request(Globals.mainServerIP + "getMatchData?matchID=" + str(matchID), ["authorization: Bearer " + (Globals.serverPrivateToken)], false);
		else:
			pass;

func _HTTP_GetMatchData_Completed(result, response_code, headers, body):
	if get_tree().is_network_server():
		if(response_code == 200):
			var json = JSON.parse(body.get_string_from_utf8());
			# Have to parse again because players is stored as a JSON string
			Globals.allowedPlayers = JSON.parse(json.result.players).result;
			print(Globals.allowedPlayers);

# Joins a server
func join_server():
	print("joining server");
	player_name = 'Client';
	client = WebSocketClient.new();
	#client.trusted_ssl_certificate = load("res://HTTPSKeys/linux_fullchain.crt");
	var url = "wss://" + Globals.serverIP;
	var error = client.connect_to_url(url, PoolStringArray(), true);
	get_tree().set_network_peer(client);

# Starts the match
func start_match():
	if get_tree().is_network_server() and players.size() >= 2:
		# Set each team's score to 0;
		scores = [0, 0];
		rpc("set_scores", scores);
		rpc("load_new_round");
		match_is_running = true;

# Sets the score of the game to the given score. This should only ever be called by the server
remotesync func set_scores(new_scores):
	scores = new_scores;
	get_tree().get_root().get_node("MainScene/UI_Layer").set_score_text(scores[0], scores[1]);
	print("current scores: " + str(scores));
	
# Sets the team of a player
# NOTE: - DEPRECATED SINCE TEAMS ARE ASSIGNED ON PLAYER REGISTRATION NOW
remotesync func set_player_team(player_id, team_id):
	players[player_id]['team_id'] = team_id;

# Spawns a new flag
remotesync func spawn_flag(team_id, position, flag_id):
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

func _HTTP_GameServerCheckUser_Completed(result, response_code, headers, body):
	if get_tree().is_network_server():
		if(response_code == 200):
			var json = JSON.parse(body.get_string_from_utf8());
			var player_name = json.result.name;
			var user_id = json.result.uid;
			print(Globals.allowedPlayers);
			print(user_id);
			print(Globals.allowedPlayers.has(user_id));
			# If the user is one of the players in the current match
			if(Globals.allowedPlayers.has(user_id)):
				# Register each existing player for this new player
				for player_id in players:
					rpc_id(player_check_queue[0]['networkID'], "register_new_player", player_id, players[player_id]['name'], players[player_id]['team_id'], players[player_id]['user_id']);
				var team_id = 1;
				if(float(Globals.allowedPlayers.find_last(user_id) + 1)/float(Globals.allowedPlayers.size()) <= 0.5):
					team_id = 0;
				# Then, register this new player for everybody
				rpc("register_new_player", player_check_queue[0]['networkID'], player_name, team_id, user_id);
			else:
				print("Disconnecting player " + str(player_check_queue[0]['networkID']) + " because they are not in the allowed players list");
				server.disconnect_peer(player_check_queue[0]['networkID'], 1000, "You are not a player in this match")
		else:
			print("Disconnecting player " + str(player_check_queue[0]['networkID']) + " because the checkUser backend call failed with a non 200 status");
			server.disconnect_peer(player_check_queue[0]['networkID'], 1000, "An Unknown Error Occurred.")
		player_check_queue.pop_front();




var player_check_queue = [];
# Client calls this on the server to notify that the client's connection is ready
remote func user_ready(id, userToken):
	print("User Ready");
	if get_tree().is_network_server():
		player_check_queue.push_back({"networkID":id, "userToken":userToken});

# The server calls this for everyone telling them to register a new player
remotesync func register_new_player(id, name, team_id, user_id):
	players[id] = {"name" : name, "team_id" : team_id, "user_id": user_id};
	print("Registering New Player : " + str(players[id]));

# A test function for sending a ping
remotesync func test_ping():
	print("Test Ping");

# Spawns a new player
remotesync func spawn_player(id, position):
	var player = load("res://GameContent/Player.tscn").instance();
	player.set_name(str(id));
	player.set_network_master(id);
	player.player_id = id;
	player.team_id = players[id]["team_id"];
	player.position = position;
	player.start_pos = position;
	
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
	get_tree().change_scene("res://TitleScreen.tscn");

# Called when this client disconnects from the server
func server_disconnect():
	print("Server Disconnect");
	get_tree().get_root().get_node("MainScene/UI_Layer").enable_leave_match_button();

# Called when a player scores a point
remotesync func round_ended(scoring_team_id, scoring_player_id):
	print("Player : " + str(scoring_player_id) + " won a point for team : " + str(scoring_team_id));
	get_tree().get_root().get_node("MainScene").slowdown_music();
	get_tree().get_root().get_node("MainScene/UI_Layer").set_big_label_text(str(players[scoring_player_id]['name']) + "\nSCORED!", scoring_team_id);
	get_tree().get_root().get_node("MainScene/Score_Audio").play();
	var scoring_player = get_tree().get_root().get_node("MainScene/Players/" + str(scoring_player_id));
	round_is_ended = true;
	print("Round_is_ended");
	# If we are not the server
	if !get_tree().is_network_server():
		var local_player = get_tree().get_root().get_node("MainScene/Players/" + str(get_tree().get_network_unique_id()));
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
remotesync func load_new_round():
	print("Loading New Round");
	round_is_ended = false;
	reset_game_objects();
	get_tree().get_root().get_node("MainScene/Countdown_Audio").play();
	# If we're the server, instruct other to spawn game nodes
	if get_tree().is_network_server():
		# Spawn players
		for player in players:
			var spawn_pos = Vector2(0,0);
			if players[player]["team_id"] == 0:
				spawn_pos = Vector2(-3600, 0);
			elif players[player]["team_id"] == 1:
				spawn_pos = Vector2(3600, 0);
			rpc("spawn_player", player, spawn_pos);
		# Spawn flags
		rpc("spawn_flag", 0, Vector2(-3150, 0), 0);
		rpc("spawn_flag", 1, Vector2(3150, 0), 1);
	
	get_tree().get_root().get_node("MainScene/UI_Layer").clear_big_label_text();
	
	$Round_Start_Timer.start();

# Starts the currently loaded round
remotesync func start_round():
	print("Starting Round");
	get_tree().get_root().get_node("MainScene").slowdown_music();
	# If we are not the server
	if !get_tree().is_network_server():
		var local_player = get_tree().get_root().get_node("MainScene/Players/" + str(get_tree().get_network_unique_id()));
		local_player.control = true;
		local_player.activate_camera();

# Only called on clients by server
remote func end_match(winning_team_id):
	match_is_running = false;
	print("Ending Match");
	var team_name = "NOBODY";
	if winning_team_id == 0:
		team_name = "BLUE TEAM";
	elif winning_team_id == 1:
		team_name = "RED TEAM"
	get_tree().get_root().get_node("MainScene/UI_Layer").set_big_label_text(team_name + " WINS!", winning_team_id);
	get_tree().get_root().get_node("MainScene/UI_Layer").enable_leave_match_button();

# Only called on server by server
func end_match_server(winning_team_id):
	winning_team_id_to_use = winning_team_id;
	print("Calling http request");
	print(Globals.mainServerIP + "gameServerEndMatch?matchID=" + str(Globals.matchID) + "&winningTeamID=" + str(winning_team_id_to_use));
	$HTTPRequest_GameServerEndMatch.request(Globals.mainServerIP + "gameServerEndMatch?matchID=" + str(Globals.matchID) + "&winningTeamID=" + str(winning_team_id_to_use), ["authorization: Bearer " + (Globals.serverPrivateToken)]);

# Temporary storage of the winning_team_id to use since the call GameServerEndMatch may require multiple calls if it fails
var winning_team_id_to_use;
# Called when the HTTP request GameServerEndMatch completes. If successful, it will reset the server for next use after 5 seconds
func _HTTP_GameServerEndMatch_Completed(result, response_code, headers, body):
	if(response_code == 200):
		print("success")
		yield(get_tree().create_timer(5.0), "timeout")
		get_tree().set_network_peer(null);
		start_server();
	else:
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
			print(str(winning_team_id) + " won the match.");
			for i in players:
				rpc_id(i, "end_match", winning_team_id);
			end_match_server(winning_team_id);
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






