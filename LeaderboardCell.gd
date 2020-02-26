extends Node2D


var rank = -1;
var mmr = -1;
var player_name = "";
var player_id = -1;

# Called when the node enters the scene tree for the first time.
func _ready():
	var color = "[color=black]";
	if rank < 4:
		color = "[color=red]";
	$Text_Rank.bbcode_text = "[center]" + color + String(rank) + "[/color][/center]";
	$Text_Name.bbcode_text = player_name;

