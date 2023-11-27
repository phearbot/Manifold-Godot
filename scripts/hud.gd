extends CanvasLayer

@export var up_color : Color = Color.RED
@export var down_color : Color = Color.ORANGE
@export var left_color : Color = Color.YELLOW
@export var right_color : Color = Color.GREEN
@export var forward_color : Color = Color.BLUE
@export var back_color : Color = Color.PURPLE

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update_reticle_color(target_normal):
	var color

	match target_normal:
		Vector3.UP:
			color = up_color
		Vector3.DOWN:
			color = down_color
		Vector3.LEFT:
			color = left_color
		Vector3.RIGHT:
			color = right_color
		Vector3.FORWARD:
			color = forward_color
		Vector3.BACK:
			color = back_color
		_:
			color = Color.WHITE

	$Reticle.material.set_shader_parameter("reticle_color", color)
	
