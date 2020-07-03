extends Node2D

var bullet_atlas_blue = preload("res://Assets/Weapons/bullet_b.png");
var bullet_atlas_red = preload("res://Assets/Weapons/bullet_r.png");

var demo_atlas_blue = preload("res://Assets/Weapons/bullet_b.png");
var demo_atlas_red = preload("res://Assets/Weapons/bullet_r.png");

var Muzzle_Bullet = preload("res://GameContent/Muzzle_Bullet.tscn");
var Bullet = preload("res://GameContent/Bullet.tscn");
var Demo = preload("res://GameContent/Demo.tscn");
var Laser = preload("res://GameContent/Laser.tscn");

var reduced_cooldown_enabled = false;
const AIMING_SPEED = 15;

var player;

# The direction the laser is firing at
var laser_direction = Vector2(0,0);
# The position the laser is firing from
var laser_position = Vector2(0,0);
var laser_target_position = null;
# The number of bullets this player has shot. Used for naming bullets
var bullets_shot = 0;
# The number of demos this player has shot. Used for naming demos
var demos_shot = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Globals.connect("class_changed", self, "class_changed");
	
	player = get_parent();
	
	if Globals.testing or Globals.localPlayerID == player.player_id:
		$Laser_Timer.wait_time += 0.1;
		$Laser_Charge_Audio.set_pitch_scale(float(0.5)/$Laser_Timer.wait_time);
	else:
		$Laser_Charge_Audio.set_volume_db(-10);
		$Laser_Fire_Audio.set_volume_db(-10);
	
	$Laser_Timer.connect("timeout", self, "_laser_timer_ended");
	$Laser_Input_Timer.connect("timeout", self, "_laser_input_timer_ended");

func class_changed():
	pass;

func update_cooldown_lengths():
	if Globals.current_class == Globals.Classes.Bullet:
		$Cooldown_Timer.wait_time = float(get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("bulletCooldown"))/1000.0;
	elif Globals.current_class == Globals.Classes.Laser:
		$Cooldown_Timer.wait_time = float(get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("laserCooldown"))/1000.0;
	elif Globals.current_class == Globals.Classes.Demo:
		$Cooldown_Timer.wait_time = 750.0/1000.0;
	if reduced_cooldown_enabled:
		$Cooldown_Timer.wait_time = $Cooldown_Timer.wait_time / 2.0;
	$Laser_Timer.wait_time = float(get_tree().get_root().get_node("MainScene/NetworkController").get_game_var("laserChargeTime"))/1000.0;

func _process(delta):
	
	if !player.alive:
		$Cooldown_Timer.stop();
		$Laser_Timer.stop();
		$Shoot_Animation_Timer.stop();
		$Laser_Input_Timer.stop();
		
	update_cooldown_lengths();
	
	# Shooting on inputs
	if player.control:
		if $Laser_Timer.time_left + $Laser_Input_Timer.time_left > 0:
			player.speed = AIMING_SPEED * ($Laser_Timer.time_left / $Laser_Timer.wait_time);
		# Move & Shoot around as long as we aren't typing in chat
		if !Globals.is_typing_in_chat:
			shoot_on_inputs();
	
	# Gun Animation
	var sprite_gun = player.get_node("Sprite_Gun");
	sprite_gun.position.y = int(2 * sin((PI * 0.25) + (1 - player.get_node("Top_Animation_Timer").time_left/player.get_node("Top_Animation_Timer").wait_time)*(2 * PI)))/2.0;
	sprite_gun.position.x = 0;
	# Shooting Animation (Overrides idleness)
	if $Shoot_Animation_Timer.time_left > 0:
		if player.look_direction == 0:
			sprite_gun.position.y = 20 * $Shoot_Animation_Timer.time_left;
		elif player.look_direction == 1:
			sprite_gun.position.y = +20 * $Shoot_Animation_Timer.time_left;
			sprite_gun.position.x = -20 * $Shoot_Animation_Timer.time_left;
		elif player.look_direction == 2 or player.look_direction == 3:
			sprite_gun.position.y = -20 * $Shoot_Animation_Timer.time_left;
			sprite_gun.position.x = -20 * $Shoot_Animation_Timer.time_left;
		elif player.look_direction == 4:
			sprite_gun.position.y = -20 * $Shoot_Animation_Timer.time_left;
		elif player.look_direction == 5 or player.look_direction == 6:
			sprite_gun.position.y = -20 * $Shoot_Animation_Timer.time_left;
			sprite_gun.position.x = 20 * $Shoot_Animation_Timer.time_left;
		elif player.look_direction == 7:
			sprite_gun.position.y = +20 * $Shoot_Animation_Timer.time_left;
			sprite_gun.position.x = 20 * $Shoot_Animation_Timer.time_left;
	
	update();



func _draw():
	if $Laser_Timer.time_left > 0:
		var size;
		if $Laser_Input_Timer.time_left > 0:
			size = 0;
		else:
			size = clamp(1 / ($Laser_Timer.time_left / $Laser_Timer.wait_time), 0 , 3);
		var red = 1 if player.team_id == 1 else 0;
		var green = 10.0/255.0 if player.team_id == 1 else 130.0/255.0;
		var blue = 1 if player.team_id == 0 else 0;
		var lightener = 0.2;
		red = red + lightener;
		green = green + lightener;
		blue = blue + lightener;
		var target_position = laser_target_position;
		if laser_target_position == null:
			$CollisionTester.position = Vector2(0,0);
			$CollisionTester.move_and_collide(laser_direction * 1000.0)
			var length = $CollisionTester.position.distance_to(Vector2.ZERO) + 10;
			laser_target_position = laser_direction * length;
			target_position = laser_direction * length;
		var progress = 1 - ($Laser_Timer.time_left / $Laser_Timer.wait_time);
		draw_line(laser_position, target_position, Color(red, green, blue, progress), size);
		draw_circle(laser_position, size + 3, Color(red,green,blue,(sin((progress) * 2 * PI * 25 * (0.1 * (1.0+progress) ) )+1)/2.0));
		draw_circle(laser_position, size + 0.5, Color(red + 0.1,green + 0.1,blue + 0.1,progress));
		draw_circle(target_position, size + 3, Color(red,green,blue,(sin((progress) * 2 * PI * 25 * (0.1 * (1.0+progress) ) )+1)/2.0));
		draw_circle(target_position, size + 0.5, Color(red + 0.1,green + 0.1,blue + 0.1,progress));


func shoot_on_inputs():
	if Globals.is_typing_in_chat or Globals.displaying_loadout:
		return;
	# Check for mouse input
	if Input.is_action_pressed("clickL"):
		# Only accepts clicks if we're not aiming a laser
		if $Laser_Timer.time_left == 0:
			if !player.attempt_drop_flag():
				if Globals.current_class == Globals.Classes.Bullet:
					if $Cooldown_Timer.time_left == 0:
						call_deferred("shoot_bullet", ((get_global_mouse_position() - global_position).normalized()));
				elif Globals.current_class == Globals.Classes.Laser:
					var direction = (get_global_mouse_position() - player.position).normalized();
					laser_direction = direction;
					laser_position = player.position + get_node("Laser_Starts/" + String(player.look_direction)).position * 20;
					# If we are still in input phase, update direction
					if $Laser_Input_Timer.time_left == 0:
						start_laser_input();
				elif Globals.current_class == Globals.Classes.Demo:
					if $Cooldown_Timer.time_left == 0:
						if !Globals.testing:
							rpc("shoot_demo", ((get_global_mouse_position() - global_position).normalized()),demos_shot);
						else:
							shoot_demo(((get_global_mouse_position() - global_position).normalized()),demos_shot);

remotesync func shoot_demo(d, shots):
	$Cooldown_Timer.start();
	$Shoot_Animation_Timer.start();
	var direction = d.normalized();
	var start_pos = player.position + get_node("Bullet_Starts/" + String(player.look_direction)).position;
	
	$CollisionTester.position = Vector2(0,8.5);
	var collision = $CollisionTester.move_and_collide(direction * 25.0)
	var collision_tester_length = $CollisionTester.position.distance_to(Vector2(0,8.5));
	
	# If we are too close to a wall shoot a pre reflected shot
	if(collision_tester_length < 10 and collision):
		# Reflect Demo
		var reflection_dir = (direction - (2 * direction.dot(collision.normal) * collision.normal)).normalized();
		$CollisionTester.move_and_collide(reflection_dir * 2.0)
		direction = reflection_dir.normalized();
		start_pos = player.position + $CollisionTester.position;
	
	
	# Initialize Bullet
	var node = Demo.instance();
	node.original_time_shot = OS.get_system_time_msecs() - Globals.match_start_time;
	node.position = start_pos;
	node.direction = direction;
	node.team_id = player.team_id;
	node.player_id = player.player_id;
	node.name = node.name + "-" + str(player.player_id) + "-" + str(shots);
	node.get_node("Sprite").set_texture(demo_atlas_red if player.team_id == 1 else demo_atlas_blue);
	demos_shot = shots + 1;
	node.set_network_master(player.get_network_master());
	get_tree().get_root().get_node("MainScene").call_deferred("add_child", node);

# Shoots a bullet shot
func shoot_bullet(d):
	$Cooldown_Timer.start();
	var direction = d.normalized();
	
	$CollisionTester.position = Vector2(0,5.5);
	$CollisionTester.move_and_collide(direction * 25.0)
	var collision_tester_length = $CollisionTester.position.distance_to(Vector2(0,5.5));
	
	bullets_shot = bullets_shot + 1;
	# Re-enable the code below to have the bullet start out of the end of the gun
	var bullet_start = player.position + get_node("Bullet_Starts/" + String(player.look_direction)).position;
	var time = OS.get_system_time_msecs() - Globals.match_start_time;
	var bullet_name = "Bullet"+ "-" + str(player.player_id) + "-" + str(bullets_shot);
	#camera_ref.shake();
	$Shoot_Animation_Timer.start();
	
	# If we are too close to a wall, shoot a blank
	if(collision_tester_length < 10):
		spawn_bullet(bullet_start, 0 if Globals.testing else player.player_id, direction, time, bullet_name, true);
	else:
		if !Globals.testing:
			rpc("spawn_bullet", bullet_start, player.player_id, direction,time, bullet_name);
		else:
			spawn_bullet(bullet_start, 0, direction,time, bullet_name);
# Spawns a bullet given various initializaiton parameters
remotesync func spawn_bullet(pos, player_id, direction, time_shot, bullet_name, is_blank = false):
	
	# Muzzle Flair
	var particles = Muzzle_Bullet.instance();
	particles.team_id = player.team_id;
	#get_tree().get_root().get_node("MainScene").add_child(particles);
	call_deferred("add_child", particles);
	particles.position = get_node("Bullet_Starts/" + String(player.look_direction)).position;
	particles.rotation = Vector2(0,0).angle_to_point(direction) + PI;
	
#	# If this was fired by another player, compensate for player lerp speed
	if false and !Globals.testing and player_id != Globals.localPlayerID:
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
	bullet.team_id = player.team_id;
	bullet.original_time_shot = time_shot
	bullet.name = bullet_name;
	bullet.is_blank = is_blank;
	bullet.set_network_master(get_network_master());
	if player.team_id == 0:
		bullet.get_node("Sprite").set_texture(bullet_atlas_blue);
	elif player.team_id == 1:
		bullet.get_node("Sprite").set_texture(bullet_atlas_red);
	get_tree().get_root().get_node("MainScene").call_deferred("add_child", bullet);
	return bullet;

remote func send_start_laser(direction, start_pos, target_pos, look_direction):
	if get_tree().is_network_server():# Only run if it's the server
		var clients = get_tree().get_network_connected_peers();
		for i in clients: # For each connected client
			if i != get_tree().get_rpc_sender_id(): # Don't do it for the player who sent it
				rpc_id(i, "receive_start_laser", direction, start_pos,target_pos, look_direction);
		start_laser(direction, start_pos,target_pos, look_direction); # Also call it locally for the server

remote func receive_start_laser(direction, start_pos, target_pos, look_direction):
	start_laser(direction, start_pos,target_pos, look_direction);

func start_laser(direction, start_pos, target_pos, look_direction):
	player.get_node("Sprite_Gun").frame = look_direction;
	player.get_node("Sprite_Head").frame = look_direction;
	player.get_node("Sprite_Body").frame = look_direction;
	player.get_node("Sprite_Legs").frame = look_direction;
	#$CollisionTester.position = target_pos;
	laser_direction = direction;
	laser_position = start_pos;
	laser_target_position = target_pos;
	$Laser_Timer.start();
	player.speed = AIMING_SPEED;
	player.camera_ref.shake($Laser_Timer.wait_time, 0.5, true);
	$Laser_Charge_Audio.play();
	var red = 1 if player.team_id == 1 else 0;
	var green = 10.0/255.0 if player.team_id == 1 else 130.0/255.0;
	var blue = 1 if player.team_id == 0 else 0;
	var lightener = 0.2;
	red = red + lightener;
	green = green + lightener;
	blue = blue + lightener;
	$Laser_Particles.color = Color(red, green, blue);
	$Laser_Particles.restart();
	#$Laser_Particles.emitting = true;
	$Laser_Particles.position = start_pos;

func _laser_timer_ended():
	shoot_laser();
	player.speed = player.BASE_SPEED;

func start_laser_input():
	laser_target_position = null;
	$Laser_Input_Timer.start();
func _laser_input_timer_ended():
	var start_pos = get_node("Laser_Starts/" + String(player.look_direction)).position;
	$CollisionTester.position = Vector2(0,0);
	$CollisionTester.move_and_collide(laser_direction * 1000.0)
	var length = $CollisionTester.position.distance_to(Vector2.ZERO) + 10;
	laser_target_position = laser_direction * length;
	var target_pos = laser_target_position;
	rpc_id(1, "send_start_laser", laser_direction, start_pos,target_pos, player.look_direction);
	start_laser(laser_direction, start_pos,target_pos, player.look_direction);

# Shoots a laser shot
func shoot_laser():
	$Shoot_Animation_Timer.start();
	if is_network_master():
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
	var laser = Laser.instance();
	laser.position =  player.position + laser_position;
	laser.target_pos = player.position + laser_target_position;
	laser.player_id = player.player_id;
	laser.team_id = player.team_id;
	laser.z_index = player.z_index + 4;
	get_tree().get_root().get_node("MainScene").add_child(laser);
	$Laser_Fire_Audio.play();
	$Cooldown_Timer.start();
