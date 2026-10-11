# Parceiros Porto Prime

Cadastro por CPF ou CNPJ, com nome de divulgação e atividade. Pessoas físicas não precisam de razão social. Aprovação e rejeição utilizam os controles de acesso existentes. A comissão inicial é de 5%, editável individualmente no Admin, entre 0% e 100%, com duas casas decimais.

O QR aponta para a raiz pública do aplicativo com `?ref=<código único>`. `FRONTEND_PUBLIC_URL` tem prioridade sobre a origem enviada pela interface. No Codespaces, o script inicia o backend com a URL pública da porta 8086. A divulgação para clientes externos exige acesso público à porta do app. O frontend grava a última indicação válida por 30 dias no mesmo dispositivo, inclusive antes do login. Uma nova indicação válida substitui a anterior; a anterior não é compartilhada entre dispositivos.

O backend confirma que o parceiro está aprovado e ativo e que não é o próprio comprador, antes de vincular o pedido. Referência indisponível não impede uma compra normal. O percentual é congelado na criação do pedido. Ele incide sobre os produtos efetivamente entregues, sem taxa de entrega e sem itens removidos, reembolsados ou transformados em voucher. Créditos usados como pagamento não duplicam nem aumentam a base de produtos.

A conclusão da entrega paga o motoboy usando sua regra existente e credita a comissão do parceiro na mesma transação. Uma falha em qualquer crédito impede a conclusão da transação. O ledger possui uma chave única por pedido, evitando crédito duplicado. Pedidos excluídos, cancelados, sem pagamento ou não concluídos não geram comissão. O crédito é atualizado via evento de carteira e perfil. Saques usam a carteira e os controles financeiros existentes; não há PIX automático.

Admin: lista pesquisável em páginas de 20, edição cadastral e de comissão, QR para download, últimos 50 pedidos indicados, saldo, histórico de comissões e saques, atalho para gestão financeira. Mudanças de percentual ficam no histórico de auditoria financeira e só valem para novos pedidos.

## Validação

Nest e Admin compilados. Testes automatizados cobrem elegibilidade, cálculo, itens removidos, percentual congelado, arredondamento, idempotência, propagação de falha, autorização e campos protegidos. A sintaxe Dart foi verificada; não há Flutter SDK nem PostgreSQL de teste neste ambiente.

No Codespaces: execute a atualização Admin/backend antes da atualização Flutter, mantendo banco e OSRM ligados. Verifique cadastro CPF/CNPJ, aprovação, QR em janela anônima, login do cliente, compra, liberação e conclusão da entrega. A carteira do parceiro deve permanecer sem crédito até a entrega e receber uma única comissão depois; repetir a confirmação não deve duplicar o saldo. Confirme também mudança do percentual entre dois pedidos, escolha de voucher/reembolso e saque por PIX.

## Correção de ativação e divulgação (11/10)

A ativação administrativa de um parceiro agora utiliza a aprovação completa, sincronizando `User.status` com `PartnerProfile.approved`. Uma migração corrige perfis já ativos que ficaram com a flag de aprovação falsa pelo controle anterior.

O perfil Flutter mostra diretamente um cartão com QR, link selecionável, cópia e compartilhamento por WhatsApp. O endpoint leve `/partners/me/referral` não consulta carteira, pedidos ou saques. O mesmo link mantém a atribuição existente por 30 dias.

O Admin preserva cadastro e edição quando dados financeiros/indicações estiverem temporariamente indisponíveis, exibindo avisos explícitos e valores indisponíveis em vez de inventar saldos. A origem pública pode ser obtida do Codespace atual mesmo ao reiniciar o Nest manualmente. Um erro na preparação do QR não impede a abertura do cadastro; o link permanece utilizável quando disponível.
