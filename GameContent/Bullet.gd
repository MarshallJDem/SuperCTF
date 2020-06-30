extends KinematicBody2D

enum Puppet_State{Master, Puppet, Server};
var puppet_state = Puppet_State.Master;
var direction = Vector2(0,0);
var speed = 400;
var player_id;
var team_id = -1;
var show_death_particles = true;
# The exact time the player who shot this actually shot this (used to sync up lag)
var original_time_shot = 0;
var puppet_time_shot = 0;
var is_blank = false;


func _ready():
	$Death_Timer.connect("timeout", self, "_death_timer_ended");
	$Animation_Timer.connect("timeout", self, "_animation_timer_ended");
	# If the master of this bullet is not the local master player, then this is a puppet
	puppet_time_shot = OS.get_system_time_msecs() - Globals.match_start_time;
	if !Globals.testing and get_tree().get_network_unique_id() != get_network_master():
		if get_tree().is_network_server():
			puppet_state = Puppet_State.Server;
		else:
			puppet_state = Puppet_State.Puppet;
			$Death_Timer.wait_time += -(puppet_time_shot-original_time_shot)/1000.0;
	if puppet_state == Puppet_State.Master:
		$Lag_Comp_Timer.wait_time *= 4;
		$Death_Timer.wait_time += ((Globals.ping/2.0)-Globals.player_lerp_time)/1000.0;
	$Lag_Comp_Timer.start();
	if is_blank:
		die();

func _process(_delta):
	speed = get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("bulletSpeed");
	pass;

# stupid workaround neccessary to make particles not flash random colors upon spawning
func _physics_process(delta):
	move(delta);
	self.z_index = self.position.y;
	if should_die:
		die();

var previous_compensation_progress = 0.0;

# Given an amount of delta time, moves the bullet in its trajectory direction using its speed
func move(d):
	var compensation_progress = 1.0 - ($Lag_Comp_Timer.time_left/$Lag_Comp_Timer.wait_time);
	var progress_delta = compensation_progress - previous_compensation_progress;
	previous_compensation_progress = compensation_progress;
	var total_compensation = 0;
	var deltatime = d;
	
	# Meat
	if puppet_state == Puppet_State.Master:
		total_compensation = (-(Globals.ping/2.0)-Globals.player_lerp_time)/1000.0;
	elif puppet_state == Puppet_State.Puppet:
		total_compensation = (puppet_time_shot-original_time_shot)/1000.0;
	elif puppet_state == Puppet_State.Server:
		total_compensation = 0;
		
	deltatime += progress_delta * total_compensation;
	var collision = move_and_collide(direction * deltatime * speed);


# Called when the animation timer fires
func _animation_timer_ended():
	$Sprite.frame = ($Sprite.frame + 1) % $Sprite.hframes;
# Called by server to terminate this bullet early
remotesync func receive_death():
	should_die = true;

func die():
	#Only show particles if we havn't already done so from a preliminary death
	if show_death_particles:
		spawn_death_particles();
	call_deferred("queue_free");

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
	if Globals.testing:
		should_die = true;


func spawn_death_particles():
	var particles = get_tree().get_root().get_node("MainScene").Bullet_Death_Particles.instance();
	particles.position = position;
	particles.rotation = rotation;
	particles.z_index = z_index;
	particles.team_id = team_id;
	get_tree().get_root().get_node("MainScene").call_deferred("add_child", particles);
