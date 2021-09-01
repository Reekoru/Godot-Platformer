extends Position2D


onready var player = get_node("../Player")
onready var tween = $Tween
onready var cam = $Camera2D

var collision_shape
var size
func _process(delta):
	if(!player.tween.is_active()):
		limit_camera_to_room()
		if(player.cam_follow_player):
			# Follow player
			var target = player.global_position
			var target_pos_x
			var target_pos_y
			target_pos_x = int(lerp(global_position.x, target.x, 0.2))
			target_pos_y = int(lerp(global_position.y, target.y, 0.2))
			global_position = Vector2(target_pos_x, target_pos_y)
			
			# Clamp Anchor within the corners of the room
			if(global_position.x > cam.limit_left + player.area_size.x - 240):	# Left
				global_position.x = cam.limit_left + player.area_size.x - 240
			if(global_position.x < player.area_collision_shape.global_position.x - player.area_size.x/2 + 240):	#Right
				global_position.x = player.area_collision_shape.global_position.x - player.area_size.x/2 + 240
			if(global_position.y < player.area_collision_shape.global_position.y - player.area_size.y/2 + 135):	#Top
				global_position.y = player.area_collision_shape.global_position.y - player.area_size.y/2 + 135
			if(global_position.y > cam.limit_top + player.area_size.y - 135):	# Bottom
				global_position.y = cam.limit_top + player.area_size.y - 135

func limit_camera_to_room():
	cam.limit_top = player.area_collision_shape.global_position.y - player.area_size.y/2
	cam.limit_left = player.area_collision_shape.global_position.x - player.area_size.x/2
	cam.limit_bottom = cam.limit_top + player.area_size.y
	cam.limit_right = cam.limit_left + player.area_size.x
