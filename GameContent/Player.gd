extends KinematicBody2D

var control = false;
var player_id = 0;
var team_id = -1;
const BASE_SPEED = 625;
const AIMING_SPEED = 150;
const SPRINT_SPEED = 250;
const TELEPORT_SPEED = 7500;
var speed = BASE_SPEED;
# Where this player starts on the map and should respawn at
var start_pos = Vector2(0,0);
# Whether or not this player is alive
var alive = true;
# Whether or not this player is currently invincible
var invincible = false;
# The camera that is associated with this player. A permanent reference is used because it may switch parents
var camera_ref = null;
# The direction the laser is firing at
var laser_direction = Vector2(0,0);
# The number of bullets this player has shot. Used for naming bullets
var bullets_shot = 0;
# The time in millis the last position was received
var time_of_last_received_pos = 0;
# The position to start lerping from
var lerp_start_pos = Vector2(0,0);
# The position to end lerping at
var lerp_end_pos = Vector2(0,0);
# Whether or not the player is sprinting
var sprintEnabled = false;
# Whether the player can currently teleport
var can_teleport = true;
var can_place_forcefield = true;
var max_forcefield_distance = 5000;
var remote_db_level = -10;
# The position the player was in last frame
var last_position = Vector2(0,0);


var bullet_atlas_blue = preload("res://Assets/Weapons/bullet_b.png");
var bullet_atlas_red = preload("res://Assets/Weapons/bullet_r.png");

var running_top_atlas_blue = preload("res://Assets/Player/running_top_B.png");
var running_top_atlas_red = preload("res://Assets/Player/running_top_R.png");

var shooting_top_atlas_blue = preload("res://Assets/Player/shooting_top_B.png");
var shooting_top_atlas_red = preload("res://Assets/Player/shooting_top_R.png");

var idle_top_atlas_blue = preload("res://Assets/Player/idle_top_B.png");
var idle_top_atlas_red = preload("res://Assets/Player/idle_top_R.png");

func _ready():
	camera_ref = $Center_Pivot/Camera;
	
	last_position = position;
	
	if Globals.testing:
		activate_camera();
		control = true
	
	if is_network_master() || Globals.testing:
		activate_camera();
		$Laser_Timer.wait_time += 0.1;
		$Laser_Charge_Audio.set_pitch_scale(float(0.5)/$Laser_Timer.wait_time);
	else:
		$Laser_Charge_Audio.set_volume_db(remote_db_level);
		$Laser_Fire_Audio.set_volume_db(remote_db_level);
	
	$Respawn_Timer.connect("timeout", self, "_respawn_timer_ended");
	$Invincibility_Timer.connect("timeout", self, "_invincibility_timer_ended");
	$Laser_Timer.connect("timeout", self, "_laser_timer_ended");
	$Teleport_Timer.connect("timeout", self, "_teleport_timer_ended");
	$Forcefield_Timer.connect("timeout", self, "_forcefield_timer_ended");
	$Animation_Timer.connect("timeout", self, "_animation_timer_ended");
	$Shoot_Animation_Timer.connect("timeout", self, "_shoot_animation_timer_ended");
	$Shoot_Animation_Timer.wait_time = $Animation_Timer.wait_time * $Sprite_Top.vframes;
	lerp_start_pos = position;
	lerp_end_pos = position;

func _input(event):
	if Globals.is_typing_in_chat:
		return;
	if control:
		if event is InputEventKey and event.pressed:
			if event.scancode == KEY_T:
				get_tree().get_root().get_node("MainScene/NetworkController").rpc("test_ping");
			if event.scancode == KEY_SHIFT:
				if $Flag_Holder.get_child_count() == 0:
					sprintEnabled = !sprintEnabled;
			if event.scancode == KEY_SPACE:
				# If were not holding a flag, attempt a teleport
				if $Flag_Holder.get_child_count() == 0:
					if can_teleport:
						move_on_inputs(true);
						camera_ref.lag_smooth();
						$Teleport_Timer.start();
						can_teleport = false;
			if event.scancode == KEY_E:
				# If were not holding a flag, create forcefield
				if $Flag_Holder.get_child_count() == 0:
					if can_place_forcefield:
						forcefield_placed();
			if event.scancode == KEY_1:
				Globals.player_lerp_time = 10;
			if event.scancode == KEY_2:
				Globals.player_lerp_time = 50;
			if event.scancode == KEY_3:
				Globals.player_lerp_time = 100;
			if event.scancode == KEY_4:
				Globals.player_lerp_time = 150;
			if event.scancode == KEY_5:
				Globals.player_lerp_time = 200;
		elif event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT:
				if event.pressed: # Click down
					# Only accepts clicks if we're not aiming a laser
					if $Laser_Timer.time_left == 0:
						if $Flag_Holder.get_child_count() == 0:
							shoot_bullet();
							sprintEnabled = false;
						else: # Otherwise drop our flag
							drop_current_flag($Flag_Holder.get_global_position());
							rpc_id(1, "send_drop_flag", $Flag_Holder.get_global_position());
				else: # Click up
					pass
			if event.button_index == BUTTON_RIGHT:
				if event.pressed:
					# Only accepts clicks if we're not aiming a laser
					if $Laser_Timer.time_left == 0:
						if $Flag_Holder.get_child_count() == 0:
							var direction = (get_global_mouse_position() - global_position).normalized();
							rpc_id(1, "send_start_laser", direction, position, $Sprite_Top.frame);
							start_laser(direction, position, $Sprite_Top.frame);
							sprintEnabled = false;
						else: # Otherwise drop our flag
							drop_current_flag($Flag_Holder.get_global_position());
							rpc_id(1, "send_drop_flag", $Flag_Holder.get_global_position());
				else:
					pass;

func _process(delta):
	if control:
		# Don't look around if we're shooting a laser
		if $Laser_Timer.time_left == 0:
			look_to_mouse();
		else:
			speed = AIMING_SPEED * ($Laser_Timer.time_left / $Laser_Timer.wait_time);
		# Move around as long as we aren't typing in chat
		if !Globals.is_typing_in_chat:
			move_on_inputs();
	update();
	if $Invincibility_Timer.time_left > 0:
		var t = $Invincibility_Timer.time_left / $Invincibility_Timer.wait_time 
		var x =  (t * 10);
		$Sprite_Top.modulate = Color(1,1,1,(sin( (PI / 2) + (x * (1 + (t * ((2 * PI) - 1))))) + 1)/2)
	z_index = global_position.y + 15;
	# Old
	# If we are a puppet and not the server, then lerp our position
	if !is_network_master() and !get_tree().is_network_server() and !Globals.testing:
		position = lerp(lerp_start_pos, lerp_end_pos, clamp(float(OS.get_ticks_msec() - time_of_last_received_pos)/float(Globals.player_lerp_time), 0.0, 1.0));
	
	if is_network_master():
		rpc_unreliable_id(1, "send_position", position, get_tree().get_network_unique_id());
	
	
	# Idle Animation
	var diff = last_position - position;
	if sqrt(pow(diff.x, 2) + pow(diff.y, 2)) < 1:
		if team_id == 1:
			$Sprite_Top.set_texture(idle_top_atlas_red);
		else:
			$Sprite_Top.set_texture(idle_top_atlas_blue);
		$Sprite_Bottom.frame = $Sprite_Top.frame % $Sprite_Top.hframes;
	else:
		if team_id == 1:
			$Sprite_Top.set_texture(running_top_atlas_red);
		else:
			$Sprite_Top.set_texture(running_top_atlas_blue);
		$Sprite_Bottom.frame = $Sprite_Top.frame;
		
	# Shooting Animation (Overrides idleness)
	if $Shoot_Animation_Timer.time_left > 0:
		if team_id == 1:
			$Sprite_Top.set_texture(shooting_top_atlas_red);
		else:
			$Sprite_Top.set_texture(shooting_top_atlas_blue);
		
	last_position = position;
	
remote func send_start_laser(direction, player_pos, frame):
	if get_tree().is_network_server():# Only run if it's the server
		var players = get_tree().get_root().get_node("MainScene/NetworkController").players;
		for i in players: # For each player
			if i != player_id && i != 1: # Don't do it for the player who sent it or for the server
				get_tree().get_root().get_node("MainScene/Players/" + str(player_id)).rpc_id(i, "receive_start_laser", direction, player_pos, frame);
		start_laser(direction, player_pos, frame); # Also call it locally for the server

remote func receive_start_laser(direction, player_pos, frame):
	start_laser(direction, player_pos, frame);

func start_laser(direction, player_pos, frame):
	position = player_pos;
	$Sprite_Top.frame = frame;
	$Sprite_Bottom.frame = frame;
	laser_direction = direction;
	$Laser_Timer.start();
	speed= AIMING_SPEED;
	camera_ref.shake($Laser_Timer.wait_time, 1, true);
	$Laser_Charge_Audio.play();

func _laser_timer_ended():
	shoot_laser();
	speed = BASE_SPEED;

# Called when the player attempts to place a forcefield
# This function will either place it in the appropriate spot or deny it (bad location or something)
func forcefield_placed():
	var distance = get_global_mouse_position().distance_to(position);
	var forcefield_position = get_global_mouse_position();
	if distance > max_forcefield_distance:
		var direction = (get_global_mouse_position() - global_position).normalized();
		forcefield_position = global_position + (direction * max_forcefield_distance);
	rpc("spawn_forcefield", forcefield_position);
	can_place_forcefield = false;
	$Forcefield_Timer.wait_time = Globals.forcefield_cooldown;
	$Forcefield_Timer.start();
	if Globals.testing:
		var forcefield = load("res://GameContent/Forcefield.tscn").instance();
		get_tree().get_root().get_node("MainScene").add_child(forcefield);
# Called when the forcefield cooldown timer ends
func _forcefield_timer_ended():
	can_place_forcefield = true;

# Called by client telling everyone to spawn a forcefield in a spot
# NOTE - in future this should be handled by servers - not the client.
remotesync func spawn_forcefield(pos):
	var forcefield = load("res://GameContent/Forcefield.tscn").instance();
	get_tree().get_root().get_node("MainScene").add_child(forcefield);
	forcefield.position = pos;
	forcefield.player_id = player_id;
	forcefield.team_id = team_id;


# Shoots a laser shot
func shoot_laser():
	print("SHOOT LASER");
	if is_network_master():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
	# Only run if we're the server
	var laser = load("res://GameContent/Laser.tscn").instance();
	get_tree().get_root().get_node("MainScene").add_child(laser);
	laser.position = position;
	laser.rotation = -get_vector_angle(laser_direction);
	laser.player_id = player_id;
	laser.team_id = team_id;
	$Laser_Fire_Audio.play();


func _draw():
	if $Laser_Timer.time_left > 0:
		var size = clamp(1 / ($Laser_Timer.time_left / $Laser_Timer.wait_time), 0 , 20);
		var red = 1 if team_id == 1 else 0;
		var green = 10.0/255.0 if team_id == 1 else 130.0/255.0;
		var blue = 1 if team_id == 0 else 0;
		var lightener = 0.2;
		red = red + lightener;
		green = green + lightener;
		blue = blue + lightener;
		draw_line(Vector2(0,0), laser_direction * 5000, Color(red, green, blue, 1 - ($Laser_Timer.time_left / $Laser_Timer.wait_time)), size);


# Shoots a bullet shot
func shoot_bullet():
	var direction = (get_global_mouse_position() - global_position).normalized()
	bullets_shot = bullets_shot + 1;
	var bullet_start = position + get_node("Bullet_Starts/" + String($Sprite_Top.frame % $Sprite_Top.hframes)).position;
	var bullet = spawn_bullet(bullet_start, get_tree().get_network_unique_id(), direction, null);
	camera_ref.shake();
	$Shoot_Animation_Timer.start();
	animation_set_frame = 0;
	rpc_id(1, "send_bullet", bullet_start, get_tree().get_network_unique_id(), direction, bullet.name);

# Spawns a bullet given various initializaiton parameters
func spawn_bullet(pos, player_id, direction, bullet_name = null):
	
#	# If this was fired by another player, compensate for player lerp speed
#	if player_id != get_tree().get_network_unique_id() && !get_tree().is_network_server():
#		var t = Timer.new()
#		t.set_wait_time(float(Globals.player_lerp_time)/float(1000.0))
#		t.set_one_shot(true)
#		self.add_child(t)
#		t.start()
#		yield(t, "timeout")
#		t.queue_free();
#		print("waited");
	
	var bullet = load("res://GameContent/Bullet.tscn").instance();
	bullet.position = pos;
	bullet.direction = direction;
	bullet.player_id = player_id;
	bullet.team_id = team_id;
	if team_id == 0:
		bullet.get_node("Sprite").set_texture(bullet_atlas_blue);
	elif team_id == 1:
		bullet.get_node("Sprite").set_texture(bullet_atlas_red);
	get_tree().get_root().get_node("MainScene").add_child(bullet);
	bullet.set_network_master(player_id);
	if bullet_name != null:
		bullet.name = bullet_name;
		print("Received: " + bullet_name);
	else:
		bullet.name = bullet.name + "-" + str(player_id) + "-" + str(bullets_shot);
		print("Made: " + bullet.name);
	
	
	return bullet;

# A vector 2D representing the last movement key directions pressed
var last_movement_input = Vector2(0,0);

# Checks the current pressed keys and calculates a new player position using the KinematicBody2D
func move_on_inputs(teleport = false):
	var input = Vector2(0,0);
	input.x = (1 if Input.is_key_pressed(KEY_D) else 0) - (1 if Input.is_key_pressed(KEY_A) else 0)
	input.y = (1 if Input.is_key_pressed(KEY_S) else 0) - (1 if Input.is_key_pressed(KEY_W) else 0)
	last_movement_input = input;
	
	# Distribute values evenly so that distance is equal even when moving at angle
	var c = 1;
	if input.x != 0 and input.y != 0:
		c = 1 / sqrt (pow(input.x, 2) + pow(input.y, 2));
	var distribution = input * c;
	var move_speed = speed;
	if sprintEnabled:
		move_speed += SPRINT_SPEED;
	if teleport:
		move_speed = TELEPORT_SPEED;
	var vec = (distribution * move_speed);
	
	var previous_pos = position;
	var change = move_and_slide(vec);
	var new_pos = position;
	
	if teleport:
		rpc("create_ghost_trail", previous_pos, new_pos);
		if Globals.testing:
			$Teleport_Audio.play();
	

func _teleport_timer_ended():
	can_teleport = true;

remotesync func create_ghost_trail(start, end):
	$Teleport_Audio.play();
	for i in range(6):
		var node = load("res://GameContent/Ghost_Trail.tscn").instance();
		get_tree().get_root().get_node("MainScene").add_child(node);
		node.position = start;
		node.position.x = node.position.x + ((i) * (end.x - start.x)/4)
		node.position.y = node.position.y + ((i) * (end.y - start.y)/4)
		node.get_node("Death_Timer").start((i) * 0.05 + 0.0001);
		node.get_node("Sprite_Top").texture = $Sprite_Top.texture
		node.get_node("Sprite_Top").hframes = $Sprite_Top.hframes
		node.get_node("Sprite_Top").vframes = $Sprite_Top.vframes
		node.get_node("Sprite_Top").frame = $Sprite_Top.frame
		node.get_node("Sprite_Top").scale = $Sprite_Top.scale
		node.get_node("Sprite_Bottom").texture = $Sprite_Bottom.texture
		node.get_node("Sprite_Bottom").hframes = $Sprite_Bottom.hframes
		node.get_node("Sprite_Bottom").vframes = $Sprite_Bottom.vframes
		node.get_node("Sprite_Bottom").frame = $Sprite_Bottom.frame
		node.get_node("Sprite_Bottom").scale = $Sprite_Bottom.scale
	# If this is a puppet, use this ghost trail as an oppurtunity to also update its position
	if !is_network_master():
		lerp_start_pos = end;
		lerp_end_pos = end;
		position = end;
	
# Changes the sprite's frame to make it "look" at the mouse
func look_to_mouse():
	var pos = get_global_mouse_position();
	var dist = pos - position;
	var angle = get_vector_angle(dist);
	var adjustedAngle = -1 * (angle + (PI/8));
	var octant = (adjustedAngle / (2 * PI)) * 8
	var frame = int((octant + 9) + 4) % 8;
	frame += animation_set_frame * $Sprite_Top.hframes;
	if frame != $Sprite_Top.frame: # If it changed since last time
		set_look_direction(frame);
		rpc_unreliable_id(1, "send_look_direction", frame, get_tree().get_network_unique_id());
var animation_set_frame = 0;
# Called when the animation timer fires
func _animation_timer_ended():
	animation_set_frame += 1;
	animation_set_frame = animation_set_frame % $Sprite_Top.vframes;

func _shoot_animation_timer_ended():
	if team_id == 1:
		$Sprite_Top.set_texture(running_top_atlas_red);
	else:
		$Sprite_Top.set_texture(running_top_atlas_blue);

# Gets the angle that a vector is making
func get_vector_angle(dist):
	var angle = (-(PI / 2) if dist.y < 0 else ( 3 * PI / 2)) if dist.x == 0 else atan(dist.y / dist.x);
	angle = angle * -1;
	angle += PI/2;
	if dist.x < 0:
		angle += PI;
	return angle;

# Set the direction that the player is "looking" at by changing sprite frame
func set_look_direction(frame):
	$Sprite_Top.frame = frame;
	$Sprite_Bottom.frame = frame;
	

# Updates this player's position with the new given position. Only ever called remotely
func update_position(new_pos):
	# Instantly update position for server
	if get_tree().is_network_server():
		position = new_pos;
		return;
	# Otherwise lerp
	
	position = lerp(lerp_start_pos, lerp_end_pos, clamp(float(OS.get_ticks_msec() - time_of_last_received_pos)/float(Globals.player_lerp_time), 0.0, 1.0));
	time_of_last_received_pos = OS.get_ticks_msec();
	lerp_start_pos = position;
	lerp_end_pos = new_pos;

# Activates the camera on this player
func activate_camera():
	camera_ref.current = true;

# De-activates the camera on this player
func deactivate_camera():
	camera_ref.current = false;

# Called when this player is hit by a projectile
func hit_by_projectile(attacker_id, projectile_type):
	if projectile_type == 0 || projectile_type == 1: # Bullet or Laser
		die();
		if is_network_master():
			var attacker_team_id = get_tree().get_root().get_node("MainScene/NetworkController").players[attacker_id]["team_id"]
			var attacker_name = get_tree().get_root().get_node("MainScene/NetworkController").players[attacker_id]["name"]
			get_tree().get_root().get_node("MainScene/UI_Layer").set_big_label_text("KILLED BY\n" + str(attacker_name), attacker_team_id);
			camera_ref.get_parent().remove_child(camera_ref);
			get_tree().get_root().get_node("MainScene/Players/" + str(attacker_id) + "/Center_Pivot").add_child(camera_ref);
		

# "Kills" the player. Only for visuals on client - the server handles the respawning.
func die():
	visible = false;
	control = false;
	alive = false;
	spawn_death_particles();
	# If we're the server
	if get_tree().is_network_server():
		$Respawn_Timer.start();
	# Drop the flag if you have one
	drop_current_flag($Flag_Holder.get_global_position());
	position = start_pos;
	if is_network_master():
		$Death_Audio.play();
	else:
		$Killed_Audio.play();

func spawn_death_particles():
	var particles = load("res://GameContent/Player_Death_Particles.tscn").instance();
	get_tree().get_root().get_node("MainScene").add_child(particles);
	particles.position = position;
	particles.rotation = rotation;
	# Were using the bullet gradients out of laziness
	if team_id == 0:
		particles.color_ramp = load("res://GameContent/Blue_Bullet_Death_Particle_Gradient.tres")
	elif team_id == 1:
		particles.color_ramp = load("res://GameContent/Red_Bullet_Death_Particle_Gradient.tres")

# Called by the respawn timer when it ends
func _respawn_timer_ended():
	rpc("receive_respawn");

# Respawns the player at their team's start location
func respawn():
	visible = true;
	alive = true;
	position = start_pos;
	if is_network_master():
		control = true;
	start_temporary_invincibility();
	if is_network_master():
			get_tree().get_root().get_node("MainScene/UI_Layer").clear_big_label_text();
			camera_ref.get_parent().remove_child(camera_ref);
			$Center_Pivot.add_child(camera_ref);
	else:
		lerp_start_pos = position;
		lerp_end_pos = position;
		time_of_last_received_pos = 0;

# Takes the given flag
func take_flag(flag_id):
	if is_network_master():
		get_tree().get_root().get_node("MainScene").speedup_music();
	$Flag_Pickup_Audio.play();
	for flag in get_tree().get_nodes_in_group("Flags"):
		if flag.flag_id == flag_id:
			flag.re_parent($Flag_Holder);
			flag.is_at_home = false;
			flag.position = Vector2(0,0);
	sprintEnabled = false;

# Drops the currently held flag (If there is one)
func drop_current_flag(flag_position):
	
	if is_network_master():
		get_tree().get_root().get_node("MainScene").slowdown_music();
	$Flag_Drop_Audio.play();
	# Only run if there is a flag in the Flag_Holder
	if $Flag_Holder.get_child_count() > 0:
		# Just get the first flag because there should only ever be one
		var flag = $Flag_Holder.get_children()[0];
		flag.get_node("Area2D").player_id_drop_buffer = player_id;
		flag.get_node("Area2D").ignore_next_buffer_reset = true;
		flag.re_parent(get_tree().get_root().get_node("MainScene"));
		flag.position = flag_position;

# Starts the temporary Invincibility cooldown
func start_temporary_invincibility():
	$Invincibility_Timer.start();
	invincible = true;
# Called by timer when invincibility is over
func _invincibility_timer_ended():
	# If we're the server, make the call to actually end invinciblity
	if get_tree().is_network_server():
		rpc("receive_end_invinciblity");

	


# -------- NETWORKING ------------------------------------------------------------>



# Client tells Server to run this function so that it can send it's latest position
# The Server then sends that position to all other clients
remote func send_position(new_pos, player_id):
	if get_tree().is_network_server(): # Only run if it's the server
		var players = get_tree().get_root().get_node("MainScene/NetworkController").players;
		for i in players: # For each player
			if i != player_id && i != 1: # Don't do it for the player who sent it or for the server
				get_tree().get_root().get_node("MainScene/Players/" + str(player_id)).rpc_unreliable_id(i, "receive_position", new_pos);
		update_position(new_pos); # Also call it locally for the server

# "Receives" the position of this player from the server
remote func receive_position(new_pos):
	update_position(new_pos);

# Client tells the server that it just shot a bullet
remote func send_bullet(pos, player_id, direction, bullet_name):
	if get_tree().is_network_server(): # Only run if it's the server
		var players = get_tree().get_root().get_node("MainScene/NetworkController").players;
		for i in players: # For each player
			if i != player_id && i != 1: # Don't do it for the player who sent it or for the server
				get_tree().get_root().get_node("MainScene/Players/" + str(player_id)).rpc_id(i, "receive_bullet", pos, player_id, direction, bullet_name);
		spawn_bullet(pos, player_id, direction, bullet_name); # Also call it locally for the server

# "Receives" a bullet from the server that was shot by another client
remote func receive_bullet(pos, player_id, direction, bullet_name):
	spawn_bullet(pos, player_id, direction, bullet_name);

# Client tells the server what direction frame it's looking at 
remote func send_look_direction(frame, player_id):
	if get_tree().is_network_server(): # Only run if it's the server
		var players = get_tree().get_root().get_node("MainScene/NetworkController").players;
		for i in players: # For each player
			if i != player_id && i != 1: # Don't do it for the player who sent it or for the server
				get_tree().get_root().get_node("MainScene/Players/" + str(player_id)).rpc_id(i, "receive_look_direction", frame);
		set_look_direction(frame); # Also call it locally for the server

# "Receives" the direction frame that this player is looking at from the server
remote func receive_look_direction(frame):
	set_look_direction(frame);

# "Receives" notification from the server that this player was hit by a projectile
remotesync func receive_hit(attacker_id, projectile_type):
	hit_by_projectile(attacker_id, projectile_type);

# Receives notification from the server that this player took the given flag
remotesync func receive_take_flag(flag_id):
	take_flag(flag_id);

# Client tells server that it is dropping the flag
remote func send_drop_flag(flag_position):
	if get_tree().is_network_server():# Only run if it's the server
		var players = get_tree().get_root().get_node("MainScene/NetworkController").players;
		for i in players: # For each player
			if i != player_id && i != 1: # Don't do it for the player who sent it or for the server
				get_tree().get_root().get_node("MainScene/Players/" + str(player_id)).rpc_id(i, "receive_drop_flag", flag_position);
		drop_current_flag(flag_position); # Also call it locally for the server

# Sent by server to tell clients that this player dropped its flag at the given position
remote func receive_drop_flag(flag_position):
	drop_current_flag(flag_position);

# Receives notification from the server to respawn this player
remotesync func receive_respawn():
	respawn();

# Received by server to end this player's invincibility
remotesync func receive_end_invinciblity():
	invincible = false;
	$Invincibility_Timer.stop();
	$Sprite_Top.modulate = Color(1,1,1,1);
	$Sprite_Bottom.modulate = Color(1,1,1,1);
