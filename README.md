# VOZES DO OCEANO

*Um jogo de ficção científica psicológica em primeira pessoa, inspirado nos temas de «Solaris», de Stanisław Lem.*

Você é K‑9, um astronauta enviado sozinho à estação orbital **ARGOS‑4**, em órbita baixa do planeta‑oceano **ÍRIO**.
A estação parou de responder há 47 dias. A tripulação de cinco pessoas desapareceu sem deixar corpos.
E o oceano lá embaixo começou a reproduzir, com água e luz, as pessoas que existem dentro da memória de quem ainda está vivo.

Este é um jogo de **exploração, investigação e atmosfera**. Não há combate. Não há explicação definitiva.

| | |
|---|---|
| Motor | **Godot 4.4** (Forward+) |
| Linguagem | GDScript |
| Conteúdo | 100% procedural (geometria, texturas, shaders, áudio e trilha sintetizados em tempo real) |
| Idioma | Português (pt‑BR) |
| Duração | ~45–70 minutos por partida |
| Conteúdo próprio | 5 finais (4 finais + variações guiadas pelas decisões), 17 tipos de anomalia, 4 conveses, 11 setores |
| Playtest | jogado do início ao fim por um jogador-robô de QA, **no build exportado**: **69 verificações OK, 0 falhas** (inclui mouse e áudio) — ver `docs/RELATORIO-PLAYTEST.md` |

---

## Como jogar

### Opção 1 — Build pronto (sem instalar nada)

```
dist/VozesDoOceano.x86_64      # Linux (64 bits)
dist/VozesDoOceano.exe         # Windows (64 bits)
dist/VozesDoOceano.pck         # recursos — mantenha ao lado do executável
```

No Linux:
```bash
chmod +x dist/VozesDoOceano.x86_64
./dist/VozesDoOceano.x86_64
```

> Requisitos: GPU com Vulkan (ou OpenGL 3.3+ via `--rendering-driver opengl3`).
> Se o seu sistema já tem Godot 4.4 instalado, o `.pck` funciona com qualquer binário 4.4 da mesma arquitetura.

### Opção 2 — Pelo editor Godot

```bash
godot --path .            # abre o projeto
godot --path . --editor   # abre no editor
```

O projeto abre como qualquer projeto Godot 4.4: tudo o que existe é gerado em código
(`Station.build()`, `StationKit`, `Mats`, `G3D`), então não há cenas binárias para sincronizar.

### Opção 3 — Scripts de execução

```bash
./run.sh                  # compila/roda pelo editor instalado
./dist/execute.sh         # roda o build de release
```

---

## Controles

| Tecla | Ação |
|---|---|
| `W A S D` | Andar |
| `Mouse` | Olhar |
| `SHIFT` | Correr |
| `CTRL` | Agachar |
| `E` | Interagir / ler / confirmar |
| `F` | Lanterna de capacete (a única "defesa" do jogo) |
| `TAB` | Diário de bordo (registros, decisões, anomalias) |
| `ESC` | Pausa, opções, salvar/carregar |
| `← →` | Alternar entre documentos, canais de rádio e câmeras |
| `G` | (no terminal de câmeras) forçar interferência |

---

## Como o jogo está organizado

```
project.godot                 autoloads, renderização, áudio
scenes/main.tscn              único arquivo de cena: um Node3D + script
icon.svg

assets/shaders/               oceano, céu, planeta, CRT, CCTV, manifestação, granulação
assets/audio/vozes/*.mp3      falas gravadas da tripulação (pt-BR)

scripts/core/
  boot.gd                     cria o mapa de entrada em código
  content.gd                  acesso ao material narrativo
  game_state.gd               flags, decisões, confiança, ressonância, save/load
  audio_man.gd                síntese das camadas de trilha + efeitos + vozes
  ocean.gd                    o planeta como personagem (shader compartilhado)
  director.gd                 capítulos, gatilhos, ambiente, finais

scripts/data/
  data_docs.gd                todos os documentos (briefings, diários, fitas, fotos)
  data_lore.gd                entradas do PDA, anomalias, decisões, diálogos, sinais de rádio

scripts/world/
  station.gd                  a estação em 4 conveses (hangar, refeitório, labs, engenharia,
                              comando, câmara do sino, eclusa, módulo de observação)
  station_kit.gd              kit de construção: salas, corredores, consoles, tubulações
  door.gd                     portas deslizantes industriais
  manifestation.gd            as pessoas que o oceano constrói
  interactable.gd             pontos de interação
  lamp_grid.gd / cam_grid.gd  redes de luz e câmeras
  sector_area.gd              setores (trilha sonora + pressão/oxigênio)

scripts/anomalies/anomalies.gd   17 manifestações do fenômeno
scripts/player/player.gd         jogador em primeira pessoa
scripts/ui/                      HUD, leitor de documentos, CCTV, rádio, decisões,
                                 teclado, diário/pausa, menu, abertura e finais
scripts/lib/                     utilitários de geometria e materiais procedurais
```

### Sistemas principais

**Trilha e sons 100% sintetizados.** `audio_man.gd` gera, por amostragem em tempo real,
seis camadas de música (sub, pad dissonante em Ré, ar, zumbido, mar, pulsação lenta) e
17 efeitos (cliques, portas, passos, o "sino", glitch, respiração). Não há um único arquivo
de áudio além das vozes.

**Duas variáveis invisíveis movem o jogo.**
- **Confiança** (‑5…+5): o quanto o oceano se aproxima de você. Muda quem aparece, o que as
  manifestações dizem e se elas repetem gestos humanos ou apenas o formato de gente.
- **Ressonância** (0…10): o quanto o fenômeno já ressoou na estação. Muda o oceano
  (de ondulação orgânica a interferência geométrica), acende glitch no HUD, sobe a trilha
  e faz o mar começar a **imitar construções humanas** vistas das janelas.

**O oceano é o shader.** Rede de ruído + interferência senoidal + espirais logarítmicas +
anéis de resposta. A cada nível de ressonância ele se torna mais regular — e mais errado.

**Anomalias com contexto.** Cada manifestação consulta o que o jogador já viu, onde ele está
e o que decidiu: a porta que se abre é sempre uma porta que o jogador fechou; a figura nas
câmeras aparece longe do jogador, mas *dentro* do campo de visão de alguma câmera.

---

## Sobrevivência (leve, como pedido)

| Recurso | Como funciona |
|---|---|
| **Oxigênio** | Só cai em setores despressurizados (eclusa inferior). Recarrega na enfermaria. Abaixo de 15% a visão escurece e aparece uma poça/figura que não deveria existir. Zerado: você desmaia e acorda com o filtro "trocado". |
| **Bateria** | A lanterna consome devagar; abaixo de 25% ela pisca. Recarrega na engenharia. A luz forte **dissolve manifestações** — a única forma de "defesa" no jogo, e ela custa energia. |
| **Energia da estação** | Um fusível de 400 A no depósito + a sequência de disjuntores no painel (A2‑B1‑C3‑D4). Restaurar a energia acende a estação **e é o evento que faz o oceano notar você** (Capítulo 1). |

Sem combate. Sem inventário de armas. Sem sustos gratuitos: o horror vem da porta que
estava fechada, da voz que você ainda não conhecia, da pessoa na foto que não deveria existir.

---

## Estrutura narrativa

| Capítulo | Quando começa | O que muda |
|---|---|---|
| **0 — Ruído de fundo** | Ao acoplar | Luz de emergência, atmosfera baixa, SAL‑5 saúda você |
| **1 — Ele percebeu** | Energia restaurada | Portas acordam, passos-eco, primeiras anomalias, glitch mínimo |
| **2 — O Protocolo Espelho** | Ao ler a especificação do projeto | O módulo de observação se abre sozinho; o sino toca; figuras aparecem |
| **3 — Visitantes** | Ao entrar no módulo de observação | Íris aparece; decisão sobre o que você fez com as reproduções |
| **4 — A pergunta** | Ao ler o último registro de Íris | O coro; o console ECHO; a decisão final |

Os quatro finais (**Chamado**, **Silêncio**, **Partida**, **Repetição Nova**) dependem da
confiança e da ressonância acumuladas — isto é, de *como* você tratou cada manifestação,
não apenas da última escolha.

---

## Créditos e referências

Inspirado nos temas de *Solaris* (Stanisław Lem, 1961): a impossibilidade de comunicação,
a inteligência que responde com o que existe dentro de nós, e o oceano como personagem.
Atmosfera com referências declaradas de *2001*, *Alien*, *SOMA* e *Observation* — com
identidade visual e narrativa próprias: estética soviético-industrial retrofuturista,
tecnologia analógica, luz fria e um oceano que nunca é explicado.

Sem explicação definitiva. Ao final, o jogo deve deixar mais perguntas do que respostas.
