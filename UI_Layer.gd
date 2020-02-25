extends CanvasLayer

enum {VIEW_START, VIEW_MAIN, VIEW_IN_QUEUE, VIEW_CREATE_ACCOUNT, VIEW_LOGIN, VIEW_SPLASH}

# Called when the node enters the scene tree for the first time.
func _ready():
	$FindMatchButton.connect("pressed", self, "_find_match_pressed");
	$CancelQueueButton.connect("pressed", self, "_cancel_queue_pressed");
	$PlayAsGuestButton.connect("pressed", self, "_play_as_guest_pressed");
	$SignInButton.connect("pressed", self, "_sign_in_pressed");
	$CreateAccountButton.connect("pressed", self, "_create_account_pressed");
	$LogoutButton.connect("pressed", self, "_logout_pressed");
	$SplashStartButton.connect("pressed", self, "_splash_start_pressed");
	$Searching_Text_Timer.connect("timeout", self, "_searching_text_timer_ended");
	disable_buttons();

var current_search_dot_count = 0;
# Called when the Searching text timer ends
func _searching_text_timer_ended():
	current_search_dot_count += 1;
	if current_search_dot_count > 3:
		current_search_dot_count = 0;
	$Searching_Text.text = "Searching";
	for i in current_search_dot_count:
		$Searching_Text.text += ".";

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
	$Title.bbcode_text = "[center]SUPER[color=" + color + "]" + "CTF" + "[/color]";
func set_mmr_and_rank_labels(rank, mmr):
	$PlayerRank.bbcode_text = "[center][color=green]" + String(rank);
	$PlayerMMR.bbcode_text = "[center][color=green]" + String(mmr);
# Disables all the situational buttons
func disable_buttons():
	$CancelQueueButton.visible = false;
	$FindMatchButton.visible = false;
	$PlayAsGuestButton.visible = false;
	$SignInButton.visible = false;
	$CreateAccountButton.visible = false;
	$SplashStartButton.visible = false;
	$SplashBackground.visible = false;
	$Searching_Text.visible = false;
	$PlayerRank.visible = false;
	$PlayerMMR.visible = false;
	$PlayerRankSubtitle.visible = false;
	$PlayerMMRSubtitle.visible = false;

func set_view(state):
	# All UI has a default state of being disabled
	disable_buttons();
	$LogoutButton.visible = true;
	# Enable UI based on view
	match state:
		VIEW_START:
			$LogoutButton.visible = false;
			$PlayAsGuestButton.visible = true;
			$SignInButton.visible = true;
			$CreateAccountButton.visible = true;
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
			$SplashBackground.visible = true;
	
	# temporary while these buttons are useless
	$SignInButton.visible = false;
	$CreateAccountButton.visible = false;

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

