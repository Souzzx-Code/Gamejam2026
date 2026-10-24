extends CharacterBody2D

signal health_changed(current_health: int, max_health: int)
signal died

## quando terminar de carregar todos os nós, o tipo de variável animated
## recebe o caminho de onde está o nó
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_label: Label = $HealthLabel

const SPEED = 150.0
const JUMP_VELOCITY = -300.0
const MAX_HEALTH := 5

var health := MAX_HEALTH
var tasks_completed := 0

# NOVO: referência à área de interação do jogador.
# É necessário criar InteractionArea e CollisionShape2D como filhos do Player.
@onready var interaction_area: Area2D = $InteractionArea

# NOVO: guarda o objeto interativo mais próximo.
var nearby_interactable: Node2D = null


func _ready() -> void:
	add_to_group("player")
	_update_health_label()
	# NOVO: conecta os sinais da área de interação.
	interaction_area.area_entered.connect(_on_area_entered)
	interaction_area.area_exited.connect(_on_area_exited)


func take_damage(amount: int) -> void:
	if amount <= 0 or health <= 0:
		return
	health = maxi(health - amount, 0)
	_update_health_label()
	health_changed.emit(health, MAX_HEALTH)
	print("O vampiro sofreu dano. Vida: ", health, "/", MAX_HEALTH)
	if health == 0:
		set_physics_process(false)
		set_process(false)
		anim.play("idle")
		died.emit()


func _update_health_label() -> void:
	if health_label != null:
		health_label.text = "VIDA: %d/%d" % [health, MAX_HEALTH] 


func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if is_on_floor():

		## como meu personagem está invertido, coloquei true quando estiver andando pra direita
		if direction > 0:
			anim.flip_h = true
			anim.play("walk")
		elif direction < 0:
			anim.flip_h = false
			anim.play("walk")
		else:
			anim.play("idle")
	else:
		anim.play("jump")

	move_and_slide()


# NOVO: verifica quando a tecla E é pressionada.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("interagir"):
		if nearby_interactable != null:
			if nearby_interactable.has_method("interact"):
				nearby_interactable.interact()
			else:
				print("O objeto próximo não possui a função interact().")
		else:
			print("Nenhuma porta ou elevador interativo por perto.")


# NOVO: detecta a entrada em uma área interativa.
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("interactable"):
		nearby_interactable = area
		print("Objeto interativo detectado: ", area.name)


# NOVO: detecta quando o jogador sai da área interativa.
func _on_area_exited(area: Area2D) -> void:
	if nearby_interactable == area:
		nearby_interactable = null
		print("Você saiu da área de interação.")
