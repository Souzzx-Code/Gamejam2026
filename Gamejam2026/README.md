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

Bem-vindo(a) à **Game Jam FATEC Campinas 2026**!  
Este README traz um **resumo simplificado do regulamento**, com foco nas etapas de **desenvolvimento e submissão do jogo via GitHub**.  
Para detalhes completos, consulte o regulamento oficial disponibilizado pela organização.

---

## 🎯 Sobre o Evento

A **Game Jam FATEC Campinas 2026** é uma maratona de desenvolvimento de jogos que acontecerá entre **17 e 24 de outubro de 2026**.

O evento tem como objetivo:
- Incentivar a criatividade e o trabalho em equipe;
- Estimular o aprendizado prático em programação, design e lógica de jogos;
- Promover a integração entre alunos de diferentes cursos e semestres.

📍 **Abertura presencial:** 17/10 (sábado), a partir das 9h  
💻 **Desenvolvimento remoto:** 18/10 a 24/10 às 13h  
🏫 **Apresentações:** Semana de Tecnologia (26–29/10)  
🏆 **Premiação:** 06/11/2026

---

## 👥 Equipes

- Cada equipe deve ter **3 a 5 integrantes**.  
- A participação é **gratuita, voluntária e intransferível**.  
- O jogo final deve **funcionar nos computadores da FATEC**.

---

## 🧩 Desenvolvimento do Jogo

- Ferramentas permitidas: **Scratch**, **Pygame**, **Godot**, **Gamemaker**, **RPG Maker** e **Unity**.  
- É permitido o uso de **assets prontos**, desde que **livres de direitos autorais** ou com **licença adequada**.  
- O uso de **Inteligência Artificial (IA)** é permitido, mas deve ser **declarado no relatório** e limitado a funções auxiliares.  
- O jogo deve refletir **principalmente o trabalho da equipe**.  
- Todo conteúdo de terceiros deve ter **crédito e licença indicados** no relatório final.

---

## 💻 Submissão do Projeto (GitHub)

A entrega do projeto será feita **exclusivamente via GitHub**, seguindo as etapas abaixo:

### 1️⃣ Fork do Repositório Oficial
Cada equipe deve fazer o **fork** deste repositório.  
O fork será o **ambiente de desenvolvimento** do jogo.

### 2️⃣ Criação da Branch
No repositório forkeado, crie uma **branch de desenvolvimento** com nome identificável, por exemplo: equipe_nomeDoJogo 

### 3️⃣ Estrutura e Conteúdo Obrigatório

O repositório deve conter:

- `README.md` com informações básicas do projeto  
- `relatorioInicial_nomeEquipe` (documento criado no Ideathon)  
- `relatorioFinal_nomeEquipe`, contendo:
  - Nome da equipe e dos integrantes (curso, período, semestre)
  - Título do jogo
  - Ferramenta utilizada
  - Descrição do jogo (gênero, estilo, tema aplicado)
  - Arquitetura e tecnologias adotadas
  - Instruções de execução
  - Mudanças desde o relatório inicial
  - Créditos, licenças e uso de IA
  - Capturas, GIFs ou vídeos demonstrativos do jogo

### 4️⃣ Pull Request (PR)
Após finalizar o desenvolvimento:

- Abra um **Pull Request (PR)** da sua branch de desenvolvimento para a `main` do **repositório forkeado**.  
- Inclua:
  - Título informativo e identificável  
  - Descrição das principais funcionalidades  
  - Imagens e vídeos do jogo  
  - Arquivo executável (para rodar nas máquinas da FATEC)

📅 **Prazo final:** 24/10/2025 às **13h00 (horário de Brasília)**  
⛔ PRs abertos após o prazo **não serão considerados**.

> **Dica:** mantenha commits frequentes e documentados durante o desenvolvimento!  
> Isso ajuda a organização e demonstra o progresso da equipe.
---

## 🧠 Avaliação e Premiação

- O jogo deve **rodar corretamente nos computadores da FATEC**.  
- Durante a **Semana de Tecnologia (26–29/10)**, os participantes apresentarão seus jogos.  
- O público votará em seus favoritos.  
- Os **3 jogos mais votados** receberão premiações no dia **06/11/2025**.

---

## ⚖️ Código de Conduta e Direitos

- É obrigatório manter um ambiente de **respeito, colaboração e inclusão**.  
- O jogo é **propriedade da equipe**, mas a FATEC terá **direito de uso não exclusivo e gratuito** para fins acadêmicos e de divulgação.  
- É **vedado o plágio** ou uso de materiais sem licença.
