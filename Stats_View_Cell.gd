extends Node2D


var stats;
var player_id;
var players;

# Called when the node enters the scene tree for the first time.
func _ready():
	$Player_Stats.bbcode_text = "[center]" + str(stats[player_id]["kills"]) + "\n\n" + str(stats[player_id]["deaths"]) + "\n\n" + str(stats[player_id]["captures"]) + "\n\n" + str(stats[player_id]["recovers"]);
	$Player_Name.bbcode_text = "[center]" + str(players[player_id]["name"]);
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
