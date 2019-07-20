extends CanvasLayer

func _ready():
	$Leave_Match_Button.connect("pressed", self, "_leave_match_button_pressed");

# Color 0 = blue, 1 = red
func set_big_label_text(text, color):
	clear_big_label_text();
	if color == 0:
		$Big_Label_Blue.text = text;
	if color == 1:
		$Big_Label_Red.text = text;
# Clears the text in the big labels
func clear_big_label_text():
	$Big_Label_Blue.text = "";
	$Big_Label_Red.text = "";

func enable_leave_match_button():
	$Leave_Match_Button.visible = true;

func _leave_match_button_pressed():
	print("pressed");
	get_tree().get_root().get_node("MainScene/NetworkController").leave_match();
	