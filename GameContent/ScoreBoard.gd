extends PanelContainer

var players_data = {"1" : {"name": "sml", "team_id" : 0}, "2" : {"name" : "WreallylongnameW", "team_id" : 1}, "3" : {"name" : "Spinny man", "team_id" : 1}}
var stats_data = {"1" : {"kills" : 7, "deaths": 5, "captures" : 1, "recovers" : 4}, "2" : {"kills" : 5, "deaths": 7, "captures" : 2, "recovers" : 7}, "3" : {"kills" : 5, "deaths": 7, "captures" : 2, "recovers" : 7}}

var label_font = preload("res://fonts/Pixel_Chat_Corrected.tres")

func _ready() -> void:
	setup()
	get_tree().connect("screen_resized", self, "_screen_resized");
	_screen_resized()
	
func _process(delta: float) -> void:
	if Input.is_action_pressed("score_board"):
		self.visible = true
	else:
		self.visible = false
	if Input.is_key_pressed(KEY_R):
		_refresh()
	
func make_new_label(color):
	var new_label = Label.new()
	new_label.set("custom_fonts/font", label_font)
	new_label.set("custom_colors/font_color", (color))
	return(new_label)

#create labels for the current players and add them to the score board
func setup():
	#check if all players have stats
	if len(players_data) == len(stats_data):
	
		for current_player in len(players_data):
			current_player += 1
			if players_data[str(current_player)]["team_id"] == 0:
				
				#make a label for player name and add it to the scoreboard
				var player_label = make_new_label("0e00ff")
				player_label.text = players_data[str(current_player)]["name"]
				$MarginContainer/Teams/Team_1/Columns/Name_Column.add_child(player_label)
				
				#make a label for player kills and add it to the scoreboard
				player_label = make_new_label("0e00ff")
				player_label.text = str(stats_data[str(current_player)]["kills"])
				$MarginContainer/Teams/Team_1/Columns/Kills_Column.add_child(player_label)
				
				#make a label for player deaths and add it to the scoreboard
				player_label = make_new_label("0e00ff")
				player_label.text = str(stats_data[str(current_player)]["deaths"])
				$MarginContainer/Teams/Team_1/Columns/Deaths_Column.add_child(player_label)
				
				#make a label for player captures and add it to the scoreboard
				player_label = make_new_label("0e00ff")
				player_label.text = str(stats_data[str(current_player)]["captures"])
				$MarginContainer/Teams/Team_1/Columns/Captures_Column.add_child(player_label)
				
				#make a label for player recovers and add it to the scoreboard
				player_label = make_new_label("0e00ff")
				player_label.text = str(stats_data[str(current_player)]["recovers"])
				$MarginContainer/Teams/Team_1/Columns/Recovers_Column.add_child(player_label)
			
			elif players_data[str(current_player)]["team_id"] == 1:
				
				#make a label for player name and add it to the scoreboard
				var player_label = make_new_label("ff0000")
				player_label.text = players_data[str(current_player)]["name"]
				$MarginContainer/Teams/Team_2/Columns2/Name_Column2.add_child(player_label)
				
				#make a label for player kills and add it to the scoreboard
				player_label = make_new_label("ff0000")
				player_label.text = str(stats_data[str(current_player)]["kills"])
				$MarginContainer/Teams/Team_2/Columns2/Kills_Column2.add_child(player_label)
				
				#make a label for player deaths and add it to the scoreboard
				player_label = make_new_label("ff0000")
				player_label.text = str(stats_data[str(current_player)]["deaths"])
				$MarginContainer/Teams/Team_2/Columns2/Deaths_Column2.add_child(player_label)
				
				#make a label for player captures and add it to the scoreboard
				player_label = make_new_label("ff0000")
				player_label.text = str(stats_data[str(current_player)]["captures"])
				$MarginContainer/Teams/Team_2/Columns2/Captures_Column2.add_child(player_label)
				
				#make a label for player recovers and add it to the scoreboard
				player_label = make_new_label("ff0000")
				player_label.text = str(stats_data[str(current_player)]["recovers"])
				$MarginContainer/Teams/Team_2/Columns2/Recovers_Column2.add_child(player_label)
				
			else:
				print("error player had team id "+str(players_data[str(current_player)]["team_id"]))
	else:
		print("Error player_data and stat_data are not the same size")

#refresh the score board to the current stats of the stats_data dictionary
func _refresh():
	var nc = get_tree().get_root().get_node("MainScene/NetworkController")
	stats_data = nc.game_stats
	print("scoreboard stats")
	print(nc.game_stats)
	print(stats_data)
	players_data = nc.players
	#counts how many blue players there are
	var blue_players = 0
	#counts how many red players there are
	var red_players = 0
	#go through all players
	for current_player in len(stats_data):
		current_player += 1
		#if player is blue
		if players_data[str(current_player)]["team_id"] == 0:
			blue_players += 1
			#set all stats to current stats_data stats
			$MarginContainer/Teams/Team_1/Columns/Kills_Column.get_child(blue_players).text = str(stats_data[str(current_player)]["kills"])
			$MarginContainer/Teams/Team_1/Columns/Deaths_Column.get_child(blue_players).text = str(stats_data[str(current_player)]["deaths"])
			$MarginContainer/Teams/Team_1/Columns/Captures_Column.get_child(blue_players).text = str(stats_data[str(current_player)]["captures"])
			$MarginContainer/Teams/Team_1/Columns/Recovers_Column.get_child(blue_players).text = str(stats_data[str(current_player)]["recovers"])
		#if player is red
		elif players_data[str(current_player)]["team_id"] == 1:
			red_players += 1
			#set all stats to current stats_data stats
			$MarginContainer/Teams/Team_2/Columns2/Kills_Column2.get_child(red_players).text = str(stats_data[str(current_player)]["kills"])
			$MarginContainer/Teams/Team_2/Columns2/Deaths_Column2.get_child(red_players).text = str(stats_data[str(current_player)]["deaths"])
			$MarginContainer/Teams/Team_2/Columns2/Captures_Column2.get_child(blue_players).text = str(stats_data[str(current_player)]["captures"])
			$MarginContainer/Teams/Team_2/Columns2/Recovers_Column2.get_child(blue_players).text = str(stats_data[str(current_player)]["recovers"])

func _screen_resized():
	var window_size = OS.get_window_size();
	var s;
	# More horizontal than usual
	if window_size.x / window_size.y > 1920.0/1080.0:
		# Clip to height
		s = window_size.y / 1080;
	else:
		s = window_size.x / 1920;
	self.rect_scale = Vector2(s,s);
		


