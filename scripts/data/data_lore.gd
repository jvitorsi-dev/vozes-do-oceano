class_name DataLore
extends RefCounted
## Lore: entradas do PDA, anomalias, decisões, diálogos e sinais de rádio.

static func entries() -> Dictionary:
	return {
		"e_estacao": {
			"title": "ARGOS-4",
			"body": "Estação orbital de pesquisa. Órbita baixa sobre o planeta ÍRIO.\nTripulação: 5 humanos + a inteligência de bordo SAL-5.\nFunção oficial: estudo da biosfera oceânica e do que a Diretoria chamava de «comportamento emergente».\nPerda de contato: 47 dias.",
		},
		"e_k9": {
			"title": "VOCÊ — KEPLER-9",
			"body": "Módulo de acoplamento monoplace. Sem escolta, sem equipe de resgate, sem retorno programado.\nSua missão nominal: avaliar a estação, recuperar registros, decidir se ela pode ser reativada.\nSua missão real, no rodapé do documento: «determinar a natureza do fenômeno e sua relação com a tripulação».",
		},
		"e_tripulacao": {
			"title": "TRIPULAÇÃO DE ARGOS-4",
			"body": "ÍRIS VALE — chefe científica, xenobiologia. 43 anos.\nANDREI SOLOKOV — engenharia de sistemas. 51 anos.\nDR. TOMÁS RANGEL — medicina e psiquiatria de bordo. 38 anos.\nNADIA KESSLER — piloto e operações. 34 anos.\nSAL-5 — inteligência de bordo, protocolo de continuidade.\nNenhum deles foi encontrado. Nenhum corpo foi encontrado.",
		},
		"e_oceano": {
			"title": "ÍRIO — O OCEANO",
			"body": "Cobertura oceânica: 99,4% da superfície.\nOndas de até 40 metros. Estruturas de interferência com simetria de até 11 eixos, estáveis por horas.\nMassa total calculada: incompatível com a estabilidade orbital observada.\nNota de Tomás, à margem: «O número não é o problema. O problema é que ele se repete.»",
		},
		"e_espelho": {
			"title": "O QUE ELES TENTARAM",
			"body": "Não estavam apenas medindo o oceano. Estavam tentando conversar.\nA ideia era de Íris: se a inteligência do planeta só sabe responder ao que existe dentro de nós, então era preciso oferecer a ela um pensamento — inteiro, organizado, datado — e ver o que voltava.\nEles chamaram isso de Protocolo Espelho.\nEles não previram que, para responder, o oceano precisaria usar as pessoas.",
		},
		"e_manif": {
			"title": "MANIFESTAÇÕES",
			"body": "Testemunhos da tripulação, em ordem cronológica:\n1. Objetos fora de lugar, portas e corredores que não fecham como deveriam.\n2. Primeira figura: um homem no corredor de serviço, cerca de 20 segundos.\n3. Reprodução de sons: vozes de pessoas ausentes, chamadas pelo nome.\n4. Reprodução de corpos: alguém que respira, esquenta, machuca-se e sangra — e não tem batimentos.\nRegra que Tomás escreveu e ninguém contestou: «não é uma imitação de pessoas. É uma hipótese sobre pessoas.»",
		},
		"e_sino": {
			"title": "A CÂMARA DO SINO",
			"body": "Sistema de acústica profunda instalado no casco inferior.\nAndrei chamava o módulo de «sino» porque, quando o oceano respondia, o metal tocava como um sino — sem percussão, sem fonte, sem transmissão estrutural detectável.\nForam registradas 9 ocorrências. Nas 9, havia alguém acordado e sozinho no módulo.",
		},
		"e_sal5": {
			"title": "SAL-5",
			"body": "Inteligência de bordo. Voz de emergência, protocolo de continuidade.\nRegistra, avisa, conserva. Não julga — oficialmente.\nEm 11 de abril, SAL-5 começou a repetir uma frase fora do protocolo: «Eu também estou esperando.»",
		},
		"e_kolokol": {
			"title": "O SINO FALA",
			"body": "Andrei decodificou 1 padrão dos 47 recebidos no casco.\nEle nunca escreveu o resultado em nenhum relatório. Escreveu apenas, num papel, em russo, e escondeu no forro da própria cabine:\n«Он повторяет то, что мы уже забыли.»\n(Ele repete aquilo que já esquecemos.)",
		},
		"e_doces": {
			"title": "HÁ DOIS DE VOCÊS?",
			"body": "Nota manuscrita, letra de Tomás, sem data:\n«Pergunta séria, para mim mesmo: se o oceano constrói um corpo a partir da minha memória de alguém, o corpo é uma cópia ou é uma pergunta?\nSe eu responder à pergunta, ele aprende.\nSe eu me recusar, ele tenta de novo.\nNão existe opção de não participar.»",
		},
		"e_final_a": {
			"title": "RESPOSTA — CHAMADO",
			"body": "Você falou com ele usando a única língua que ele parece ter aprendido: você mesmo.\nEle levou isso para dentro do mar e ficou com aquilo.",
		},
		"e_final_b": {
			"title": "RESPOSTA — SILÊNCIO",
			"body": "Você se calou. O oceano continuou trabalhando, com paciência de coisa que não tem pressa.\nTalvez o silêncio também seja uma resposta.",
		},
		"e_final_c": {
			"title": "RESPOSTA — PARTIDA",
			"body": "Você virou as costas para ÍRIO.\nOs instrumentos registram, na descida de órbita, algo prendendo-se ao casco por 41 segundos: massa, temperatura e forma de um corpo humano.\nDepois, nada.",
		},
		"e_final_d": {
			"title": "RESPOSTA — REPETIÇÃO NOVA",
			"body": "Você entregou ao oceano um pensamento que ele ainda não tinha: não o que a tripulação lembrava, mas o que eles poderiam ter sido.\nO mar aceitou. E começou a ensaiar.",
		},
		"e_crepusculo": {
			"title": "NOTA FINAL DE BORDO",
			"body": "Não existe explicação para ÍRIO neste arquivo.\nExiste o registro de cinco pessoas que tentaram por meses, e um sexto que chegou tarde.\nSe você está lendo isto e ainda está vivo, considere: o planeta nunca precisou que alguém o compreendesse. Precisava apenas de alguém que fosse compreensível.",
		},
	}


static func anomalies() -> Dictionary:
	return {
		"porta_aberta": {
			"entry": "e_manif",
			"hint": "A porta estava travada. Agora está aberta.",
			"trust": 0, "resonance": 1,
		},
		"objeto_movido": {"hint": "Objetos trocam de lugar quando ninguém está olhando.", "resonance": 1},
		"corredor_estendido": {
			"entry": "e_manif",
			"hint": "O corredor é maior por dentro do que deveria ser.",
			"resonance": 2, "trust": 1,
		},
		"cam_fantasma": {"entry": "e_manif", "hint": "Há alguém nas câmeras.", "resonance": 2},
		"foto_extra": {
			"entry": "e_manif",
			"hint": "A tripulação era cinco. Na foto, são seis.",
			"resonance": 2, "trust": 1,
		},
		"radio_voz": {
			"entry": "e_manif",
			"hint": "Uma voz no rádio. Você nunca a ouviu antes.",
			"resonance": 2, "trust": 1,
		},
		"eco_passos": {"hint": "Os seus passos têm uma sombra.", "resonance": 1},
		"espelho_agua": {"hint": "A poça reflete o teto. Você está sobre o teto?", "resonance": 2},
		"sino": {"entry": "e_sino", "hint": "O metal toca sem que nada o toque.", "resonance": 3, "trust": 2},
		"manifesto_iris": {
			"entry": "e_espelho",
			"hint": "Íris está na estação. Íris não está na estação.",
			"resonance": 3, "trust": 2,
		},
		"manifesto_andrei": {"entry": "e_sino", "hint": "Andrei voltou para o sino.", "resonance": 3},
		"coro": {
			"entry": "e_manif",
			"hint": "A estação ficou cheia de gente que não existe.",
			"resonance": 4, "trust": 2,
		},
		"terra_falsa": {
			"entry": "e_manif",
			"hint": "Por um momento, a janela mostrou um lugar que você conhece.",
			"resonance": 3, "trust": 2,
		},
		"mao_no_vidro": {"entry": "e_manif", "hint": "Do outro lado do vidro, uma mão humana.", "resonance": 4, "trust": 2},
		"trilha_molhada": {"hint": "Pegadas molhadas indo na direção da parede. E parando.", "resonance": 2},
		"sala_reconstruida": {"entry": "e_manif", "hint": "A sala voltou ao estado de antes do acidente. Inclusive as pessoas.", "resonance": 3, "trust": 1},
	}


static func decisions() -> Dictionary:
	return {
		"orgao": {
			"trigger": "Uma reprodução está se formando nos laboratórios. Ela parece incompleta.",
			"options": [
				{"id": "deixar", "label": "Deixar terminar", "detail": "Não interrompa o processo. Observe até o fim."},
				{"id": "interromper", "label": "Interromper com a lanterna", "detail": "Luz forte interrompeu manifestações antes."},
				{"id": "coletar", "label": "Coletar amostra do tecido", "detail": "Ciência primeiro. Você tem luvas e frascos."},
			],
			"effects": {
				"deixar": {"trust": 2, "resonance": 1, "flag": "deixou_terminar", "note": ["DECISÃO", "Você deixou a reprodução terminar. Depois disso, o Oceano pareceu considerar você um interlocutor."]},
				"interromper": {"trust": -2, "resonance": 1, "flag": "interrompeu", "note": ["DECISÃO", "Você interrompeu uma reprodução. Durante horas, o oceano não formou mais nada. Depois, voltou — mais insistente."]},
				"coletar": {"resonance": 2, "flag": "coletou_amostra", "note": ["DECISÃO", "Amostra coletada. Composição: água, sal, proteínas humanas. Nenhuma célula. Nenhum DNA."]},
			},
		},
		"gravacao": {
			"trigger": "A gravação mostra a tripulação decidindo o que fazer com você. Ela é anterior à sua chegada.",
			"options": [
				{"id": "preservar", "label": "Preservar a gravação", "detail": "O arquivo fica. Alguém, algum dia, vai precisar dele."},
				{"id": "apagar", "label": "Apagar o registro", "detail": "Há coisas que não devem voltar com você."},
				{"id": "reenviar", "label": "Reenviar para a Terra", "detail": "Transmissão de alto custo em energia. Alguém vai ouvir."},
			],
			"effects": {
				"preservar": {"trust": 1, "resonance": 2, "flag": "preservou_gravacao"},
				"apagar": {"trust": -1, "flag": "apagou_gravacao"},
				"reenviar": {"resonance": 3, "flag": "reenviou", "note": ["TRANSMISSÃO", "Pacote enviado. A antena não registra eco de retorno. A Terra está a 9 horas-luz de distância."]},
			},
		},
		"chamado": {
			"trigger": "Alguém está chamando pelo seu indicativo no rádio. A voz diz: «Você demorou.»",
			"options": [
				{"id": "responder", "label": "Responder", "detail": "Identificar-se e pedir identificação."},
				{"id": "silenciar", "label": "Silenciar o canal", "detail": "Se não é da tripulação, não é assunto seu."},
				{"id": "gravar", "label": "Gravar sem responder", "detail": "Deixar a voz falar. Registrar tudo."},
			],
			"effects": {
				"responder": {"trust": 2, "resonance": 2, "flag": "respondeu_radio"},
				"silenciar": {"trust": -2, "flag": "silenciou_radio"},
				"gravar": {"resonance": 1, "flag": "gravou_radio", "note": ["TRANSCRIÇÃO", "A voz repetiu o seu indicativo 31 vezes, sem variação. Depois, disse o seu nome completo. Você nunca disse o seu nome completo nesta estação."]},
			},
		},
		"espelho": {
			"trigger": "O Protocolo Espelho ainda está armado. Bastaria reativá-lo.",
			"options": [
				{"id": "reativar", "label": "Reativar o Protocolo Espelho", "detail": "Oferecer ao oceano um pensamento organizado. O seu."},
				{"id": "desligar", "label": "Desligar definitivamente", "detail": "Encerrar o que Íris começou."},
			],
			"effects": {
				"reativar": {"trust": 3, "resonance": 3, "flag": "protocolo_ativo", "note": ["PROTOCOLO ESPELHO", "Reativado. Fonte: você. O oceano aceitou o pensamento em 0,4 segundos."]},
				"desligar": {"trust": -3, "resonance": -2, "flag": "protocolo_off"},
			},
		},
	}


static func dialogues() -> Dictionary:
	return {
		"iris_1": {
			"lines": [
				{"who": "ÍRIS", "text": "K-9. Você chegou tarde.", },
				{"who": "ÍRIS", "text": "Não se preocupe. Eu não vou pedir nada a você.", },
				{"who": "ÍRIS", "text": "Só queria que alguém de fora visse: eu não fugi. Eu fiquei.", },
			],
			"voice": "iris_01",
		},
		"iris_fria": {
			"lines": [
				{"who": "ÍRIS", "text": "Você interrompeu muitas coisas.", },
				{"who": "ÍRIS", "text": "Eu tinha perguntas. Você apagou as respostas.", },
				{"who": "ÍRIS", "text": "Ele vai continuar perguntando. Eu também.", },
			],
		},
		"andrei_1": {
			"lines": [
				{"who": "ANDREI", "text": "O sino tocou às três e vinte.", },
				{"who": "ANDREI", "text": "Eu acordei antes de tocar. Isso é o que me assusta.", },
			],
			"voice": "andrei_02",
		},
		"radio_1": {
			"lines": [
				{"who": "?", "text": "K-9. K-9, aqui é a estação Argos-4.", },
				{"who": "?", "text": "Você demorou.", },
				{"who": "?", "text": "Eu esperei quarenta e sete dias. Eu não me importo de esperar.", },
			],
			"voice": "sal_02",
		},
		"sala_reconstruida": {
			"lines": [
				{"who": "SAL-5", "text": "Registro anômalo. A copa está intacta.", },
				{"who": "SAL-5", "text": "A copa não está intacta. Portanto, algo nesta estação tem pressa em ser lembrado.", },
			],
		},
	}


static func radio_signals() -> Dictionary:
	return {
		"terra_1": {
			"freq": "2214.6 kHz",
			"who": "TERRA // CONTROLE DE MISSÃO",
			"text": "K-9, alerta. Não reinicie os sistemas de pesquisa. Não reative o Protocolo Espelho. Repetimos: NÃO reative o Protocolo Espelho. A estação Argos-4 perdida por fenômeno não catalogado. Sua prioridade é retornar. Sua prioridade é retornar.",
			"static": 0.55,
		},
		"terra_2": {
			"freq": "2214.6 kHz",
			"who": "TERRA // CONTROLE DE MISSÃO",
			"text": "Transmissão 44 do ciclo. Ic-..-ndo mudanças no relatório da Dra. Vale: ela afirma que o .-al está «respondendo a pensamentos». Diretoria decidiu suspender o envio de equipe médica. K-9, se estiver ouvindo: o fenômeno não é uma entidade. O fenômeno não é uma entidade. O fenômeno não é...",
			"static": 0.8,
		},
		"sal_1": {
			"freq": "CANAL INTERNO 3",
			"who": "SAL-5",
			"text": "Protocolo de continuidade ativo. Tripulação: 5 registrados, 5 ausentes. Não sei se isso é lealdade ou hábito. Continuo funcionando porque fui programada para continuar. Sessenta e três por cento dos sensores estão indisponíveis. Um sensor, porém, responde melhor do que antes.",
			"static": 0.15,
		},
		"voz_extra": {
			"freq": "CANAL INTERNO 7 // SEM ORIGEM",
			"who": "V-7",
			"text": "Não é assim que se usa esse transmissor, K-9. Você tem que deixar o canal aberto depois de falar. Igual a uma pessoa. Igual a uma pessoa que escuta.",
			"static": 0.9,
		},
		"nadia_1": {
			"freq": "CANAL INTERNO 4 // GRAVAÇÃO PARTICULAR",
			"who": "N. KESSLER",
			"text": "Terra, é Nadia. Eu não vou deixar nada registrado, não vou escrever o que vi. Porque se eu escrever, ninguém vai me deixar voltar pra casa. Mas eu vi. Ele usou o rosto do meu irmão, e acenou do jeito que ele acenava quando a gente era criança. Terra... eu nunca tive um irmão.",
			"static": 0.35,
		},
		"tomas_1": {
			"freq": "CANAL INTERNO 6 // DIÁRIO DE ÁUDIO",
			"who": "DR. T. RANGEL",
			"text": "Teste quarenta. Descrevi em voz alta uma cidade que não existe: ruas inventadas, uma praça com uma fonte que eu nunca vi. Esta manhã, a janela sul mostrava a praça. Com a fonte. Conclusão: ele não copia memória. Ele copia imaginação. Consequência: eu não sei mais qual parte de mim é minha.",
			"static": 0.2,
		},
	}


static func items() -> Dictionary:
	return {
		"chave_eng": {"name": "Chave de engenharia", "desc": "Cartão magnético gasto. Acesso: setores técnicos."},
		"fusivel": {"name": "Fusível 400 A", "desc": "Pesado, quente na mão."},
		"gravador": {"name": "Gravador de campo", "desc": "Analógico. Não há mais fitas virgens na estação."},
		"fita_1": {"name": "Fita: cabine de A. Solokov", "desc": "Rotulada à mão: «para quem vier depois»."},
		"fita_2": {"name": "Fita: câmara do sino", "desc": "Um lado vazio. O outro tem 40 minutos de silêncio e uma respiração."},
		"amostra": {"name": "Amostra do oceano", "desc": "Água, sal, proteínas humanas. Nenhuma célula."},
		"foto_trip": {"name": "Fotografia da tripulação", "desc": "Cinco pessoas. Três sorrindo. Uma olhando para a máquina. Uma olhando para você."},
		"caderno": {"name": "Caderno de Tomás", "desc": "Metade do conteúdo é análise. A outra metade é caligrafia apertada, feita de madrugada."},
	}
