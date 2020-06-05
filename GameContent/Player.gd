extends KinematicBody2D

var control = false;
var IS_CONTROLLED_BY_MOUSE = true;
# The ID of this player 0,1,2 etc. NOT the network unique ID
var player_id = -1;
var team_id = -1;
var BASE_SPEED = 200;
const AIMING_SPEED = 15;
const SPRINT_SPEED = 50;
const FLAG_SLOWDOWN_SPEED = -25;
var TELEPORT_SPEED = 2000;
var POWERUP_SPEED = 0;
var BULLET_COOLDOWN_PMODIFIER = 0;
var DASH_COOLDOWN_PMODIFIER = 0;
var FORCEFIELD_COOLDOWN_PMODIFIER = 0;
var LASER_WIDTH_PMODIFIER = 0;
var player_name = "Guest999";
var speed = BASE_SPEED;
# Where this player starts on the map and should respawn at
var start_pos = Vector2(0,0);
# Whether or not this player is alive
var alive = true;
# Whether or not this player is currently invincible
var invincible = false;
# The camera that is associated with this player. A reference is used because it may switch parents
var camera_ref = null;
# The direction the laser is firing at
var laser_direction = Vector2(0,0);
# The position the laser is firing from
var laser_position = Vector2(0,0);
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
var max_forcefield_distance = 5000;
var remote_db_level = -10;
# The position the player was in last frame
var last_position = Vector2(0,0);
# Whether the grenade weapon is currently enabled
var grenade_enabled = false;
# The frame of the all of the sprite on the top (Gun, Head, Body)
var look_direction = 0;

# Kits / Classes
var grenade_equipped = false;
var laser_equipped = false;
var bullet_equipped = false;
enum Kits {Bullet, Laser, Grenade};


var bullet_atlas_blue = preload("res://Assets/Weapons/bullet_b.png");
var bullet_atlas_red = preload("res://Assets/Weapons/bullet_r.png");

var running_top_atlas_blue = preload("res://Assets/Player/running_top_B.png");
var running_top_atlas_red = preload("res://Assets/Player/running_top_R.png");

var shooting_top_atlas_blue = preload("res://Assets/Player/shooting_top_B.png");
var shooting_top_atlas_red = preload("res://Assets/Player/shooting_top_R.png");

var idle_top_atlas_blue = preload("res://Assets/Player/idle_top_B.png");
var idle_top_atlas_red = preload("res://Assets/Player/idle_top_R.png");

var Muzzle_Bullet = preload("res://GameContent/Muzzle_Bullet.tscn");
var Bullet = preload("res://GameContent/Bullet.tscn");
var Forcefield = preload("res://GameContent/Forcefield.tscn");
var Laser = preload("res://GameContent/Laser.tscn");
var Grenade = preload("res://GameContent/Grenade.tscn");
var Ghost_Trail = preload("res://GameContent/Ghost_Trail.tscn");
var Player_Death = preload("res://GameContent/Player_Death.tscn");


func _ready():
	camera_ref = $Center_Pivot/Camera;
	set_kit(Kits.Bullet);
	
	last_position = position;
	
	if Globals.testing:
		activate_camera();
		control = true
	
	if Globals.testing or Globals.localPlayerID == player_id:
		$Laser_Timer.wait_time += 0.1;
		$Laser_Charge_Audio.set_pitch_scale(float(0.5)/$Laser_Timer.wait_time);
	else:
		$Laser_Charge_Audio.set_volume_db(remote_db_level);
		$Laser_Fire_Audio.set_volume_db(remote_db_level);
	
	$Respawn_Timer.connect("timeout", self, "_respawn_timer_ended");
	$Invincibility_Timer.connect("timeout", self, "_invincibility_timer_ended");
	$Laser_Timer.connect("timeout", self, "_laser_timer_ended");
	$Laser_Input_Timer.connect("timeout", self, "_laser_input_timer_ended");
	$Powerup_Timer.connect("timeout", self, "_powerup_timer_ended");
	#$Laser_Cooldown_Timer.connect("timeout", self, "_laser_cooldown_timer_ended");
	$Forcefield_Timer.connect("timeout", self, "_forcefield_timer_ended");
	#$Top_Animation_Timer.connect("timeout", self, "_animation_timer_ended");
	#$Shoot_Animation_Timer.connect("timeout", self, "_shoot_animation_timer_ended");
	#$Shoot_Animation_Timer.wait_time = $Animation_Timer.wait_time;
	lerp_start_pos = position;
	lerp_end_pos = position;

func _input(event):
	if Globals.is_typing_in_chat:
		return;
	if control:
		if event is InputEventKey and event.pressed:
			if event.scancode == KEY_1:
				set_kit(Kits.Bullet);
			if event.scancode == KEY_2:
				set_kit(Kits.Laser);
			if event.scancode == KEY_3:
				set_kit(Kits.Grenade);
			if event.scancode == KEY_T:
				get_tree().get_root().get_node("MainScene/NetworkController").rpc("test_ping");
			if event.scancode == KEY_CONTROL:
				if $Flag_Holder.get_child_count() == 0:
					sprintEnabled = !sprintEnabled;
			if event.scancode == KEY_SHIFT:
				switch_weapons();
			if event.scancode == KEY_SPACE:
				#Attempt a teleport
				# Re-enable line below to prevent telporting while you have flag
				# if $Flag_Holder.get_child_count() == 0:
				if $Teleport_Timer.time_left == 0:
					move_on_inputs(true);
					camera_ref.lag_smooth();
					$Teleport_Timer.start();
			if event.scancode == KEY_E:
				# If were not holding a flag, create forcefield
				# This is now disabled. You can place forcefield whenever you please kiddo
				if true || $Flag_Holder.get_child_count() == 0:
					if $Forcefield_Timer.time_left == 0:
						forcefield_placed();
			if event.scancode == KEY_Q:
				# If the grenade cooldown is over
				if $Grenade_Cooldown_Timer.time_left == 0:
					toggle_grenade();
		elif event is InputEventMouseButton:
			if !event.is_pressed():
				if grenade_equipped and grenade_enabled:
					# Fire grenade on right mouse up
					if Globals.testing:
						shoot_grenade(self.global_position, self.global_position + last_grenade_position, OS.get_system_time_msecs());
					else:
						rpc("shoot_grenade",self.global_position, self.global_position + last_grenade_position, OS.get_system_time_msecs() - Globals.match_start_time);
		elif event is InputEventMouseMotion:
			if IS_CONTROLLED_BY_MOUSE and grenade_equipped and grenade_enabled:
				aim_grenade(get_local_mouse_position().normalized());
func _process(delta):
	var new_speed = get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("playerSpeed");
	if speed == BASE_SPEED:
		speed = new_speed;
	BASE_SPEED = new_speed;
	TELEPORT_SPEED = get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("dashDistance");
	$Shoot_Cooldown_Timer.wait_time = BULLET_COOLDOWN_PMODIFIER + float(get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("bulletCooldown"))/1000.0;
	$Laser_Cooldown_Timer.wait_time = float(get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("laserCooldown"))/1000.0;
	$Forcefield_Timer.wait_time = FORCEFIELD_COOLDOWN_PMODIFIER + float(get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("forcefieldCooldown"))/1000.0;
	$Teleport_Timer.wait_time = DASH_COOLDOWN_PMODIFIER + float(get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("dashCooldown"))/1000.0;
	$Laser_Timer.wait_time = float(get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("laserChargeTime"))/1000.0;
	if control:
		activate_camera();
		# Don't look around if we're shooting a laser
		if $Laser_Timer.time_left == 0:
			update_look_direction();
		if $Laser_Timer.time_left + $Laser_Input_Timer.time_left > 0:
			speed = AIMING_SPEED * ($Laser_Timer.time_left / $Laser_Timer.wait_time);
		# Move & Shoot around as long as we aren't typing in chat
		if !Globals.is_typing_in_chat:
			move_on_inputs();
			shoot_on_inputs();
	update();
	if $Invincibility_Timer.time_left > 0:
		var t = $Invincibility_Timer.time_left / $Invincibility_Timer.wait_time 
		var x =  (t * 10);
		var color = Color(1,1,1,(sin( (PI / 2) + (x * (1 + (t * ((2 * PI) - 1))))) + 1)/2);
		modulate = color
	z_index = global_position.y + 15;
	
	
	
	# If we are a puppet and not the server, then lerp our position
	if !Globals.testing and !is_network_master() and !get_tree().is_network_server():
		position = lerp(lerp_start_pos, lerp_end_pos, clamp(float(OS.get_ticks_msec() - time_of_last_received_pos)/float(Globals.player_lerp_time), 0.0, 1.0));
	
	if !Globals.testing and is_network_master() and !get_tree().is_network_server():
		rpc_unreliable_id(1, "send_position", position, player_id);
	
	
	# Animation
	var diff = last_position - position;
	if sqrt(pow(diff.x, 2) + pow(diff.y, 2)) < 1:
		# Idle
		if team_id == 1:
			#$Sprite_Top.set_texture(idle_top_atlas_red);
			pass;
		else:
			#$Sprite_Top.set_texture(idle_top_atlas_blue);
			pass;
		$Sprite_Legs.frame = look_direction;
	else:
		# Moving
		if team_id == 1:
			#$Sprite_Top.set_texture(running_top_atlas_red);
			pass;
		else:
			#$Sprite_Top.set_texture(running_top_atlas_blue);
			pass;
		$Sprite_Legs.frame = look_direction + (int((1-($Leg_Animation_Timer.time_left / $Leg_Animation_Timer.wait_time)) * 4)%4) * $Sprite_Legs.hframes;
	
	
	$Sprite_Head.position.y = int(2 * sin((1 - $Top_Animation_Timer.time_left/$Top_Animation_Timer.wait_time)*(2 * PI)))/2.0;
	$Sprite_Gun.position.y = int(2 * sin((PI * 0.25) + (1 - $Top_Animation_Timer.time_left/$Top_Animation_Timer.wait_time)*(2 * PI)))/2.0;
	$Sprite_Gun.position.x = 0;
	
	# Shooting Animation (Overrides idleness)
	if $Shoot_Animation_Timer.time_left > 0:
		if team_id == 1:
			#$Sprite_Top.set_texture(shooting_top_atlas_red);
			pass;
		else:
			#$Sprite_Top.set_texture(shooting_top_atlas_blue);
			pass;
		if look_direction == 0:
			$Sprite_Gun.position.y = 20 * $Shoot_Animation_Timer.time_left;
		elif look_direction == 1 or look_direction == 2 or look_direction == 3:
			$Sprite_Gun.position.y = -10 * $Shoot_Animation_Timer.time_left;
			$Sprite_Gun.position.x = -10 * $Shoot_Animation_Timer.time_left;
		
	# Name tag
	var color = "blue";
	if team_id == 1:
		color = "red";
	$Label_Name.bbcode_text = "[center][color=" + color + "]" + player_name;
	last_position = position;

func set_kit(kit):
	bullet_equipped = false;
	laser_equipped = false;
	grenade_equipped = false;
	if kit == Kits.Bullet:
		bullet_equipped = true;
		current_weapon = 0;
	elif kit == Kits.Laser:
		laser_equipped = true;
		current_weapon = 1;
	elif kit == Kits.Grenade:
		grenade_equipped = true;


remote func send_start_laser(direction, player_pos, look_direction):
	if get_tree().is_network_server():# Only run if it's the server
		var clients = get_tree().get_network_connected_peers();
		for i in clients: # For each connected client
			if i != get_tree().get_rpc_sender_id(): # Don't do it for the player who sent it
				rpc_id(i, "receive_start_laser", direction, player_pos, look_direction);
		start_laser(direction, player_pos, look_direction); # Also call it locally for the server

remote func receive_start_laser(direction, player_pos, look_direction):
	start_laser(direction, player_pos, look_direction);

func start_laser(direction, start_pos, look_direction):
	$Sprite_Gun.frame = look_direction;
	$Sprite_Head.frame = look_direction;
	$Sprite_Body.frame = look_direction;
	$Sprite_Legs.frame = look_direction;
	laser_direction = direction;
	laser_position = start_pos;
	$Laser_Timer.start();
	speed = AIMING_SPEED;
	camera_ref.shake($Laser_Timer.wait_time, 1, true);
	$Laser_Charge_Audio.play();

func _laser_timer_ended():
	shoot_laser();
	speed = BASE_SPEED;

func start_laser_input():
	$Laser_Input_Timer.start();
func _laser_input_timer_ended():
	var start_pos = get_node("Bullet_Starts/" + String(look_direction)).position;
	rpc_id(1, "send_start_laser", laser_direction, start_pos, look_direction);
	start_laser(laser_direction, start_pos, look_direction);
	sprintEnabled = false;
	
var current_weapon = 0;
func switch_weapons():
	return;
	#current_weapon = 1 if current_weapon == 0 else 0;

# Called when the player attempts to place a forcefield
# This function will either place it in the appropriate spot or deny it (bad location or something)
func forcefield_placed():
	rpc("spawn_forcefield", position, team_id);
	$Forcefield_Timer.start();
	if Globals.testing:
		var forcefield = Forcefield.instance();
		forcefield.position = position;
		forcefield.team_id = team_id;
		get_tree().get_root().get_node("MainScene").add_child(forcefield);
		
# Called when the forcefield cooldown timer ends
func _forcefield_timer_ended():
	pass;

# Called by client telling everyone to spawn a forcefield in a spot
# TODO - in future this should be handled by servers - not the client.
remotesync func spawn_forcefield(pos, team_id):
	var forcefield = Forcefield.instance();
	forcefield.position = pos;
	forcefield.player_id = player_id;
	forcefield.team_id = team_id;
	get_tree().get_root().get_node("MainScene").add_child(forcefield);


# Shoots a laser shot
func shoot_laser():
	if is_network_master():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
	# Only run if we're the server
	var laser = Laser.instance();
	get_tree().get_root().get_node("MainScene").add_child(laser);
	laser.position = position + laser_position;
	laser.rotation = Vector2(0,0).angle_to_point(laser_direction) + PI/2;
	laser.direction = laser_direction;
	laser.player_id = player_id;
	laser.team_id = team_id;
	laser.z_index = z_index;
	laser.WIDTH_PMODIFIER = LASER_WIDTH_PMODIFIER;
	$Laser_Fire_Audio.play();
	$Laser_Cooldown_Timer.start();


func _draw():
	if $Laser_Timer.time_left > 0:
		var size;
		if $Laser_Input_Timer.time_left > 0:
			size = 0;
		else:
			size = clamp(1 / ($Laser_Timer.time_left / $Laser_Timer.wait_time), 0 , 3);
		var red = 1 if team_id == 1 else 0;
		var green = 10.0/255.0 if team_id == 1 else 130.0/255.0;
		var blue = 1 if team_id == 0 else 0;
		var lightener = 0.2;
		red = red + lightener;
		green = green + lightener;
		blue = blue + lightener;
		$CollisionTester.position = Vector2(0,0);
		$CollisionTester.move_and_collide(laser_direction * 1000.0)
		var length = $CollisionTester.position.distance_to(Vector2.ZERO) + 10;
		draw_line(laser_position, laser_direction * length, Color(red, green, blue, 1 - ($Laser_Timer.time_left / $Laser_Timer.wait_time)), size);
	if last_grenade_position != Vector2.ZERO:
		#draw_line(Vector2.ZERO, last_grenade_position,Color(0,0,0,1), 1.0, true);
		draw_circle(last_grenade_position, get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("grenadeRadius"), Color(0,0,0,0.2));
		draw_circle(last_grenade_position, get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("grenadeRadius")/10, Color(0,0,0,0.2));

# Shoots a bullet shot
func shoot_bullet(d):
	$Shoot_Cooldown_Timer.start();
	var direction = d.normalized();
	bullets_shot = bullets_shot + 1;
	# Re-enable the code below to have the bullet start out of the end of the gun
	var bullet_start = position + get_node("Bullet_Starts/" + String(look_direction)).position;
	# Offset bullet start by a bit because player frames are perfectly centered
	if false and direction.y == 0:
		bullet_start += Vector2(0, 10);
	if false and direction.x != 0 and direction.y != 0:
		bullet_start += Vector2(10 * direction.x/abs(direction.x),0);
	var time = OS.get_system_time_msecs() - Globals.match_start_time;
	var bullet = spawn_bullet(bullet_start, 0 if Globals.testing else player_id, direction,time, null);
	#camera_ref.shake();
	$Shoot_Animation_Timer.start();
	if !Globals.testing:
		rpc_id(1, "send_bullet", bullet_start,player_id, direction, time, bullet.name);

# Spawns a bullet given various initializaiton parameters
func spawn_bullet(pos, player_id, direction, time_shot, bullet_name = null):
	
	# Muzzle Flair
	var particles = Muzzle_Bullet.instance();
	particles.team_id = team_id;
	#get_tree().get_root().get_node("MainScene").add_child(particles);
	call_deferred("add_child", particles);
	particles.position = get_node("Bullet_Starts/" + String(look_direction)).position;
	particles.rotation = Vector2(0,0).angle_to_point(direction) + PI;
	
#	# If this was fired by another player, compensate for player lerp speed
	if !Globals.testing and player_id != Globals.localPlayerID:
		var t = Timer.new();
		t.set_wait_time(float(Globals.player_lerp_time)/float(1000.0));
		t.set_one_shot(true);
		self.add_child(t);
		t.start();
		yield(t, "timeout");
		t.queue_free();
	
	# Initialize Bullet
	var bullet = Bullet.instance();
	bullet.position = pos;
	bullet.direction = direction;
	bullet.player_id = player_id;
	bullet.team_id = team_id;
	bullet.initial_time_shot = time_shot
	bullet.set_network_master(get_network_master());
	if team_id == 0:
		bullet.get_node("Sprite").set_texture(bullet_atlas_blue);
	elif team_id == 1:
		bullet.get_node("Sprite").set_texture(bullet_atlas_red);
	get_tree().get_root().get_node("MainScene").call_deferred("add_child", bullet);
	if bullet_name != null:
		bullet.name = bullet_name;
	else:
		bullet.name = bullet.name + "-" + str(player_id) + "-" + str(bullets_shot);
	
	
	return bullet;

# A vector 2D representing the last movement key directions pressed
var last_movement_input = Vector2(0,0);

# Checks the current pressed keys and calculates a new player position using the KinematicBody2D
func move_on_inputs(teleport = false):
	var input = Vector2(0,0);
	input.x = (1 if Input.is_key_pressed(KEY_D) else 0) - (1 if Input.is_key_pressed(KEY_A) else 0)
	input.y = (1 if Input.is_key_pressed(KEY_S) else 0) - (1 if Input.is_key_pressed(KEY_W) else 0)
	input = input.normalized();
	last_movement_input = input;
	
	
	var move_speed = speed + POWERUP_SPEED;
	if($Flag_Holder.get_child_count() > 0):
		move_speed += FLAG_SLOWDOWN_SPEED;
	if sprintEnabled:
		move_speed += SPRINT_SPEED;
	if teleport:
		move_speed = TELEPORT_SPEED;
	var vec = (input * move_speed);
	
	var previous_pos = position;
	var change = move_and_slide(vec);
	var new_pos = position;
	
	if teleport:
		if Globals.testing:
			$Teleport_Audio.play();
		else:
			rpc("create_ghost_trail", previous_pos, new_pos);

func shoot_on_inputs():
	var input = Vector2(0,0);
	input.x = (1 if Input.is_key_pressed(KEY_RIGHT) else 0) - (1 if Input.is_key_pressed(KEY_LEFT) else 0)
	input.y = (1 if Input.is_key_pressed(KEY_DOWN) else 0) - (1 if Input.is_key_pressed(KEY_UP) else 0)
	input = input.normalized();
	
	if input != Vector2.ZERO:
		
		IS_CONTROLLED_BY_MOUSE = false;
		if $Flag_Holder.get_child_count() != 0:
			drop_current_flag($Flag_Holder.get_global_position());
			if !Globals.testing:
				rpc_id(1, "send_drop_flag", $Flag_Holder.get_global_position());
		elif grenade_equipped and grenade_enabled and $Grenade_Cooldown_Timer.time_left == 0:
			aim_grenade(input);
		elif current_weapon == 0 and bullet_equipped and $Shoot_Cooldown_Timer.time_left == 0:
			shoot_bullet(input);
		elif current_weapon == 1 and laser_equipped and $Laser_Cooldown_Timer.time_left == 0:
			# If we are still in input phase, update direction
			if $Laser_Input_Timer.time_left != 0:
				laser_direction = input;
				laser_position = get_node("Bullet_Starts/" + String(look_direction)).position * 20;
			elif $Laser_Timer.time_left == 0:
				start_laser_input();
	else:
		# Check for mouse input
		if Input.is_action_pressed("clickL"):
			IS_CONTROLLED_BY_MOUSE = true;
			# Only accepts clicks if we're not aiming a laser
			if $Laser_Timer.time_left == 0:
				if $Flag_Holder.get_child_count() == 0:
					if current_weapon == 0 and bullet_equipped:
						if $Shoot_Cooldown_Timer.time_left == 0:
							call_deferred("shoot_bullet", ((get_global_mouse_position() - global_position).normalized()));
					elif current_weapon == 1 and laser_equipped:
						var direction = (get_global_mouse_position() - global_position).normalized();
						laser_direction = direction;
						print(get_node("Bullet_Starts/" + String(look_direction)).position);
						print(get_node("Bullet_Starts/" + String(look_direction)).position * 20);
						laser_position = get_node("Bullet_Starts/" + String(look_direction)).position * 20;
						# If we are still in input phase, update direction
						if $Laser_Input_Timer.time_left == 0:
							start_laser_input();
					elif grenade_equipped:
						if $Grenade_Cooldown_Timer.time_left == 0:
							grenade_enabled = true;
							aim_grenade(get_local_mouse_position().normalized());
					sprintEnabled = false;
				else: # Otherwise drop our flag
					drop_current_flag($Flag_Holder.get_global_position());
					rpc_id(1, "send_drop_flag", $Flag_Holder.get_global_position());
		if Input.is_action_pressed("clickR"):
			# If were not holding a flag
			if $Flag_Holder.get_child_count() == 0:
				if grenade_equipped and $Grenade_Cooldown_Timer.time_left == 0:
					grenade_enabled = true;
					aim_grenade(get_local_mouse_position().normalized());
				sprintEnabled = false;
			else: # Otherwise drop our flag
				drop_current_flag($Flag_Holder.get_global_position());
				rpc_id(1, "send_drop_flag", $Flag_Holder.get_global_position());
		if started_aiming_grenade and !IS_CONTROLLED_BY_MOUSE:
			if Globals.testing:
				shoot_grenade(self.global_position, self.global_position + last_grenade_position, OS.get_system_time_msecs());
			else:
				rpc("shoot_grenade",self.global_position, self.global_position + last_grenade_position, OS.get_system_time_msecs() - Globals.match_start_time);
var started_aiming_grenade = false;
var last_grenade_position = Vector2(0,0);
var last_grenade_direction = Vector2(0,0);
var grenade_input_change_buffer = 0;
func aim_grenade(direction):
	if !started_aiming_grenade:
		started_aiming_grenade = true;
		$Grenade_Aiming_Timer.start();
	if !IS_CONTROLLED_BY_MOUSE:
		var x =  ($Grenade_Aiming_Timer.wait_time - $Grenade_Aiming_Timer.time_left)/$Grenade_Aiming_Timer.wait_time;
		x = clamp(x, 0.01, 1.0);
		if last_grenade_direction != direction:
			if grenade_input_change_buffer < 3:
				grenade_input_change_buffer += 1;
				return;
		last_grenade_position = direction * x * 1000;
	else:
		print(get_global_mouse_position().distance_to(position));
		if get_local_mouse_position().length() <= 1000:
			last_grenade_position = get_local_mouse_position();
		else:
			last_grenade_position = direction * 1000;
	last_grenade_direction = direction;
	grenade_input_change_buffer = 0;
	

remotesync func shoot_grenade(from_pos, to_pos, time_shot):
	started_aiming_grenade = false;
	grenade_enabled = false;
	$Grenade_Cooldown_Timer.start();
	var node = Grenade.instance();
	node.initial_real_pos = from_pos;
	node.target_pos = to_pos;
	node.initial_time_shot = time_shot;
	node.player_id = player_id;
	node.team_id = team_id;
	get_tree().get_root().get_node("MainScene").call_deferred("add_child", node);
	last_grenade_position = Vector2(0,0);
	
func toggle_grenade():
	started_aiming_grenade = false;
	grenade_enabled = !grenade_enabled;
	last_grenade_position = Vector2(0,0);

func enable_powerup(type):
	var text = "";
	if type == 1:
		POWERUP_SPEED = 50;
		$Powerup_Timer.wait_time = 10;
		text = "[color=green]^^ SPEED UP ^^";
	elif type == 2:
		DASH_COOLDOWN_PMODIFIER = -0.5;
		$Powerup_Timer.wait_time = 6;
		text = "[color=blue]˅˅˅˅˅˅^^ DASH RATE UP ^^";
	elif type == 3:
		BULLET_COOLDOWN_PMODIFIER = -0.1;
		$Powerup_Timer.wait_time = 8;
		text = "[color=red]^^ BULLET FIRE RATE UP ^^";
	elif type == 4:
		LASER_WIDTH_PMODIFIER = 15;
		$Powerup_Timer.wait_time = 6;
		text = "[color=#FF8C00]^^ LASER WIDTH UP ^^";
	elif type == 5:
		FORCEFIELD_COOLDOWN_PMODIFIER = -1.5;
		$Powerup_Timer.wait_time = 10;
		text = "[color=purple]^^ FORCEFIELD RATE UP ^^";
	
	
	# Only display message if this is our local player
	if Globals.testing or player_id == Globals.localPlayerID:
		get_tree().get_root().get_node("MainScene/UI_Layer").set_alert_text("[center]" + text);
	$Powerup_Timer.start();

func _powerup_timer_ended():
	POWERUP_SPEED = 0;
	DASH_COOLDOWN_PMODIFIER = 0;
	BULLET_COOLDOWN_PMODIFIER = 0;
	FORCEFIELD_COOLDOWN_PMODIFIER = 0;
	LASER_WIDTH_PMODIFIER = 0;

remotesync func create_ghost_trail(start, end):
	$Teleport_Audio.play();
	for i in range(6):
		var node = Ghost_Trail.instance();
		get_tree().get_root().get_node("MainScene").add_child(node);
		node.position = start;
		node.position.x = node.position.x + ((i) * (end.x - start.x)/4)
		node.position.y = node.position.y + ((i) * (end.y - start.y)/4)
		node.look_direction = look_direction;
		node.sprite_scale = $Sprite_Body.scale
		node.legs_frame = $Sprite_Legs.frame;
		node.get_node("Death_Timer").start((i) * 0.05 + 0.0001);
		node.get_node("Sprite_Gun").texture = $Sprite_Top.texture
		node.get_node("Sprite_Head").texture = $Sprite_Bottom.texture
		node.get_node("Sprite_Body").texture = $Sprite_Top.texture
		node.get_node("Sprite_Legs").texture = $Sprite_Bottom.texture
	# If this is a puppet, use this ghost trail as an oppurtunity to also update its position
	if !is_network_master():
		lerp_start_pos = end;
		lerp_end_pos = end;
		position = end;
	
# Changes the sprite's frame to make it "look" at the mouse
var previous_look_input = Vector2(0,0);
func update_look_direction():
	var pos;
	if IS_CONTROLLED_BY_MOUSE:
		pos = get_global_mouse_position();
	else:
		var input = Vector2(0,0);
		input.x = (1 if Input.is_key_pressed(KEY_RIGHT) else 0) - (1 if Input.is_key_pressed(KEY_LEFT) else 0)
		input.y = (1 if Input.is_key_pressed(KEY_DOWN) else 0) - (1 if Input.is_key_pressed(KEY_UP) else 0)
		input = input.normalized();
		if input == Vector2(0,0):
			input.x = (1 if Input.is_key_pressed(KEY_D) else 0) - (1 if Input.is_key_pressed(KEY_A) else 0)
			input.y = (1 if Input.is_key_pressed(KEY_S) else 0) - (1 if Input.is_key_pressed(KEY_W) else 0)
			input = input.normalized();
			if input == Vector2(0,0):
				input = previous_look_input;
		previous_look_input = input;
		pos = position + (input * 100) + Vector2(1,1); # Add 1,1 to prevent 0 edge cases
	var dist = pos - position;
	var angle = get_vector_angle(dist);
	var adjustedAngle = -1 * (angle + (PI/8));
	var octant = (adjustedAngle / (2 * PI)) * 8
	var dir = int((octant + 9) + 4) % 8;
	if dir != look_direction: # If it changed since last time
		set_look_direction(dir);
		if !Globals.testing:
			rpc_unreliable_id(1, "send_look_direction", dir, player_id);


# Gets the angle that a vector is making
func get_vector_angle(dist):
	var angle = (-(PI / 2) if dist.y < 0 else ( 3 * PI / 2)) if dist.x == 0 else atan(dist.y / dist.x);
	angle = angle * -1;
	angle += PI/2;
	if dist.x < 0:
		angle += PI;
	return angle;

# Set the direction that the player is "looking" at by changing sprite frame
func set_look_direction(dir):
	look_direction = dir;
	$Sprite_Head.frame = dir;
	$Sprite_Gun.frame = dir;
	$Sprite_Body.frame = dir;
	$Sprite_Legs.frame = look_direction + (int((1-($Leg_Animation_Timer.time_left / $Leg_Animation_Timer.wait_time)) * 4)%4) * $Sprite_Legs.hframes;
	if dir == 2 or dir == 3:
		$Sprite_Head.z_index =1;
		$Sprite_Body.z_index =0;
		$Sprite_Gun.z_index =2;
	else:
		$Sprite_Head.z_index =2;
		$Sprite_Body.z_index =0;
		$Sprite_Gun.z_index =1;
	

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
	if camera_ref:
		camera_ref.current = true;

# De-activates the camera on this player
func deactivate_camera():
	if camera_ref:
		camera_ref.current = false;

# Called when this player is hit by a projectile
func hit_by_projectile(attacker_id, projectile_type):
	if projectile_type == 0 || projectile_type == 1 || projectile_type == 2: # Bullet or Laser
		die();
		var attacker_team_id = get_tree().get_root().get_node("MainScene/NetworkController").players[attacker_id]["team_id"]
		var attacker_name = get_tree().get_root().get_node("MainScene/NetworkController").players[attacker_id]["name"]
		if attacker_id == Globals.localPlayerID:
			var color = "blue"
			if team_id == 1:
				color = "red";
			get_tree().get_root().get_node("MainScene/UI_Layer").set_alert_text("[center][color=black]KILLED [color=" + color +"]" + player_name);
		if is_network_master():
			get_tree().get_root().get_node("MainScene/UI_Layer").set_big_label_text("KILLED BY\n" + str(attacker_name), attacker_team_id);
			camera_ref.get_parent().remove_child(camera_ref);
			get_tree().get_root().get_node("MainScene/Players/P" + str(attacker_id) + "/Center_Pivot").add_child(camera_ref);
		

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
	var node = Player_Death.instance();
	node.position = position;
	node.xFrame = look_direction;
	node.z_index = z_index;
	get_tree().get_root().get_node("MainScene").add_child(node);

# Called by the respawn timer when it ends
func _respawn_timer_ended():
	rpc("receive_respawn");

# Respawns the player at their team's start location
func respawn():
	visible = true;
	alive = true;
	position = start_pos;
	if is_network_master() and get_tree().get_root().get_node("MainScene/NetworkController").round_is_running:
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
	if Globals.testing or is_network_master():
		get_tree().get_root().get_node("MainScene").speedup_music();
	$Flag_Pickup_Audio.play();
	var flag_team_id;
	for flag in get_tree().get_nodes_in_group("Flags"):
		if flag.flag_id == flag_id:
			flag.re_parent($Flag_Holder);
			flag.is_at_home = false;
			flag.position = Vector2(0,0);
			flag_team_id = flag.team_id;
	sprintEnabled = false;
	var subject = player_name;
	var subjectColor = "blue"
	var color = "red";
	var teamNoun = "RED TEAM";
	if team_id == 1:
		subjectColor = "red";
		color = "blue";
		teamNoun = "BLUE TEAM";
	if player_id == Globals.localPlayerID:
		subject = "You";
	if !get_tree().is_network_server():
		if get_tree().get_root().get_node("MainScene/NetworkController").players[Globals.localPlayerID]["team_id"] == flag_team_id:
			teamNoun = "YOUR TEAM";
		get_tree().get_root().get_node("MainScene/UI_Layer").set_alert_text("[center][color=" + subjectColor + "]" + subject + "[color=black] took " + "[color=" + color + "]" + teamNoun + "'s[color=black] flag!");
	

# Drops the currently held flag (If there is one)
func drop_current_flag(flag_position = $Flag_Holder.get_global_position()):
	# Only run if there is a flag in the Flag_Holder
	if $Flag_Holder.get_child_count() > 0:
		if Globals.testing or is_network_master():
			get_tree().get_root().get_node("MainScene").slowdown_music();
		$Flag_Drop_Audio.play();
		# Just get the first flag because there should only ever be one
		var flag = $Flag_Holder.get_children()[0];
		flag.get_node("Area2D").player_id_drop_buffer = player_id;
		flag.get_node("Area2D").ignore_next_buffer_reset = true;
		flag.re_parent(get_tree().get_root().get_node("MainScene"));
		flag.position = flag_position;
		$Shoot_Cooldown_Timer.start();
		$Laser_Cooldown_Timer.start();

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
		get_tree().get_root().get_node("MainScene/NetworkController").players[player_id]["position"] = position;
		var clients = get_tree().get_network_connected_peers();
		for i in clients: # For each connected client
			if i != get_tree().get_rpc_sender_id(): # Don't do it for the player who sent it
				rpc_unreliable_id(i, "receive_position", new_pos);
		update_position(new_pos); # Also call it locally for the server

# "Receives" the position of this player from the server
remote func receive_position(new_pos):
	update_position(new_pos);

# Client tells the server that it just shot a bullet
remote func send_bullet(pos, player_id, direction, time_shot, bullet_name):
	if get_tree().is_network_server(): # Only run if it's the server
		var clients = get_tree().get_network_connected_peers();
		for i in clients: # For each connected client
			if i != get_tree().get_rpc_sender_id(): # Don't do it for the player who sent it
				rpc_id(i, "receive_bullet", pos, player_id, direction,time_shot, bullet_name);
		spawn_bullet(pos, player_id, direction,time_shot, bullet_name); # Also call it locally for the server

# "Receives" a bullet from the server that was shot by another client
remote func receive_bullet(pos, player_id, direction,time_shot, bullet_name):
	spawn_bullet(pos, player_id, direction,time_shot, bullet_name);

# Client tells the server what direction frame it's looking at 
remote func send_look_direction(frame, player_id):
	if get_tree().is_network_server(): # Only run if it's the server
		var clients = get_tree().get_network_connected_peers();
		for i in clients: # For each connected client
			if i != get_tree().get_rpc_sender_id(): # Don't do it for the player who sent it
				rpc_id(i, "receive_look_direction", frame);
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
		var clients = get_tree().get_network_connected_peers();
		for i in clients: # For each connected client
			if i != get_tree().get_rpc_sender_id(): # Don't do it for the player who sent it
				rpc_id(i, "receive_drop_flag", flag_position);
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
	modulate = Color(1,1,1,1);
