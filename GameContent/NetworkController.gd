extends Node

var		SCORE_LIMIT	= 2;
var		players		= {};
var		flags_data	= {};

var		game_vars	= Globals.game_var_defaults.duplicate();
var		scores		= [];
var		round_num	= 0;

var bot_id_tracker = 0 # For assigning unique ids to bots. First one will be -1

var server = null;
var client = null;
var isSuddenDeath = false;
var isDD = false;

var game_loaded = false;

signal round_started();

var round_is_ended = false;
var match_is_running = false;
var round_is_running = false;

var Game_Results_Screen = preload("res://Game_Results_Screen.tscn");

# players Struct (Indexed by player game ID (which is arbitrary 0,1,2,3, etc in a match and UID in a skirmish))
#	- name: string
#	- team_id: int
#	- user_id: int
#	- network_id: int
#	- position: Vector2D
#	- spawn_pos: Vector2D
#	- DD_vote: bool
#	- BOT: bool

# flag_data Struct (Indexed by flag id)
#	- holder_player_id: int
#	- position: Vector2D
#	- team_id: int

func _ready():
	
	if !Globals.isServer and (Globals.player_status == 1 || Globals.directLiveSkirmish):
		print("Overriding matchType and setting to 0 (This should not happen on servers)");
		Globals.matchType = 0;
		Globals.serverIP = Globals.skirmishIP;
	if Globals.matchType == 0:
		Globals.mapName = Globals.skirmishMap;
	
		
	spawn_map(Globals.mapName);
	
	if Globals.testing:
		call_deferred("init_map_for_testing");
		return;
	
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
	_err = $HTTPRequest_GameServerConfirmConnection.connect("request_completed", self, "_HTTP_GameServerConfirmConnection_Completed");
	_err = $HTTPRequest_GameServerEndMatch.connect("request_completed", self, "_HTTP_GameServerEndMatch_Completed");
	_err = $HTTPRequest_GetPredictedMMRChanges.connect("request_completed", self, "_HTTP_GetPredictedMMRChanges_Completed");
	_err = $Match_Time_Limit_Timer.connect("timeout", self, "_match_time_limit_ended");
	if(Globals.isServer):
		call_deferred("start_server");
	else:
		call_deferred("join_server");

func spawn_map(map_name = "TehoMap1"):
	var map = load("res://GameContent/Maps/" + map_name + ".tscn").instance();
	map.name = "Map";
	get_tree().get_root().get_node("MainScene").call_deferred("add_child", map);

func init_map_for_testing():
	flags_data["0"] = {"team_id" : 0, "position" : get_tree().get_root().get_node("MainScene/Map/YSort/Flag_Home-" + str(0)).position, "holder_player_id" : -1};
	flags_data["1"] = {"team_id" : 1, "position" : get_tree().get_root().get_node("MainScene/Map/YSort/Flag_Home-" + str(1)).position, "holder_player_id" : -1};
	spawn_flag(0);
	spawn_flag(1);

func _process(delta):
	SCORE_LIMIT = get_game_var("scoreLimit");
	if server != null and server.is_listening() and (server.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED || 
	server.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTING):
		server.poll();
	if client != null and (client.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTED || 
	client.get_connection_status() == NetworkedMultiplayerPeer.CONNECTION_CONNECTING):
		client.poll();
	if $Round_Start_Timer.time_left != 0:
		var label = get_tree().get_root().get_node_or_null("MainScene/UI_Layer/Countdown_Label");
		if label != null:
			label.text = str(int($Round_Start_Timer.time_left) + 1);

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
	get_tree().get_root().get_node("MainScene/UI_Layer").clear_big_label_text();

# Starts a server
func start_server():
	print("Starting Server");
	reset_game();
	server = WebSocketServer.new();
	if Globals.useSecure:
		server.private_key = load("res://HTTPS_Keys/linux_privkey.key");
		server.ssl_certificate = load("res://HTTPS_Keys/linux_cert.crt");
	server.listen(Globals.port, PoolStringArray(), true);
	get_tree().set_network_peer(server);
	AudioServer.set_bus_volume_db(0, -500);
	$Timing_Sync_Timer.stop();
	if Globals.matchType == 0:
		print("Starting a skirmish");
		start_match();
	else:
		print("Starting a match using command line matchData");
		$HTTPRequest_GameServerConfirmConnection.request(Globals.mainServerIP + "gameServerConfirmConnection", ["authorization: Bearer " + (Globals.serverPrivateToken)], false);
		var i = 0;
		# Go through each new allowed player and populate the players array
		for player in Globals.allowedPlayers:
			var team_id = 1;
			if(i < ceil(Globals.allowedPlayers.size()/2)):
				team_id = 0;
			var spawn_pos = Vector2(0,0);
			if team_id == 0:
				var spawn = get_tree().get_root().get_node_or_null("MainScene/Map/YSort/BlueSpawn_Location");
				if spawn != null:
					spawn_pos = spawn.position;
				else:
					print("<ERROR> Map not found");
					print_stack();
			else:
				var spawn = get_tree().get_root().get_node_or_null("MainScene/Map/YSort/RedSpawn_Location");
				if spawn != null:
					spawn_pos = spawn.position;
				else:
					print("<ERROR> Map not found");
					print_stack();
			players[i] = {"name" : str(player.name), "team_id" : team_id, "user_id": int(player.uid), "network_id": 1, "spawn_pos": spawn_pos, "position": spawn_pos, "class" : Globals.Classes.Bullet, "DD_vote" : false, "BOT" : false};
			i += 1;
		start_match();



func _HTTP_GameServerConfirmConnection_Completed(result, response_code, headers, body):
	if response_code != 200:
		print("Error with _HTTP_GameServerConfirmConnection_Completed");
	if get_tree().is_network_server():
		# Poll endlessly
		yield(get_tree().create_timer(3.0), "timeout");
		$HTTPRequest_GameServerConfirmConnection.request(Globals.mainServerIP + "gameServerConfirmConnection", ["authorization: Bearer " + (Globals.serverPrivateToken)], false);

remotesync func set_game_var(variable, value):
	game_vars[variable] = value;

func get_game_var(name):
	return game_vars[name];

func _cancel_match_timer_ended():
	if !get_tree().is_network_server():
		return;
	# Don't cancel the match if this is a skirmish
	if Globals.matchType == 0:
		return;
	
	# If any players have not connected yet, cancel the match
	var allConnected = true;
	for player in players:
		if players[player]["network_id"] == 1:
			allConnected = false;
	# Cancel match if its ranked and any players are missing, otherwise only cancel if nobody has connected
	if (not allConnected and Globals.matchType == 2 and !Globals.temporaryQuickplayDisable) or (get_tree().get_network_connected_peers().size() == 0):
		rpc("cancel_match");
	else:
		print("Decided not to cancel match")

remotesync func cancel_match():
	if get_tree().is_network_server():
		# TODO WARN THE BACKEND 
		print("Canceling match");
		print("WARNING WE STILL HAVE A TODO TO WARN THE BACKEND ABOUT CANCELING");
		get_tree().quit();
	else:
		Globals.create_popup("The match was canceled due to one or more players failing to connect. If this is happening consistently, please let us know in the discord. Something may be wrong with the servers.");
		leave_match();

# Joins a server
func join_server():
	client = WebSocketClient.new();
	client.verify_ssl = false;
	# TODO make this work on backend
	var url = "ws://" + Globals.serverIP;
	if Globals.useSecure:
		url = "wss://" + Globals.serverIP;
	print("Attempting to connect to server with url : " +str(url));
	var error = client.connect_to_url(url, PoolStringArray(), true);
	
	
	if error == 0:
		get_tree().set_network_peer(client);
	else:
		print("ERROR CONNECTING TO SERVER");
		print(error);
		# Attempt one more connection
		yield(get_tree().create_timer(1.0), "timeout");
		error = client.connect_to_url(url, PoolStringArray(), true);
		if error == 0:
			get_tree().set_network_peer(client);
		else:
			if Globals.matchType == 0:
				Globals.create_popup("Failed to join the skirmish lobby. You are still successfully in the matchmaking queue, but please tell us on discord that our skirmish lobby is down!  Error code 1552");
			else:
				Globals.create_popup("Failed to join the match. You should try refreshing your page. If that doesn't work please tell us in the discord that something went wrong with your match!  Error code 16122");

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

# Sets the score of the game to the given score. This should only ever be called by the server
remotesync func set_scores(new_scores):
	scores = new_scores;
	Globals.result_team0_score = scores[0];
	Globals.result_team1_score = scores[1];
	if Globals.matchType != 0:
		get_tree().get_root().get_node("MainScene/UI_Layer").set_score_text(scores[0], scores[1]);
	print("current scores: " + str(scores));
	

func spawn_flag(flag_id):
	
	# Spawn Flag
	var flag = load("res://GameContent/Flag.tscn").instance();
	flag.position = flags_data[str(flag_id)]["position"];
	flag.flag_id = flag_id;
	flag.set_team(flags_data[str(flag_id)]["team_id"]);
	var home = get_tree().get_root().get_node("MainScene/Map/YSort/Flag_Home-" + str(flag_id));
	if home != null:
		flag.home_position = home.position;
	else:
		print_stack();
	flag.name = "Flag-" + str(flag_id);
	get_tree().get_root().get_node("MainScene").call_deferred("add_child", flag);
	
	if flags_data[str(flag_id)]["holder_player_id"] != -1:
		var player = get_tree().get_root().get_node_or_null("MainScene/Players/P" + str(flags_data[str(flag_id)]["holder_player_id"]));
		if player != null:
			player.call_deferred("take_flag",(flag_id));
		else:
			print("ERROR FOUND NULL PLAYER IN SPAWN FLAG");
			print_stack();

# Called when the client's connection is ready, and then tells the server
func _connection_ok():
	print("Connection OK");
	rpc_id(1, "user_ready", get_tree().get_network_unique_id(), Globals.userToken);

func _connection_failed():
	print("Connection to serverfailed");
	if Globals.matchType == 0:
		Globals.create_popup("Something unknown went wrong when trying to connect to the skirmish lobby. You are still likely successfully in the matchmaking queue.");
	else:
		Globals.create_popup("Something unknown went wrong when trying to connect to the game server. You should try refreshing your page. That being said this is most likely our fault.");

func update_player_objects():
	# Delete players that have left and spawn new players
	# For every old player that no longer exists
	for player in get_tree().get_root().get_node("MainScene/Players").get_children():
		var n = player.name;
		n.erase(0,1);
		if !players.has(int(n)):
			player.drop_current_flag();
			player.call_deferred("free");
	# For every new player
	for player in players:
		if !get_tree().get_root().get_node("MainScene/Players").has_node("P" + str(player)):
			spawn_player(player);
	# For every 
	for player_id in players:
		if !get_tree().is_network_server() and players[player_id]["network_id"] == get_tree().get_network_unique_id():
			Globals.localPlayerID = player_id;
			Globals.localPlayerTeamID = players[player_id]["team_id"];
		var player_node = get_tree().get_root().get_node_or_null("MainScene/Players/P" + str(player_id));
		if player_node != null:
			player_node.set_team_id(players[player_id]["team_id"])
			player_node.start_pos = players[player_id]["spawn_pos"]
			player_node.player_name = players[player_id]["name"];
			player_node.update_class(players[player_id]["class"]);
			player_node.set_network_master(players[player_id]['network_id']);
			if !get_tree().is_network_server() and players[player_id]['network_id'] == get_tree().get_network_unique_id():
				player_node.control = round_is_running;
				player_node.activate_camera();
		else:
			pass
			#TODO TAKE CARE OF THIS. THIS HAPPENS A LOT PROBS BECAUSE THE OBJECT DOESN INSTANCE IMMEDIATELY

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
		#rpc("resync_match_time_limit", $Match_Time_Limit_Timer.time_left, $Match_Time_Limit_Timer.paused);
func _HTTP_GameServerCheckUser_Completed(result, response_code, headers, body):
	if get_tree().is_network_server():
		if(response_code == 200):
			# Get some precursor information about this player situation before making decisions
			var json = JSON.parse(body.get_string_from_utf8());
			var player_name = json.result.user.name;
			var user_id = int(json.result.user.uid);
			var network_id = int(json.result.networkID);
			# If this player disconnected already then dont make them a player
			var is_connected = false;
			for peer in get_tree().get_network_connected_peers():
				if peer == network_id:
					is_connected = true;
			if !is_connected:
				return;
			# If the user is one of the players in the current match or this is a skirmish
			var allowed = false;
			for player in Globals.allowedPlayers:
				if str(player.uid) == str(user_id):
					allowed = true;
			var player_id_collision = null;
			for player_id in players:
				if players[player_id]['user_id'] == user_id:
					player_id_collision = player_id;
			
			#START MAKING DECISIONS:
			
			# Kick unallowed players if this is a match (not a skirmish)
			if(allowed || Globals.matchType == 0):
				var message = player_name + " connected";
				get_tree().get_root().get_node("MainScene/Chat_Layer/Line_Edit").rpc("receive_message", "[color=green]" + message +  "[/color]", -1);
			else:
				print("Disconnecting player " + str(network_id) + " " + str(json.result.user.uid) + " because they are not in the allowed players list : " + to_json(Globals.allowedPlayers));
				server.disconnect_peer(network_id, 1000, "You are not a player in this match")
				return;
			
			
			# If there is a collision, disconnect original peer if there was one
			if player_id_collision != null:
				if players[player_id_collision]['network_id'] != 1:
					print("Disconnecting peer " + str(players[player_id_collision]['network_id']) + " because a new player connected to the same user id " + str(user_id) + " and name " + str(player_name) +  " with new network id: " + str(network_id));
					server.disconnect_peer(players[player_id_collision]['network_id'], 1000, "A new computer has connected as this player");
			# Else if this is a skirmish, and there is no collision, allocate a new player for this connection
			elif Globals.matchType == 0:
				# Choose team
				var team_id = 0;
				team_id = allocate_bots_for_new_player()
				# Get spawn points
				var spawn_pos = get_default_spawn_for_team(team_id)
				players[user_id] = {"name" : player_name, "team_id" : team_id, "user_id": user_id, "network_id": network_id,"spawn_pos": spawn_pos, "position": spawn_pos, "class" : Globals.Classes.Bullet, "DD_vote" : false, "BOT" : false};
				player_id_collision = user_id;
				print("Added a new player for Skirmish of networkID : " + str(network_id) + " | userID : " + str(user_id) + " | name : " + str(player_name));
			else: #Else if there is no collision and this is a match, then something has gone wrong. Disconnect the peer
				print("A PLAYER CONNECTED TO MATCH AND WAS IN ALLOWED PLAYER BUT WE HAD NO ALLOCATED SPOT FOR THEM. DISCONNECTING PEER");
				server.disconnect_peer(network_id, 1000, "Something went wrong sorry! We don't know the issue yet.");
			
			# Through the above logic player_id_collision must no longer be null and we can now update the players data to tell people
			players[player_id_collision]['name'] = player_name;
			# TODO FORCE PLAYER TO USE EXISTING CLASS
			players[player_id_collision]['class'] = Globals.Classes.Bullet;
			players[player_id_collision]['network_id'] = network_id;
			print("Authenticated new connection : " + str(network_id) + " and giving them control of player id " + str(player_id_collision) + " with name " + str(player_name));
			rpc("update_players_data", players, round_is_running);
			rpc("resync_match_time_limit", $Match_Time_Limit_Timer.time_left, $Match_Time_Limit_Timer.paused);
			# If this user is joining mid match
			if match_is_running:
				update_flags_data();
				rpc_id(network_id, "load_mid_round", players, scores, $Round_Start_Timer.time_left, round_num, OS.get_system_time_msecs() - Globals.match_start_time, flags_data, game_vars); 

			
		else:
			print("WE SHOULD BE DISCONNECTING A player because the checkUser backend call failed with a non 200 status BUT WE DON'T KNOW THEIR NETWORKID'");
			#server.disconnect_peer(player_check_queue[0]['networkID'], 1000, "An Unknown Error Occurred.")

# Figures out what team a new player should join and what bots to add
func allocate_bots_for_new_player():
	var team_id = 0
	# How many players are on each team
	var b=0; var r=0; #Real players
	var bots_b=0; var bots_r=0;#Bots
	# Go through teams and count up players
	for player_id in players:
		if players[player_id]["team_id"] == 0:
			b += 1;
			if players[player_id]["BOT"] == true:
				bots_b += 1
				b -= 1 # dont double count bots
		else:
			r += 1;
			if players[player_id]["BOT"] == true:
				bots_r += 1
				r -= 1 # dont double count bots
	# If there are more REAL players on blue team, assign to red
	if b > r:
		team_id = 1;
		# Remove a bot from red team
		var removed_a_bot = false
		for player_id in players:
			if players[player_id]["team_id"] == 1 and players[player_id]["BOT"] == true:
				players.erase(player_id);
				print("Removed a bot from red team " + str(player_id))
				removed_a_bot = true
				break
		if !removed_a_bot:
			print("ERROR: WE SHOULD HAVE REMOVED A BOT FROM RED TEAM BUT WE COULDNT FIND ONE")
	else: # Else assign to blue
		team_id = 0;
		# If there are any bots on blue team, remove one
		if bots_b > 0:
			var removed_a_bot = false
			for player_id in players:
				if players[player_id]["team_id"] == 0 and players[player_id]["BOT"] == true:
					players.erase(player_id);
					print("Removed a bot from blue team " + str(player_id))
					removed_a_bot = true
					break
			if !removed_a_bot:
				print("ERROR: WE SHOULD HAVE REMOVED A BOT FROM RED TEAM BUT WE COULDNT FIND ONE")
		# Else add a bot to red team
		else:
			bot_id_tracker -= 1
			var bot_id = bot_id_tracker
			add_bot(1)
			print("Added a bot to red team " + str(bot_id))
	return team_id

func get_default_spawn_for_team(team_id):
	var spawn_pos = Vector2(0,0)
	if team_id == 0:
		var spawn = get_tree().get_root().get_node_or_null("MainScene/Map/YSort/BlueSpawn_Location");
		if spawn != null:
			spawn_pos = spawn.position;
		else:
			print("<ERROR> Map not found");
			print_stack();
	else:
		var spawn = get_tree().get_root().get_node_or_null("MainScene/Map/YSort/RedSpawn_Location");
		if spawn != null:
			spawn_pos = spawn.position;
		else:
			print("<ERROR> Map not found");
			print_stack();
	return spawn_pos

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
		var net_id = get_tree().get_rpc_sender_id();
		var repeats = 0;
		var http = HTTPRequest.new();
		add_child(http);
		http.connect("request_completed", self, "_HTTP_GameServerCheckUser_Completed")
		http.request(Globals.mainServerIP + "gameServerCheckUser?" + "userToken=" + str(userToken) + "&networkID=" + str(id), ["authorization: Bearer " + Globals.serverPrivateToken], false);
		yield(http, "request_completed");
		http.call_deferred("free");

# A test function for sending a ping
remotesync func test_ping():
	print("Test Ping");

func add_bot(team_id):
	if !get_tree().is_network_server():
		return
	bot_id_tracker -= 1
	var bot_id = bot_id_tracker
	players[bot_id] = {"name" : "BOT"+str(-1*bot_id), "team_id" : team_id, 
		"user_id": bot_id, "network_id": 1,"spawn_pos": get_default_spawn_for_team(team_id), 
		"position": get_default_spawn_for_team(team_id), "class" : Globals.Classes.Bullet, 
		"DD_vote" : false, "BOT" : true};
	
	rpc("update_players_data",players,round_is_running)
	
func spawn_player(id):
	
	var p = get_tree().get_root().get_node_or_null("MainScene/Players/P" + str(id));
	if p != null:
		p.set_name("P" + str(id) + "DELETED");
		p.call_deferred("free");
	
	var player = load("res://GameContent/Player.tscn").instance();
	player.set_name("P" + str(id));
	player.set_network_master(players[id]["network_id"]);
	player.player_id = id;
	player.team_id = players[id]["team_id"];
	player.position = players[id]["position"];
	player.start_pos = players[id]["spawn_pos"];
	player.current_class = players[id]["class"];
	player.is_bot = players[id]["BOT"]
	print("Spawning Player " + str(players[id]));
	player.player_name = players[id]["name"];
	if players[id]["network_id"] == get_tree().get_network_unique_id():
		player.control = round_is_running;
		player.activate_camera();
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
			# Delete as we go just incase something weird happens and we have multiple entries for one network_id
			if get_tree().is_network_server():
				var message = players[player_id]["name"];
				message += " disconnected";
				for peer in  get_tree().get_network_connected_peers():
					get_tree().get_root().get_node("MainScene/Chat_Layer/Line_Edit").rpc_id(peer, "receive_message", "[color=red]" + message +  "[/color]", -1);
				get_tree().get_root().get_node("MainScene/Chat_Layer/Line_Edit").receive_message( "[color=red]" + message +  "[/color]", -1);
				if Globals.matchType == 0:
					print("Erasing player_id " + str(player_id) + " with name " + str(players[player_id]["name"]));
					var team_id = players[player_id]["team_id"]
					players.erase(player_id);
					compensate_bots_for_player_leaving(team_id)
					# If this is a skirmish and there are no players left, reset some stuff
					if players.size() == 0:
						game_vars = Globals.game_var_defaults.duplicate();
						for flag in get_tree().get_nodes_in_group("Flags"):
							flag.rpc("return_home")
	if player_id == -1:
		print("COULDNT FIND PLAYER IN PLAYERS DATA TO DELETE FOR NETWORKID : " + str(id));
		return;
	if get_tree().is_network_server():
		if $Match_End_Timer.time_left > 0:
			complete_match_end();
			return;
		for peer in  get_tree().get_network_connected_peers():
			rpc_id(peer,"update_players_data", players, round_is_running);
		update_players_data(players,round_is_running);
		if Globals.matchType != 0:
			if get_tree().get_network_connected_peers().size() == 0:
				# If this is an actual match, if after 15 seconds go by and there is still 0 connections cancel the match
				yield(get_tree().create_timer(15), "timeout");
				if get_tree().get_network_connected_peers().size() == 0:
					rpc("cancel_match");
	else: # This will disable DD buttons etc on game results screen
		if $Match_End_Timer.time_left > 0:
			$Match_End_Timer.stop();

func compensate_bots_for_player_leaving(team_id):
	var enemy_team_id = 1 if team_id == 0 else 0
	# Try first compensating by deleting an enemy bot
	for id in players:
		if players[id]["team_id"] == enemy_team_id and players[id]["BOT"] == true:
			players.erase(id)
			return
	# If no enemy bots were found, add one for this team since theyre losing a player
	add_bot(team_id)

# Goes back to title screen and drops the socket connection and resets the game
func leave_match():
	print("Leave Match");
	get_tree().change_scene("res://TitleScreen.tscn");
	get_tree().call_deferred("set_network_peer", null);
	call_deferred("free");

# Called when this client disconnects from the server
func server_disconnect():
	print("LOST CONNECTION WITH SERVER");
	# Force user back to titlescreen if the game results screen isn't present for some reason
	if !get_tree().get_root().has_node("MainScene/Game_Results_Screen"):
		leave_match();
	else: # Otherwise set match end timer to 0 for the game results screen to take notice of
		$Match_End_Timer.stop();

# Called when a player scores a point or match time runs out
remotesync func round_ended(scoring_team_id, scoring_player_id, time_limit_reached = false):
	if time_limit_reached:
		if !get_tree().is_network_server():
			get_tree().get_root().get_node("MainScene/UI_Layer").set_big_label_text("TIME LIMIT REACHED", Globals.localPlayerTeamID);
	else:
		print("Player : " + str(scoring_player_id) + " won a point for team : " + str(scoring_team_id));
		# Visuals 
		get_tree().get_root().get_node("MainScene").slowdown_music();
		get_tree().get_root().get_node("MainScene/UI_Layer").set_big_label_text(str(players[scoring_player_id]['name']) + "\nSCORED!", scoring_team_id);
		get_tree().get_root().get_node("MainScene/Score_Audio").play();
		
		if !get_tree().is_network_server():
			var scoring_player = get_tree().get_root().get_node_or_null("MainScene/Players/P" + str(scoring_player_id));
			var local_player = get_tree().get_root().get_node_or_null("MainScene/Players/P" + str(Globals.localPlayerID));
			if local_player != null:
				local_player.deactivate_camera();
			else:
				print_stack();
			if scoring_player != null:
				scoring_player.activate_camera();
			else:
				print_stack();
	round_is_ended = true;
	round_is_running = false;
	print("Round_is_ended");
	# If we are not the server
	if !get_tree().is_network_server():
		var local_player = get_tree().get_root().get_node_or_null("MainScene/Players/P" + str(Globals.localPlayerID));
		if local_player != null:
			local_player.control = false;
		else:
			print_stack();
	# Else if we are the server
	else:
		for p in get_tree().get_nodes_in_group("Players"):
			p.control = false;
		if Globals.matchType != 0 and !time_limit_reached:
			scores[scoring_team_id] = scores[scoring_team_id] + 1;
			rpc("set_scores", scores);
			rpc("pause_match_time_limit", $Match_Time_Limit_Timer.time_left);
		$Round_End_Timer.start()

# Resets all objects in the game scene by deleting them
func reset_game_objects(kill_players = false):
	# Refresh player properties
	for player in get_tree().get_root().get_node("MainScene/Players").get_children():
		player.position = player.start_pos;
		player.visible = true;
		player.stop_powerups();
		if player.player_id == Globals.localPlayerID:
			player.activate_camera();
		# Remove any old player nodes
		if kill_players:
			player.call_deferred("free");
	# Remove any old flags
	for flag in get_tree().get_nodes_in_group("Flags"):
		flag.set_name(flag.name + "DELETING");
		flag.call_deferred("free");
	# Remove any old projectiles
	for projectile in get_tree().get_nodes_in_group("Projectiles"):
		projectile.set_name(projectile.name + "DELETING");
		projectile.call_deferred("free");
	# Remove any old forcefields
	for forcefield in get_tree().get_nodes_in_group("Forcefields"):
		forcefield.set_name(forcefield.name + "DELETING");
		forcefield.call_deferred("free");
	# Remove any old landmines
	for mine in get_tree().get_nodes_in_group("Landmines"):
		mine.set_name(mine.name + "DELETING");
		mine.die();
	# Remove any powerups
	for powerup in get_tree().get_nodes_in_group("Powerups"):
		powerup._used();
	Globals.active_landmines = 0;

# Loads up a new round but does not start it yet
# WARNING - you will likely need to make these edits in "load_mid_round" too
remotesync func load_new_round(suddenDeath = false, new_player_data = null):
	print("Loading New Round" + str(round_num + 1));
	game_loaded = true;
	isSuddenDeath = suddenDeath;
	# Reset ults for sudden death
	if isSuddenDeath:
		scores = [0,0];
		for player in get_tree().get_root().get_node("MainScene/Players").get_children():
			player.get_node("Ability_Node").ult_charge = 0;
	
	# Sometimes we directly pass new player data (in between rounds of skirmish)
	# This helps us switch up teams and not run into async issues with RPC
	if new_player_data != null:
		players = new_player_data
		update_player_objects()
	
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
	
	# If we're the server, instruct other to spawn game nodes
	if get_tree().is_network_server():
		# Update score
		rpc("set_scores", scores);
	
	reset_game_objects()
	
	var home0 = get_tree().get_root().get_node("MainScene/Map/YSort/Flag_Home-" + str(0));
	var home1 = get_tree().get_root().get_node("MainScene/Map/YSort/Flag_Home-" + str(1));
	flags_data[str(0)] = {"holder_player_id" : -1, "position": Vector2.ZERO, "team_id" : 0};
	flags_data[str(1)] = {"holder_player_id" : -1, "position": Vector2.ZERO, "team_id" : 1};
	if home0 != null:
		flags_data[str(0)]["position"] = home0.position;
	else:
		print_stack();
	if home1 != null:
		flags_data[str(1)]["position"] = home1.position;
	else:
		print_stack();
	spawn_flag(0);
	spawn_flag(1);
	
	
	get_tree().get_root().get_node("MainScene/UI_Layer").clear_big_label_text();
	
	
	if isSuddenDeath:
		var overlay = load("res://GameContent/SuddenDeath_Overlay.tscn").instance();
		get_tree().get_root().get_node("MainScene").call_deferred("add_child", overlay);
		yield(get_tree().create_timer(9), "timeout");
		get_tree().get_root().get_node("MainScene/Countdown_Audio").play();
		$Round_Start_Timer.set_wait_time(3);
		$Round_Start_Timer.start();
	else:
		get_tree().get_root().get_node("MainScene/Countdown_Audio").play();
		$Round_Start_Timer.set_wait_time(3);
		$Round_Start_Timer.start();

# Rearrange the teams and removes extraneous bots. Used inbetween rounds of skirmish
func rearrange_teams():
	# Delete all bots
	for player_id in players:
		if players[player_id]["BOT"]:
			players.erase(player_id)
	
	# Shuffle real player ids
	var ids = players.keys()
	ids.shuffle()
	
	# Assign to teams
	var i = 0
	var teams = [0,1]
	teams.shuffle() # Shuffle blue vs red
	for id in ids:
		# If in first half, assign to team 1
		if i < ids.size()/2:
			players[id]["team_id"] = teams[0]
			players[id]["spawn_pos"] = get_default_spawn_for_team(teams[0])
		else: # Else team 2
			players[id]["team_id"] = teams[1]
			players[id]["spawn_pos"] = get_default_spawn_for_team(teams[1])
		i += 1
	
	# If teams are uneven, assign one bot to first team
	if ids.size()%2 != 0:
		add_bot(teams[0])
	
	
	
# For when a player joins mid round
remote func load_mid_round(players, scores, round_start_timer_timeleft, round_num, round_time_elapsed, flags_data, game_vars):
	print("Loading in the middle of a round" + str(round_num));
	game_loaded = true;
	
	# Wait til our player objects have initialized
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
	if Globals.matchType != 0:
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
	# If we haven't loaded the game yet, ignore the call.
	# This can occasionally happen if a player somehow joins just at the right
	# time that this function calls before they load in
	if !game_loaded:
		return;
	
	print("Starting Round");
	round_is_running = true;
	emit_signal("round_started");
	get_tree().get_root().get_node("MainScene").slowdown_music();
	# If we are not the server
	if !get_tree().is_network_server():
		var local_player = get_tree().get_root().get_node_or_null("MainScene/Players/P" + str(Globals.localPlayerID));
		if local_player != null:
			local_player.control = true;
			local_player.activate_camera();
		else:
			print_stack();
	else:
		var is_first = true
		for p in get_tree().get_nodes_in_group("Players"):
			p.control = true
			if is_first:
				p.activate_camera();
				is_first = false
		if Globals.matchType != 0 and !isSuddenDeath:
			rpc("resume_match_time_limit", $Match_Time_Limit_Timer.time_left);

var match_end_winning_team_id;
# Ends the match
remotesync func end_match(winning_team_id):
	print("Ending Match");
	match_end_winning_team_id = winning_team_id;
	match_is_running = false;
	round_is_running = false;
	$Match_End_Timer.start();
	if !Globals.testing and get_tree().is_network_server():
		yield(get_tree().create_timer(4.0), "timeout");
		if(Globals.matchType == 2): # Ranked
			print("GETTING PREDICTED CHANGES WITH MATCHID : " + str(Globals.matchID));
			$HTTPRequest_GetPredictedMMRChanges.request(Globals.mainServerIP + "gameServerGetPredictedMMRChanges?matchID=" + str(Globals.matchID) + "&winningTeamID=" + str(match_end_winning_team_id) + "&isDoubleDown=" + str(isDD), ["authorization: Bearer " + (Globals.serverPrivateToken)]);
		elif(Globals.matchType == 1): # Quickplay
			rpc("show_results_screen", scores, get_game_stats(), players, null, Globals.matchType);
		else:
			# Uh oh sphagettios
			print("ERROR : THERE WAS NOT A VALID MATCH TYPE WHEN TRYING TO END THE MATCH");
			rpc("show_results_screen", scores, get_game_stats(), players, null, Globals.matchType);
	
	else:
		if !Globals.testing:
			var local_player = get_tree().get_root().get_node_or_null("MainScene/Players/P" + str(Globals.localPlayerID));
			if local_player != null:
				local_player.control = false;
			else:
				print_stack();
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
		rpc("show_results_screen", scores, get_game_stats(), players, json.result, Globals.matchType);
	else:
		rpc("show_results_screen", scores, get_game_stats(), players,  null, Globals.matchType);
		# I mean i guess we can't do anything about this failing...
		pass;

func get_game_stats():
	var stats = {};
	for player_id in players:
		var player = get_tree().get_root().get_node_or_null("MainScene/Players/P" + str(player_id));
		if player != null:
			stats[player_id] = player.get_stats();
		else:
			print("I DONT KNOW WHY OR HOW BUT A PLAYER WASN'T SPAWNED ON THE SERVER WHEN GETTING STATS");
	return stats;

remotesync func show_results_screen(scores, stats,players, results, matchType):
	if get_tree().is_network_server():
		return;
	var scn = Game_Results_Screen.instance();
	# Get local player user_id
	var uid = players[Globals.localPlayerID]["user_id"];
	if results != null:
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
	scn.matchType = matchType;
	
	get_tree().get_root().get_node("MainScene").call_deferred("add_child", scn);
	$"../UI_Layer".disappear();

# Shows over. You don't have to go home but you can't stay here
remotesync func tell_clients_to_piss_off():
	if !get_tree().is_network_server():
		var message = "CHAT HAS ENDED";
		get_tree().get_root().get_node("MainScene/Chat_Layer/Line_Edit").rpc("receive_message", "[color=red]" + message +  "[/color]", -1);
		$Match_End_Timer.stop();
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
		$HTTPRequest_GameServerEndMatch.request(Globals.mainServerIP + "gameServerEndMatch?matchID=" + str(Globals.matchID) + "&winningTeamID=" + str(match_end_winning_team_id) + "&isDoubleDown=" + str(isDD), ["authorization: Bearer " + (Globals.serverPrivateToken)]);
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
			get_tree().get_root().get_node("MainScene/Game_Results_Screen").call_deferred("free");
			get_tree().get_root().get_node("MainScene/UI_Layer").appear();

# Temporary storage of the winning_team_id to use since the call GameServerEndMatch may require multiple calls if it fails
var winning_team_id_to_use;
# Called when the HTTP request GameServerEndMatch completes. If successful, it will reset the server for next use after 5 seconds
func _HTTP_GameServerEndMatch_Completed(result, response_code, headers, body):
	if(response_code == 200):
		yield(get_tree().create_timer(5.0), "timeout");
		print("End match completed. Closing server.");
		get_tree().quit();
	else:
		# Endlessly attempt to end the match until the server responds. It is important that this eventually works!
		print("FAILED TO END MATCH FOR SOME REASON");
		yield(get_tree().create_timer(5.0), "timeout");
		
		$HTTPRequest_GameServerEndMatch.request(Globals.mainServerIP + "gameServerEndMatch?matchID=" + str(Globals.matchID) + "&winningTeamID=" + str(winning_team_id_to_use) + "&isDoubleDown=" + str(isDD), ["authorization: Bearer " + (Globals.serverPrivateToken)]);

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
				# Rearrange teams if this is a skirmish
			if Globals.matchType == 0:
				rearrange_teams()
				rpc("load_new_round", false, players);
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

remotesync func resync_match_time_limit(time_left, isPaused):
	$Match_Time_Limit_Timer.stop();
	$Match_Time_Limit_Timer.wait_time = time_left;
	$Match_Time_Limit_Timer.start();
	$Match_Time_Limit_Timer.paused = isPaused;
	

func _match_time_limit_ended():
	if get_tree().is_network_server():
		rpc("round_ended",-1,-1,true);





