extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	$Control/Button.connect("pressed", self, "_enter_pressed");
	$Control/Cancel_Button.connect("pressed", self, "_cancel_pressed");
	$Control/Background_Button.connect("pressed", self, "_cancel_pressed");
	$JoinParty_HTTP.connect("request_completed", self, "_JoinParty_HTTP_Completed");
	pass 

func _enter_pressed():
	var code = $Control/LineEdit.text;
	var query = "?partyCode=" + str(code);
	if $JoinParty_HTTP.get_http_client_status() == 0:
		$Control/TitleText.bbcode_text = "[color=black][center]Loading...";
		$JoinParty_HTTP.request(Globals.mainServerIP + "joinParty" + query, ["authorization: Bearer " + Globals.userToken]);

func _JoinParty_HTTP_Completed(result, response_code, headers, body):
	if response_code == 200:
		var json = JSON.parse(body.get_string_from_utf8())
		$Control/TitleText.bbcode_text = "[color=green][center]Joined Party!";
		yield(get_tree().create_timer(0.5), "timeout");
		self.call_deferred("free");
		return;
	elif response_code == 404:
		$Control/TitleText.bbcode_text = "[color=red][center]Invalid Party Code";
		return;
	elif response_code == 403:
		var json = JSON.parse(body.get_string_from_utf8())
		if json.result.has("isFull") and json.result.isFull:
			$Control/TitleText.bbcode_text = "[color=red][center]Party Full";
			return;
		if json.result.has("isQueued") and json.result.isQueued:
			$Control/TitleText.bbcode_text = "[color=red][center]Party is already queued";
			return;
	$Control/TitleText.bbcode_text = "[color=red][center]An uknown error occurred (Sorry we're in beta)";
	return;

func _process(delta):
	if $Control/LineEdit.text.length() > 4:
		var txt = $Control/LineEdit.text.substr(0,4);
		$Control/LineEdit.clear();
		$Control/LineEdit.append_at_cursor(txt);

func _cancel_pressed():
	call_deferred("free");
