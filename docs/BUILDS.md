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
tem a seção **Artifacts** com `vozes-do-oceano-windows` (zip, ~60 MB,
ficam 30 dias no ar). Baixe, deszipe e rode `VozesDoOceano.exe`.
É um arquivo só: o conteúdo do jogo vai embutido no executável.

Requisitos da máquina: Windows 10/11 x86_64 com placa de vídeo e driver em
dia (o jogo abre em Forward+/Vulkan).

## Build local (editor Godot)

1. Instale o **Godot 4.4-stable** (mesma versão do CI).
2. Abra o projeto; em *Editor → Manage Export Templates*, baixe os modelos.
3. *Project → Export* já traz três presets prontos: **Linux**, **Windows**
   e **Web**. Escolha *Windows* → *Export Release*.
4. Sai `dist/VozesDoOceano.exe` (pck embutido, arquivo único).

## Versão web

Todo push no branch de trabalho exporta a versão web (job `web`) e deixa o
artefato `web` na execução. Publicar em https://jvitorsi-dev.github.io/
vozes-do-oceano/ depende de ligar o Pages nas configurações do repositório
(Settings → Pages → Source: GitHub Actions); sem isso, o job `publicar`
falha e o artefato continua disponível para baixar.
