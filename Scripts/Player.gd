extends KinematicBody2D

# Constants
const UP = Vector2(0, -1)
const GRAVITY = 20
const MAX_FALLSPEED = 200
const MAX_MOVESPEED = 100
const JUMPFORCE = 275
const ACCELERATION = 20
const DASHSPEED = 300

var velocity = Vector2()
var direction = Vector2()
var dash_direction = Vector2()
var facing_direction = 1 # 1 = right -1 = left
var can_dash = true
var grace_jump = 5
var wall_jump_time = 7
var wall_jump_timer = wall_jump_time

var area_starting_position = Vector2()

#Camera Variables: Used in Anchor
var cam_follow_player = false
var area_collision_shape
var area_size

onready var to_free_timer = get_node("ChangeToFreeTimer")
onready var collision_ray = get_node("CollisionRay")
onready var tween = get_node("Tween")

# States
enum {
	IDLE
	FREE 
	DASH
	UPWARD_ROOM_TRANS
	ON_WALL
	WALL_JUMP
	DEATH
	}
var state: int = FREE

func _ready():
	pass # Replace with function body.

# warning-ignore:unused_argument
func _physics_process(delta):
	print(area_starting_position)
	# Obstacle Detection
	for i in get_slide_count():
		var collision = get_slide_collision(i)
		if(collision.collider.name == "Obstacles"):
			change_state(DEATH)
	$Sprite.visible = true
	# Flip ray to player's direction
	var ray_length = 9
	collision_ray.cast_to.x = facing_direction* ray_length
	# Dash
	if(Input.is_action_just_pressed("dash") && can_dash):
		velocity.x = 0 # Stop player for dash
		velocity.y = 0
		dash_direction = Vector2.ZERO
		to_free_timer.wait_time = 0.25
		to_free_timer.start()
		change_state(DASH)
	# Move player with collision
	velocity = move_and_slide(velocity, UP)
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
			velocity.y += GRAVITY
			
			# Clamp fall speed
			if(velocity.y > MAX_FALLSPEED):
				velocity.y = MAX_FALLSPEED
			
			# Clamp horizontal movement
			velocity.x = clamp(velocity.x, -MAX_MOVESPEED, MAX_MOVESPEED)
			
			# Horizontal Movement
			if(Input.is_action_pressed("right") || Input.is_action_pressed("left")):
				if($AnimationPlayer.current_animation != "Jump" || $AnimationPlayer.current_animation != "Falling"):
					$AnimationPlayer.play("Run")
				facing_direction = direction.x
				velocity.x += ACCELERATION * direction.x
			else:
				$AnimationPlayer.play("Idle")
				if(is_on_floor()):
					velocity.x = lerp(velocity.x, 0, 0.4)	# Deceleration on floor
				else:
					velocity.x = lerp(velocity.x, 0, 0.05)	# Deceleration of air
				
				
			# Jump
			grace_jump -= 1	# Cayote time
			if(grace_jump > 0 && Input.is_action_just_pressed("jump")):
					velocity.y = -JUMPFORCE
			if(is_on_floor()):
				can_dash = true
				grace_jump = 5
			else:
				if(velocity.y < 0):
					$AnimationPlayer.play("Jump")
				elif(velocity.y > 0):
					$AnimationPlayer.play("Falling")
			# Varaible Jump Height
			if(!Input.is_action_pressed("jump") && velocity.y < 0):
				velocity.y = max(velocity.y, -JUMPFORCE/2)
				
			"""if(collision_ray.is_colliding() && !is_on_floor() && velocity.y > 0 && direction.x != 0):
				velocity.y = velocity.y/2
				change_state(ON_WALL)""" # Might remove wall mechanic
		# Dash State
		DASH:
			$Sprite.visible = false
			"""var orb_velocity = Vector2()
			if(Input.is_action_pressed("up")):
				orb_velocity.y = -DASHSPEED
			elif(Input.is_action_pressed("down")):
				orb_velocity.y = DASHSPEED
			
			if(Input.is_action_pressed("right")):
				orb_velocity.x = DASHSPEED
			elif(Input.is_action_pressed("left")):
				orb_velocity.x = -DASHSPEED
			
			if(Input.is_action_just_pressed("jump")):
				velocity.y = -JUMPFORCE
				can_dash = false
				change_state(FREE)
			velocity = lerp(velocity, orb_velocity, 0.035 )"""	# Orb lfying mechanic code
			if(direction.y != 0 && can_dash):
				dash_direction.y = direction.y
			if(direction.x != 0 && can_dash):
				dash_direction.x = direction.x
			if(direction.x == 0 && direction. y == 0 && can_dash):
				dash_direction.x = DASHSPEED * facing_direction
			can_dash = false
			velocity = dash_direction.normalized() * DASHSPEED	# Normalize Vector
		UPWARD_ROOM_TRANS:
			velocity.y = -JUMPFORCE
			# Changes back to free after a while because of timer
		# On Wall State
		ON_WALL:
			$Sprite.scale.x = -facing_direction # Only for this sprite because climbing is flipped
				
			# Wall Grab
			if(Input.is_action_pressed("grab")):
				velocity.y = 0
				if(direction.y != 0):
					velocity.y *= -JUMPFORCE/4
				if(direction.y < 0):
					$AnimationPlayer.play("Climbing")
					velocity.y = direction.y * MAX_MOVESPEED / 4
				elif(direction.y > 0):
					$AnimationPlayer.play_backwards("Climbing")
					velocity.y = direction.y * MAX_MOVESPEED / 4
				else:
					$AnimationPlayer.play("On_Wall_Idle")
			else:
				$AnimationPlayer.play("On_Wall_Idle")
				velocity.y += GRAVITY/8
			if(Input.is_action_just_pressed("jump") && Input.is_action_pressed("grab")):
				velocity.y = -JUMPFORCE/2
				if(direction.x == -facing_direction):
					velocity.x = -facing_direction * MAX_MOVESPEED*2
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
		
		DEATH:
			self.global_position = area_starting_position
			velocity = Vector2.ZERO
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

func _on_RoomDetector_area_entered(area):
	print(area.name)
	area_collision_shape = area.get_node("CollisionShape2D")
	area_size = area_collision_shape.shape.extents * 2
	#area_starting_position = area.get_node("StartingPosition")
	var room_transition_timer = get_node("RoomTransTimer")	
	var camera_target_position = area.get_node("CameraPosition")
	var camera_anchor = get_node("../Anchor")
	var cam = get_node("../Anchor/Camera2D")
	var view_size = get_viewport().size
	
	#print(area_starting_position.global_position)
	#print(area_starting_position.global_transform.origin.distance_to(self.global_transform.origin))
	# Remove Limits of Camera
	cam.limit_bottom = 10000
	cam.limit_right = 10000
	cam.limit_left = -10000
	cam.limit_top= -10000
	
	# Pause player
	room_transition_timer.start()
	$AnimationPlayer.stop()
	set_physics_process(false)

	# Check if room is bigger than viewport
	if(area_size.x > view_size.x || area_size.y > view_size.y):
		cam_follow_player = true
	else:
		cam_follow_player = false
	
	# Interpolate between two Position2Ds
	tween.interpolate_property(camera_anchor, "global_position", camera_anchor.global_position, camera_target_position.global_position, 1, Tween.TRANS_SINE)
	tween.start()


func _on_RoomTransTimer_timeout():
	#Resumes player when transition is over
	set_physics_process(true)
	# If player is coming from below the room
	if(global_position.y > area_collision_shape.global_position.y + area_size.y/2 - 16):
		change_state(UPWARD_ROOM_TRANS)
		to_free_timer.wait_time = 0.15
		to_free_timer.start()

func _on_ChangeToFreeTimer_timeout():
	change_state(FREE)
