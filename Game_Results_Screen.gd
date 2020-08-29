extends Node2D

# The winning team ID of the match
var winning_team_ID = -1;
# The team_ID that the local player was on
var player_team_ID = -1;
var scores;
var old_mmr = -1;
var new_mmr = -1;
var match_ID = -1;
var has_animated_mmr = false;
var stats;

var stats_view_cell = preload("res://Stats_View_Cell.tscn");


func _ready():
	$CanvasLayer/Control/Button_Titlescreen.connect("pressed", self, "_exit_pressed");
	$CanvasLayer/Control/Button_Rematch.connect("pressed", self, "_rematch_pressed");
	if get_tree().get_root().get_node("MainScene/NetworkController").isDD:
		$CanvasLayer/Control/Button_Rematch.visible = false;
		$CanvasLayer/Control/DD_Description.visible = false;
		$CanvasLayer/Control/DD_Votes.visible = false;
	get_tree().connect("screen_resized", self, "_screen_resized");
	_screen_resized();
	
	yield(get_tree().create_timer(1.0), "timeout");
	has_animated_mmr = true;
	$MMR_Animation_Timer.start();
	setup_stats_visuals();
	
func _screen_resized():
	var window_size = OS.get_window_size();
	var s;
	# More horizontal than usual
	if window_size.x / window_size.y > 1920.0/1080.0:
		# Clip to height
		s = window_size.y / 1080;
	else:
		s = window_size.x / 1920;
	$CanvasLayer/Control.rect_scale = Vector2(s,s);

func _exit_pressed():
	get_tree().set_network_peer(null);
	get_tree().change_scene("res://TitleScreen.tscn");

var rematch_vote = false;

func _rematch_pressed():
	switch_views();
	return;
	rematch_vote = !rematch_vote;
	get_tree().get_root().get_node("MainScene/NetworkController").rpc_id(1, "change_DD_vote", rematch_vote);

func setup_stats_visuals():
	$CanvasLayer/Control/Main_View/Text_KDC.bbcode_text = "[center]" + str(stats[Globals.localPlayerID]['kills']) + " : " + str(stats[Globals.localPlayerID]['deaths']) + " : " + str(stats[Globals.localPlayerID]['captures'])
	var count = 0;
	for player_id in stats:
		count += 1; # Theres probably a better way to get this number lol
	var spread = 1000; # The total spread of the cells
	var start_pos = -(spread/2);
	var i = 0
	for player_id in stats:
		var cell = stats_view_cell.instance();
		cell.position.x = start_pos + i * (spread / (count - 1));
		#cell.stats = stats[player_id];
		$CanvasLayer/Control/Stats_View.call_deferred("add_child", cell);
		i += 1;

var view = 0;
func switch_views():
	if view == 0:
		view = 1;
		$CanvasLayer/Control/Main_View.position.x = -1920;
		$CanvasLayer/Control/Stats_view.position.x = 0;
	else:
		view = 0;
		$CanvasLayer/Control/Main_View.position.x = 0;
		$CanvasLayer/Control/Stats_view.position.x = 1920;


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
	$CanvasLayer/Control/Main_View/Text_Result.bbcode_text = "[color=" + color + "][center]" + result + "[/center][/color]";
	$CanvasLayer/Control/Main_View/Text_Score.bbcode_text = "[center][color=blue]" + String(scores[0]) + "[/color]" + "[color=black]-[/color][color=red]" + String(scores[1]) + "[/color][/center]";
	
	# MMR Label setup
	if has_animated_mmr:
		var x = ($MMR_Animation_Timer.time_left / $MMR_Animation_Timer.wait_time);
		var current_value = int(old_mmr + ((1 - x*x*x*x*x) * (new_mmr - old_mmr)));
		$CanvasLayer/Control/Main_View/Text_MMR.bbcode_text = "[center]" + String(current_value) + "[/center]";
	else:
		$CanvasLayer/Control/Main_View/Text_MMR.bbcode_text = "[center]" + String(old_mmr) + "[/center]";
	# MMR Sub text setup
	if has_animated_mmr:
		var MMR_change = new_mmr - old_mmr;
		var change_text;
		if MMR_change >= 0:
			change_text = "+" + String(MMR_change);
		else:
			change_text = String(MMR_change);
		var change_color = "red" if MMR_change < 0 else "green";
		$CanvasLayer/Control/Main_View/Text_MMR_Sub.bbcode_text = "[center][color=black]Your MMR ([/color][color=" + change_color + "]" + change_text + "[/color][color=black])[/color][/center]"; 
	else:
		$CanvasLayer/Control/Main_View/Text_MMR_Sub.bbcode_text = "[center]Your MMR[/center]";
	
	# DD
	var players = get_tree().get_root().get_node("MainScene/NetworkController").players;
	var num_of_votes = 0;
	var bob = {};
	for player_id in players:
		if players[player_id]["DD_vote"]:
			num_of_votes += 1;
	$CanvasLayer/Control/DD_Votes.bbcode_text = str(num_of_votes) + "/" + str(players.size()) + " Votes";
