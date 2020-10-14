extends KinematicBody2D

enum Puppet_State{Master, Puppet, Server};
var puppet_state = Puppet_State.Master;
var direction = Vector2(0,-1);
var speed = 400;
var team_id = -1;
var player_id = -1;
var original_time_shot = 0;
var puppet_time_shot = 0;
var is_blank = false;

func _ready():
	$Detonation_Timer.connect("timeout", self, "_detonation_timer_ended");
	$Death_Timer.connect("timeout", self, "_death_timer_ended");
	if is_blank:
		detonate();
		return;
	#$Animation_Timer.connect("timeout", self, "_animation_timer_ended");
	# If the master of this bullet is not the local master player, then this is a puppet
	
	puppet_time_shot = OS.get_system_time_msecs() - Globals.match_start_time;
	if !Globals.testing and get_tree().get_network_unique_id() != get_network_master():
		if get_tree().is_network_server():
			puppet_state = Puppet_State.Server;
		else:
			puppet_state = Puppet_State.Puppet;
			if (puppet_time_shot-original_time_shot)/1000.0 > $Detonation_Timer.wait_time:
				call_deferred("free");
				return;
			$Detonation_Timer.wait_time += -(puppet_time_shot-original_time_shot)/1000.0;
	if puppet_state == Puppet_State.Master:
		$Lag_Comp_Timer.wait_time *= 3;
		$Detonation_Timer.wait_time += ((Globals.ping/2.0)-Globals.player_lerp_time)/1000.0;
	$Lag_Comp_Timer.start();
	$Detonation_Timer.start();
	$Area2D.monitorable = false;
	

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
		t.call_deferred("free");
		print("Waited for detonation");

	$Detonation_Timer.stop();
	$Death_Timer.start();
	$Explosion_Audio.play();
	$Area2D.monitorable = true;
	speed = 0;

func _death_timer_ended():
	
	# Give time for audio to finish
	$Area2D.monitorable = false;
	$Area2D.monitoring = false;
	$Area2D2.monitorable = false;
	$Area2D2.monitoring = false;
	visible = false;
	yield(get_tree().create_timer(1), "timeout");
	call_deferred("free");
func _process(delta):
	if $Death_Timer.time_left > 0:
		var progress = 1.0 - $Death_Timer.time_left/$Death_Timer.wait_time;
		var frame = int(progress * ($Sprite.hframes + 1)) - 1;
		if frame >= $Sprite.hframes:
			frame = $Sprite.hframes - 1;
		if frame < 0:
			frame = 0;
		$Sprite.frame = frame;
	update();

func _draw():
	var alpha = 0.25 + (sin(2 * PI * 5 *(1 - $Death_Timer.time_left/$Death_Timer.wait_time))+1)/4.0;
	var color = Color(0,0.2,1,alpha);
	if team_id == 1:
		color = Color(1,0.2,0,alpha);
	if $Area2D.monitorable and !is_blank:
		draw_circle(Vector2.ZERO,50,color);
func _physics_process(delta):
	if !is_blank:
		move(delta);

var previous_compensation_progress = 0.0;
# Given an amount of delta time, moves the bullet in its trajectory direction using its speed
func move(d):
	if $Death_Timer.time_left > 0:
		return;
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
		if check_for_explosion(collision):
			return;
		# Reflect bullet
		var reflection_dir = (direction - (2 * direction.dot(collision.normal) * collision.normal)).normalized();
		collision = move_and_collide(reflection_dir * collision.remainder.distance_to(Vector2.ZERO));
		if collision:
			check_for_explosion(collision);
		direction = reflection_dir;
func check_for_explosion(collision) -> bool:
	if !Globals.testing and !get_tree().is_network_server():
		return false;
	if collision.collider.is_in_group("Forcefield_Bodies"):
		if Globals.testing:
			fizout();
		else:
			rpc("fizout", true);
		return true;
	return false;
remotesync func fizout():
	$Death_Timer.start();
	is_blank = true;
