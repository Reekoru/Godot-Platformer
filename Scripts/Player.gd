extends KinematicBody2D

# Constants
const UP = Vector2(0, -1)
const GRAVITY = 20
const MAX_FALLSPEED = 200
const MAX_MOVESPEED = 100
const JUMPFORCE = 275
const ACCELERATION = 20
const DASHSPEED = 250

var motion = Vector2()
var direction = Vector2()
var facing_direction = 1 # 1 = right -1 = left
var can_dash = true
var wall_jump_time = 7
var wall_jump_timer = wall_jump_time

#Camera Variables
var cam_follow_player = false
var area_collision_shape
var area_size

onready var dash_timer = get_node("DashTimer")
onready var collision_ray = get_node("CollisionRay")
onready var tween = get_node("Tween")

# States
enum {
	IDLE
	FREE 
	DASH
	ON_WALL
	WALL_JUMP
	}
var state: int = FREE

func _ready():
	pass # Replace with function body.

# warning-ignore:unused_argument
func _physics_process(delta):
	$Sprite.visible = true
	# Flip ray to player's direction
	var ray_length = 9
	collision_ray.cast_to.x = facing_direction* ray_length
		# Dash
	if(Input.is_action_just_pressed("dash") && can_dash):
		motion.x = 0 # Stop player for dash
		motion.y = 0
		dash_timer.start()
		change_state(DASH)
	# Move player with collision
	motion = move_and_slide(motion, UP)
	# Get player input direction
	if(Input.is_action_pressed("right")):
		direction.x = 1
		$Sprite.scale.x = 1 
	elif(Input.is_action_pressed("left")):
		direction.x = -1
		$Sprite.scale.x = -1
	else:
		direction.x = 0
	if(Input.is_action_pressed("up")):
		direction.y = -1
	elif(Input.is_action_pressed("down")):
		direction.y = 1
	else:
		direction.y = 0
	match state:
	# Free State (Movement)
		FREE:
			motion.y += GRAVITY

			if(motion.y > MAX_FALLSPEED):
				motion.y = MAX_FALLSPEED

			motion.x = clamp(motion.x, -MAX_MOVESPEED, MAX_MOVESPEED)
							
			if(Input.is_action_pressed("right") || Input.is_action_pressed("left")):
				if($AnimationPlayer.current_animation != "Jump" || $AnimationPlayer.current_animation != "Falling"):
					$AnimationPlayer.play("Run")
				facing_direction = direction.x
				motion.x += ACCELERATION * direction.x
			else:
				$AnimationPlayer.play("Idle")
				if(is_on_floor()):
					motion.x = lerp(motion.x, 0, 0.4)	# Deceleration on floor
				else:
					motion.x = lerp(motion.x, 0, 0.05)	# Deceleration of air
				
			
			# Jump
			if(is_on_floor()):
				can_dash = true
				if(Input.is_action_just_pressed("jump")):
					motion.y = -JUMPFORCE
			else:
				if(motion.y < 0):
					$AnimationPlayer.play("Jump")
				elif(motion.y > 0):
					$AnimationPlayer.play("Falling")
			# Varaible Jump Height
			if(!Input.is_action_pressed("jump") && motion.y < 0):
# warning-ignore:integer_division
				motion.y = max(motion.y, -JUMPFORCE/2)
				
			"""if(collision_ray.is_colliding() && !is_on_floor() && motion.y > 0 && direction.x != 0):
				motion.y = motion.y/2
				change_state(ON_WALL)""" # Might remove wall mechanic
		# Dash State
		DASH:
			$Sprite.visible = false
			"""var orb_motion = Vector2()
			if(Input.is_action_pressed("up")):
				orb_motion.y = -DASHSPEED
			elif(Input.is_action_pressed("down")):
				orb_motion.y = DASHSPEED
			
			if(Input.is_action_pressed("right")):
				orb_motion.x = DASHSPEED
			elif(Input.is_action_pressed("left")):
				orb_motion.x = -DASHSPEED
			
			if(Input.is_action_just_pressed("jump")):
				motion.y = -JUMPFORCE
				can_dash = false
				change_state(FREE)
			motion = lerp(motion, orb_motion, 0.035 )"""	# Orb lfying mechanic code
			
			if(direction.y != 0 && can_dash):
				motion.y = DASHSPEED * direction.y
			if(direction.x != 0 && can_dash):
				motion.x = DASHSPEED * direction.x
			if(direction.x == 0 && direction. y == 0):
				motion.x = DASHSPEED * facing_direction
			can_dash = false
			motion = motion.normalized() * DASHSPEED	# Normalize Vector
		# On Wall State
		ON_WALL:
			$Sprite.scale.x = -facing_direction # Only for this sprite because climbing is flipped
				
			# Wall Grab
			if(Input.is_action_pressed("grab")):
				motion.y = 0
				if(direction.y != 0):
# warning-ignore:integer_division
					motion.y *= -JUMPFORCE/4
				if(direction.y < 0):
					$AnimationPlayer.play("Climbing")
					motion.y = direction.y * MAX_MOVESPEED / 4
				elif(direction.y > 0):
					$AnimationPlayer.play_backwards("Climbing")
					motion.y = direction.y * MAX_MOVESPEED / 4
				else:
					$AnimationPlayer.play("On_Wall_Idle")
			else:
				$AnimationPlayer.play("On_Wall_Idle")
# warning-ignore:integer_division
				motion.y += GRAVITY/8
			if(Input.is_action_just_pressed("jump") && Input.is_action_pressed("grab")):
# warning-ignore:integer_division
				motion.y = -JUMPFORCE/2
				if(direction.x == -facing_direction):
					motion.x = -facing_direction * MAX_MOVESPEED*2
					change_state(WALL_JUMP)
				else:
					change_state(FREE)
			if(!Input.is_action_pressed("grab") && direction.x != facing_direction):
				change_state(FREE)
			if(!collision_ray.is_colliding() || is_on_floor()):
				change_state(FREE)
				
		WALL_JUMP:
			wall_jump_timer -= 1
			if(wall_jump_timer < 0):
				wall_jump_timer = wall_jump_time
				change_state(FREE)
	update() # Calls  the draw function
# warning-ignore:unused_variable
	var cam = get_node("../Anchor")
# Changes stat

func _draw():
	if(state == DASH):
		draw_circle(Vector2(0,0), 6, Color(255, 255 ,255))
func change_state(target_state: int):
	state = target_state


func DashTimer_Timeout():
	can_dash = false
	change_state(FREE)

func _on_RoomDetector_area_entered(area):
	area_collision_shape = area.get_node("CollisionShape2D")
	area_size = area_collision_shape.shape.extents * 2
	var room_transition_timer = get_node("RoomTransTimer")	
	var camera_target_position = area.get_node("Position2D")
	var camera_anchor = get_node("../Anchor")
	var cam = get_node("../Anchor/Camera2D")
	var view_size = get_viewport().size
	# Remove Limits of Camera
	cam.limit_bottom = 10000
	cam.limit_right = 10000
	cam.limit_left = -10000
	cam.limit_top= -10000
	
	# Pause player
	room_transition_timer.start()
	set_physics_process(false)
	# Check if room is bigger than viewport
	if(area_size.x > view_size.x || area_size.y > view_size.y):
		cam_follow_player = true
	else:
		cam_follow_player = false
	tween.interpolate_property(camera_anchor, "global_position", camera_anchor.global_position, camera_target_position.global_position, 1, Tween.TRANS_SINE)
	tween.start()


func _on_RoomTransTimer_timeout():
	set_physics_process(true)
