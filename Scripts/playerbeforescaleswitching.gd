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

@onready var weapon = $GreatSword
@onready var sprite = $Sprite2D
@onready var anim = $AnimationPlayer
@onready var weapon_animation_player = $GreatSword/AnimationPlayer

func _physics_process(delta):
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

		# Flip sprite and attack area based on direction
		if direction != 0:
			sprite.flip_h = direction < 0
			weapon.position.x = -10 if not sprite.flip_h else 10 # Adjust attack area position

	# Jumping
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_jump_delayed and not is_attacking:
		is_jumping = true  # Set is_jumping to true when the jump button is pressed
		start_jump_delay()

	# Rolling
	if Input.is_action_just_pressed("roll") and is_on_floor() and not is_rolling and not is_attacking:
		start_roll()

	# Attack
	if Input.is_action_just_pressed("attack") and not is_attacking:
		attack()

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
	velocity.x = roll_speed * (1 if not sprite.flip_h else -1) # Move in the direction the sprite is facing
	await get_tree().create_timer(roll_duration).timeout # Wait for the roll duration
	velocity.x = 0 # Stop horizontal movement after the roll
	is_rolling = false

func attack():
	is_attacking = true
	# Play the appropriate attack animation based on the character's facing direction
	if sprite.flip_h:
		weapon_animation_player.play("light-attack-left-1") # Play the left attack animation
	else:
		weapon_animation_player.play("light-attack-right-1") # Play the right attack animation

	weapon.monitoring = true # Enable monitoring for the weapon's Area2D

	await weapon_animation_player.animation_finished # Wait for the attack animation to finish
	if sprite.flip_h:
		weapon_animation_player.play("light-attack-left-1-to-idle") # Reset to idle animation
	else:
		weapon_animation_player.play("light-attack-right-1-to-idle") # Reset to idle animation
	print('done')
	weapon.monitoring = false # Disable monitoring after the attack
	is_attacking = false

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1)
