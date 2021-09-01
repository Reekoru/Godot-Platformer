extends Line2D


var length = 10
var point = Vector2()
func _process(delta):
	global_position = Vector2(0,0)
	global_rotation = 0
	
	point = get_parent().global_position
	if(get_parent().state == 2): # If player state is Dashing
		add_point(point)
	else:
		for i in get_point_count():
			remove_point(i)
	if(get_point_count() > length):
		remove_point(0)
