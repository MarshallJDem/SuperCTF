extends Node2D

# The winning team ID of the match
var winning_team_ID = -1;
# The team_ID that the local player was on
var player_team_ID = -1;
var team_0_score = 0;
var team_1_score = 0;
var old_mmr = -1;
var new_mmr = -1;
var match_ID = -1;
var has_animated_mmr = false;


func _ready():
	$CanvasLayer/Button_Titlescreen.connect("pressed", self, "_exit_pressed");
	winning_team_ID = Globals.result_winning_team_id;
	team_0_score = Globals.result_team0_score;
	team_1_score = Globals.result_team1_score;
	player_team_ID = Globals.result_player_team_id;
	match_ID = Globals.result_match_id;
	old_mmr = Globals.player_MMR;

func _exit_pressed():
	get_tree().change_scene("res://TitleScreen.tscn");

func _process(_delta):
	# Result and Score setup
	var color = "gray";
	if player_team_ID == 0:
		color = "blue";
	elif player_team_ID == 1:
		color = "red";
	var result = "---";
	if player_team_ID == winning_team_ID and winning_team_ID != -1:
		result = "WIN";
	elif player_team_ID != winning_team_ID:
		result = "LOSS";
	$CanvasLayer/Text_Result.bbcode_text = "[color=" + color + "][center]" + result + "[/center][/color]";
	$CanvasLayer/Text_Score.bbcode_text = "[center][color=blue]" + String(team_0_score) + "[/color]" + "[color=black]-[/color][color=red]" + String(team_1_score) + "[/color][/center]";
	
	# MMR Label setup
	if has_animated_mmr:
		var x = ($MMR_Animation_Timer.time_left / $MMR_Animation_Timer.wait_time);
		var current_value = int(old_mmr + ((1 - x*x*x*x*x) * (new_mmr - old_mmr)));
		$CanvasLayer/Text_MMR.bbcode_text = "[center]" + String(current_value) + "[/center]";
	elif old_mmr > -1:
		$CanvasLayer/Text_MMR.bbcode_text = "[center]" + String(old_mmr) + "[/center]";
		if new_mmr > -1:
			has_animated_mmr = true;
			$MMR_Animation_Timer.start();
	else:
		$CanvasLayer/Text_MMR.bbcode_text = "[center]-[/center]";
	# MMR Sub text setup
	if has_animated_mmr:
		var MMR_change = new_mmr - old_mmr;
		var change_text;
		if MMR_change >= 0:
			change_text = "+" + String(MMR_change);
		else:
			change_text = String(MMR_change);
		var change_color = "red" if MMR_change < 0 else "green";
		$CanvasLayer/Text_MMR_Sub.bbcode_text = "[center][color=black]Your MMR ([/color][color=" + change_color + "]" + change_text + "[/color][color=black])[/color][/center]"; 
	else:
		$CanvasLayer/Text_MMR_Sub.bbcode_text = "[center]-[/center]";
