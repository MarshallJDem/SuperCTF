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
var stuck_player = null;
var stick_direction = Vector2.DOWN;
var animation_progress = 0.0;
var death_atlas_blue = preload("res://Assets/Weapons/bullet_death_B.png");
var death_atlas_red = preload("res://Assets/Weapons/bullet_death_R.png");
var has_been_stuck = false;

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
	

remotesync func stick_to_player(p_id, stick_direction):
	var p = get_tree().get_root().get_node_or_null("MainScene/Players/P" + str(p_id));
	if Globals.testing:
		p = get_tree().get_root().get_node("MainScene/Test_Player");
	has_been_stuck = true;
	if p == null or !is_instance_valid(p):
		print_stack();
		return;
	stuck_player = p;
	self.stick_direction = stick_direction;

func detonate():
	
	# If we already detonated
	if $Death_Timer.time_left > 0:
		return;
	if team_id == 1:
		$Sprite.set_texture(death_atlas_red);
	else:
		$Sprite.set_texture(death_atlas_blue);
	$Sprite.hframes = 5;
		
	
	if stuck_player != null and is_instance_valid(stuck_player):
		# Detach from player if they die
		if stuck_player.alive == false:
			stuck_player = null;
		else:
			position = stuck_player.position + (10  * stick_direction);
			z_index = stuck_player.z_index + 5;
	
	if get_tree().is_network_server():
		if stuck_player != null and is_instance_valid(stuck_player):
			# Ignore invincibility because dash gives u temporary invincibility
			if stuck_player.alive == true and Globals.testing == false and stuck_player.get_node("Invincibility_Timer").time_left == 0:
				stuck_player.rpc("receive_hit", player_id, 3);
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
	if get_tree().is_network_server():
		yield(get_tree().create_timer(1), "timeout");
		rpc("die"); # WARNING : Sometimes this throws an error if the demo dies in the time of this yield.
	
remotesync func die():
	call_deferred("queue_free");
	
func _process(delta):
	
	animation_progress += delta;
	var val = sin(animation_progress * 40);
	if $Detonation_Timer.time_left <= 0.75 and $Death_Timer.time_left == 0:
		if val >= 0:
			$Sprite.frame = 0;
		else:
			$Sprite.frame = 3;
	
	# Area only detects collision for a very brief time
	if $Death_Timer.time_left != 0 and $Death_Timer.time_left < 0.4:
		$Area2D.monitorable = false;
		$Area2D.monitoring = false;
		$Area2D2.monitorable = false;
		$Area2D2.monitoring = false;
	
	if $Death_Timer.time_left > 0:
		var progress = 1.0 - $Death_Timer.time_left/$Death_Timer.wait_time;
		var frame = int(progress * ($Sprite.hframes + 1)) - 1;
		if frame >= $Sprite.hframes:
			frame = $Sprite.hframes - 1;
		if frame < 0:
			frame = 0;
		$Sprite.frame = frame;
	if !is_blank:
		if stuck_player != null and is_instance_valid(stuck_player):
			# Detach from player if they die
			if stuck_player.alive == false:
				stuck_player = null;
			else:
				position = stuck_player.position + (10  * stick_direction);
				z_index = stuck_player.z_index + 5;
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
		if !has_been_stuck:
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
	simulate_physics(deltatime);

func simulate_physics(deltatime):
	var collided_with_forcefield = false;
	var remainder = deltatime * speed;
	var samples = 0;
	while(remainder != 0 and samples < 15):
		samples += 1;
		var collision = move_and_collide(direction * remainder);
		if collision:
			if check_for_explosion(collision):
				return;
			# Reflect bullet
			var reflection_dir = (direction - (2 * direction.dot(collision.normal) * collision.normal)).normalized();
			remainder = collision.remainder.distance_to(Vector2.ZERO);
			direction = reflection_dir
			if collision.collider.is_in_group("Forcefield_Bodies"):
				collided_with_forcefield = true
		else:
			remainder = 0;
	if !Globals.testing and get_tree().is_network_server() and collided_with_forcefield:
		rpc("direction_override", direction, position, (OS.get_system_time_msecs() - Globals.match_start_time));

remotesync func direction_override(dir, pos ,time):
	# This is irellevant for the server because it would just override its own changes
	if get_tree().is_network_server():
		return;
	direction = dir;
	position = pos;
	var deltatime = ((OS.get_system_time_msecs() - Globals.match_start_time) - time)/1000;
	simulate_physics(deltatime);
	

func check_for_explosion(collision) -> bool:
	if !Globals.testing and !get_tree().is_network_server():
		return false;
	#if collision.collider.is_in_group("Forcefield_Bodies"):
	#	if Globals.testing:
	#		fizout();
	#	else:
	#		rpc("fizout");
	#	return true;
	return false;

remotesync func fizout():
	$Death_Timer.start();
	is_blank = true;
