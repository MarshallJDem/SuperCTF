extends Node2D


var stats;
var player_id;
var players;

# Called when the node enters the scene tree for the first time.
func _ready():
	$Player_Stats.bbcode_text = "[center]" + str(stats[player_id]["kills"]) + "\n\n" + str(stats[player_id]["deaths"]) + "\n\n" + str(stats[player_id]["captures"]) + "\n\n" + str(stats[player_id]["recovers"]);
	$Player_Name.bbcode_text = "[center]" + str(players[player_id]["name"]);
	var c = players[player_id]["class"];
	var t = "B";
	if(players[player_id]["team_id"] == 1):
		t = "R";
	var n;
	if c == Globals.Classes.Bullet:
		n = "gunner";
	elif c == Globals.Classes.Laser:
		n = "laser";
	elif c == Globals.Classes.Demo:
		n = "demo";
	$Player_Sprite.set_texture(load("res://Assets/Player/" + str(n) + "_head_" +t+ ".png"));

