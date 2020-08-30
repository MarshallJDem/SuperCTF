extends Node

var		SCORE_LIMIT	= 2;
var		players		= {};
var		flags_data	= {};

var		game_vars	= Globals.game_var_defaults.duplicate();
var		scores		= [];
var		round_num	= 0;

var server = null;
var client = null;
var isSkirmish = false;
var isSuddenDeath = false;
var isDD = false;

signal round_started();

var round_is_ended = false;
var match_is_running = false;
var round_is_running = false;

var Game_Results_Screen = preload("res://Game_Results_Screen.tscn");

# players Struct (Indexed by player game ID (which is only the same as network_id on skirmish, and never the same as uid))
#	- name: string
#	- team_id: int
#	- user_id: int
#	- network_id: int
#	- position: Vector2D
#	- spawn_pos: Vector2D
#	- DD_vote: bool

# flag_data Struct (Indexed by flag id)
#	- holder_player_id: int
#	- position: Vector2D
#	- team_id: int

func _ready():
	if Globals.testing:
		flags_data["0"] = {"team_id" : 0, "position" : get_tree().get_root().get_node("MainScene/Map/YSort/Flag_Home-" + str(0)).position, "holder_player_id" : -1};
		flags_data["1"] = {"team_id" : 1, "position" : get_tree().get_root().get_node("MainScene/Map/YSort/Flag_Home-" + str(1)).position, "holder_player_id" : -1};
		spawn_flag(0);
		spawn_flag(1);
		yield(get_tree().create_timer(2), "timeout");
		end_match(0);
		#call_deferred("spawn_flag", 1, Vector2(-200, 0));
		return;
	if Globals.experimental or Globals.player_status == 1 or (Globals.isServer and (Globals.port == 42402 or Globals.port == 42499)):
		isSkirmish = true;
	if isSkirmish:
		if Globals.experimental:
			Globals.port = 42499;
		Globals.serverIP = Globals.skirmishIPPrefix + str(Globals.port);
	get_tree().connect("network_peer_connected",self, "_client_connected");
	get_tree().connect("network_peer_disconnected",self, "_client_disconnected");
	get_tree().connect("connected_to_server",self, "_connection_ok");
	get_tree().connect("connection_failed",self, "_connection_failed");
	get_tree().connect("server_disconnected",self, "_server_disconnect");
	var _err = $Round_End_Timer.connect("timeout", self, "_round_end_timer_ended");
	_err = $Round_Start_Timer.connect("timeout", self, "_round_start_timer_ended");
	_err = $Match_Start_Timer.connect("timeout", self, "_match_start_timer_ended");
	_err = $Timing_Sync_Timer.connect("timeout", self, "_timing_sync_timer_ended");
	_err = $Cancel_Match_Timer.connect("timeout", self, "_cancel_match_timer_ended");
	_err = $Match_End_Timer.connect("timeout", self, "_match_end_timer_ended");
	_err = $Gameserver_Status_Timer.connect("timeout", self, "_gameserver_status_timer_ended");
	_err = $HTTPRequest_GameServerCheckUser.connect("request_completed", self, "_HTTP_GameServerCheckUser_Completed");
	_err = $HTTPRequest_GameServerPollStatus.connect("request_completed", self, "_HTTP_GameServerPollStatus_Completed");
	_err = $HTTPRequest_GameServerMakeAvailable.connect("request_completed", self, "_HTTP_GameServerMakeAvailable_Completed");
	_err = $HTTPRequest_GameServerEndMatch.connect("request_completed", self, "_HTTP_GameServerEndMatch_Completed");
	_err = $HTTPRequest_GetMatchData.connect("request_completed", self, "_HTTP_GetMatchData_Completed");
	_err = $HTTPRequest_GameServerUpdateStatus.connect("request_completed", self, "_HTTP_GameServerUpdateStatus_Completed");
	_err = $HTTPRequest_GetPredictedMMRChanges.connect("request_completed", self, "_HTTP_GetPredictedMMRChanges_Completed");
	_err = $Match_Time_Limit_Timer.connect("timeout", self, "_match_time_limit_ended");
	if(Globals.isServer):
		start_server();
	else:
		join_server();
	
		
func _process(delta):
	SCORE_LIMIT = get_game_var("scoreLimit");
	if server != null and server.is_listening():
		server.poll();
	if client != null and (client.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED || 
	client.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTING):
		client.poll();
	if $Round_Start_Timer.time_left != 0:
		get_tree().get_root().get_node("MainScene/UI_Layer/Countdown_Label").text = str(int($Round_Start_Timer.time_left) + 1);
	if !Globals.testing and get_tree().is_network_server() and !isSkirmish and $ServerPollStatus_Timer.time_left == 0 and $HTTPRequest_GameServerPollStatus.get_http_client_status() == 0:
		var query = "?knownMatchID=" + (str(Globals.matchID) if Globals.matchID != null else "-1");
		$HTTPRequest_GameServerPollStatus.request(Globals.mainServerIP + "pollGameServerStatus" + query, ["authorization: Bearer " + (Globals.serverPrivateToken)], false);


# Resets all game data so that a new game can be started
func reset_game():
	players = {};
	scores = [];
	server = null;
	client = null;
	round_is_ended = false;
	match_is_running = false;
	round_is_running = false;
	isDD = false;
	isSuddenDeath = false;
	round_num = 0;
	game_vars = Globals.game_var_defaults.duplicate();
	$Match_Time_Limit_Timer.stop();
	$Match_Time_Limit_Timer.wait_time = 300;
	$Match_Time_Limit_Timer.start();
	$Match_Time_Limit_Timer.paused = true;
	get_tree().set_network_peer(null);
	reset_game_objects(true);
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
	server.listen(Globals.port, PoolStringArray(), true);
	get_tree().set_network_peer(server);
	print("IsSkirmish? - " + str(isSkirmish));
	if !isSkirmish:
		print("Making Game Server Available");
		$HTTPRequest_GameServerMakeAvailable.request(Globals.mainServerIP + "makeGameServerAvailable?publicToken=" + str("RANDOMTOKEN"), ["authorization: Bearer " + (Globals.serverPrivateToken)], false);
		updateGameServerStatus(1);
		$Gameserver_Status_Timer.start();
	AudioServer.set_bus_volume_db(0, -500);
	$Timing_Sync_Timer.stop();
	if isSkirmish:
		start_match();


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
		else:
			pass;

func _HTTP_GameServerPollStatus_Completed(result, response_code, headers, body):
	$ServerPollStatus_Timer.start();
	if get_tree().is_network_server():
		if(response_code == 200):
			var json = JSON.parse(body.get_string_from_utf8());
			var matchID = json.result.matchID;
			# If we are already aware of this match
			if Globals.matchID == matchID:
				return;
			Globals.matchID = matchID;
			if matchID:
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
				if(i < ceil(Globals.allowedPlayers.size()/2)):
					team_id = 0;
				var spawn_pos = Vector2(0,0);
				if team_id == 0:
					spawn_pos = Vector2(-1300, 0);
				else:
					spawn_pos = Vector2(1300, 0);
				players[i] = {"name" : "Player" + str(i), "team_id" : team_id, "user_id": user_id, "network_id": 1, "spawn_pos": spawn_pos, "position": spawn_pos, "class" : Globals.Classes.Bullet};
				i += 1;
			print(players);
			start_match();

remotesync func set_game_var(variable, value):
	game_vars[variable] = value;

func get_game_var(name):
	return game_vars[name];

func _gameserver_status_timer_ended():
	updateGameServerStatus();

func _cancel_match_timer_ended():
	# Don't cancel the match if this is a skirmish
	if isSkirmish:
		return;
	# If at this time there are zero connections, cancel the match
	if get_tree().get_network_connected_peers().size() == 0:
		get_tree().set_network_peer(null);
		server = null;
		start_server();
func updateGameServerStatus(status = null):
	if status != null:
		Globals.gameserverStatus = status;
	if $HTTPRequest_GameServerUpdateStatus.get_http_client_status() == 0:
		$HTTPRequest_GameServerUpdateStatus.request(Globals.mainServerIP + "updateGameServerStatus?status=" + String(Globals.gameserverStatus), ["authorization: Bearer " + (Globals.serverPrivateToken)], false);
# Joins a server
func join_server():
	client = WebSocketClient.new();
	
	var url = "ws://" + Globals.serverIP;
	if Globals.useSecure:
		url = "wss://" + Globals.serverIP;
	print("Attempting to connect to server with url : " +str(url));
	var error = client.connect_to_url(url, PoolStringArray(), true);
	
	
	if error == 0:
		get_tree().set_network_peer(client);
	else:
		print(error);
		# Infinetely attempt to reconnect
		yield(get_tree().create_timer(1.0), "timeout");
		join_server();

# Starts the match
func start_match():
	if get_tree().is_network_server():
		# Set each team's score to 0;
		scores = [0, 0];
		rpc("set_scores", scores);
		$Match_Start_Timer.start();
		$Cancel_Match_Timer.start();
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
	if !isSkirmish:
		get_tree().get_root().get_node("MainScene/UI_Layer").set_score_text(scores[0], scores[1]);
	print("current scores: " + str(scores));
	

func spawn_flag(flag_id):
	
	# Spawn Flag
	var flag = load("res://GameContent/Flag.tscn").instance();
	flag.position = flags_data[str(flag_id)]["position"];
	flag.flag_id = flag_id;
	flag.set_team(flags_data[str(flag_id)]["team_id"]);
	flag.home_position = get_tree().get_root().get_node("MainScene/Map/YSort/Flag_Home-" + str(flag_id)).position;
	flag.name = "Flag-" + str(flag_id);
	get_tree().get_root().get_node("MainScene").call_deferred("add_child", flag);
	
	if flags_data[str(flag_id)]["holder_player_id"] != -1:
		get_tree().get_root().get_node("MainScene/Players/P" + str(flags_data[str(flag_id)]["holder_player_id"])).call_deferred("take_flag",(flag_id));

# Called when the client's connection is ready, and then tells the server
func _connection_ok():
	print("Connection OK");
	rpc_id(1, "user_ready", get_tree().get_network_unique_id(), Globals.userToken);

func _connection_failed():
	# Try again cuz this is probably a 1 off issue
	join_server();

func update_player_objects():
	# Delete players that have left and spawn new players
	# For every old player that no longer exists
	for player in get_tree().get_root().get_node("MainScene/Players").get_children():
		var name = player.name;
		name.erase(0,1);
		if !players.has(int(name)):
			player.drop_current_flag();
			player.queue_free();
	# For every new player
	for player in players:
		if !get_tree().get_root().get_node("MainScene/Players").has_node("P" + str(player)):
			spawn_player(player);
	
	for player_id in players:
		if !get_tree().is_network_server() and players[player_id]["network_id"] == get_tree().get_network_unique_id():
			Globals.localPlayerID = player_id;
			Globals.localPlayerTeamID = players[player_id]["team_id"];
		if get_tree().get_root().get_node("MainScene/Players").has_node("P" + str(player_id)):
			var player_node = get_tree().get_root().get_node("MainScene/Players/P" + str(player_id));
			player_node.team_id = players[player_id]["team_id"];
			player_node.player_name = players[player_id]["name"];
			player_node.update_class(players[player_id]["class"]);
			player_node.set_network_master(players[player_id]['network_id']);
			if !get_tree().is_network_server() and players[player_id]['network_id'] == get_tree().get_network_unique_id():
				player_node.control = round_is_running;
				player_node.activate_camera();

remote func player_class_changed(new_class):
	var sender_network_id = get_tree().get_rpc_sender_id();
	for player_id in players:
		if players[player_id]["network_id"] == sender_network_id:
			players[player_id]["class"] = new_class;
			rpc("update_players_data", players, round_is_running);
			return;


remotesync func update_players_data(players_data, round_is_running):
	players = players_data;
	self.round_is_running = round_is_running;
	update_player_objects();

# Resync the clocks between server and clients by using current server time elapsed 
remotesync func update_timing_sync(time_elapsed):
	if !get_tree().is_network_server():
		var new_start_time = OS.get_system_time_msecs() - (time_elapsed + Globals.ping/2.0);
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
			# If this player disconnected already then dont make them a player
			var is_connected = false;
			for peer in get_tree().get_network_connected_peers():
				if peer == network_id:
					is_connected = true;
			if !is_connected:
				return;
			print("HERE");
			print(Globals.allowedPlayers);
			print(user_id);
			# If the user is one of the players in the current match or this is a skirmish
			if(Globals.allowedPlayers.has(user_id) || isSkirmish):
				var message = player_name + " connected to the server";
				get_tree().get_root().get_node("MainScene/UI_Layer/LineEdit").rpc("receive_message", "[color=green]" + message +  "[/color]", -1);
				if isSkirmish:
					var team_id = 0;
					var b=0; var r=0;
					for player_id in players:
						if players[player_id]["team_id"] == 0:
							b += 1;
						else:
							r += 1;
					if b > r:
						team_id = 1;
					var spawn_pos = Vector2(0,0);
					if team_id == 0:
						spawn_pos = Vector2(-1300, 0);
					else:
						spawn_pos = Vector2(1300, 0);
					players[network_id] = {"name" : player_name, "team_id" : team_id, "user_id": user_id, "network_id": network_id,"spawn_pos": spawn_pos, "position": spawn_pos, "class" : Globals.Classes.Bullet};
				# Get the player_id associated with this user_id
				for player_id in players:
					if players[player_id]['user_id'] == user_id:
						# Update the players array and give it to everybody so they can update player data and network masters etc.
						players[player_id]['name'] = player_name;
						players[player_id]['class'] = Globals.Classes.Bullet;
						if players[player_id]['network_id'] != 1 and !isSkirmish:
							server.disconnect_peer(players[player_id]['network_id'], 1000, "A new computer has connected as this player");
						players[player_id]['network_id'] = network_id;
						print("Authenticated new connection and giving them control of player");
						print(players[player_id]);
						rpc("update_players_data", players, round_is_running);
						# If this user is joining mid match
						if match_is_running:
							update_flags_data();
							rpc_id(network_id, "load_mid_round", players, scores, $Round_Start_Timer.time_left, round_num, OS.get_system_time_msecs() - Globals.match_start_time, flags_data, game_vars); 
			else:
				print("Disconnecting player " + str(network_id) + " because they are not in the allowed players list (they mightve connected before we got match data)");
				server.disconnect_peer(network_id, 1000, "You are not a player in this match")
		else:
			print("WE SHOULD BE DISCONNECTING A player because the checkUser backend call failed with a non 200 status BUT WE DON'T KNOW THEIR NETWORKID'");
			#server.disconnect_peer(player_check_queue[0]['networkID'], 1000, "An Unknown Error Occurred.")


func update_flags_data():
	for node in get_tree().get_nodes_in_group("Flags"):
		if node.get_parent().name == "MainScene":
			flags_data[str(node.flag_id)]["holder_player_id"] = -1;
		else:
			var holding_player = node.get_parent().get_parent();
			flags_data[str(node.flag_id)]["holder_player_id"] = holding_player.player_id;
		flags_data[str(node.flag_id)]["position"] = node.position;

# Client calls this on the server to notify that the client's connection is ready
remote func user_ready(id, userToken):
	print("User Ready");
	# Now if we are the server we will add this player to the queue of players to be checked
	if get_tree().is_network_server():
		
		# Wait for match data to come in if this isn't a skirmish
		if(!isSkirmish):
			while(true):
				if(Globals.allowedPlayers != []):
					break;
				print("Waiting for allowed match data to download");
				yield(get_tree().create_timer(0.5), "timeout");
		var http = HTTPRequest.new()
		add_child(http);
		http.connect("request_completed", self, "_HTTP_GameServerCheckUser_Completed")
		http.request(Globals.mainServerIP + "gameServerCheckUser?" + "userToken=" + str(userToken) + "&networkID=" + str(id), ["authorization: Bearer " + Globals.serverPrivateToken], false);
		yield(http, "request_completed");
		http.call_deferred("queue_free");

# A test function for sending a ping
remotesync func test_ping():
	print("Test Ping");


func spawn_player(id):
	var player = load("res://GameContent/Player.tscn").instance();
	player.set_name("P" + str(id));
	player.set_network_master(players[id]["network_id"]);
	player.player_id = id;
	player.team_id = players[id]["team_id"];
	player.position = players[id]["position"];
	player.start_pos = players[id]["spawn_pos"];
	player.current_class = players[id]["class"];
	print("Spawning Player");
	print(players[id]);
	print(get_tree().get_network_unique_id());
	player.player_name = players[id]["name"];
	if players[id]["network_id"] == get_tree().get_network_unique_id():
		player.control = round_is_running;
		player.activate_camera();
	if get_tree().get_root().get_node("MainScene/Players").has_node("P" + str(id)):
		get_tree().get_root().get_node("MainScene/Players/P" + str(id)).set_name("P" + str(id) + "DELETED");
		get_tree().get_root().get_node("MainScene/Players/P" + str(id)).queue_free();
	get_tree().get_root().get_node("MainScene/Players").call_deferred("add_child",player);
	

# Called when a new peer connects
func _client_connected(id):
	#if get_tree().is_network_server():
		#rpc("update_players_data", players, round_is_running);
	print("Client " + str(id) + " connected to Server");
	
	
# Called on when a client disconnects
func _client_disconnected(id):
	print("Client " + str(id) + " disconnected from the Server");
	var player_id = -1;
	for i in players:
		if players[i]["network_id"] == id:
			player_id = i;
	if player_id == -1:
		print("ERROR - CLIENT DISCONNECTED HAD AN UNHANDLED PLAYER ID");
		return;
	if get_tree().is_network_server():
		if $Match_End_Timer.time_left > 0:
			complete_match_end();
			return;
		var message = players[player_id]["name"];
		message += " disconnected from the server";
		get_tree().get_root().get_node("MainScene/UI_Layer/LineEdit").rpc("receive_message", "[color=red]" + message +  "[/color]", -1);
		if isSkirmish:
			players.erase(player_id);
			if players.size() == 0:
				game_vars = Globals.game_var_defaults.duplicate();
		
		rpc("update_players_data", players, round_is_running);
		if !isSkirmish:
			if get_tree().get_network_connected_peers().size() == 0:
				# If this is an actual match, if after 15 seconds go by and there is still 0 connections cancel the match
				yield(get_tree().create_timer(15), "timeout");
				if get_tree().get_network_connected_peers().size() == 0:
					get_tree().set_network_peer(null);
					server = null;
					start_server();
	

# Goes back to title screen and drops the socket connection and resets the game
func leave_match():
	print("Leave Match");
	get_tree().set_network_peer(null);
	client = null;
	reset_game()
	get_tree().change_scene("res://TitleScreen.tscn");

# Called when this client disconnects from the server
func server_disconnect():
	print("LOST CONNECTION WITH SERVER");
	# Only force user back to titlescreen if the game results screen isn't present for some reason
	if !get_tree().get_root().has_node("MainScene/Game_Results_Screen"):
		leave_match();

# Called when a player scores a point or match time runs out
remotesync func round_ended(scoring_team_id, scoring_player_id, time_limit_reached = false):
	if time_limit_reached:
		if !get_tree().is_network_server():
			get_tree().get_root().get_node("MainScene/UI_Layer").set_big_label_text("TIME LIMIT REACHED", Globals.localPlayerTeamID);
	else:
		print("Player : " + str(scoring_player_id) + " won a point for team : " + str(scoring_team_id));
		if !get_tree().is_network_server():
			get_tree().get_root().get_node("MainScene").slowdown_music();
			get_tree().get_root().get_node("MainScene/UI_Layer").set_big_label_text(str(players[scoring_player_id]['name']) + "\nSCORED!", scoring_team_id);
			get_tree().get_root().get_node("MainScene/Score_Audio").play();
			var scoring_player = get_tree().get_root().get_node("MainScene/Players/P" + str(scoring_player_id));
			var local_player = get_tree().get_root().get_node("MainScene/Players/P" + str(Globals.localPlayerID));
			local_player.deactivate_camera();
			scoring_player.activate_camera();
	round_is_ended = true;
	round_is_running = false;
	print("Round_is_ended");
	# If we are not the server
	if !get_tree().is_network_server():
		var local_player = get_tree().get_root().get_node("MainScene/Players/P" + str(Globals.localPlayerID));
		local_player.control = false;
	# Else if we are the server
	else:
		if !isSkirmish and !time_limit_reached:
			scores[scoring_team_id] = scores[scoring_team_id] + 1;
			rpc("set_scores", scores);
			rpc("pause_match_time_limit", $Match_Time_Limit_Timer.time_left);
		$Round_End_Timer.start()

# Resets all objects in the game scene by deleting them
func reset_game_objects(kill_players = false):
	# Remove any old player nodes
	for player in get_tree().get_root().get_node("MainScene/Players").get_children():
		player.position = player.start_pos;
		player.visible = true;
		player.stop_powerups();
		if player.player_id == Globals.localPlayerID:
			player.activate_camera();
		if kill_players:
			player.queue_free();
	# Remove any old flags
	for flag in get_tree().get_nodes_in_group("Flags"):
		flag.set_name(flag.name + "DELETING");
		flag.queue_free();
	# Remove any old projectiles
	for projectile in get_tree().get_nodes_in_group("Projectiles"):
		projectile.set_name(projectile.name + "DELETING");
		projectile.queue_free();
	# Remove any old forcefields
	for forcefield in get_tree().get_nodes_in_group("Forcefields"):
		forcefield.set_name(forcefield.name + "DELETING");
		forcefield.queue_free();
	# Remove any old landmines
	for mine in get_tree().get_nodes_in_group("Landmines"):
		mine.set_name(mine.name + "DELETING");
		mine.die();
	# Remove any powerups
	for powerup in get_tree().get_nodes_in_group("Powerups"):
		powerup.set_name(powerup.name + "DELETING");
		powerup.die();
	Globals.active_landmines = 0;

# Loads up a new round but does not start it yet
# WARNING - you will likely need to make these edits in "load_mid_round" too
remotesync func load_new_round(suddenDeath = false):
	isSuddenDeath = suddenDeath;
	if isSuddenDeath:
		scores = [0,0];
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
	match_is_running = true;
	reset_game_objects();
	get_tree().get_root().get_node("MainScene/Countdown_Audio").play();
	# If we're the server, instruct other to spawn game nodes
	if get_tree().is_network_server():
		# Update score
		rpc("set_scores", scores);
	
	flags_data[str(0)] = {"holder_player_id" : -1, "position": get_tree().get_root().get_node("MainScene/Map/YSort/Flag_Home-" + str(0)).position, "team_id" : 0};
	flags_data[str(1)] = {"holder_player_id" : -1, "position": get_tree().get_root().get_node("MainScene/Map/YSort/Flag_Home-" + str(1)).position, "team_id" : 1};
	spawn_flag(0);
	spawn_flag(1);
	
	get_tree().get_root().get_node("MainScene/UI_Layer").clear_big_label_text();
	$Round_Start_Timer.set_wait_time(3);
	$Round_Start_Timer.start();

# For when a player joins mid round
remote func load_mid_round(players, scores, round_start_timer_timeleft, round_num, round_time_elapsed, flags_data, game_vars):
	print("Loading in the middle of a round" + str(round_num));
	
	# Wait till our player objects have initialized
	while get_tree().get_root().get_node("MainScene/Players").get_child_count() == 0:
		yield(get_tree().create_timer(0.1), "timeout");
	
	self.game_vars = game_vars;
	
	Globals.match_start_time = OS.get_system_time_msecs() - round_time_elapsed;
	# Account for a 1 way of latency
	Globals.match_start_time -= Globals.player_lerp_time/2;
	self.round_num = round_num;
	round_is_ended = false;
	self.players = players;
	self.scores = scores;
	
	self.flags_data = flags_data;
	
	# Spawn flags
	spawn_flag(0);
	spawn_flag(1);
	
	Globals.result_team0_score = scores[0];
	Globals.result_team1_score = scores[1];
	if !isSkirmish:
		get_tree().get_root().get_node("MainScene/UI_Layer").set_score_text(scores[0], scores[1]);
	else:
		get_tree().get_root().get_node("MainScene/UI_Layer").set_score_text(scores[0], scores[1], true);
	
	get_tree().get_root().get_node("MainScene/UI_Layer").clear_big_label_text();
	# If we joined in the middle of the countdown timer, then account for that.
	if (round_start_timer_timeleft) > 0:
		$Round_Start_Timer.set_wait_time(round_start_timer_timeleft);
		$Round_Start_Timer.start();

# Starts the currently loaded round
remotesync func start_round():
	print("Starting Round");
	round_is_running = true;
	emit_signal("round_started");
	get_tree().get_root().get_node("MainScene").slowdown_music();
	# If we are not the server
	if !get_tree().is_network_server():
		var local_player = get_tree().get_root().get_node("MainScene/Players/P" + str(Globals.localPlayerID));
		local_player.control = true;
		local_player.activate_camera();
	else:
		if !isSkirmish and !isSuddenDeath:
			rpc("resume_match_time_limit", $Match_Time_Limit_Timer.time_left);

var match_end_winning_team_id;
# Ends the match
remotesync func end_match(winning_team_id):
	print("Ending Match");
	match_end_winning_team_id = winning_team_id;
	match_is_running = false;
	round_is_running = false;
	if !Globals.testing and get_tree().is_network_server():
		$Match_End_Timer.start();
		yield(get_tree().create_timer(4.0), "timeout");
		$HTTPRequest_GetPredictedMMRChanges.request(Globals.mainServerIP + "gameServerGetPredictedMMRChanges?matchID=" + str(Globals.matchID) + "&winningTeamID=" + str(match_end_winning_team_id), ["authorization: Bearer " + (Globals.serverPrivateToken)]);
	else:
		if !Globals.testing:
			var local_player = get_tree().get_root().get_node("MainScene/Players/P" + str(Globals.localPlayerID));
			local_player.control = false;
		match_is_running = false;
		var team_name = "NOBODY";
		if winning_team_id == 0:
			team_name = "BLUE TEAM";
		elif winning_team_id == 1:
			team_name = "RED TEAM"
		Globals.result_winning_team_id = winning_team_id;
		get_tree().get_root().get_node("MainScene/UI_Layer").set_big_label_text(team_name + " WINS!", winning_team_id);

func _HTTP_GetPredictedMMRChanges_Completed(result, response_code, headers, body):
	if(response_code == 200):
		print("Successfully retrieved predicted MMR Changes");
		var json = JSON.parse(body.get_string_from_utf8());
		rpc("show_results_screen", scores, get_game_stats(), players, json.result);
	else:
		rpc("show_results_screen", scores, get_game_stats(), players,  null);
		# I mean i guess we can't do anything about this failing...
		pass;

func get_game_stats():
	var stats = {};
	for player_id in players:
		if get_tree().get_root().get_node("MainScene/Players").has_node("P" + str(player_id)):
			var player = get_tree().get_root().get_node("MainScene/Players/P" + str(player_id));
			stats[player_id] = player.get_stats();
		else:
			print("I DONT KNOW WHY OR HOW BUT A PLAYER WASN'T SPAWNED ON THE SERVER WHEN GETTING STATS");
	return stats;

remotesync func show_results_screen(scores, stats,players, results):
	if get_tree().is_network_server():
		return;
	var scn = Game_Results_Screen.instance();
	# Get local player user_id
	var uid = players[Globals.localPlayerID]["user_id"];
	# Find our player in the results
	for player in results:
		if str(player["playerId"]) == str(uid):
			scn.old_mmr = player["oldRank"];
			scn.new_mmr = player["newRank"];
	scn.winning_team_ID = match_end_winning_team_id;
	scn.scores = scores;
	scn.player_team_ID = players[Globals.localPlayerID]["team_id"];
	scn.match_ID = Globals.result_match_id;
	scn.stats = stats;
	scn.players = players;
	
	
	
	get_tree().get_root().get_node("MainScene").call_deferred("add_child", scn);
	$"../UI_Layer".disappear();

# Shows over. You don't have to go home but you can't stay here
remotesync func tell_clients_to_piss_off():
	if !get_tree().is_network_server():
		if !get_tree().get_root().has_node("MainScene/Game_Results_Screen"):
			leave_match();
		else:
			get_tree().set_network_peer(null);
			client = null;


func _match_end_timer_ended():
	complete_match_end();

func complete_match_end():
	$Match_End_Timer.stop();
	if get_tree().is_network_server():
		$HTTPRequest_GameServerEndMatch.request(Globals.mainServerIP + "gameServerEndMatch?matchID=" + str(Globals.matchID) + "&winningTeamID=" + str(match_end_winning_team_id), ["authorization: Bearer " + (Globals.serverPrivateToken)]);
		rpc("tell_clients_to_piss_off");

# Called by clients on server to opt in / out of double down rematch
remote func change_DD_vote(vote):
	# Can't have two DDs in a row
	if isDD:
		return;
	print("^CHANGE DD VOTE " + str(vote) + " " + str(get_tree().get_rpc_sender_id()));
	var sender_network_id = get_tree().get_rpc_sender_id();
	var all_true = true;
	for player_id in players:
		# Update vote of the player
		if players[player_id]["network_id"] == sender_network_id:
			players[player_id]["DD_vote"] = vote;
		# See if everyone voted yes
		all_true = all_true and players[player_id]["DD_vote"];
	rpc("update_players_data", players, round_is_running);
	if all_true:
		rpc("start_rematch");

remotesync func start_rematch():
	print("^STARTING REMATCH");
	isDD = true;
	isSuddenDeath = true;
	match_is_running = true;
	round_is_running = false
	if get_tree().is_network_server():
		rpc("load_new_round", true);
		$Match_End_Timer.stop();
	else:
		if get_tree().get_root().has_node("MainScene/Game_Results_Screen"):
			get_tree().get_root().get_node("MainScene/Game_Results_Screen").call_deferred("queue_free");
			get_tree().get_root().get_node("MainScene/UI_Layer").appear();

# Temporary storage of the winning_team_id to use since the call GameServerEndMatch may require multiple calls if it fails
var winning_team_id_to_use;
# Called when the HTTP request GameServerEndMatch completes. If successful, it will reset the server for next use after 5 seconds
func _HTTP_GameServerEndMatch_Completed(result, response_code, headers, body):
	if(response_code == 200):
		print("success");
		updateGameServerStatus(4);
		yield(get_tree().create_timer(5.0), "timeout");
		get_tree().set_network_peer(null);
		server = null;
		start_server();
	else:
		# Endlessly attempt to end the match until the server responds. It is important that this eventually works!
		print("failiure");
		yield(get_tree().create_timer(5.0), "timeout");
		$HTTPRequest_GameServerEndMatch.request(Globals.mainServerIP + "gameServerEndMatch?matchID=" + str(Globals.matchID) + "&winningTeamID=" + str(winning_team_id_to_use), ["authorization: Bearer " + (Globals.serverPrivateToken)]);

# Called when the Round_End_Timer ends
func _round_end_timer_ended():
	# Only run if we are the server
	if get_tree().is_network_server():
		var game_over = false;
		var winning_team_id = -1;
		# If the time ran out
		if $Match_Time_Limit_Timer.time_left == 0:
			# If its a tie, start a sudden death
			if scores[0] == scores[1]:
				rpc("load_new_round", true);
			elif scores[0] > scores[1]: # Blue Wins
				rpc("end_match", 0);
			else: # Red Wins
				rpc("end_match", 1);
			return;
		# If this is sudden death, just take the best score
		if isSuddenDeath:
			winning_team_id = 0;
			game_over = true;
			for i in range(0, scores.size()):
				if scores[i] >= scores[winning_team_id]:
					winning_team_id = i;
		else: # Otherwise if somebody hit score limit then they won
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

remotesync func pause_match_time_limit(time_left):
	$Match_Time_Limit_Timer.stop();
	$Match_Time_Limit_Timer.wait_time = time_left;
	$Match_Time_Limit_Timer.start();
	$Match_Time_Limit_Timer.paused = true;

remotesync func resume_match_time_limit(time_left):
	$Match_Time_Limit_Timer.stop();
	$Match_Time_Limit_Timer.wait_time = time_left;
	$Match_Time_Limit_Timer.start();
	$Match_Time_Limit_Timer.paused = false;

func _match_time_limit_ended():
	if get_tree().is_network_server():
		rpc("round_ended",-1,-1,true);





