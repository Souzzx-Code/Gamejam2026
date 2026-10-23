extends CharacterBody2D

## quando terminar de carregar todos os nós, o tipo de variável animated
## recebe o caminho de onde está o nó
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 200.0
const JUMP_VELOCITY = -300.0

# NOVO: referência à área de interação do jogador.
# É necessário criar InteractionArea e CollisionShape2D como filhos do Player.
@onready var interaction_area: Area2D = $InteractionArea

# NOVO: guarda o objeto interativo mais próximo.
var nearby_interactable: Node2D = null


func _ready() -> void:
	# NOVO: conecta os sinais da área de interação.
	interaction_area.area_entered.connect(_on_area_entered)
	interaction_area.area_exited.connect(_on_area_exited)


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
