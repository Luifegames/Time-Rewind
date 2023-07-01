extends KinematicBody

onready var animationPlayer = $model/AnimationPlayer
onready var hcamera = $hCamera
onready var camera = $hCamera/vCamera/Camera
onready var vcamera = $hCamera/vCamera
onready var model = $model
onready var texture_progress = $Control/TextureProgress

var VELOCITY : Vector3

var isRewind : bool = false
var fov : int = 70
var energy : int = 1 

const SPEED  = 80
const GRAVITY  = 200
const FRICTION  = 0.79
const BUFFER_MAX_SIZE = 200

var buffer = []


func _ready():
#	Mouse disappear
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
#	camera movement
	if event is InputEventMouseMotion:
		hcamera.rotate_y(deg2rad( event.relative.x *-0.1))
		vcamera.rotate_x(deg2rad( event.relative.y * -0.1))
		vcamera.rotation.x = clamp(vcamera.rotation.x, -1, 0.45)


func _physics_process(delta):
#	Camera Player Rotation
	var h_rot = hcamera.global_transform.basis.get_euler().y
	
	var input  = Vector3(-Input.get_action_strength("left") + Input.get_action_strength("right"),
					0,
					-Input.get_action_strength("forward") + Input.get_action_strength("backward")).rotated(Vector3.UP,h_rot).normalized()

	_rewind(delta)
#	circle texture animation
	texture_progress.value = buffer.size()

	if isRewind: 
		return
	
	_move(input,delta)
	_animation(input,delta)
	


func _move(input:Vector3,delta : float):
	
	VELOCITY += input * SPEED * delta
	VELOCITY *= FRICTION
	move_and_slide(VELOCITY + GRAVITY*Vector3.DOWN*delta,Vector3.UP)


func _animation(input:Vector3,delta : float):
	var animation
	if input != Vector3.ZERO:
		animation = "run"
		model.rotation.y = lerp_angle(model.rotation.y, atan2(input.x,input.z),10*delta)
	else:
		animation = "idle"
	animationPlayer.play(animation)

func _rewind(delta):
	if Input.is_action_just_pressed("rewind") && !buffer.empty():
		isRewind = true
	
	if !Input.is_action_pressed("rewind") or buffer.empty():
		isRewind = false

	if !isRewind:
#		Deafult Camera Propereties
		fov = lerp(camera.fov,50,20*delta)
		energy = lerp(camera.environment.background_energy,1,20*delta)
		animationPlayer.playback_speed = 1
		
		if buffer.size() >= BUFFER_MAX_SIZE:
			buffer.remove(0)
#		Save Properties in buffer
		buffer.append({
						pos = global_transform.origin, #Player position
						rot = model.rotation.y, #Model rotation
						anim = animationPlayer.current_animation #Current animation
					})
	else:
#		Rewind Camera Properties 
		fov = lerp(camera.fov,70,20*delta)
		energy = lerp(camera.environment.background_energy,4,20*delta)
		# Invert the animation speed
		animationPlayer.playback_speed = -1
# Load Properties
		global_transform.origin = buffer[buffer.size() - 1].pos
		animationPlayer.play(buffer[buffer.size() - 1].anim)
		model.rotation.y = buffer[buffer.size() - 1].rot
		buffer.remove(buffer.size() - 1)

#Camera Properties
	camera.fov = fov
	camera.environment.background_energy = energy
	camera.environment.dof_blur_far_enabled = isRewind
	
	
	
	
	
