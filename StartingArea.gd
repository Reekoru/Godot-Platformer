extends Area2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _process(delta):
	var bodies = get_overlapping_bodies()
	# Check if overlapping body has starting position variable
	# If it does than it is the player and set the starting position
	for body in bodies:
		if("area_starting_position" in body):
			body.area_starting_position = $StartingPosition.global_position
