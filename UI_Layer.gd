extends CanvasLayer

enum {VIEW_START, VIEW_MAIN, VIEW_IN_QUEUE, VIEW_CREATE_ACCOUNT, VIEW_LOGIN, VIEW_SPLASH}

var JoinPartyPopup = preload("res://JoinPartyPopup.tscn");
var OnboardingPopup = preload("res://OnboardingPopup.tscn");
var LoginPopup = preload("res://LoginPopup.tscn");

var current_state = VIEW_SPLASH;

# Called when the node enters the scene tree for the first time.
func _ready():
	$FindMatchButton.connect("pressed", self, "_find_match_pressed");
	$CancelQueueButton.connect("pressed", self, "_cancel_queue_pressed");
	$PlayAsGuestButton.connect("pressed", self, "_play_as_guest_pressed");
	$CreateAccountButton.connect("pressed", self, "_create_account_pressed");
	$LoginButton.connect("pressed", self, "_sign_in_pressed");
	$JoinPartyButton.connect("pressed", self, "_join_party_pressed");
	$LogoutButton.connect("pressed", self, "_logout_pressed");
	$SplashStartButton.connect("pressed", self, "_splash_start_pressed");
	$Searching_Text_Timer.connect("timeout", self, "_searching_text_timer_ended");
	$MOTDText.connect("meta_clicked", self, "_MOTD_meta_clicked");
	$Options_Button.connect("button_up", self, "_options_button_clicked");
	$HTTPRequest_LeaveParty.connect("request_completed", self, "_HTTP_LeaveParty_Completed");
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
	$CreateAccountButton.visible = false;
	$LoginButton.visible = false;
	$SplashStartButton.visible = false;
	$Searching_Text.visible = false;
	$PlayerRank.visible = false;
	$PlayerMMR.visible = false;
	$PlayerRankSubtitle.visible = false;
	$PlayerMMRSubtitle.visible = false;
	$UsernameLineEdit.visible = false;
	$PartyText.visible = false;
	$JoinPartyButton.visible = false;
	

func set_view(state):
	# All UI has a default state of being disabled
	disable_buttons();
	$LogoutButton.visible = true;
	# Enable UI based on view
	match state:
		VIEW_START:
			$LogoutButton.visible = false;
			$PlayAsGuestButton.visible = true;
			$CreateAccountButton.visible = true;
			$LoginButton.visible = true;
			$UsernameLineEdit.visible = false;
		VIEW_MAIN:
			$FindMatchButton.visible = true;
			$PlayerRank.visible = true;
			$PlayerMMR.visible = true;
			$PartyText.visible = true;
			$JoinPartyButton.visible = true;
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
	current_state = state;

func _process(delta):
	$MOTDText.bbcode_text = OS.get_name() + "\n" + String(OS.has_touchscreen_ui_hint());
	var code = "";
	var players = "";
	if Globals.player_party_data != null:
		code = str(Globals.player_party_data.partyCode);
		for i in Globals.player_party_data.players:
			players += str(i.values()[0]) + "\n";
		if Globals.player_party_data.partyHostID != Globals.player_uid:
			$FindMatchButton.disabled = true;
			$FindMatchWarning.bbcode_text = "[center][color=gray]Must be party host"
			$FindMatchWarning.visible = true;
		else:
			$FindMatchButton.disabled = false;
			$FindMatchWarning.visible = false;
	else:
		$FindMatchButton.disabled = true;
		if current_state == VIEW_MAIN:
			$FindMatchWarning.bbcode_text = "[center][color=gray]Connecting to server..."
			$FindMatchWarning.visible = true;
		else:
			$FindMatchWarning.visible = false;
	
	#$PartyText.bbcode_text = ;
	$PartyText.clear();
	$PartyText.append_bbcode("[center][color=black]Party Code\n[color=green]" + str(code) + "\n\n[color=black]Members\n[color=green]" + str(players));
	$PartyText.selection_enabled = true;
	$PartyText.update();
	if Globals.player_party_data and Globals.player_party_data.players.size() > 1:
		$JoinPartyButton.text = "Leave Party";
	else:
		$JoinPartyButton.text = "Join Party";
	
	

func _HTTP_LeaveParty_Completed(result, response_code, headers, body):
	# Do notihng cuz the results are reflected in poll player status
	return;



func _play_as_guest_pressed():
	get_parent().create_guest();
func _sign_in_pressed():
	var scn = LoginPopup.instance();
	call_deferred("add_child", scn);
func _create_account_pressed():
	var scn = OnboardingPopup.instance();
	call_deferred("add_child", scn);
func _logout_pressed():
	get_parent().logout();
func _splash_start_pressed():
	get_parent().start();

func _join_party_pressed():
	if Globals.player_party_data.players.size() > 1:
		if $HTTPRequest_LeaveParty.get_http_client_status() == 0:
			$HTTPRequest_LeaveParty.request(Globals.mainServerIP + "leaveParty", ["authorization: Bearer " + Globals.userToken]);
	else:
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

