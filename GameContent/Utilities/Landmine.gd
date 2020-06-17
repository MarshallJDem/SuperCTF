extends Node2D
var team_id = 1;
var player_id = 1;



# Called when the node enters the scene tree for the first time.
func _ready():
	$Activation_Timer.connect("timeout", self, "_activation_timer_ended");
	$Detonation_Timer.connect("timeout", self, "_detonation_timer_ended");
	$Death_Timer.connect("timeout", self, "_death_timer_ended");
	$Trigger_Area2D.monitoring = false;

func _process(delta):
	update();
func _draw():
	if $Death_Timer.time_left != 0:
		var progress = 1.0 - ($Death_Timer.time_left/$Death_Timer.wait_time);
		var frame = clamp(int(sin(progress * 2 * PI * 4) + 1),0,1);
		$Sprite.frame = frame;
		
		var red = 1 if team_id == 1 else 0;
		var green = 10.0/255.0 if team_id == 1 else 130.0/255.0;
		var blue = 1 if team_id == 0 else 0;
		draw_circle(Vector2.ZERO,50,Color(red,green,blue,0.2 + (sin(progress * 2 * PI * 4)+1)/5));
func _activation_timer_ended():
	$Sprite.frame = 1;
	$Trigger_Area2D.monitoring = true;
	if Globals.localPlayerTeamID != team_id:
		$Sprite.visible = false;

remotesync func start_detonation():
	$Sprite.visible = true;
	$Detonation_Timer.start();

func _detonation_timer_ended():
	if Globals.testing or get_tree().is_network_server():
		$Explosion_Area2D.monitoring = true;
	$Death_Timer.start();

func _death_timer_ended():
	call_deferred("queue_free");
