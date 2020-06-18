extends KinematicBody2D

enum Puppet_State{Master, Puppet, Server};
var puppet_state = Puppet_State.Master;
var direction = Vector2(0,-1);
var speed = 300;
var team_id = -1;
var player_id = -1;
var original_time_shot = 0;
var puppet_time_shot = 0;

func _ready():
	$Detonation_Timer.connect("timeout", self, "_detonation_timer_ended");
	$Death_Timer.connect("timeout", self, "_death_timer_ended");
	#$Animation_Timer.connect("timeout", self, "_animation_timer_ended");
	# If the master of this bullet is not the local master player, then this is a puppet
	if !Globals.testing and get_tree().get_network_unique_id() != get_network_master():
		if get_tree().is_network_server():
			puppet_state = Puppet_State.Server;
		else:
			puppet_state = Puppet_State.Puppet;
			$Detonation_Timer.wait_time -= (Globals.player_lerp_time * 2)/1000.0;
	if puppet_state == Puppet_State.Master:
		$Lag_Comp_Timer.wait_time *= 3;
		$Detonation_Timer.wait_time += (Globals.player_lerp_time * 2)/1000.0;
	puppet_time_shot = OS.get_system_time_msecs() - Globals.match_start_time;
	$Lag_Comp_Timer.start();
	$Detonation_Timer.start();
	$Area2D.monitorable = false;
	print(puppet_state);
func _detonation_timer_ended():
	detonate();

remotesync func detonate(from_remote = false):
	
	# If we already detonated
	if $Death_Timer.time_left > 0:
		return;
	if from_remote and puppet_state == Puppet_State.Master:
		var t = Timer.new();
		t.set_wait_time(float(Globals.player_lerp_time)/float(1000.0));
		t.set_one_shot(true);
		self.add_child(t);
		t.start();
		yield(t, "timeout");
		t.queue_free();
		print("Waited for detonation");

	$Detonation_Timer.stop();
	$Death_Timer.start();
	$Area2D.monitorable = true;
	speed = 0;

func _death_timer_ended():
	call_deferred("queue_free");

func _process(delta):
	update();

func _draw():
	if $Area2D.monitorable:
		draw_circle(Vector2.ZERO,50,Color(0.0,1.0,0.0,0.5));
# stupid workaround neccessary to make particles not flash random colors upon spawning
func _physics_process(delta):
	move(delta);
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
	if collision:
		# Reflect bullet
		var reflection_dir = (direction - (2 * direction.dot(collision.normal) * collision.normal)).normalized();
		move_and_collide(reflection_dir * collision.remainder.distance_to(Vector2.ZERO));
		direction = reflection_dir;
