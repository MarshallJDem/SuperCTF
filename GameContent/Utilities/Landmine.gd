extends Node2D
var team_id = 1;
var player_id = 1;



# Called when the node enters the scene tree for the first time.
func _ready():
	$Activation_Timer.connect("timeout", self, "_activation_timer_ended");
	$Trigger_Area2D.monitoring = false;


func _activation_timer_ended():
	$Sprite.frame = 1;
	$Trigger_Area2D.monitoring = true;
	if Globals.localPlayerTeamID != team_id:
		$Sprite.visible = false;

remotesync func start_detonation():
	$Detonation_Timer.start();
