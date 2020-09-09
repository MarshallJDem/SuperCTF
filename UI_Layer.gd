extends CanvasLayer

enum {VIEW_START, VIEW_MAIN, VIEW_IN_QUEUE, VIEW_CREATE_ACCOUNT, VIEW_LOGIN, VIEW_SPLASH}

var JoinPartyPopup = preload("res://JoinPartyPopup.tscn");

# Called when the node enters the scene tree for the first time.
func _ready():
	$FindMatchButton.connect("pressed", self, "_find_match_pressed");
	$CancelQueueButton.connect("pressed", self, "_cancel_queue_pressed");
	$PlayAsGuestButton.connect("pressed", self, "_play_as_guest_pressed");
	$JoinPartyButton.connect("pressed", self, "_join_party_pressed");
	$LogoutButton.connect("pressed", self, "_logout_pressed");
	$SplashStartButton.connect("pressed", self, "_splash_start_pressed");
	$Searching_Text_Timer.connect("timeout", self, "_searching_text_timer_ended");
	$MOTDText.connect("meta_clicked", self, "_MOTD_meta_clicked");
	$Options_Button.connect("button_up", self, "_options_button_clicked");
	disable_buttons();

func _MOTD_meta_clicked(meta):
	OS.shell_open(meta)

var current_search_dot_count = 0;
# Called when the Searching text timer ends
func _searching_text_timer_ended():
	current_search_dot_count += 1;
	if current_search_dot_count > 3:
		current_search_dot_count = 0;
	$Searching_Text.text = "Searching";
	for i in current_search_dot_count:
		$Searching_Text.text += ".";

func _options_button_clicked():
	Globals.toggle_options_menu();
	$Options_Button.release_focus();

var current_color = 0;
# Called every frame by Titlescreen with the latest playback position
func update_title_color(playback_position):
	var current_color = int(playback_position) % 3;
	var color = "#FFFFFF";
	if current_color == 0:
		color = "#000000";
	elif current_color == 1:
		color = "#4C70BA";
	else:
		color = "#ff0000";
	$Title.bbcode_text = "[center]SUPER[color=" + color + "]" + "CTF" + "[/color].COM";
func set_mmr_and_rank_labels(rank, mmr):
	$PlayerRank.bbcode_text = "[center][color=green]" + String(rank);
	$PlayerMMR.bbcode_text = "[center][color=green]" + String(mmr);
# Disables all the situational buttons
func disable_buttons():
	$CancelQueueButton.visible = false;
	$FindMatchButton.visible = false;
	$PlayAsGuestButton.visible = false;
	$SplashStartButton.visible = false;
	$Searching_Text.visible = false;
	$PlayerRank.visible = false;
	$PlayerMMR.visible = false;
	$PlayerRankSubtitle.visible = false;
	$PlayerMMRSubtitle.visible = false;
	$UsernameLineEdit.visible = false;

func set_view(state):
	# All UI has a default state of being disabled
	disable_buttons();
	$LogoutButton.visible = true;
	# Enable UI based on view
	match state:
		VIEW_START:
			$LogoutButton.visible = false;
			$PlayAsGuestButton.visible = true;
			$UsernameLineEdit.visible = true;
		VIEW_MAIN:
			$FindMatchButton.visible = true;
			$PlayerRank.visible = true;
			$PlayerMMR.visible = true;
			$PlayerRankSubtitle.visible = true;
			$PlayerMMRSubtitle.visible = true;
		VIEW_IN_QUEUE:
			$CancelQueueButton.visible = true;
			$Searching_Text.visible = true;
			$PlayerRank.visible = true;
			$PlayerMMR.visible = true;
			$PlayerRankSubtitle.visible = true;
			$PlayerMMRSubtitle.visible = true;
		VIEW_SPLASH:
			$LogoutButton.visible = false;
			$SplashStartButton.visible = true;

func _process(delta):
	var code = "";
	var players = "";
	if Globals.player_party_data != null:
		code = str(Globals.player_party_data.partyCode);
		for i in Globals.player_party_data.players:
			players += str(i.values()[0]) + "\n";
		
	$PartyText.bbcode_text = "[center][color=black]Party Code\n[color=green]" + str(code) + "\n\n[color=black]Members\n[color=green]" + str(players);


func _play_as_guest_pressed():
	get_parent().create_guest();
func _sign_in_pressed():
	pass;
func _create_account_pressed():
	pass;
func _logout_pressed():
	get_parent().logout();
func _splash_start_pressed():
	get_parent().start();

func _join_party_pressed():
	var scn = JoinPartyPopup.instance();
	call_deferred("add_child", scn);

# Called when the cancel queue button is pressed
func _cancel_queue_pressed():
	disable_buttons();
	set_view(VIEW_MAIN);
	get_parent().leave_MM_queue();

# Called when the find match button is pressed
func _find_match_pressed():
	disable_buttons();
	set_view(VIEW_IN_QUEUE);
	get_parent().join_MM_queue();

