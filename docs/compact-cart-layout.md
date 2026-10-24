# Carrinho compacto

Os produtos agora compartilham uma superficie branca com borda e divisorias leves. Cada linha reune miniatura inteira, nome, remocao, quantidade e valor, sem o antigo espaco entre dois blocos. A lista permanece um SliverList com construcao sob demanda para carrinhos maiores.

Os controles mantem areas de toque de 44 px. Em telas estreitas ou com fontes ampliadas, o valor e o seletor se reorganizam verticalmente. Imagens usam BoxFit.contain e nomes longos podem ocupar duas linhas. O subtotal existente aparece uma vez acima da acao de entrega.

Estoque, callbacks de quantidade/remocao, creditos, autenticacao, retorno a Home e checkout continuam usando os mesmos metodos. Nenhuma mudanca de API, banco ou pagamentos.

Atualizar no PowerShell, com o emulador pronto:
`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\update-compact-cart.ps1 -DeviceId emulator-5554`

Verificacao local: sintaxe Dart e comparacao dos handlers com a versao anterior. Flutter nao esta instalado no ambiente de edicao; build e instalacao sao executados pelo atualizador no Windows.
