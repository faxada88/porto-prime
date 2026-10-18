# Endereços pela Home

Cliente autenticado toca no endereço abaixo do nome e abre um painel com busca, cartões dos endereços salvos, seleção em destaque e menu de editar, usar ou remover. Novo endereço fica acessível pelo botão inferior. Exclusão exige confirmação.

A seleção usa o endpoint de atualização já existente com isDefault; Home e checkout continuam lendo o mesmo estado. A pesquisa usa /delivery/places e seus resultados abrem AddressEditorPage com initialPlace, reutilizando o preenchimento, a validação e o cálculo de entrega existentes. Edição/remoção reutilizam os métodos atuais. Nenhuma mudança de schema, backend, tarifa, geocodificação ou pagamento.

Tela sem botões de GPS fictícios. A busca admite ruas, hotéis e estabelecimentos presentes no índice atual. Cadastro manual permanece disponível. Controles bloqueiam envios duplicados, indicam carregamento e exibem erro sem fechar o painel. Layout ajusta a altura quando o teclado abre.

Verificação local: sintaxe Dart e conexão dos handlers. Testes de cartão estreito com texto ampliado e ações independentes incluídos; Flutter e Android não executados neste ambiente. O atualizador Windows executa análise, testes e build e instala com ADB -r. Deixe emulador inicializado e serviços ligados; execute scripts/update-address-selector.ps1.
