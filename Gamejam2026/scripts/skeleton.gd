extends CharacterBody2D

@export var base_speed := 150.0
@export var speed_per_task := 12.0
@export var attack_range := 78.0
@export var attack_damage := 1
@export var attack_cooldown := 1.0
@export var floor_snap_distance := 18.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

const FLOOR_Y := [960.0, 720.0, 480.0, 240.0]
const LEFT_STAIR_X := [32.0, 300.0, 32.0, 300.0]
const RIGHT_STAIR_X := [1656.0, 1388.0, 1656.0, 1388.0]
const ATTACK_DISTANCE := 78.0

var target: Node2D
var attack_timer := 0.0
var route_floor := -1
var route_stage := 0
var route_side := -1


func _ready() -> void:
	_build_animations()
	target = get_tree().get_first_node_in_group("player") as Node2D


func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as Node2D
		return

	attack_timer = maxf(attack_timer - delta, 0.0)
	var target_feet := _get_target_feet()
	var target_floor := _nearest_floor(target_feet.y)
	var player_tasks := int(target.get("tasks_completed"))
	var current_speed := base_speed + player_tasks * speed_per_task

	if route_floor == -1:
		route_floor = _nearest_floor(global_position.y)

	if route_floor == target_floor:
		route_stage = 0
		route_side = -1
		global_position.y = move_toward(global_position.y, FLOOR_Y[route_floor], current_speed * delta)
		var distance := global_position.distance_to(target_feet)
		if distance <= maxf(attack_range, ATTACK_DISTANCE):
			velocity = Vector2.ZERO
			anim.play("attack")
			if attack_timer <= 0.0 and target.has_method("take_damage"):
				target.take_damage(attack_damage)
				attack_timer = attack_cooldown
		else:
			velocity = global_position.direction_to(Vector2(target_feet.x, FLOOR_Y[route_floor])) * current_speed
			velocity.y = 0.0
			anim.flip_h = velocity.x > 0.0
			anim.play("run")
			global_position.x = move_toward(global_position.x, target_feet.x, current_speed * delta)
	else:
		var floor_direction := 1 if target_floor > route_floor else -1
		var next_floor := route_floor + floor_direction
		if route_side == -1:
			route_side = _choose_stair_side(route_floor, next_floor, target_feet.x)
		var stair_x := RIGHT_STAIR_X if route_side == 1 else LEFT_STAIR_X
		var stair_start := Vector2(stair_x[route_floor], FLOOR_Y[route_floor])
		var stair_end := Vector2(stair_x[next_floor], FLOOR_Y[next_floor])
		var waypoint := stair_start if route_stage == 0 else stair_end
		velocity = global_position.direction_to(waypoint) * current_speed
		anim.flip_h = velocity.x > 0.0
		anim.play("run")
		global_position = global_position.move_toward(waypoint, current_speed * delta)
		if global_position.distance_to(waypoint) <= 3.0:
			if route_stage == 0:
				route_stage = 1
			else:
				route_floor = next_floor
				route_stage = 0
				global_position = Vector2(global_position.x, FLOOR_Y[route_floor])


func _choose_stair_side(from_floor: int, to_floor: int, target_x: float) -> int:
	var left_distance := absf(global_position.x - LEFT_STAIR_X[from_floor])
	left_distance += absf(target_x - LEFT_STAIR_X[to_floor])
	var right_distance := absf(global_position.x - RIGHT_STAIR_X[from_floor])
	right_distance += absf(target_x - RIGHT_STAIR_X[to_floor])
	return 1 if right_distance < left_distance else 0


func _get_target_feet() -> Vector2:
	var target_position := target.global_position
	var target_collision := target.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if target_collision != null:
		var target_shape := target_collision.shape
		var target_feet_offset := 0.0
		if target_shape is CapsuleShape2D:
			target_feet_offset = (target_shape as CapsuleShape2D).height * 0.5
		elif target_shape is RectangleShape2D:
			target_feet_offset = (target_shape as RectangleShape2D).size.y * 0.5
		target_position = target_collision.global_position + Vector2(0.0, target_feet_offset)
	return target_position


func _nearest_floor(y: float) -> int:
	var nearest := 0
	var nearest_distance := absf(y - FLOOR_Y[0])
	for index in range(1, FLOOR_Y.size()):
		var distance := absf(y - FLOOR_Y[index])
		if distance < nearest_distance:
			nearest = index
			nearest_distance = distance
	return nearest


func _build_animations() -> void:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var animations := {
		"idle": "res://sprites/Skeleton/idle/alfa.png",
		"run": "res://sprites/Skeleton/run/alfa.png",
		"attack": "res://sprites/Skeleton/attack/alfa.png",
		"death": "res://sprites/Skeleton/death/alfa.png",
		"jump": "res://sprites/Skeleton/jump/alfa.png",
		"kick": "res://sprites/Skeleton/kick/alfa.png",
		"walk": "res://sprites/Skeleton/walk/alfa.png",
	}

	for animation_name in animations:
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, 8.0 if animation_name == "attack" else 10.0)
		frames.set_animation_loop(animation_name, animation_name != "death")
		var atlas := load(animations[animation_name]) as Texture2D
		for frame_index in 25:
			var frame := AtlasTexture.new()
			frame.atlas = atlas
			var row := frame_index / 5
			var column := frame_index % 5
			frame.region = Rect2(column * 256, row * 256, 256, 256)
			frames.add_frame(animation_name, frame)

	anim.sprite_frames = frames
	anim.play("run")
