extends CanvasLayer

enum {VIEW_START, VIEW_MAIN, VIEW_IN_QUEUE, VIEW_CREATE_ACCOUNT, VIEW_LOGIN, VIEW_SPLASH}

var JoinPartyPopup = preload("res://JoinPartyPopup.tscn");
var OnboardingPopup = preload("res://OnboardingPopup.tscn");
var LoginPopup = preload("res://LoginPopup.tscn");

var current_state = VIEW_SPLASH;

# Called when the node enters the scene tree for the first time.
func _ready():
	$RankedButton.connect("pressed", self, "_ranked_pressed");
	$QuickplayButton.connect("pressed", self, "_quickplay_pressed");
	$CancelQueueButton.connect("pressed", self, "_cancel_queue_pressed");
	$PlayAsGuestButton.connect("pressed", self, "_play_as_guest_pressed");
	$CreateAccountButton.connect("pressed", self, "_create_account_pressed");
	$LoginButton.connect("pressed", self, "_sign_in_pressed");
	$JoinPartyButton.connect("pressed", self, "_join_party_pressed");
	$LogoutButton.connect("pressed", self, "_logout_pressed");
	$SplashStartButton.connect("pressed", self, "_splash_start_pressed");
	$MOTDText.connect("meta_clicked", self, "_MOTD_meta_clicked");
	$Options_Button.connect("button_up", self, "_options_button_clicked");
	$Fullscreen_Button.connect("button_up", self, "_fullscreen_button_clicked");
	$HTTPRequest_LeaveParty.connect("request_completed", self, "_HTTP_LeaveParty_Completed");
	disable_buttons();

func _MOTD_meta_clicked(meta):
	OS.shell_open(meta)


func _options_button_clicked():
	Globals.toggle_options_menu();
	$Options_Button.release_focus();
func _fullscreen_button_clicked():
	OS.window_fullscreen = !OS.window_fullscreen;

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
	$RankedButton.visible = false;
	$RankedWarning.visible = false;
	$QuickplayButton.visible = false;
	$QuickplayWarning.visible = false;
	$PlayAsGuestButton.visible = false;
	$CreateAccountButton.visible = false;
	$LoginButton.visible = false;
	$SplashStartButton.visible = false;
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
			$RankedButton.visible = true;
			$QuickplayButton.visible = true;
			$PlayerRank.visible = true;
			$PlayerMMR.visible = true;
			$PartyText.visible = true;
			$JoinPartyButton.visible = true;
			$PlayerRankSubtitle.visible = true;
			$PlayerMMRSubtitle.visible = true;
		VIEW_IN_QUEUE:
			$CancelQueueButton.visible = true;
			$PlayerRank.visible = true;
			$PlayerMMR.visible = true;
			$PlayerRankSubtitle.visible = true;
			$PlayerMMRSubtitle.visible = true;
		VIEW_SPLASH:
			$LogoutButton.visible = false;
			$SplashStartButton.visible = true;
	current_state = state;

func _process(delta):
	var code = "";
	var players = "";
	var players_in_party = 0;
	if Globals.player_party_data != null:
		code = str(Globals.player_party_data.partyCode);
		for i in Globals.player_party_data.players:
			players += str(i.name) + "\n";
			players_in_party += 1;
		if Globals.player_party_data.partyHostID != Globals.player_uid:
			$RankedButton.disabled = true;
			$RankedWarning.bbcode_text = "[center][color=gray]Must be party host"
			$RankedWarning.visible = true;
			$QuickplayButton.disabled = true;
			$QuickplayWarning.bbcode_text = "[center][color=gray]Must be party host"
			$QuickplayWarning.visible = true;
		else:
			$RankedButton.disabled = false;
			$RankedWarning.visible = false;
			$QuickplayButton.disabled = false;
			$QuickplayWarning.visible = false;
	else:
		$RankedButton.disabled = true;
		$QuickplayButton.disabled = true;
		if current_state == VIEW_MAIN:
			$RankedWarning.bbcode_text = "[center][color=gray]Connecting to server..."
			$RankedWarning.visible = true;
			$QuickplayWarning.bbcode_text = "[center][color=gray]Connecting to server..."
			$QuickplayWarning.visible = true;
		else:
			$RankedWarning.visible = false;
			$QuickplayWarning.visible = false;
	
	# Disable ranked for parties bigger than 2
	if players_in_party > 2:
		$RankedButton.disabled = true;
		$RankedWarning.bbcode_text = "[center][color=gray]Max party size is 2"
		$RankedWarning.visible = true;
	
	# Disable quickplay for parties bigger than 6
	if players_in_party > 6:
		$QuickplayButton.disabled = true;
		$QuickplayWarning.bbcode_text = "[center][color=gray]Max party size is 6"
		$QuickplayWarning.visible = true;
	
	
	# Disable Ranked for guests
	if Globals.player_type == 'G':
		$RankedButton.disabled = true;
		$RankedWarning.bbcode_text = "[center][color=gray]Must make an account"
		$RankedWarning.visible = true;
	
	if Globals.temporaryQuickplayDisable:
		$RankedButton.visible = false;
		$RankedWarning.visible = false;
		$QuickplayButton.disabled = false;
		$QuickplayWarning.visible = false;
		$QuickplayButton.text = "Find Match"
		if players_in_party > 2:
			$QuickplayButton.disabled = true;
			$QuickplayWarning.visible = true;
			$QuickplayWarning.bbcode_text = "[center][color=gray]Max party size is 2 currently"
		if Globals.player_party_data != null and Globals.player_party_data.partyHostID != Globals.player_uid:
			$QuickplayButton.disabled = true;
			$QuickplayWarning.visible = true;
			$QuickplayWarning.bbcode_text = "[center][color=gray]Must be party host"
		
		
	
	#$PartyText.bbcode_text = ;
	$PartyText.clear();
	$PartyText.append_bbcode("[center][color=black]Party Code\n[color=green]" + str(code) + "\n\n[color=black]Members\n[color=green]" + str(players));
	$PartyText.selection_enabled = true;
	$PartyText.update();
	if Globals.player_party_data and Globals.player_party_data.players.size() > 1:
		$JoinPartyButton.text = "Leave Party";
	else:
		$JoinPartyButton.text = "Join Party";
	
	

func _HTTP_LeaveParty_Completed(_result, _response_code, _headers, _body):
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
	if Globals.control_scheme == Globals.Control_Schemes.touchscreen:
		OS.window_fullscreen = true;

func _join_party_pressed():
	if Globals.player_party_data != null and Globals.player_party_data.players.size() > 1:
		if $HTTPRequest_LeaveParty.get_http_client_status() == 0:
			$HTTPRequest_LeaveParty.request(Globals.mainServerIP + "leaveParty", ["authorization: Bearer " + Globals.userToken]);
	else:
		var scn = JoinPartyPopup.instance();
		call_deferred("add_child", scn);

# Called when the cancel queue button is pressed
func _cancel_queue_pressed():
	disable_buttons();
	set_view(VIEW_MAIN);
	Globals.leave_MMQueue();

# Called when the ranked button is pressed
func _ranked_pressed():
	disable_buttons();
	set_view(VIEW_IN_QUEUE);
	get_parent().join_MM_queue(2);

# Called when the Quickplay button is pressed
func _quickplay_pressed():
	disable_buttons();
	set_view(VIEW_IN_QUEUE);
	if Globals.temporaryQuickplayDisable:
		get_parent().join_MM_queue(2);
		return;
	get_parent().join_MM_queue(1);

