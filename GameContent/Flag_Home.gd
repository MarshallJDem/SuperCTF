extends Node2D

# The id of the team this flag home belongs to
export var team_id = -1;
# The id of the flag that this home houses
export var flag_id = 1;

func _ready() -> void:
	#Flip arrow around if the flag home is above the y axis, so that they can see it sooner
	if self.position.y < -30 :
		var score_helper = $ScoreHelper
		score_helper.position.y *= -1
		score_helper.rotation = 0
		
		
#turns score helper invisible or visbible using a boolean 
func toggle_score_helper(has_flag: bool):
	$ScoreHelper.visible = has_flag
