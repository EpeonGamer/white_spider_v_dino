extends CharacterBody3D

@onready var cam_pivot_h: Node3D = %cam_pivot_h
@onready var cam_pivot_v: Node3D = %cam_pivot_v
var mouse_sensitivity : float = 0.01

const SPEED := 5.0
const SPRINT_MOD := 2.5

const GRAVITY := 24.8  # faster fall
const JUMP_VELOCITY := 8.0  # higher pop
const FALL_MULTIPLIER := 2.0  # faster descent
const LOW_JUMP_MULTIPLIER := 2.0  # short-hop effect

const FALL_MOD := 2.0 # lift factor while gliding
const FLAP_VELOCITY := 8.0
const AIR_SPEED_CONTROL := 2.5
const TERMINAL_VELOCITY := -2.0
var is_gliding := false
var has_jumped := false

@onready var interact_area: Area3D = $interact_area


func _physics_process(delta: float) -> void:
	# Apply gravity (including glide condition)
	if not is_on_floor():
		if is_gliding:
			if velocity.y < 0:
				velocity.y -= GRAVITY * FALL_MULTIPLIER * (1.0/FALL_MOD) * delta
			else:
				velocity.y -= GRAVITY * (1.0/FALL_MOD) * delta
			velocity.y = max(velocity.y, TERMINAL_VELOCITY)  # Optional terminal velocity
		elif velocity.y < 0:
			velocity.y -= GRAVITY * FALL_MULTIPLIER * delta
		elif not Input.is_action_pressed("ui_accept"):
			velocity.y -= GRAVITY * LOW_JUMP_MULTIPLIER * delta
		else:
			velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0
		is_gliding = false
		has_jumped = false
	
	
	# Handle jump and glide trigger
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
			has_jumped = true
			is_gliding = false
		elif has_jumped:
			if not is_gliding:
				# Start gliding
				is_gliding = true
				print("Glide started!")
			else:
				velocity.y = FLAP_VELOCITY
	
	# Movement with air control
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		var air_mult : float = 1.0 if is_on_floor() else AIR_SPEED_CONTROL
		velocity.x = direction.x * SPEED * air_mult * (SPRINT_MOD if Input.is_action_pressed("sprint") else 1)
		velocity.z = direction.z * SPEED * air_mult * (SPRINT_MOD if Input.is_action_pressed("sprint") else 1)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	move_and_slide()


func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		cam_pivot_h.rotate_x(-event.relative.y * mouse_sensitivity)
		cam_pivot_h.rotation.x = clampf(cam_pivot_h.rotation.x, -deg_to_rad(70), deg_to_rad(70))
	
	if Input.is_action_just_pressed("ui_cancel"):
		match Input.mouse_mode:
			Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			Input.MOUSE_MODE_VISIBLE:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if Input.is_action_just_pressed("interact"):
		if interact_area.get_overlapping_bodies():
			var closest : Node3D =  get_closest(global_position, interact_area.get_overlapping_bodies())
			if closest.has_method("interact"):
				closest.interact()


func get_closest(target : Vector3, positions : Array):
	var closest : Node3D = positions[0]
	for i : Node3D in positions:
		if i.global_position.distance_squared_to(target) >= closest.global_position.distance_squared_to(target):
			closest = i
	return closest
