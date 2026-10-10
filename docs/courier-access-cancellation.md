# Acesso e cancelamento de pendências

Ativar um motoboy no Admin usa a mesma aprovação transacional do cadastro, sem ignorar pendências. Aprovação, criação, resolução e cancelamento notificam o Admin e sessões conectadas.

Cancelamento conserva o histórico (status interno RESOLVED + canceledAt/canceledBy). O Admin mostra Cancelada e o aplicativo exclui solicitações encerradas. Respostas concorrentes não reabrem uma solicitação cancelada.

Solicitações novas guardam o estado anterior. Cancelar a última solicitação ainda ativa restaura apenas o acesso ACTIVE/APPROVED interrompido por elas, se o cadastro continua PENDING. Nunca libera contas BLOCKED/SUSPENDED ou novos candidatos. Pendências anteriores a esta versão não têm histórico de estado: depois de cancelar, use Aprovar cadastro/Aprovar e ativar acesso. Cancelar uma solicitação já resolvida apenas registra o cancelamento.

O login do Flutter mantém uma sessão autenticada quando falha a atualização inicial dos dados, com mensagem de atualização indisponível. A consulta normaliza o CPF e não tenta renovar uma sessão antiga. A interface considera também o status do acesso ao apresentar a candidatura.

Instalação: scripts/update-courier-access.sh. Requer o banco já iniciado, Node e Flutter disponíveis. Aplica SQL aditivo idempotente, gera Prisma e instala dependências; não apaga dados ou sessões. Reinicie Nest/Admin/Flutter após a instalação. A compilação TypeScript do Admin e 45 testes de backend passaram. Flutter e integração no Codespace precisam de validação no ambiente de execução; esta mudança não resolve indisponibilidade de banco ou portas privadas.
