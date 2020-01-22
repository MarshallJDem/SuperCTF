extends Node2D

var direction = Vector2(0,0);
var speed = 875;
var player_id;
var team_id;
var show_death_particles = true;

func _ready():
	$Death_Timer2.connect("timeout", self, "_death_timer_ended");
	$Animation_Timer.connect("timeout", self, "_animation_timer_ended");
	rotation = Vector2(0,0).angle_to_point(direction) + PI;

func _process(delta):
	move(delta);
	self.z_index = self.position.y;

# stupid workaround neccessary to make particles not flash random colors upon spawning
func _physics_process(delta):
	if should_die:
		die();
	
# Given an amount of delta time, moves the bullet in its trajectory direction using its speed
func move(delta):
	position = position + (direction * speed * delta);
	
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
