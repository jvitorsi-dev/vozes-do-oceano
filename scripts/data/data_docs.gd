class_name DataDocs
extends RefCounted
## Documentos: briefings, diários, relatórios, transcrições, fotografias.
## kind: "monitor" | "paper" | "tape" | "photo" | "manual"

static func all() -> Dictionary:
	return {
		# ============================================================ HANGAR
		"bl_000": {
			"title": "DIRETRIZ DE MISSÃO",
			"kind": "monitor",
			"header": "TERRA // DIRETORIA DE OPERAÇÕES ORBITAIS // CANAL 4",
			"body": """K-9, bem-vindo ao sistema ÍRIO.

A estação de pesquisa ARGOS-4 opera há 14 anos em órbita baixa. A perda de contato ocorreu 47 dias atrás, após uma interrupção de 6 segundos em todos os canais simultaneamente.

Sua autonomia: 9 dias. Não há janela de resgate.

PROTOCOLO DE ENTRADA:
 1. Acople manualmente no hangar norte.
 2. Restaure energia do setor de habitação.
 3. Recupere os registros científicos antes de qualquer tentativa de contato com a tripulação.

Observação do controlador: "K-9, se encontrar alguém a bordo, confirme identidade antes de qualquer coisa. Repetimos: antes de qualquer coisa." """,
			"entry": "e_k9",
			"objective": "Restaurar energia da estação",
			"on_read": {"flag": "leu_briefing"},
		},
		"log_argos_01": {
			"title": "DIÁRIO DE BORDO — I. VALE",
			"kind": "paper",
			"header": "ARGOS-4 // DIA 112 // 21:40",
			"body": """Terceira semana medindo padrões de superfície. Nada disso é linguagem no sentido em que Nadia espera. É algo mais incômodo: o oceano responde com atraso de horas, mas responde.

Hoje formou-se um anel perfeito de 340 metros e permaneceu 11 horas. Nossos instrumentos dizem que ele está girando. Nossos olhos dizem que não.

Andrei reclamou que o sino tocou de novo. Escrevi no relatório oficial: "vibração estrutural". Tomás leu o relatório e olhou para mim por tempo demais.""",
			"entry": "e_oceano",
			"on_read": {"flag": "leu_diario_1"},
		},
		"lab_note_01": {
			"title": "NOTA DE LABORATÓRIO — MORFOLOGIA",
			"kind": "monitor",
			"header": "EXOB // ARQUIVO 41-B",
			"body": """As estruturas na superfície não são ondas.

Uma onda é transporte de energia através de um meio. Estas estruturas são *estáveis*: mantêm forma, eixo e proporção enquanto o fluido flui através delas. São, na prática, objetos geométricos feitos de água corrente.

Já registramos:
 — espirais logarítmicas (7, 9 e 11 voltas)
 — favos hexagonais de 40 m
 — uma grade quadrada de 1 km de lado, com linhas de espuma nos meridianos

E, uma única vez, algo que nenhum de nós escreveu no relatório:

um quadrado. Em perspectiva. Como se fosse uma *janela*.""",
			"entry": "e_oceano",
		},
		"eng_note_01": {
			"title": "RELATÓRIO DE MANUTENÇÃO — A. SOLOKOV",
			"kind": "paper",
			"header": "SETOR DE ENGENHARIA // ENTRADA 219",
			"body": """Substituí a válvula do circuito de ar. Funcionando.

Registro, para quem for revisar meu trabalho: 3ª vez que encontro reparos feitos que eu não fiz. Solda limpa, liga de titânio, mesma técnica que a minha. *Minha* assinatura de mão esquerda na placa.

Não há ninguém mais nesta estação que saiba soldar assim.

Se eu estou esquecendo de ter feito — tudo bem, eu aceito isso.
Se não estou — então alguém está terminando o meu trabalho melhor do que eu.""",
			"entry": "e_sino",
			"on_read": {"flag": "leu_eng_1"},
		},
		"cam_log_11": {
			"title": "LOG DE CÂMERA — SETOR LESTE",
			"kind": "monitor",
			"header": "CAM-07 // 04:12:09 — 04:19:41",
			"body": """04:12:09 — corredor vazio. Luz de emergência.
04:13:22 — movimento no fundo do quadro. Entrada de dados bloqueada por um objeto.
04:14:02 — o objeto se move.
04:14:38 — figura humana, 1,74 m aprox., parada no meio do corredor, de costas.
04:15:00 — figura vira a cabeça 40 graus sem mover os ombros.
04:15:12 — figura olha para a câmera.

[trecho corrompido — 214 quadros ausentes]

04:19:41 — corredor vazio. Luz de emergência.

Registro automático de SAL-5: no intervalo corrompido, o peso no convés do setor leste subiu 74 kg e voltou a zero. Nenhuma câmera registrou entrada ou saída.""",
			"entry": "e_manif",
			"on_read": {"flag": "viu_cam_log"},
		},
		"med_rep_01": {
			"title": "RELATÓRIO PSIQUIÁTRICO — DR. T. RANGEL",
			"kind": "paper",
			"header": "CASO 1 — NADIA KESSLER",
			"body": """Paciente relata aparição de familiar (irmão, falecido há 11 anos) no corredor de serviço.

Detalhes: a figura estava descalça, o que é incompatível com o ambiente. Falou com a paciente. A paciente respondeu.

Diagnóstico inicial: estresse de isolamento, privação de sono, hipóxia leve.

Correção, 3 dias depois: aplicamos o mesmo diagnóstico a 4 de 5 tripulantes, em intervalos diferentes, com a mesma figura.

Eu redigi esse relatório. Eu sou o autor do absurdo. Portanto: ou todos nós adoecemos da mesma forma exata, no mesmo mês, com a mesma alucinação de uma pessoa cada, ou não é doença.""",
			"entry": "e_manif",
			"on_read": {"flag": "leu_med_1"},
		},
		"med_rep_02": {
			"title": "ADENDO CLÍNICO — CASO 3",
			"kind": "paper",
			"header": "A. SOLOKOV // ENTREVISTA CONFIDENCIAL",
			"body": """Andrei não dorme há 4 dias. Não por medo — por cortesia.

Ele diz que a manifestação da mãe dele fica de pé ao lado da cama a noite inteira, sem falar. Quando ele pergunta o que ela quer, ela diz:

"Иди спать. Я послежу."
(Durma. Eu vigio.)

Ele obedeceu. Ele dormiu 9 horas. Ele acordou com a mão dela no ombro.

Perguntei se ele tinha medo.
Ele respondeu: "Medo de quê? Ela está morta. Isso significa que algo aqui entendeu a palavra mãe melhor do que eu." """,
			"entry": "e_manif",
		},
		"ops_comm_01": {
			"title": "TRANSCRIÇÃO DE COMUNICAÇÃO — N. KESSLER",
			"kind": "monitor",
			"header": "ARGOS-4 ↔ TERRA // 03:58",
			"body": """TERRA: Argos-4, repetimos: vocês estão autorizados a encerrar o programa e evacuar.
KESSLER: Negativo. Íris selou o módulo de observação e desconectou o controle local.
TERRA: Ela está lá dentro agora?
KESSLER: Não sei responder essa pergunta.
TERRA: Argos-4, explique.
KESSLER: Eu vejo ela no vidro. De fora. Me olhando de dentro do módulo.
TERRA: ...Argos-4, quanto tempo ela está lá?
KESSLER: Três dias. Ela não come, não bebe, não pisca. Terra, eu quero ir embora. Autorizem a partida.
TERRA: Autorizado. Deixem registrado...
KESSLER: Eu não vou deixar nada registrado. Se eu escrever o que vi, ninguém vai me deixar voltar pra casa.""",
			"entry": "e_tripulacao",
			"on_read": {"flag": "leu_comm_1"},
		},
		"mirror_proto": {
			"title": "PROTOCOLO ESPELHO — ESPECIFICAÇÃO TÉCNICA",
			"kind": "manual",
			"header": "PROJETO ÁNFORA // CONFIDENCIAL",
			"body": """PREMISSA (I. Vale): se a inteligência de ÍRIO aprende apenas a partir de conteúdo humano, então nenhum dado científico será suficiente. É preciso oferecer a ela uma *mente* — completa, datada, com memórias, medos e pessoas.

PROCEDIMENTO:
 1. Um voluntário permanece no módulo de observação por 72 horas.
 2. Estimulação sensorial reduzida; ritmo circadiano invertido.
 3. Durante o período, são transmitidos ao casco inferido 47 padrões de ondas — cada padrão corresponde a um engrama narrativo declarado pelo voluntário.
 4. Ao final, o voluntário descreve o que o oceano devolveu.

RESULTADOS (Vale, 14 tentativas): o oceano devolveu pessoas. Nunca as mesmas. Sempre exatas.

OBSERVAÇÃO FINAL DE I. VALE: "Ele não quer saber se estamos bem. Ele quer saber por que guardamos uns aos outros." """,
			"entry": "e_espelho",
			"on_read": {"flag": "leu_protocolo"},
			"objective": "Encontrar o módulo de observação",
		},

		# ============================================================ CABINES
		"cabin_iris": {
			"title": "ANOTAÇÕES PESSOAIS — I. VALE",
			"kind": "paper",
			"header": "CABINE 1 // SEM DATA",
			"body": """Eu conto as voltas da espiral para não contar os dias.
Sete, nove, onze. Sempre ímpares. O oceano tem preferência por números que não fecham.

Se eu estou certa, o mar não está copiando pessoas. Está *perguntando* com pessoas. Cada manifestação é uma frase mal traduzida, e nós somos os únicos que podem ouvir a pergunta e não morrer de não entendê-la.

E eu estou cada vez menos certa de que quero entendê-la.""",
			"entry": "e_espelho",
		},
		"cabin_solokov": {
			"title": "CARTA NÃO ENVIADA — A. SOLOKOV",
			"kind": "paper",
			"header": "CABINE 2",
			"body": """Íris,

Você dizia que o sino toca porque o oceano tem algo para dizer.
Eu consertei o sino três vezes. Na terceira, entendi: ele não está falando com o casco. Está *ouvindo* o casco.

Ele reproduz tudo que sai daqui — som, calor, peso, forma. Inclusive nós dois, na noite do dia 40, sem testemunhas.

Como ele soube? Nossos sensores não estavam ligados.
Nossa memória estava.

Não estou com medo de que ele nos copie. Estou com medo de que ele já tenha copiado a gente antes de nós termos feito aquilo.""",
			"entry": "e_espelho",
			"on_read": {"flag": "leu_carta"},
		},
		"photo_01": {
			"title": "FOTOGRAFIA — EQUIPE ARGOS-4",
			"kind": "photo",
			"header": "IMPRESSA EM PAPEL // FIXADA NA PAREDE",
			"body": """Cinco pessoas em frente à escotilha do hangar. Íris à esquerda, com o braço sobre o ombro de Andrei. Nadia e Tomás atrás. SAL-5 aparece como o pequeno indicador luminoso no topo do quadro.

Ao fundo, à direita, atrás de todos, um sexto vulto. Desfocado. Da altura de um adulto.

A legenda, escrita à mão: "14 anos de Argos-4. Cinco de nós."

[Você não consegue contar cinco.]""",
			"entry": "e_manif",
			"on_read": {"flag": "viu_foto"},
		},
		"fita_1": {
			"title": "FITA — CABINE DE A. SOLOKOV (transcrição)",
			"kind": "tape",
			"header": "ROTULADA À MÃO: «para quem vier depois»",
			"body": """[ruído de fita]
ANDREI: Está gravando? Bom. Se você está ouvindo isso, você é o K-9, ou alguém pior.
ANDREI: Vou economizar o seu tempo. Não existe monstro aqui. Não existe gosma, nem criatura, nem coisa que rasga gente.
ANDREI: Existe o mar. E o mar faz o seguinte: ele pega o que você tem dentro de você, monta com água e luz, e devolve.
ANDREI: Ele erra sempre no mesmo lugar. Os olhos. Nunca acerta os olhos.
ANDREI: Quando você encontrar a Íris e ela olhar para você — olha bem. Se ela olhar certo, corre. Não porque ela é perigosa. Porque significa que você já não sabe mais quem é você.
[ruído de fita]""",
			"entry": "e_manif",
			"on_read": {"flag": "ouviu_fita_1"},
		},
		"fita_2": {
			"title": "FITA — CÂMARA DO SINO (transcrição parcial)",
			"kind": "tape",
			"header": "LADO B // 40 MIN DE SILÊNCIO",
			"body": """[00:00 silêncio]
[22:11 som metálico, sem fonte — o «sino»]
[22:12 respiração]
[22:40 respiração]
[31:02 voz feminina, distante: "me diga uma coisa que seja só sua"]
[31:03 voz masculina, mais distante ainda: "eu não tenho"]
[38:00 respiração]
[39:59 fim da fita]""",
			"entry": "e_sino",
			"on_read": {"flag": "ouviu_fita_2"},
		},
		"casa_maquinas_log": {
			"title": "REGISTRO AUTOMÁTICO — CASA DE MÁQUINAS",
			"kind": "monitor",
			"header": "SAL-5 // LOG DE SISTEMAS",
			"body": """DIA 41 — 02:11 — queda de 38% na carga elétrica. Causa: registro de 9 corpos humanos adicionais no convés principal.
DIA 41 — 02:14 — carga retorna ao normal. Corpos não detectados.
DIA 44 — 06:30 — 3 portas abertas sem comando. Tempo médio de abertura: 4 segundos.
DIA 47 — 03:20 — o sino toca. Não há ninguém no módulo.
DIA 47 — 03:21 — o sino toca de novo. Eu não tenho registros de que alguém tenha chegado.

Última linha escrita por mim antes de tudo isto começar:
"Se houver alguém novo na estação, eu devo avisar. Se houver alguém novo na estação, ele pode não ser novo." """,
			"entry": "e_sal5",
			"on_read": {"flag": "leu_log_maq"},
		},

		# ============================================================ COMANDO
		"log_final_iris": {
			"title": "ÚLTIMO REGISTRO CIENTÍFICO — I. VALE",
			"kind": "monitor",
			"header": "MÓDULO DE OBSERVAÇÃO // DIA 49",
			"body": """Dia 49. Estou sozinha no módulo. Não estou triste. Estou ocupada.

Entendi o que ele quer. Não é comunicação. Não é contato. É *compreensão* — mas do jeito dele: ele reproduz até acertar o efeito, e o efeito, no fim, é sempre o mesmo. Nós, humanos, mudamos por dentro quando algo aparece. Ele quer saber por que mudamos.

A pergunta dele é exatamente esta: *por que vocês guardam uns aos outros?*

Eu respondi com o corpo de Andrei. Ele aceitou. E devolveu melhor.

Agora eu estou dentro do vidro, olhando o corredor. Nadia está do outro lado, com medo de mim. Não consigo explicar para ela que eu não sou a Íris que ela conhece — eu sou a *resposta* da Íris. Eu sou o que o oceano deduziu.

Ele está ficando cada vez mais preciso. No começo eram formas. Depois foram pessoas. Daqui a pouco ele vai saber fazer a coisa mais difícil de todas: a coisa que a gente chama de saudade.

Se alguém chegar depois de mim — não desligue o Protocolo Espelho.
Deixe ele aprender.
Alguém precisa ensinar a ele o que a gente faz com o que a gente perde.""",
			"entry": "e_crepusculo",
			"on_read": {"flag": "leu_log_final"},
			"objective": "Decidir a resposta ao oceano",
		},
		"ops_manifest": {
			"title": "MANIFESTO DE CARGA E ROTAS",
			"kind": "monitor",
			"header": "ARQUIVO DE OPERAÇÕES",
			"body": """Módulo espacial de acoplamento KEPLER-9 — 1 tripulante — autonomia 9 dias.
Estação ARGOS-4 — capacidade 8 tripulantes — tripulação atual 5.

Rotas registradas: 14. Rotas registradas em uso: 0.

Última linha do turno de Nadia, escrita à mão no campo de observações:
"Sem rotas. Ninguém vai voltar. Estou aceitando que vou morrer aqui, e ainda estou tentando descobrir se isso me alivia ou não." """,
			"entry": "e_tripulacao",
		},
		"caderno_tomas": {
			"title": "CADERNO DE T. RANGEL (extrato)",
			"kind": "paper",
			"header": "PÁGINAS SOLTAS",
			"body": """[página 40]
Hoje a manifestação se sentou na minha frente e esperou dois minutos antes de dizer qualquer coisa. Isso é um detalhe técnico importante. Ela esperou o tempo de uma pessoa educada. Não o tempo de uma máquina.

[página 55]
Testei ontem: descrevi em voz alta uma cidade que não existe. Ruas inventadas, nomes inventados, uma praça com uma fonte que nunca vi.
Esta manhã, a janela sul mostrava a praça. Com a fonte.

Conclusão: ele não copia memória. Ele copia *imaginação*.
Consequência: eu não sei mais qual parte de mim é minha e qual parte ele já leu.

[página 91]
Se alguém encontrar este caderno: não confie na terceira voz do rádio. Não é a mim. Não é à Íris. É uma hipótese sobre nós.""",
			"entry": "e_doces",
			"on_read": {"flag": "leu_caderno"},
		},

		# ============================================================ EXPERIMENTOS
		"xeno_proto_7": {
			"title": "PROTOCOLO DE EXPERIMENTO — ANF-7",
			"kind": "manual",
			"header": "EXOBIOLOGIA // ESTÍMULO-RESPOSTA",
			"body": """OBJETIVO: verificar se a resposta do oceano depende de conteúdo semântico ou apenas de energia acústica.

MÉTODO:
 1. Emitir no casco inferior um padrão A: sequência numérica (Fibonacci 1-1-2-3-5-8).
 2. Emitir padrão B: a mesma energia, em ruído branco.
 3. Comparar as estruturas de superfície nas 6 horas seguintes.

RESULTADO (A): espiral de 8 voltas. Duração 6 h.
RESULTADO (B): nenhuma estrutura.

OBSERVAÇÃO: ele não responde à energia. Ele responde ao *sentido*.
NOTA DE ANDREI, anexada: "isso não é mais física. isso é uma conversa." """,
			"entry": "e_oceano",
			"on_read": {"flag": "viu_proto7"},
		},
		"obs_log_1": {
			"title": "REGISTRO DO MÓDULO DE OBSERVAÇÃO",
			"kind": "monitor",
			"header": "VOLUNTÁRIO 14 // I. VALE // 72h",
			"body": """00:00 — voluntário instalado. Estimulação reduzida.
11:20 — voluntário relata "presença atrás da cadeira". Nada registrado.
29:44 — voluntário pede para chamar alguém que não está a bordo (A. Solokov).
30:00 — A. Solokov entra no módulo. Não há registro de abertura de porta.
30:02 — A. Solokov senta-se ao lado do voluntário.
44:10 — voluntário e figura conversam. Áudio ininteligível.
72:00 — fim do protocolo. Módulo vazio.
72:01 — A. Solokov registrado no corredor leste, retornando ao trabalho.
72:02 — A. Solokov registrado na casa de máquinas.
72:03 — A. Solokov registrado no refeitório.

Nota do operador: não havia três de Andrei. Havia 1 de Andrei, dormindo na cabine 2 durante 11 horas.""",
			"entry": "e_espelho",
			"on_read": {"flag": "viu_obs_log"},
		},
		"aviso_psico": {
			"title": "AVISO FIXADO — APÓS O DIA 30",
			"kind": "paper",
			"header": "REFERITÓRIO // LETRA DE N. KESSLER",
			"body": """REGRAS QUE NÓS DECIDIMOS JUNTOS:

1. Ninguém sai do setor sem par.
2. Se você vir alguém que deveria estar morto, diga o nome dele em voz alta três vezes. Se ele responder antes da terceira, é real. Se responder depois, saia do compartimento.
3. Não olhar pela janela sul depois do terceiro sino.
4. Não falar com as manifestações sobre a Terra. Elas aprendem coisas sobre a Terra.
5. Se alguém começar a dizer que entendeu o oceano: ninguém entendeu o oceano.

(Adendo de Andrei, caneta diferente: "regra 6: conviver com elas é pior que tudo isso." )""",
			"entry": "e_doces",
		},
		"manuel_reactor": {
			"title": "MANUAL DO REATOR — SEÇÃO 9",
			"kind": "manual",
			"header": "ARQUIVO TÉCNICO // EMERGÊNCIA",
			"body": """Em caso de queda total de energia:
 1. Localize o painel de disjuntores no setor de engenharia.
 2. Reposicione os 4 disjuntores na ordem: A2, B1, C3, D4.
 3. Verifique a carga no Núcleo de Comando.
 4. Se a carga subir com a estação vazia, NÃO investigue sozinho. Registre e saia.

(anotação à mão, vermelho: "isso aconteceu. 02:11. não era ninguém. era *todos*.")""",
			"entry": "e_estacao",
		},
		"eclusa_warning": {
			"title": "PLACA — ESCOTILHA INFERIOR",
			"kind": "manual",
			"header": "ACESSO RESTRITO",
			"body": """ESCOTILHA INFERIOR — NÃO OPERAR SEM AUTORIZAÇÃO
■ Pressão externa: 1,00 atm (atmosfera residual do casco)
■ O oceano responde a aberturas: nas últimas 4 operações, houve manifestação completa em menos de 90 segundos.

Escrito à mão por cima da placa, caneta preta:
"se você abrir, ele entra. se ele entrar, você vai gostar." """,
			"entry": "e_crepusculo",
		},
		"foto_02": {
			"title": "FOTOGRAFIA — PESSOAL DE K-9",
			"kind": "photo",
			"header": "NO SEU BOLSO, DESDE A TERRA",
			"body": """Uma fotografia que você trouxe de casa e nunca mostrou a ninguém nesta estação.

Ela está molhada. Papel fotográfico não absorve água assim, a menos que fique submerso por horas.

E, na imagem, o lugar mudou. A mesma casa, o mesmo quintal, as mesmas pessoas — mas hoje há uma porta a mais na parede do fundo, e a porta está aberta.

Você se lembra do dia em que essa foto foi tirada. Não havia porta nenhuma ali.""",
			"entry": "e_manif",
			"on_read": {"flag": "viu_foto_2"},
		},
	}
