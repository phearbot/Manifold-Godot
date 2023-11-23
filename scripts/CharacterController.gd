extends CharacterBody3D

# This stutter fix is an option curtesy of this gamer: https://www.youtube.com/watch?v=pqrD3B75yKo
# Another option is to dynamically sync refresh rate and physics tic: https://www.reddit.com/r/godot/comments/ynmxf8/protip_for_all_godot_projects_i_just_discovered/
# I'm a lazy bitch so I just set my physics tic to 144 kekw ¯\_(ツ)_/¯

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = .003

# WORLD ROTATION VARIABLES
const ROTATION_TIME = .2
const RAY_LENGTH = .7
var target_normal = null


# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head = $Head
@onready var camera = $Head/Camera3D

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	#ProjectSettings.set_setting("physics/3d/default_gravity_vector", Vector3(1,1,1))


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		head.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		#velocity.y -= gravity * delta
		var velocity_to_apply = ProjectSettings.get_setting("physics/3d/default_gravity_vector") * gravity * delta
		velocity += velocity_to_apply
		print("Applying Gravity: ", velocity_to_apply)

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
		velocity -= ProjectSettings.get_setting("physics/3d/default_gravity_vector") * JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (head.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# GRAVITY FLIPPING BREAKS HERE BECAUSE X/Z ARE BEING SET TO 0 
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()


func _process(delta):
	if (Input.is_action_just_pressed("interact") && target_normal != null):
		print("Target Normal: ", target_normal)
		ProjectSettings.set_setting("physics/3d/default_gravity_vector", target_normal)	
		print("Default Gravity Vector: ", ProjectSettings.get_setting("physics/3d/default_gravity_vector"))


	# Raycast for detecting normals
	var cam = $Head/Camera3D
	var space = get_world_3d().direct_space_state
	# this raycast may completely break when we rotate the world
	var query = PhysicsRayQueryParameters3D.create(cam.global_position, cam.global_position - cam.global_transform.basis.z * RAY_LENGTH)
	var collision = space.intersect_ray(query)
	if collision:
		#$CanvasLayer/Label.text = collision.collider.name

		target_normal = collision.normal
	else:
		#$CanvasLayer/Label.text = ""
		#print("no hit")
		target_normal = null
		pass

