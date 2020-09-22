extends Node2D

var speed = 600;
var player_id;
var team_id = -1;
var target_pos = Vector2(0,0);
# The exact time the player who shot this actually shot this (used to sync up lag)
var initial_time_shot;
# The original position this grenade was shot from on the master's screen
var initial_real_pos;


var grenade_atlas_blue = preload("res://Assets/Utilities/grenade_B.png");
var grenade_atlas_red = preload("res://Assets/Utilities/grenade_R.png");

var Grenade_Explosion = preload("res://GameContent/Grenade_Explosion.tscn");

func _ready():
	$Detonation_Timer.connect("timeout", self, "_detonation_timer_ended");
	$Animation_Timer.connect("timeout", self, "_animation_timer_ended");
	position = initial_real_pos;
	if team_id == 1:
		$Sprite.set_texture(grenade_atlas_red);
	else:
		$Sprite.set_texture(grenade_atlas_blue);
	
func _process(_delta):
	pass;

# stupid workaround neccessary to make particles not flash random colors upon spawning
func _physics_process(_delta):
	move();
	
# Given an amount of delta time, moves the grenade in its trajectory direction using its speed
func move():
	var time_elapsed = ((OS.get_system_time_msecs() - Globals.match_start_time) - initial_time_shot)/1000.0;
	if time_elapsed < 0:
		time_elapsed = 0;
	var speed_distance = initial_real_pos.distance_to(initial_real_pos + (Vector2.ONE * speed));
	var target_distance = initial_real_pos.distance_to(target_pos);
	var t;
	if target_distance == 0:
		t = time_elapsed
	else:
		t = time_elapsed * (speed_distance / target_distance);
	t = clamp(t, 0.0, 1.0);
	position = lerp(initial_real_pos, target_pos, clamp(t, 0.0, 1.0));
	
	# Throwing animation
	var height = (target_distance / 600.0) * 75;
	var scale_max = (target_distance / 600.0) * 1.0;
	position.y -= height * (-pow((2 *t) - 1,2) +1);
	self.z_index = position.y +  2 * height * (-pow((2 *t) - 1,2) +1);
	
	rotation = -2 * PI * t;
	var sca = (1 +  scale_max * (-pow((2 *t) - 1,2) +1))
	scale = Vector2(sca,sca);
	if t >= 1.0 and $Detonation_Timer.time_left == 0:
		# If this grenade was thrown very close by, take longer to detonate
		if time_elapsed < 0.5:
			$Detonation_Timer.wait_time += (0.5 - time_elapsed);
		$Detonation_Timer.start();

# Called when the animation timer fires
func _animation_timer_ended():
	$Sprite.frame = ($Sprite.frame + 1) % $Sprite.hframes;

func explode():
	var explosion = Grenade_Explosion.instance();
	explosion.position = position;
	#explosion.z_index = z_index;
	explosion.team_id = team_id;
	explosion.player_id = player_id;
	get_tree().get_root().get_node("MainScene").call_deferred("add_child", explosion);
	call_deferred("queue_free");
		
# Called when the death timer finishes
# NOTE- we can trust each client to handle it's own grenade deaths because the server detects collisions anyways
func _detonation_timer_ended():
	explode();


