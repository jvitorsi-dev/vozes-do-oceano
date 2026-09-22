# RELATÓRIO DE PLAYTEST — VOZES DO OCEANO

*Rodada automatizada: um jogador-robô (iniciante, sem conhecer o jogo) foi colocado no
hangar e jogou até os créditos finais. Tudo abaixo foi observado em execução real
do jogo (Godot 4.4, OpenGL3), não em teste unitário.*

## Resultado final

```
[BOT] verificações ok: 69      (rodada 2, jogada no BUILD EXPORTADO)
[BOT] avisos: 4                (enroscos leves em móveis, todos contornados)
[BOT] falhas: 0
[BOT] screenshots: 15 em /home/user/bot_shots
```

O robô: pulou a abertura de texto, leu os terminais de emergência, pegou o fusível,
chamou e operou o monta-carga, restaurou a energia pelo teclado de disjuntores,
testou a lanterna e a bateria, leu o Protocolo Espelho (capítulo 2), sintonizou o
rádio, abriu o cofre, ouviu a fita do sino, viu a porta selada se abrir sozinha,
subiu no módulo de observação, olhou a janela para o oceano e respondeu ao ECHO
— chegando ao desfecho com a tela de final e os barramentos de áudio íntegros.

## Rodada 2 — o mouse e o áudio do build

Depois do relato de "o mouse não está funcionando no jogo", a rodada 2 passou a
testar o mouse de verdade: o robô injeta movimento e cliques como o sistema
operacional entrega (antes ele mirava a câmera por código — por isso esse
caminho nunca tinha sido testado).

| # | Sintoma sentido pelo jogador | Causa | Correção |
|---|---|---|---|
| 9 | Mouse para de responder depois de alt-tab, aviso do sistema ou lançamento sem foco | não havia NENHUMA recuperação de captura: o cursor voltava a ficar solto e ficava assim para sempre | auto-recaptura (0,35 s) sempre que o jogo está jogável + recaptura no clique dentro da janela + recaptura quando a janela volta ao primeiro plano; se o sistema recusar `CAPTURED`, cai para `CONFINED_HIDDEN`; aviso no rodapé: "CLIQUE NA JANELA PARA OLHAR COM O MOUSE" |
| 10 | Câmera gira diferente conforme o tamanho da janela (rápida demais em janela pequena) | o olhar usava `relative`, que é **multiplicado pela escala do viewport** (medido: 2,50× a mais em 640×360 com HUD de 1600×900) | olhar passa a usar `screen_relative` (pixels de tela, imune à escala) — medido 1,00× em 640×360 e em 1280×720 |
| 11 | — | o mesmo [E] que abre um painel podia fechá-lo no quadro seguinte | o jogador consome o evento; painéis ignoram input nos 2 primeiros quadros |
| 12 | Movimento relativo podia ser engolido por Controles do HUD | vários Controles do HUD nasciam com `mouse_filter = STOP` | HUD inteiro com `IGNORE`; olhar tratado em `_input` (antes de qualquer GUI) |
| 13 | **No build entregue, a tripulação estava MUDA** (as 9 vozes não carregavam) | `_load_voices()` listava o diretório com `DirAccess`, que **não enumera `res://` dentro de um `.pck` exportado** | lista explícita de vozes + varredura de diretório só como conveniência do editor; agora o build carrega as 9 e a voz realmente toca (verificado: 15,1 s de áudio) |

Testes novos que pegam isso para sempre (`scripts/dev/playbot.gd`):
captura do cursor durante o jogo, rotação horizontal e vertical pelo movimento
relativo, recuperação depois de o sistema soltar o cursor, olhar funcionando
mesmo com o cursor solto, sensibilidade medida em duas resoluções, clique real
no botão "NOVA EXPEDIÇÃO" do menu (modo `-- --play-menu`) e voz tocando de fato.

O ajuste de sensibilidade continua em **ESC → SISTEMA** (agora persistido no save),
com faixa de 0,0008 a 0,006 rad por pixel de tela.

## Defeitos encontrados e corrigidos (rodada 1)

| # | Sintoma sentido pelo jogador | Causa | Correção |
|---|---|---|---|
| 1 | Terminais do hangar/depósito respondiam "SEM ENERGIA" antes do reator ligar — o jogo travava na primeira porta lógica | a checagem de energia do console não considerava terminais de emergência | monitores agora carregam `needs_power`; esses terminais têm `{"needs_power": false}` |
| 2 | Apertar "Chamar monta-carga" no corredor mandava a plataforma para o OUTRO convés | o painel de chamada usava a mesma lógica do painel da plataforma | painéis de chamada carregam `call_to` ("bottom"/"top"); se já estiver no nível, a tela diz isso |
| 3 | Um documento abria e fechava no mesmo instante (parecia piscar) | o mesmo [E] que abria o painel era entregue ao painel recém-criado | o jogador consome o evento (`set_input_as_handled`) e os painéis ignoram input nos 2 primeiros quadros |
| 4 | O cofre nunca abria: a pista dizia "onze de abril" mas o teclado aceitava outro número | código `1147` divergindo da pista | código agora é `1104` (11/04 = onze de abril) |
| 5 | Os elevadores bloqueavam o corredor inteiro e o painel do monta-carga B nascia dentro do núcleo selado | poços de 3,1 m atravessando corredores de 4 m | poços e plataformas re-dimensionados (2,5 m) com faixa caminhável ao lado |
| 6 | A plataforma subia deixando o jogador no chão (ou escorregava da borda) | tampo nivelado com o piso + viagem sem contenção | tampo 0,17 m acima do piso (há subida de degrau), aviso "suba na plataforma" e o passageiro é mantido sobre a plataforma |
| 7 | A porta da antessala para o módulo de observação era uma caixa sólida: o final do jogo era inalcançável a pé | "moldura" da passagem construída como bloco cheio | virou dois batentes laterais + verga, com o vão livre |
| 8 | Ao chegar na Sala Segura o robô ficava sem saída com o teclado aberto depois de um código errado | o robô não fechava painéis | jogador-robô fecha painéis antes de andar (robustez do teste) |

Também foram conferidos: 4 barramentos de áudio (Music/SFX/Voice/Radio), 9 falas de
voz carregadas, camadas de trilha ativas, HUD legível em 1280×720 (objetivo, relógio,
setor, O2/bateria, legendas) e a geometria dos quatro convés (D1..D4).

## O que ainda precisa de olho humano

* **Áudio**: o ambiente de teste não tem saída de som (driver "dummy"), então as vozes,
  a ambiência do casco e a trilha foram verificadas estruturalmente, não de ouvido.
* **Sensação de jogo**: ritmo, dificuldade dos puzzles, sustos lentos e legibilidade
  no escuro pedem uma sessão humana — o robô só prova que tudo funciona de ponta a ponta.
* Avisos de percurso registrados (sem falha): esbarrões em caixotes no depósito, entre
  consoles no comando e na soleira da câmara do sino. São móveis, não bloqueios.

*Regerar esta rodada:*
```bash
xvfb-run -a --server-args="-screen 0 640x360x24" \
  $G --path . --resolution 640x360 --rendering-driver opengl3 --quit-after 60000 -- --play
```
