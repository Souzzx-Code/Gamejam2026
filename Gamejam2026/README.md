# 🕹️ Game Jam FATEC Campinas 2026

## 🦇 O Retorno do Vampiro

**O Retorno do Vampiro** é um jogo 2D de ação e perseguição com temática de Halloween,
desenvolvido em **Godot 4** pela equipe Fox. O jogador controla um vampiro que precisa
coletar os números das tarefas e escapar enquanto um esqueleto perseguidor tenta alcançá-lo.

### Objetivo e funcionalidades

- Explorar os quatro andares do mapa da FATEC;
- Coletar os três números das tarefas;
- Usar elevadores e escadarias para circular pelo prédio;
- Evitar o esqueleto, que persegue o vampiro e fica mais rápido a cada tarefa concluída;
- Sobreviver aos ataques usando a barra de vida;
- Abrir a saída após concluir os objetivos;
- Reiniciar a partida por uma tela de derrota quando a vida chega a zero.

### Controles

| Ação | Tecla |
| --- | --- |
| Mover | A/D ou setas esquerda/direita |
| Pular | Espaço |
| Interagir | E |
| Subir escadas | Cima ou W |
| Descer escadas | Baixo ou S |

### Como executar

#### Pelo Godot

1. Instale o **Godot 4.7** ou versão compatível.
2. Abra o arquivo `project.godot`.
3. Execute o projeto com **F6** ou **F5**.

#### Versão Windows

Baixe `Gamejam2026-Windows.zip` na raiz deste repositório, extraia os arquivos e execute
`Gamejam2026.exe`. O arquivo `.pck` deve permanecer na mesma pasta do executável.

### Tecnologias e arquitetura

- Godot 4 e GDScript;
- Cenas independentes para jogador, perseguidor, menus e jogo;
- Mapa procedural com colisões, escadas, elevadores e áreas interativas;
- Sprite sheets para as animações do vampiro e do esqueleto;
- HUD em `CanvasLayer` para a barra de vida.

### Créditos, licenças e uso de IA

Os integrantes devem ser listados no relatório final da equipe. Assets de terceiros devem
ser mantidos com seus créditos e respectivas licenças no relatório final.

A IA foi utilizada como ferramenta auxiliar para apoio na implementação, depuração e
organização de código. A concepção do jogo, decisões de design e integração final são
responsabilidade da equipe.
