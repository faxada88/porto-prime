# Central financeira — Admin, motoboys e parceiros

Aba Saques: fila compacta com busca por nome, PIX e identificador, filtros por papel/status e carregamento progressivo. Métricas agregam o histórico completo. Lista mostra até 200 saques recentes; contas até 200 por busca, com busca no servidor em todas as contas; detalhe mostra até 100 registros por seção. Nenhum total de saldo é calculado a partir da lista limitada.

Carteiras: abrir uma conta permite consultar saldo disponível, reservas, PIX, movimentações, solicitações e registro administrativo. Crédito positivo e bônus exigem motivo; não existe ajuste negativo livre nem alteração direta de saldo. Admin pode solicitar saque em nome de motoboy/parceiro, com chave validada e preservada no saque. Informar uma chave no saque não modifica silenciosamente o cadastro.

Crédito, reserva de saque e estorno usam transação e lock na linha do perfil. Motoboys usam o mesmo lock e ledger existentes no app; parceiros têm ledger e saques próprios. UUID da operação permanece no formulário durante novas tentativas para impedir duplicação. Reserva debitada uma vez; rejeição devolve uma vez; pagamento não debita novamente. Saque pago/rejeitado/cancelado não pode ter outro status. Confirmação de pagamento exige processamento anterior, motivo e referência do repasse. Pode informar comprovante HTTPS já hospedado; não há upload de arquivo nesta etapa.

O sistema NÃO realiza transferência bancária/PIX. Admin executa o repasse externamente, verifica e registra PAID. Motivos, operador, valor, horário e referência ficam no registro administrativo. Saldo disponível continua calculado pelo ledger. Comissões automáticas de parceiros não foram inventadas: créditos administrativos/bônus são explícitos.

Novas rotas `/api/finance/admin/*` são restritas a ADMIN. `/api/finance/me` e `/api/finance/me/withdrawals` são próprias do parceiro autenticado; não aceitam operar outra conta. Dados de onboarding completos não são retornados pela central financeira. Eventos `wallet.updated` são direcionados à conta e ao ADMIN, sem publicar dados financeiros no canal público do catálogo. App motoboy mantém carteira existente; app parceiro ganha Carteira e saques no perfil. Reconexão/polling recuperam atualizações.

Migração somente aditiva: PartnerLedgerEntry, PartnerWithdrawal e FinancialAudit. Nenhum reset, recriação ou alteração do ledger antigo. Histórico antigo continua visível como movimentações/saques; ações anteriores à central não possuem auditoria retroativa fabricada.

Validação: 40 testes unitários de finanças/PIX/reserva/status com mocks e TypeScript do Admin. Flutter/Prisma CLI/PostgreSQL real não disponíveis no ambiente de edição; não houve teste de transferência real, concorrência em banco real ou compilação visual Flutter. Atualização: parar serviços, manter banco ativo, executar scripts/update-finance.sh e reiniciar Nest/Admin/Flutter. O script não executa reset de banco.
