# VOZES DO OCEANO — Manual de bordo

*Leia isto como se fosse o manual que veio na cápsula. Sem spoilers de enredo.*

---

## 1. Você

Você é **K‑9**. Chegou sozinho, sem equipe de resgate e sem janela de retorno.
A estação está sem energia, sem tripulação e sem explicação.

**Seu objetivo visível:** restaurar a energia, recuperar os registros científicos e
descobrir o que aconteceu.
**Seu objetivo real:** o jogo vai mudar essa frase sozinho.

---

## 2. Controles

| Tecla | Ação |
|---|---|
| `W A S D` | Andar |
| `Mouse` | Olhar |
| `SHIFT` | Correr |
| `CTRL` | Agachar |
| `E` | Interagir, ler, confirmar |
| `F` | Lanterna de capacete |
| `TAB` | Diário de bordo |
| `ESC` | Pausa / opções / salvar |
| `← →` | Alternar entre documentos, canais de rádio, câmeras |
| `N` | (no leitor) avançar registro |

Quando um painel está aberto, o mouse é liberado automaticamente.

---

## 3. Primeiros quinze minutos

1. Você acorda no **hangar norte**, ao lado da sua cápsula. Garimpe o hangar: há um
   **terminal** com o briefing da missão.
2. A estação está sem energia. Procure o **depósito** (oeste do anel, convés 1):
   há um **fusível de 400 A** sobre uma caixa. Pegue.
3. O painel de energia fica na **engenharia** (anel do convés 2). Ele pede uma sequência
   de disjuntores — a resposta está no *Manual do Reator, seção 9* (terminale do depósito).
4. Quando a energia voltar, **preste atenção no que muda**. É aí que o jogo começa.

**Terminais de emergência** (hangar, depósito, cabines e o reprodutor de fitas) funcionam
antes de a energia voltar: é por eles que você começa a entender a estação.

**Mouse** — três formas de olhar, na ordem em que você deve tentar:
1. Normal: ao começar a expedição o cursor fica preso ao jogo.
2. Se ele escapar (alt-tab, aviso do sistema, janela sem foco): clique uma vez dentro
   da janela, ou aperte **F1**.
3. Se o sistema **negar** a captura (navegador, tela cheia bloqueada, alguns Linux/macOS):
   **segure o botão esquerdo e arraste** para olhar. O rodapé avisa quando é esse o caso.
**F3** abre o diagnóstico do mouse (modo do cursor, janela, escala, sensibilidade). A sensibilidade fica em **ESC → SISTEMA → Sensibilidade do
mouse** e é guardada junto do progresso.

**Monta-cargas**: no corredor existe um painel "Chamar monta-carga" que traz a plataforma
para o seu nível; para subir, fique **em cima da plataforma** e use o painel "Operar
monta-carga" (se apertar do lado de fora, ela avisa e não parte).

---

## 4. Sistemas

### Lanterna e bateria
`F` acende. Ela consome bateria devagar e pisca abaixo de 25%. Recarregue no **ponto de
recarga** da engenharia. Importante: **luz forte dissolve manifestações** — é a única
forma de intervenção física no jogo. Ela não machuca nada; ela *interrompe*.

### Oxigênio
Só cai em setores despressurizados (a **eclusa inferior**, no convés 3). Recarregue na
enfermaria. Se zerar, você desmaia — e acorda em outro lugar, com o filtro trocado.

### Portas
Portas com luz **verde** estão abertas, **vermelha** fechadas, **âmbar** travadas.
Cartões de acesso abrem travas específicas; há um cartão de engenharia no cofre do comando.

### Salvar
`ESC` → **SISTEMA** → salvar/carregar. O jogo também salva automaticamente ao terminar
uma partida.

---

## 5. Onde procurar as coisas

| Setor | Convés | O que tem |
|---|---|---|
| Hangar Norte | 1 | KEPLER-9, briefing, caixas |
| Depósito / Oficina | 1 | Fusível 400 A, manual do reator, relatório de solda |
| Cabines | 1 | Fitas, fotografias, cartas que ninguém enviou |
| Refeitório | 1 | A janela sul, as regras coladas na parede, hidroponia |
| Laboratórios | 2 | Relatórios de morfologia, mesa de exames, estações de amostra |
| Engenharia | 2 | Reator, recarga de traje, log da casa de máquinas |
| Enfermaria | 2 | Relatórios psiquiátricos, recarga de O2 |
| Rádio | 2 | Transceptor: 6 frequências, uma delas sem origem |
| Comando | 3 | SAL-5, CCTV, cofre (código de 4 dígitos escondido num relatório) |
| Câmara do Sino | 3 | O casco que toca; fita com 40 minutos de silêncio |
| Módulo de Observação | 4 | O Protocolo Espelho, o vidro, o console ECHO |

---

## 6. Como se comportar diante do que aparecer

O jogo registra tudo o que você faz — inclusive do que você **não** faz.

- Manifestações **não são hostis**, mas não suportam serem tocadas: se você chegar perto
  rápido demais, elas se desfazem em água. Isso conta como interrupção.
- Interromper, silenciar, apagar: reduz a **confiança** do oceano em você. As manifestações
  seguintes ficam mais frias, mais erradas nos olhos, mais parecidas com gente.
- Observar, ouvir, deixar terminar: aumenta a confiança. Elas começam a fazer perguntas.
- Presenciar anomalias aumenta a **ressonância**. Com ressonância alta, o oceano muda de
  comportamento (estruturas geométricas, imitações de construções) e o HUD começa a falhar.

Nada disso aparece em números na tela. Você percebe pelo comportamento delas.

---

## 7. Perguntas que o jogo não responde (e que você vai fazer)

- A pessoa na sua frente é um corpo, uma hipótese, um decodificador ou um pedido?
- SAL‑5 está comprometida ou apenas leal?
- A sala reconstruída foi um presente, uma demonstração ou um teste?
- O oceano está tentando entender vocês — ou está tentando **você**?
- Se ele acertar os olhos na próxima vez, o que você vai fazer?

---

## 8. Problemas comuns

| Sintoma | Solução |
|---|---|
| O jogo não abre | Precisa de Vulkan; tente `--rendering-driver opengl3` |
| Sem som | O jogo sintetiza áudio em tempo real; verifique se não há driver "dummy" no ambiente |
| Não consigo ler um documento | Alguns terminais exigem energia restaurada |
| Uma porta não abre | Pode estar travada (luz âmbar) ou sem energia |
| Achei que estava perdido | `TAB` mostra objetivo atual, registros e anomalias testemunhadas |
