extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	$Control/Enter_Button.connect("pressed", self, "_enter_pressed");
	$Control/Cancel_Button.connect("pressed", self, "_cancel_pressed");
	$Control/Background_Button.connect("pressed", self, "_cancel_pressed");
	$CreateAccount_HTTP.connect("request_completed", self, "_CreateAccount_HTTP_Completed");

func _enter_pressed():
	var n = $Control/Name_LineEdit.text;
	var password = $Control/Password_LineEdit.text;
	var email = $Control/Email_LineEdit.text.strip_edges(true,true);
	
	# Sanitize name
	var regex = RegEx.new()
	regex.compile("^(?=.{3,15}$)(?!.*[_]{2})[a-zA-Z0-9_]+$")
	var result = regex.search(n)
	if !result:
		$Control/Warning_Text.bbcode_text = '[color=red][center]Name must be 3-15 letters, numbers, or single underscores';
		return;
	# Sanitize email
	regex = RegEx.new()
	regex.compile("^([a-zA-Z0-9_\\-\\.]+)@([a-zA-Z0-9_\\-\\.]+)\\.([a-zA-Z]{2,5})$")
	result = regex.search(email)
	if !result:
		$Control/Warning_Text.bbcode_text = '[color=red][center]Please enter a valid E-mail address';
		return;
	# Sanitize password
	regex = RegEx.new()
	regex.compile("^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z!@#\\$%_+~=\\-&\\*\\?\\d]{8,30}$");
	result = regex.search(password)
	if !result:
		$Control/Warning_Text.bbcode_text = '[color=red][center]Password must be 8 characters with at least 1 letter and 1 number\nand may contain special characters !@#$%&?*-_+=~';
		return;
	
	if $CreateAccount_HTTP.get_http_client_status() == 0:
		$Control/Warning_Text.bbcode_text = "[color=black][center]Loading...";
		var query = "?name=" + str(n) + "&email=" + str(email);
		var body = '{"password" : "' + str(password) + '"}';
		$CreateAccount_HTTP.request(Globals.mainServerIP + "createAccount" + query, PoolStringArray(), true,2,body);
	

func _CreateAccount_HTTP_Completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.parse(body.get_string_from_utf8())
		$Control/Warning_Text.bbcode_text = "[color=green][center]Created Account!";
		var token = json.result.token;
		if(token):
			Globals.userToken = token;
			Globals.write_save_data();
			get_parent().set_view(get_parent().VIEW_MAIN);
		else:
			$Control/Warning_Text.bbcode_text = "[color=red][center]A serious error(9290) occurred. Please tell us on discord";
		yield(get_tree().create_timer(0.5), "timeout");
		self.call_deferred("queue_free");
		return;
	elif response_code == 409:
		var json = JSON.parse(body.get_string_from_utf8())
		if json.result.has("failReason"):
			var reason = json.result.failReason;
			$Control/Warning_Text.bbcode_text = "[color=red][center]" + reason;
			return;
	$Control/Warning_Text.bbcode_text = "[color=red][center]A serious error(2737) occurred. Please tell us on discord";
	return;

func _cancel_pressed():
	call_deferred("queue_free");
