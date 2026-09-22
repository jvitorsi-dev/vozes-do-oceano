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

## Rodada 3 — o retorno do jogador: mouse, texturas e preview no navegador

O jogador reportou três coisas: "o mouse continua não funcionando", "algumas texturas
estão estranhas ou simples demais" e pediu para testar direto no navegador.

### O que foi descoberto (e é importante)

1. **As builds que o jogador baixou eram de código ANTIGO.** Os arquivos grandes do
   motor (1,2 GB de templates + 180 MB de ferramentas) ficavam dentro do workspace e
   estouravam o limite de snapshot: a cada rodada o projeto voltava para uma versão
   anterior, e a exportação saía daquele código. Isso explica o mouse "não funcionar"
   mesmo depois das correções. **Agora o toolchain vive fora do workspace** (`/opt/godot`)
   e as builds saem em `dist/` — o projeto não pode mais ser revertido por tamanho.
2. **O jogo é Forward+ (Vulkan), mas todas as capturas de conferência usavam o
   renderizador de compatibilidade (OpenGL)** — que ignora oclusão de ambiente,
   reflexos e neblina volumétrica. Ou seja: eu estava avaliando um jogo diferente do
   que o jogador vê. As capturas passaram a usar Vulkan.
3. **No navegador a captura do cursor é bloqueada** dentro de iframe de preview. Sem
   uma alternativa, o mouse parece "não funcionar" ali de verdade.

### Correções desta rodada

| # | Item | O que mudou |
|---|---|---|
| 14 | Olhar com o mouse | Além da captura + auto-recaptura + F1, agora existe **arrasto com o botão esquerdo**: segure e arraste para olhar. Funciona SEMPRE — navegador, iframe, Wayland, macOS sem permissão, janela sem foco. O aviso no rodapé aparece quando o sistema nega a captura |
| 15 | Diagnóstico | **F3** mostra na tela: modo do cursor, se está capturado, tamanho da janela, resolução interna, escala e sensibilidade. É a informação que faltava para diagnosticar remotamente |
| 16 | Texturas | Reescritas do zero: **albedo + normal + rugosidade/metalicidade (ORM)** gerados de um campo de altura. Padrões: painéis rebitados, grade de piso, azulejo, teto perfurado, metal escovado, ferrugem com escorrimento, trama de tecido, listras de perigo. **Mapeamento triplanar em coordenadas de mundo** (fim do esticamento) |
| 17 | Materiais novos | `wall_blue` (cabines), `wall_rust` (depósito), `tile_wall` (refeitório e enfermaria), `floor_plate` (hangar, engenharia, labs), `pipe` (tubulações). Cada setor tem paleta própria — antes tudo era o mesmo cinza |
| 18 | Iluminação | **SSAO** (encaixa móveis no espaço), **SSIL**, **SSR** (piso e vidro refletem), **neblina volumétrica** (ar com corpo e feixes de luz), glow mais fotográfico. Lâmpadas: alcance 9 → 14 m, energia maior, ambiente de emergência mais legível |
| 19 | Teste no navegador | **Build web (WebGL2) servida em `http://localhost:8080`** para o jogador testar sem baixar nada — com o arrasto funcionando no lugar da captura bloqueada |

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
