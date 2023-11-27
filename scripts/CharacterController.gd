extends CharacterBody3D
# A stutter fix ption is suggested by this gamer: https://www.youtube.com/watch?v=pqrD3B75yKo
# Another option is to dynamically sync refresh rate and physics tic: https://www.reddit.com/r/godot/comments/ynmxf8/protip_for_all_godot_projects_i_just_discovered/
# I'm a lazy bitch so I just set my physics tic to 144 kekw ¯\_(ツ)_/¯

# MOVEMENT VARIABLES
const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const SENSITIVITY = .003

# WORLD ROTATION VARIABLES
const ROTATION_TIME = .2
const RAY_LENGTH = .8
var target_normal = null
var is_rotating = false
var rotating_timer = 0
var previous_transform
var target_transform


var gravity_to_apply = Vector3.ZERO

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
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))

func _physics_process(delta):
	# Add the gravity.

	if (is_rotating):
		rotating_timer += delta
		if (rotating_timer > ROTATION_TIME):
			rotating_timer = ROTATION_TIME
			is_rotating = false

		var a = Quaternion(previous_transform.basis)
		var b = Quaternion(target_transform.basis)
		transform.basis = Basis(a.slerp(b,rotating_timer/ROTATION_TIME))

		return

	
	if not is_on_floor():
		#velocity.y -= gravity * delta
		#var gravity_this_frame = ProjectSettings.get_setting("physics/3d/default_gravity_vector") * gravity * delta
		gravity_to_apply += ProjectSettings.get_setting("physics/3d/default_gravity_vector") * gravity * delta
		#velocity += velocity_to_apply
		#print("Applying Gravity: ", velocity_to_apply)
	else:
		gravity_to_apply = Vector3.ZERO

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		gravity_to_apply -= ProjectSettings.get_setting("physics/3d/default_gravity_vector") * JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (head.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# GRAVITY FLIPPING BREAKS HERE BECAUSE X/Z ARE BEING SET TO 0 
	var proposed_velocity = direction * SPEED + gravity_to_apply
	velocity = proposed_velocity

	
	# Checks for input, null values, and the last guy makes sure you aren't clicking the floor
	if (Input.is_action_just_pressed("interact") && target_normal != null && not global_transform.basis.y.is_equal_approx(target_normal)):
		# Sets project gravity vector and game controller up direction
		ProjectSettings.set_setting("physics/3d/default_gravity_vector", -target_normal)	
		up_direction = target_normal
		
		# Sets
		previous_transform = transform
		target_transform = align_with_y(global_transform, target_normal)
		is_rotating = true
		rotating_timer = 0
		
		
		print("Default Gravity Vector: ", ProjectSettings.get_setting("physics/3d/default_gravity_vector"))

	move_and_slide()


func _process(delta):
	# Clicking switches the gravity to the inverse of the normal you click (The surface you clicked is now "the ground")

	# Raycast for detecting normals
	var cam = $Head/Camera3D
	var space = get_world_3d().direct_space_state
	# this raycast may completely break when we rotate the world
	var query = PhysicsRayQueryParameters3D.create(cam.global_position, cam.global_position - cam.global_transform.basis.z * RAY_LENGTH)
	var collision = space.intersect_ray(query)
	if collision:
		target_normal = collision.normal
		$"../HUD".update_reticle_color(target_normal)
	else:
		target_normal = null
		$"../HUD".update_reticle_color(Vector3.ZERO)


# Finds the rotation axis (Perpendicular to the current y (up) and the proposed y)
# https://docs.godotengine.org/en/stable/tutorials/math/vector_math.html#cross-product
func align_with_y(xform, new_y):
	var rotation_axis = xform.basis.y.cross(new_y)
	xform = xform.rotated(rotation_axis, TAU/4) #TAU/4 is just 90 degrees
	return xform
