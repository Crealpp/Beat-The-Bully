extends CharacterBody2D


const SPEED = 300.0
var  movimiento = PlayerInput
const SKIN_FRAMES := {
	"idle (1)": preload("res://assets/images/sprites/idle.tres"),
	"idle pj2": preload("res://assets/images/sprites/idlepj2.tres")
}

func _ready() -> void:
	add_to_group("player")
	set_skin(Gamemanager.selectedskin)



func _physics_process(delta) -> void :
	var direction = Vector2.ZERO
	direction.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	direction.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	velocity = direction.normalized() * SPEED	
	move_and_slide()
	print(direction)
	print(position)
	
func set_skin(skinname): 
	if SKIN_FRAMES.has(skinname):
		$Animated.sprite_frames = SKIN_FRAMES[skinname]
	$Animated.play("Idle")
	
