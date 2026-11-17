# Como jogar as atualizações (builds)

O jogo é exportado pelo GitHub Actions — não é preciso instalar nada para
conferir uma atualização.

## .exe de Windows (sem instalar nada)

Duas formas de pedir o build:

1. **Pela interface do GitHub:** Actions → "Conferencia visual" →
   *Run workflow* (botão no canto direito). Roda só o job `exe`.
2. **Por commit:** qualquer commit cuja mensagem contenha `[build-exe]`
   roda só o job `exe` (a conferência visual longa é pulada).

Em ambos os casos, ao fim da execução (uns 5 minutos), a página da execução
tem a seção **Artifacts** com `vozes-do-oceano-windows` (zip, ~40 MB,
ficam 30 dias no ar). Baixe, deszipe e rode `VozesDoOceano.exe`.
O zip traz dois arquivos que precisam ficar **na mesma pasta**:
`VozesDoOceano.exe` (o motor) e `VozesDoOceano.pck` (o jogo). Se quiser
renomear, renomeie os dois com o mesmo nome-base.

A execução gera um segundo artefato, `vozes-do-oceano-windows-compat`
(`VozesDoOceanoCompat.exe` + `.pck`): o mesmo jogo no renderizador de
compatibilidade — o que o CI confere a cada push, abre em qualquer máquina
e não usa Vulkan. É o fallback oficial enquanto o crash do Forward+ na
primeira tela não é diagnosticado; também é a versão recomendada para
máquinas sem Vulkan ou com driver antigo.

Requisitos da máquina: Windows 10/11 x86_64 com placa de vídeo e driver em
dia (o jogo abre em Forward+/Vulkan).

### Primeira abertura pode parecer travamento
Na primeira vez, o Forward+ compila todos os shaders na hora: a janela pode
ficar "sem resposta" por alguns minutos enquanto o som do mar já toca.
Um aviso na tela explica isso; nas aberturas seguintes o motor usa o cache
e abre rápido. Se travar de verdade, feche pelo gerenciador de tarefas e
mande o arquivo `boot.log`, que o jogo grava **ao lado do .exe**: ele diz em
que segundo cada etapa da abertura aconteceu e onde parou.

### Modo leve (`--lowfx`)
`VozesDoOceano.exe --lowfx` desliga SSAO, iluminação indireta em tela,
reflexos em tela e neblina volumétrica. Serve para jogar em máquinas
modestas e para diagnosticar: se o travamento some com `--lowfx`, o culpado
é um desses efeitos.

## Build local (editor Godot)

1. Instale o **Godot 4.4-stable** (mesma versão do CI).
2. Abra o projeto; em *Editor → Manage Export Templates*, baixe os modelos.
3. *Project → Export* já traz três presets prontos: **Linux**, **Windows**
   e **Web**. Escolha *Windows* → *Export Release*.
4. Sai `dist/VozesDoOceano.exe` + `dist/VozesDoOceano.pck` — mantenha os dois
   na mesma pasta para jogar.

## Versão web

Todo push no branch de trabalho exporta a versão web (job `web`) e deixa o
artefato `web` na execução. Publicar em https://jvitorsi-dev.github.io/
vozes-do-oceano/ depende de ligar o Pages nas configurações do repositório
(Settings → Pages → Source: GitHub Actions); sem isso, o job `publicar`
falha e o artefato continua disponível para baixar.

### Log da exportação
O job `exe` grava o log completo da exportação em `docs/ci/exe.log` no
próprio branch (ele volta no commit "[skip ci]" da execução), já que os
logs da Actions não são acessíveis fora do GitHub.

### Forçar o renderizador de compatibilidade sem trocar de exe
Qualquer build abre no modo compat (sem Vulkan) com:
`VozesDoOceano.exe --rendering-driver opengl3`
É o mesmo renderer das capturas do CI — útil em máquina sem Vulkan,
driver antigo, ou para contornar o crash conhecido do Forward+.

### Bissecção de crash de abertura (`--so-splash`)
`VozesDoOceano.exe --so-splash` (ou o Compat) abre só o aviso 2D, sem HUD e
sem mundo, e grava "vivo aos Xs" no boot.log a cada 5 segundos. Serve para
localizar um crash de abertura: se sobreviver, o problema está no conteúdo
da cena; se morrer igual, está na inicialização do renderer ou da janela.
