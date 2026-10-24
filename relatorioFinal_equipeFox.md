# Relatório Final — Equipe Fox

> Game Jam FATEC Campinas 2026 — Grupo 4

## 1. Equipe

| Integrante | Curso | Período | Semestre |
|---|---|---|---|
| Luiz Gustavo do Nascimento Souza | ADS | Tarde | 3º semestre |
| Thiago Rodrigues | ADS | Tarde | 3º semestre |
| Jonas Santos | ADS | Tarde | 3º semestre |

## 2. Título oficial do projeto

**O Retorno do Vampiro**

## 3. Ferramenta escolhida

O projeto foi desenvolvido utilizando a **engine Godot 4.7**, com scripts escritos em
**GDScript** e exportação para Windows.

## 4. Descrição do projeto

**O Retorno do Vampiro** é um jogo 2D de aventura, exploração e perseguição com
temática de Halloween. O jogador controla um vampiro dentro de uma versão assombrada
da FATEC Campinas e precisa realizar tarefas, coletar números e escapar antes que o
esqueleto perseguidor alcance o personagem.

O jogo combina exploração de um mapa vertical, interação com objetos, movimentação por
elevadores e escadarias, coleta de objetivos e sobrevivência durante uma perseguição.

## 5. Abordagem do tema

O tema Halloween foi aplicado na ambientação completa do jogo: a FATEC foi transformada
em um prédio assombrado com iluminação dramática, morcegos, fantasmas, teias, abóboras,
portas temáticas e decoração pixel art.

O vampiro, o esqueleto perseguidor e os elementos sobrenaturais reforçam a identidade
do tema. A ameaça constante do perseguidor cria a tensão típica de uma fuga em um
ambiente assombrado.

## 6. Descrição geral

O jogo começa no mapa principal da FATEC. O vampiro precisa:

1. Encontrar a Diretoria e obter o cabo de rede;
2. Ir ao servidor no segundo andar e habilitar a rede;
3. Visitar os monitores dos andares 1, 2 e 3;
4. Coletar os três números das tarefas;
5. Retornar à saída no térreo;
6. Informar a senha formada pelos números coletados.

Enquanto realiza os objetivos, o esqueleto persegue o vampiro. Cada ataque reduz a
vida do jogador, exibida em uma barra na parte inferior da tela. A velocidade do
perseguidor aumenta a cada número coletado. Se a vida chegar a zero, uma tela de derrota
é apresentada e o jogador pode reiniciar a partida.

## 7. Arquitetura da solução

O projeto foi organizado em cenas e scripts independentes:

- `scene/game.tscn`: cena principal do jogo;
- `entidades/player.tscn`: cena do vampiro;
- `entidades/skeleton.tscn`: cena do perseguidor;
- `main_menu.tscn`: menu inicial temático;
- `menu.tscn`: tela de derrota e reinício;
- `scripts/player.gd`: movimento, interação e vida do vampiro;
- `scripts/skeleton.gd`: perseguição, animações, ataque e aumento de velocidade;
- `scripts/fatec_map_pixel (1).gd`: mapa procedural, colisões, elevadores, portas,
  monitores, tarefas, iluminação e HUD;
- `scripts/main_menu.gd` e `scripts/menu.gd`: navegação dos menus.

O mapa é criado proceduralmente por um script, que também constrói as colisões das
lajes, paredes, rampas e áreas interativas. A comunicação entre sistemas utiliza sinais,
grupos do Godot e referências às entidades da cena.

## 8. Tecnologias e padrões utilizados

- Godot Engine 4.7;
- GDScript;
- CharacterBody2D para o vampiro e o perseguidor;
- AnimatedSprite2D e SpriteFrames para animações;
- Area2D para áreas de interação;
- StaticBody2D e CollisionShape2D para colisões;
- CanvasLayer, Label e ProgressBar para HUD;
- CanvasModulate e PointLight2D para iluminação;
- Cenas reutilizáveis (`.tscn`);
- Sinais para comunicar coleta de tarefas, alteração de vida e derrota;
- Grupos do Godot para localizar o jogador;
- Sprite sheets em pixel art para os personagens.

## 9. Compilação, instalação e execução

### Executar pelo Godot

1. Instale o Godot 4.7 ou versão compatível.
2. Abra `project.godot` no editor.
3. Pressione **F5** para executar o projeto.
4. O menu inicial será exibido antes da partida.

### Executar a versão Windows

1. Baixe `Gamejam2026-Windows.zip`.
2. Extraia o conteúdo completo para uma pasta.
3. Mantenha `Gamejam2026.exe` e `Gamejam2026.pck` na mesma pasta.
4. Execute `Gamejam2026.exe`.

O jogador não precisa ter o Godot instalado para executar a versão exportada.

### Controles

| Ação | Tecla |
|---|---|
| Mover | A/D ou setas esquerda/direita |
| Pular | Espaço |
| Interagir | E |
| Subir escadas | W ou seta para cima |
| Descer escadas | S ou seta para baixo |
| Alternar tela cheia | F11 ou Alt + Enter |

## 10. Mudanças desde o Relatório Inicial

### Ferramenta e implementação

- O relatório inicial previa Unity e C#. O produto final foi desenvolvido em Godot 4.7
  e GDScript.
- A estrutura final passou a utilizar cenas `.tscn`, scripts GDScript e recursos
  nativos da Godot.
- O mapa passou a ser gerado proceduralmente por código.

### Conceito e personagens

- O título provisório **Mummenstein** foi substituído por **O Retorno do Vampiro**.
- A ideia inicial de uma aventura cooperativa com Frankenstein e Múmia foi alterada
  para uma experiência solo de sobrevivência e perseguição.
- O protagonista final é um vampiro.
- O antagonista final é um esqueleto com animações de corrida e ataque.

### Jogabilidade

- O modo multiplayer para dois jogadores foi substituído por controle individual.
- Foram adicionados objetivos de coleta de três números.
- Foi criada a sequência de progressão: Diretoria, cabo de rede, servidor, monitores e
  saída.
- Foi implementado um perseguidor que segue o jogador, ataca e aumenta sua velocidade
  conforme as tarefas são concluídas.
- Foram adicionados vida do jogador, dano, derrota e tela de reinício.
- Foi criada uma barra de vida minimalista na parte inferior da tela.
- Foi criado um painel de objetivos com instruções de progressão.
- Foram implementadas escadarias, elevadores, portas e áreas de interação.

### Interface e apresentação

- Foi criado um menu inicial com temática de Halloween.
- Foi criada uma tela de derrota com opção de jogar novamente.
- Foi implementado suporte para alternar entre janela e tela cheia.
- Foi adicionada uma versão exportada para Windows.

## 11. Créditos e uso de IA

Os integrantes da equipe são responsáveis pela concepção, decisões de design, integração
e validação final do projeto. Os assets visuais utilizados estão organizados nas pastas
`sprites/Vampiro` e `sprites/Skeleton`; suas licenças e créditos devem ser mantidos de
acordo com a origem dos arquivos utilizados pela equipe.

A Inteligência Artificial foi utilizada como ferramenta auxiliar para apoio à
implementação, organização, depuração e documentação. A direção do projeto, as escolhas
de gameplay e a integração final foram realizadas pela equipe.

