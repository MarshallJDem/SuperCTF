extends PanelContainer

var players_data = {"1" : {"name": "sml", "team_id" : 0}, "2" : {"name" : "WreallylongnameW", "team_id" : 1}, "3" : {"name" : "Spinny man", "team_id" : 1}}
var stats_data = {"1" : {"kills" : 7, "deaths": 5, "captures" : 1, "recovers" : 4}, "2" : {"kills" : 5, "deaths": 7, "captures" : 2, "recovers" : 7}}

func _ready() -> void:
	setup()
	refresh()

func setup():
	var player_label = Label.new()
	for player in players_data.values():
		if player["team_id"] == 0:
			player_label.text = player["name"]
			$Teams/Team_1/Columns/Name_Column.add_child(player_label)
		else:
			player_label.text = player["name"]
			$Teams/Team_2/Columns2/Name_Column2/Columns/Name_Column.add_child(player_label)
			
	

func refresh():
	for player in players_data.values():
		print(player["name"])


