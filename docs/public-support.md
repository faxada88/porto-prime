# Atendimento público e comercial

A entrada “Conte com a Porto Prime” funciona sem autenticação. Acesso, conta,
problemas gerais, parcerias e patrocínios possuem assuntos próprios. Usuários
cadastrados continuam utilizando o suporte autenticado já existente.

Cada contato recebe protocolo aleatório e código privado gerado no dispositivo.
O servidor armazena somente o hash do código; o Admin nunca recebe esse código.
O dispositivo conserva os últimos dez acessos para recuperação, inclusive envios
com resposta perdida. Em outro dispositivo, protocolo e código são necessários.
Não há busca pública por e-mail nem envio automático de e-mails ou SMS.
As respostas ficam no acompanhamento do protocolo, atualizado periodicamente.

O Admin recebe eventos em tempo real em “Sem login e comercial”, separado das
filas de clientes, motoboys e parceiros autenticados. Pesquisa, filtros, respostas
prontas editáveis, notas internas, encerramento e reabertura estão disponíveis.
O perfil declarado pelo visitante não comprova identidade; o atendimento não
concede permissões nem altera contas automaticamente. Notas nunca são públicas.

A migração é aditiva e idempotente: PublicContact e PublicContactMessage.
Validação de campos, limites de envio, segredo fora da URL, respostas paginadas
e identificadores idempotentes protegem o canal público.

Validação local: build de produção do Admin e 11 testes do serviço com mocks.
Fontes Dart verificadas sintaticamente. Os atualizadores executam Vitest real,
geração Prisma, build Nest e testes/build Flutter no Codespaces. Nenhum teste
local com banco real ou execução do Flutter foi alegado.
