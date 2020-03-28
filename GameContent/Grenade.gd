extends Node2D

var speed = 400;
var player_id;
var team_id = -1;
var target_pos = Vector2(0,0);
# The exact time the player who shot this actually shot this (used to sync up lag)
var initial_time_shot;
# The original position this grenade was shot from on the master's screen
var initial_real_pos;


var grenade_atlas_blue = preload("res://Assets/Weapons/grenade_b.png");
var grenade_atlas_red = preload("res://Assets/Weapons/grenade_r.png");

func _ready():
	$Detonation_Timer.connect("timeout", self, "_detonation_timer_ended");
	$Animation_Timer.connect("timeout", self, "_animation_timer_ended");
	position = initial_real_pos;
	var radius = get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("grenadeRadius");
	$Area2D/CollisionShape2D.scale = Vector2(radius,radius);
	if team_id == 1:
		$Sprite.set_texture(grenade_atlas_red);
	else:
		$Sprite.set_texture(grenade_atlas_blue);
	
func _process(_delta):
	speed = get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("bulletSpeed");
	pass;

# stupid workaround neccessary to make particles not flash random colors upon spawning
func _physics_process(_delta):
	move();
	self.z_index = self.position.y;
	
# Given an amount of delta time, moves the grenade in its trajectory direction using its speed
func move():
	var time_elapsed = ((OS.get_system_time_msecs() - Globals.match_start_time) - initial_time_shot)/1000.0;
	if time_elapsed < 0:
		time_elapsed = 0;
	var speed_distance = initial_real_pos.distance_to(initial_real_pos + (Vector2.ONE * speed));
	var target_distance = initial_real_pos.distance_to(target_pos);
	var t;
	if target_distance == Vector2.ZERO:
		t = time_elapsed
	else:
		t = time_elapsed * (speed_distance / target_distance);
	position = lerp(initial_real_pos, target_pos, clamp(t, 0.0, 1.0));
	if t >= 1 and $Detonation_Timer.time_left == 0:
		$Detonation_Timer.start();
		

# Called when the animation timer fires
func _animation_timer_ended():
	$Sprite.frame = ($Sprite.frame + 1) % $Sprite.hframes;

func explode():
	var explosion = load("res://GameContent/Grenade_Explosion.tscn").instance();
	explosion.position = position;
	explosion.z_index = z_index;
	explosion.team_id = team_id;
	get_tree().get_root().get_node("MainScene").call_deferred("add_child", explosion);
	call_deferred("queue_free");
		
# Called when the death timer finishes
# NOTE- we can trust each client to handle it's own grenade deaths because the server detects collisions anyways
func _detonation_timer_ended():
	explode();


