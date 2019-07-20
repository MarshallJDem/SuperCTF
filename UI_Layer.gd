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
	
	disable_buttons();

# Disables all the situational buttons
func disable_buttons():
	$CancelQueueButton.visible = false;
	$FindMatchButton.visible = false;
	$PlayAsGuestButton.visible = false;
	$SignInButton.visible = false;
	$CreateAccountButton.visible = false;
	$SplashStartButton.visible = false;
	$SplashBackground.visible = false;

func set_view(state):
	disable_buttons();
	$LogoutButton.visible = true;
	match state:
		VIEW_START:
			$LogoutButton.visible = false;
			$PlayAsGuestButton.visible = true;
			$SignInButton.visible = true;
			$CreateAccountButton.visible = true;
		VIEW_MAIN:
			$FindMatchButton.visible = true;
		VIEW_IN_QUEUE:
			$CancelQueueButton.visible = true;
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
	OS.window_fullscreen = true;
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

