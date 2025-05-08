extends CharacterBody2D

enum State {IDLE, CHASE, ATTACK, STUNNED, DEAD}

var current_state = State.IDLE
@export var speed = 100
@export var max_health = 10
var health = max_health

@onready var player = null
@onready var anim = $AnimationPlayer
@onready var attack_timer = $Timer

func _ready():
	player = get_tree().get_root().get_node("Main/Player") # Adjust to your player path
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	switch_state(State.IDLE)

func _physics_process(delta):
	match current_state:
		State.IDLE:
			idle_state(delta)
		State.CHASE:
			chase_state(delta)
		State.ATTACK:
			attack_state(delta)
		State.STUNNED:
			stunned_state(delta)
		State.DEAD:
			dead_state(delta)

func idle_state(delta):
	if player and position.distance_to(player.position) < 200:
		switch_state(State.CHASE)

func chase_state(delta):
	var direction = (player.position - position).normalized()
	velocity = direction * speed
	move_and_slide()

	if position.distance_to(player.position) < 50:
		switch_state(State.ATTACK)

func attack_state(delta):
	velocity = Vector2.ZERO
	move_and_slide()
	anim.play("attack")
	attack_timer.start(1.0) # delay before next move

func stunned_state(delta):
	# You could play a stunned animation or delay here
	velocity = Vector2.ZERO
	move_and_slide()

func dead_state(delta):
	velocity = Vector2.ZERO
	move_and_slide()

func switch_state(new_state):
	if current_state == new_state:
		return
	current_state = new_state
	print("Switched to state:", new_state)

	if new_state == State.ATTACK:
		anim.play("attack")
	elif new_state == State.DEAD:
		anim.play("death")

func take_damage(amount):
	if current_state == State.DEAD:
		return

	health -= amount
	if health <= 0:
		switch_state(State.DEAD)
	else:
		switch_state(State.STUNNED)
		await get_tree().create_timer(0.5).timeout
		switch_state(State.CHASE)


func _on_area_2d_area_entered(area):
	if area.is_in_group("PlayerWeapon") and area.monitoring:
		print("Boss got hit!")
		take_damage(1)
		# queue_free()

func _on_attack_timer_timeout():
	if current_state == State.ATTACK:
		switch_state(State.CHASE)
