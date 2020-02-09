extends Node2D

var direction = Vector2(0,0);
var speed = 875;
var player_id;
var team_id;
var show_death_particles = true;
var is_from_puppet = false;
# The exact time the player who shot this actually shot this (used to sync up lag)
var initial_time_shot; # Unfortunately this is in seconds. We will use player lerp speed to guess latency
# The original position this bullet was shot from on the master's screen
var initial_real_pos;
# The first position the bullet started at as a puppet (slightly down trajectory)
var initial_puppet_pos;
# The time the puppet began its trajectory
var puppet_time_shot;

func _ready():
	$Death_Timer2.connect("timeout", self, "_death_timer_ended");
	$Animation_Timer.connect("timeout", self, "_animation_timer_ended");
	rotation = Vector2(0,0).angle_to_point(direction) + PI;
	# If the master of this bullet is not the local master player, then this is a puppet
	if get_tree().get_network_unique_id() != get_network_master():
		is_from_puppet = true;
	
	initial_real_pos = position;
	if is_from_puppet:
		$Lag_Comp_Timer.start();
		# Start the bullet slightly down directory to help with lag sync a bit
		position = position + (direction * Globals.lag_comp_headstart_dist);
		initial_puppet_pos = position;
		puppet_time_shot = OS.get_system_time_msecs();
		if Globals.testing:
			initial_time_shot = initial_time_shot - 100
	print(is_from_puppet);

func _process(delta):
	move(delta);
	self.z_index = self.position.y;
	

# stupid workaround neccessary to make particles not flash random colors upon spawning
func _physics_process(delta):
	if should_die:
		die();
	
# Given an amount of delta time, moves the bullet in its trajectory direction using its speed
func move(delta):
	var time_elapsed = (OS.get_system_time_msecs() - initial_time_shot)/1000.0;
	var real_position = initial_real_pos + (direction * speed * time_elapsed);
	if $Lag_Comp_Timer.time_left > 0:
		var puppet_time_elapsed = (OS.get_system_time_msecs() - puppet_time_shot)/1000.0;
		var puppet_position = initial_puppet_pos + (direction * speed * puppet_time_elapsed);
		position = lerp(puppet_position, real_position, 1.0 - ($Lag_Comp_Timer.time_left/$Lag_Comp_Timer.wait_time))
	else:
		position = real_position;

# Called when the animation timer fires
func _animation_timer_ended():
	$Sprite.frame = ($Sprite.frame + 1) % $Sprite.hframes;
# Called by server to terminate this bullet early
remotesync func receive_death():
	die();

func die():
	#Only show particles if we havn't already done so from a preliminary death
	if show_death_particles:
		spawn_death_particles();
	queue_free();

var should_die = false;
# Called when the death timer finishes
# NOTE- we can trust each client to handle it's own bullet deaths because the server detects collisions anyways
func _death_timer_ended():
	should_die = true;
	pass;

# Called if the bullet dies locally on the machine. For now we handle it as just making it look like bullet death
func preliminary_death():
	visible = false
	#Only show particles if we havn't already done so from a preliminary death
	if show_death_particles:
		spawn_death_particles();
	# Don't show particles again when the server tells us to die
	show_death_particles = false;


func spawn_death_particles():
	var particles = load("res://GameContent/Bullet_Death_Particles.tscn").instance();
	get_tree().get_root().get_node("MainScene").add_child(particles);
	particles.position = position;
	particles.rotation = rotation;
	if team_id == 0:
		particles.color_ramp = load("res://GameContent/Blue_Bullet_Death_Particle_Gradient.tres")
	elif team_id == 1:
		particles.color_ramp = load("res://GameContent/Red_Bullet_Death_Particle_Gradient.tres")
