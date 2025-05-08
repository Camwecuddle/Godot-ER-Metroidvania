extends CharacterBody2D

const speed = 50
const jump_velocity = -200
const roll_speed = 150 # Speed during the roll
const roll_duration = 0.4 # Duration of the roll in seconds

var gravity = 900
var is_attacking = false
var is_jump_delayed = false
var is_rolling = false # New variable to track if the character is rolling
var is_jumping = false
var was_on_floor = false
var previous_direction = 0

# Input buffer variables
var buffered_action = null
var buffer_time = 0.0
const MAX_BUFFER_TIME = 0.3  # Maximum time (in seconds) to hold the input in the buffer

@onready var weapon = $GreatSword
@onready var sprite = $Sprite2D
@onready var anim = $AnimationPlayer
@onready var weapon_animation_player = $GreatSword/AnimationPlayer

func _physics_process(delta):
	# Update buffer time
	if buffer_time > 0:
		buffer_time -= delta
	else:
		buffered_action = null  # Clear the buffer if the time expires

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# Reset is_jumping when the character lands
		if is_jumping and not was_on_floor:
			is_jumping = false

	# Stop horizontal movement if attacking and on the floor
	if is_attacking and not is_jumping and is_on_floor():
		velocity.x = 0

	# Left/right movement
	if not is_rolling and not is_attacking: # Prevent movement input during roll or attack
		var direction = Input.get_axis("move_left", "move_right")
		velocity.x = direction * speed

		# Flip sprite only if the direction changes
		if direction != 0 and direction != previous_direction:
			scale.x = -1
			previous_direction = direction # Update the previous direction

	# Handle buffered actions
	if buffered_action == "jump" and is_on_floor() and not is_jump_delayed and not is_attacking and not is_rolling:
		is_jumping = true
		start_jump_delay()
		buffered_action = null  # Clear the buffer after executing the action

	elif buffered_action == "roll" and is_on_floor() and not is_rolling and not is_attacking:
		start_roll()
		buffered_action = null  # Clear the buffer after executing the action

	elif buffered_action == "attack" and not is_attacking and not is_rolling:
		attack()
		buffered_action = null  # Clear the buffer after executing the action

	# Jumping
	if Input.is_action_just_pressed("jump"):
		if is_on_floor() and not is_jump_delayed and not is_attacking and not is_rolling:
			is_jumping = true
			start_jump_delay()
		else:
			buffer_input("jump")  # Buffer the jump input

	# Rolling
	if Input.is_action_just_pressed("roll"):
		if is_on_floor() and not is_rolling and not is_attacking:
			start_roll()
		else:
			buffer_input("roll")  # Buffer the roll input

	# Attacking
	if Input.is_action_just_pressed("attack"):
		if not is_attacking and not is_rolling:
			attack()
		else:
			buffer_input("attack")  # Buffer the attack input

	was_on_floor = is_on_floor() # Track if the character was on the floor last frame

	# Move the character
	move_and_slide()

func start_jump_delay():
	is_jump_delayed = true
	anim.play("squish") # Play the squish animation
	await get_tree().create_timer(0.1).timeout # Wait for 0.1 seconds
	velocity.y = jump_velocity
	is_jump_delayed = false

func start_roll():
	is_rolling = true
	anim.play("roll") # Play the roll animation

	# Determine roll direction based on direction
	velocity.x = roll_speed * previous_direction if previous_direction != 0 else roll_speed

	await get_tree().create_timer(roll_duration).timeout # Wait for the roll duration
	velocity.x = 0 # Stop horizontal movement after the roll
	is_rolling = false

func attack():
	is_attacking = true
	# Play the appropriate attack animation based on the character's facing direction
	weapon_animation_player.play("light-attack-right-1") # Play the right attack animation

	weapon.monitoring = true # Enable monitoring for the weapon's Area2D

	await weapon_animation_player.animation_finished # Wait for the attack animation to finish
	weapon_animation_player.play("light-attack-right-1-to-idle") # Reset to idle animation
	print('done')
	weapon.monitoring = false # Disable monitoring after the attack
	is_attacking = false

func buffer_input(action):
	buffered_action = action
	buffer_time = MAX_BUFFER_TIME  # Reset the buffer timer

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1)
