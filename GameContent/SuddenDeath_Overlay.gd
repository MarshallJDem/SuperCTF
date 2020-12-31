extends Control


# Declare member variables here. Examples:
# var a: int = 2
# var b: String = "text"

enum {WALK_IN, WALK_OUT};
var phase = -1;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Starting values
	$Title.percent_visible = 0.0;
	$Subtitle.percent_visible = 0.0
	$Blue_Flag.modulate = Color(0,0,0,0);
	$Player.anchor_left = -0.1;
	$"Blue_Flag/x-symbol".visible = false;
	
	$Animation_Timer.connect("timeout", self, "_animation_timer_ended");
	

	
	yield(get_tree().create_timer(1), "timeout");
	$Title.percent_visible = 0.5;
	yield(get_tree().create_timer(0.70), "timeout");
	$Title.percent_visible = 1.0;
	yield(get_tree().create_timer(1), "timeout");
	
	$Subtitle.percent_visible = 1.0
	yield(get_tree().create_timer(1), "timeout");
	
	
	$Animation_Timer.wait_time = 4;
	phase = WALK_IN;
	$Animation_Timer.start();
	
	$Blue_Flag.modulate = Color(1,1,1,1);
	yield(get_tree().create_timer(2), "timeout");
	$Blue_Flag.modulate = Color(1,1,1,0.4);
	yield(get_tree().create_timer(0.5), "timeout");
	var i = 0.4
	while(i < 1.0):
		yield(get_tree().create_timer(0.05), "timeout");
		i += 0.05;
		$Blue_Flag.modulate = Color(1,1,1,i);
	yield(get_tree().create_timer(1), "timeout");
	return;
	i = 0.9
	while(i > 0):
		yield(get_tree().create_timer(0.05), "timeout");
		i -= 0.05;
		self.modulate = Color(1,1,1,i);
	call_deferred("queue_free");


func _animation_timer_ended():
	return;


func _physics_process(delta: float) -> void:
	$Player._update_look_direction(2);
	$Player._update_animation(Vector2(10,0))
	var progress = 1.0 - ($Animation_Timer.time_left / $Animation_Timer.wait_time);

	$Player.anchor_left = lerp(-0.1, 1.1, progress);
