extends Node2D

var total_time = 0;
var frame_order = [0, 1, 2, 3, 4];
var animation_duration = 0.5;
var direction = Vector2(0,0);
var speed = 750;
var player_id;
var team_id;
var show_death_particles = true;

func _ready():
	$Death_Timer.connect("timeout", self, "_death_timer_ended");
	rotation = Vector2(0,0).angle_to_point(direction) + PI;

func _process(delta):
	total_time = total_time + delta;
	animate_frames();
	move(delta);

# Given an amount of delta time, moves the bullet in its trajectory direction using its speed
func move(delta):
	position = position + (direction * speed * delta);

# Determines and sets a new animation frame for the bullet based on game time
func animate_frames():
	var frame = fmod(total_time, animation_duration);
	frame = frame / animation_duration;
	frame = int(frame * frame_order.size());
	$Sprite.frame = frame_order[frame];

# Called by server to terminate this bullet early
remotesync func receive_death():
	die();

func die():
	#Only show particles if we havn't already done so from a preliminary death
	if show_death_particles:
		spawn_death_particles();
	get_parent().remove_child(self);
	self.queue_free();

# Called when the death timer finishes
# NOTE- we can trust each client to handle it's own bullet deaths because the server detects collisions anyways
func _death_timer_ended():
	die();

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