extends Node2D

# The id of the team this flag home belongs to
export var team_id = -1;
# The id of the flag that this home houses
export var flag_id = 1;
#If the flag home is on screen or not
export var is_flag_home_visible: bool = false



func _ready() -> void:
	$VisibilityNotifier2D.connect("screen_entered", self, "_flaghome_entered_screen");
	$VisibilityNotifier2D.connect("screen_exited", self, "_flaghome_exited_screen");
	#Flip arrow around if the flag home is above the y axis, so that they can see it sooner
	if self.position.y < -30 :
		var score_helper = $ScoreHelper
		score_helper.position.y *= -1
		score_helper.rotation = 0

func _flaghome_exited_screen():
	is_flag_home_visible = false
	
	
func _flaghome_entered_screen():
	is_flag_home_visible = true
	

#turns score helper invisible or visbible using a boolean and if it is on screen
func toggle_score_helper(has_flag):
	$ScoreHelper.visible = has_flag and is_flag_home_visible


