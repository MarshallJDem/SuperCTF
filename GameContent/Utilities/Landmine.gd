extends Node2D
var team_id = 1;
var player_id = 1;

var atlas_blue = preload("res://Assets/Utilities/landmine_B.png");
var atlas_red = preload("res://Assets/Utilities/landmine_R.png");

# Called when the node enters the scene tree for the first time.
func _ready():
	$Activation_Timer.connect("timeout", self, "_activation_timer_ended");
	$Detonation_Timer.connect("timeout", self, "_detonation_timer_ended");
	$Death_Timer.connect("timeout", self, "_death_timer_ended");
	$Trigger_Area2D.monitoring = false;
	$Explosion_Area2D.monitorable = false;
	if Globals.testing:
		team_id = 1;
		player_id = 1;
	if team_id == 0:
		$Sprite.set_texture(atlas_blue);
	else:
		$Sprite.set_texture(atlas_red);
	z_index = position.y - 3;
	#set_network_master(1);

func _process(delta):
	update();
func _draw():
	if $Death_Timer.time_left != 0:
		var progress = 1.0 - ($Death_Timer.time_left/$Death_Timer.wait_time);
		var frame = clamp(int(sin(progress * 2 * PI * 4) + 1),0,1);
		$Sprite.frame = frame;
		
		draw_circle(Vector2.ZERO,100,Color(0.0,0.1,0.0,0.4 + (sin(progress * 2 * PI * 4)+1)/5));
func _activation_timer_ended():
	$Sprite.frame = 1;
	$Trigger_Area2D.monitoring = true;
	if Globals.localPlayerTeamID != team_id:
		modulate = Color(0.0,0.0,0.0,0.0);

remotesync func start_detonation():
	modulate = Color(1,1,1,1);
	$Detonation_Timer.start();
	

func _detonation_timer_ended():
	$Explosion_Area2D.monitorable = true;
	$Death_Timer.start();
func die():
	Globals.active_landmines -= 1;
	call_deferred("queue_free");
func _death_timer_ended():
	die();
