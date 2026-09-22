# VOZES DO OCEANO — Documento de design

> Documento que mapeia, item por item, como o pedido original foi implementado em um jogo
> real, rodando em Godot 4.4 — e onde ele deliberadamente **não** entrega respostas.

---

## 1. Premissa

**"E se uma inteligência alienígena tentasse compreender a humanidade reproduzindo aquilo
que existe dentro da nossa própria mente?"**

ÍRIO não ataca, não invade, não negocia. Ele **deduz**. Observou cinco humanos por quatorze
anos, e a única linguagem que aprendeu foi a deles: memória, saudade, culpa, os mortos que
carregamos. Então constrói corpos com água, sal e luz — e espera ver o que acontece.

O jogador chega como o sétimo ponto de dados: alguém com um passado que o oceano ainda não
leu. A pergunta do jogo não é "como derrotar o planeta?", e sim **"por que vocês guardam uns
aos outros?"** — a frase que o coro sussurra no refeitório.

### O que o jogo nunca faz
- Nunca confirma se uma manifestação é corpo real, alucinação, simulação ou tradução.
- Nunca revela se SAL‑5 está comprometida, e nunca deixa de sugerir que sim.
- Nunca mostra "o oceano" como criatura: ele é sempre superfície, comportamento, padrão.
- Nunca premia curiosidade com explicação — recompensa com **correspondência**.

---

## 2. Estrutura do mundo

### A estação ARGOS‑4 (4 conveses, ~11 setores)

```
CONVÉS 4 (y≈76)  MÓDULO DE OBSERVAÇÃO — o vidro de 20 m sobre o mar, a poltrona do
                 Protocolo Espelho, o console ECHO (decisão final)
CONVÉS 3 (y≈64)  COMANDO CENTRAL — núcleo de SAL-5, terminais, CCTV, cofre (código 1104 = 11 de abril)
                 CÂMARA DO SINO — o casco que toca como um sino
                 ECLUSA INFERIOR — despressurizada, a única área que consome O2
                 CORREDOR DE OBSERVAÇÃO
CONVÉS 2 (y≈52)  LABORATÓRIOS — mesas de exame, amostras, onde algo se forma
                 ENGENHARIA — reator, painel de disjuntores (A2-B1-C3-D4), recarga de traje
                 ENFERMARIA — leitos, recarga de O2, relatórios psiquiátricos
                 RÁDIO — transceptor; 6 frequências, uma sem origem
CONVÉS 1 (y≈40)  HANGAR NORTE — a KEPLER-9, o briefing, o fusível de 400 A
                 DEPÓSITO E OFICINA — solda que Andrei não fez
                 CABINES — leitos de Íris e Andrei, fitas, fotografias
                 REFEITÓRIO — a JANELA SUL, as regras da Nadia na parede
                 CORREDOR DE SERVIÇO — mais longo por dentro (anomalia real, geométrica)
```

Cada convés tem um **anel de circulação** em volta de um núcleo selado (com placas de
"NÃO ABRIR" em quatro idiomas pictóricos) — o layout faz você se sentir sempre em movimento
circular, e a circulação é uma peça narrativa: os ecos de passos vêm do outro lado do anel.

### O planeta
- Oceano 2,6 km + plano distante de 9 km, alimentados por um único `ShaderMaterial` global.
- Ondulação orgânica → à medida que a **ressonância** sobe, surgem interferências senoidais
  (grades quadradas), favos hexagonais e espirais logarítmicas de 7, 9 e 11 voltas.
- **Anéis de resposta**: qualquer evento importante dentro da estação emite uma onda que
  atravessa o mar (usado na energia restaurada, no sino e nas manifestações maiores).
- Com ressonância ≥ 6, o mar começa a erguer **imitações de construções humanas** (blocos
  com pavimentos e janelas) — visíveis pelas janelas, nunca explicadas.
- O planeta gigante ao fundo e um campo de estrelas procedural completam o céu.

---

## 3. Gameplay

| Pedido | Implementação |
|---|---|
| Exploração em primeira pessoa | `CharacterBody3D` com head-bob, respiração dinâmica, FOV 78°, lanterna de capacete com sombra, monta-cargas funcionais entre conveses |
| Investigação | 24 documentos em 5 mídias (monitor CRT, papel, fita com forma de onda, fotografia procedural, manual) + 6 sinais de rádio + 11 canais de CFTV + fitas com voz |
| Puzzles | Sequência de disjuntores do reator (pista no manual, na casa de máquinas); teclado numérico do cofre (1104, pista no relatório de Nadia: onze de abril); restauração de energia e de oxigênio; operação de elevadores; válvula de circulação de ar |
| Energia / O2 / recursos | Ver §"Sobrevivência" do README — O2 só cai em zona despressurizada; a lanterna é recurso limitado e instável |
| Decisões que alteram fenômenos | 5 decisões maiores (`orgao`, `gravacao`, `chamado`, `espelho`, `final`) que mexem em **confiança** e **ressonância** — e mudam quais anomalias aparecem depois |
| Sem combate | Não existe dano, morte ou inimigo. A lanterna dissolve manifestações: é defesa, não arma — e custa bateria |
| Medo por atmosfera | Luz de emergência, névoa, trilha em camadas, granulação de HUD que responde à ressonância e ao estresse, inconsistências discretas |

---

## 4. Anomalias — o catálogo do horror lento

17 manifestações, todas registradas no diário do jogador (que nunca explica, só cataloga):

| Anomalia | Como se comporta |
|---|---|
| `porta_aberta` | Uma porta **que o jogador fechou** aparece aberta, longe dele, sem comando |
| `objeto_movido` | Dois objetos próximos trocam de posição, com som, sem testemunha |
| `corredor_estendido` | Uma extensão geométrica real do corredor de serviço se torna visível e sólida ("maior por dentro") |
| `cam_fantasma` | Uma figura aparece **na posição real do mundo** e só pode ser vista pelo CFTV — se o jogador correr até lá, ela já dissolveu |
| `foto_extra` | A fotografia da tripulação passa a ter seis pessoas; a legenda continua "cinco de nós" |
| `radio_voz` | Uma voz sem frequência de origem responde a você no transceptor |
| `eco_passos` | Seus passos ganham uma sombra, meio segundo depois |
| `espelho_agua` | Uma poça reflete uma figura deitada **acima** do teto |
| `sino` | O casco inteiro toca uma nota longa sem percussão, sem fonte, sem transmissão estrutural |
| `manifesto_iris` | Íris aparece no módulo de observação; a versão hostil depende da sua confiança |
| `manifesto_andrei` | Andrei, sentado no sino, entrega o texto em russo que ele nunca escreveu no relatório |
| `coro` | Quatro pessoas sentadas no refeitório, respirando no ritmo errado |
| `terra_falsa` | A janela sul mostra uma cidade que não existe — e depois volta a ser mar |
| `mao_no_vidro` | Marca de mão humana do lado de dentro do vidro, quente e molhada |
| `trilha_molhada` | Pegadas molhadas atravessando o corredor que terminam viradas para a parede |
| `sala_reconstruida` | O refeitório destruído aparece reconstruído — com a tripulação dentro |
| `orgao` | Uma massa de tecido se forma na mesa de exames: calor, membrana, sem batimentos. Só existe para virar **decisão** |

Cada anomalia chama `GameState.add_resonance/add_trust` — ou seja, **cada coisa que você vê
piora (ou aprofunda) o que você vai ver depois**. Ver não é passivo.

---

## 5. Decisões e as duas variáveis escondidas

### Decisão `orgao` — a reprodução se formando
| Escolha | Efeito |
|---|---|
| Deixar terminar | confiança +2, ressonância +1 → Íris aparece e fala |
| Interromper com a lanterna | confiança −2 → as manifestações esfriam, Íris vem hostil |
| Coletar amostra | ressonância +2 → a amostra vira "água, sal e proteínas humanas" |

### Decisão `gravacao` — a tripulação discutia você antes de você chegar
Preservar / apagar / **reenviar para a Terra** (custa energia e acelera o Capítulo 2).

### Decisão `chamado` — a voz pede para ser respondona no rádio
Responder (+confiança) / silenciar (−confiança) / gravar sem responder (+ressonância).

### Decisão `espelho` — reativar ou desligar o Protocolo Espelho de Íris

### Decisão `final` — o console ECHO
Quatro respostas, quatro finais: **Chamado**, **Silêncio**, **Partida**, **Repetição Nova**.
Os finais consultam também a confiança acumulada, então a mesma escolha pode render textos
ligeiramente diferentes em partidas diferentes.

---

## 6. Atmosfera e identidade visual

- **Paleta:** azul-aço (paredes), verde-fósforo (terminais), âmbar (fita/rádio), vermelho de
  emergência. Nada de colorido saturado: contraste 1.12, saturação 0.88, tone mapping filmic.
- **Arquitetura:** painéis de aço com reforço a cada 2,6 m, tubulação aparente, pisos de
  grade metálica, faixas de perigo, placas bilíngues pintadas à mão, consoles de teclado
  analógico, monitores CRT curvos com queima de fósforo.
- **Luz:** todas as salas nascem em luz de emergência (0,15 de energia, vermelha). Restaurar
  a energia é literalmente a transição do primeiro ato: os tubos frios acendem e a estação
  muda de tom.
- **Janelas:** a janela sul do refeitório (15 m) e o vidro do módulo de observação (20 m)
  são as duas "telas" do oceano — os dois lugares onde o fenômeno se manifesta em escala.
- **HUD:** sem números de dano; apenas O2, bateria, objetivo, relógio da estação (que corre
  3× mais rápido que o seu) e legendas. A granulação e a vinheta sobem com a ressonância.
- **Áudio:** trilha em seis camadas (drone grave, pad dissonante, ar, zumbido, mar, pulsação
  lenta), com reverb por barramento; efeitos gerados por síntese — inclusive o "sino" (uma
  soma de harmônicos inarmônicos de 7 segundos, usado como assinatura do planeta).

---

## 7. O que ficou para depois (propositalmente, como ganchos)

- Um módulo de reconstrução de fitas que obrigue o jogador a **escolher** o que ouvir da
  tripulação (e a assumir a consequência de apagar).
- Traduzir os 46 padrões restantes do casco (hoje só o primeiro está decodificado).
- O "coro" na estação de acoplagem no final `d` — o jogo sugere que uma nova cápsula chega.
- Suporte a gamepad e tradução EN/PL (toda a interface é construída em código e localizável
  trocando os dicionários em `scripts/data/`).
