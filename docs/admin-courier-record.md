# Ficha completa do motoboy no Admin

Disponível nos detalhes de Aprovações e Motoboys. A ficha organiza identidade/contato, habilitação, veículo, endereço, recebimentos, foto e campos adicionais do cadastro em seções expansíveis. Ganhos e histórico de saques ficam em uma área recolhível. Gerenciamento de acesso continua separado nos controles existentes.

O Admin edita CPF, nascimento, contato, CNH, veículo, endereço, PIX, foto e informações adicionais existentes. CPF/nascimento alterados passam pela mesma integração CPFHub e exigem CPF regular; nome oficial e situação cadastral são atualizados pelo retorno da consulta. CPF de outro perfil é bloqueado e a transação confere se a identidade mudou enquanto a consulta era feita. Situação verificada, permissões, credenciais e valores financeiros não são campos livres de cadastro.

A foto é selecionada no navegador, reduzida para até 512 pixels e JPEG compacto e validada pelo validador existente no backend. Atualizações são persistidas em User/CourierProfile e publicam courier.profile.updated. Foto, nome, telefone e placa notificam também os clientes das entregas ativas. O formulário envia apenas os campos alterados, preservando dados não editados e informações adicionais. Dados adicionais não podem introduzir campos desconhecidos nem substituir metadados de autenticação/operação.

Pendências oferecem 12 motivos prontos e uma opção personalizada: foto ilegível/divergente, CNH ilegível/vencida/incompatível, comprovante inválido/desatualizado, documento do veículo, placa divergente, PIX, identidade e documento faltante. Título e orientação são preenchidos e podem ser ajustados. Observação opcional é acrescentada à mensagem final, com prévia. O endpoint e os estados de pendência existentes são mantidos.

Atualização: bash scripts/update-courier-admin.sh. Instala dependências API/Admin e verifica TypeScript do Admin. Reiniciar Nest e Admin depois. Não requer alteração de schema, atualização Flutter, reconstrução de rotas ou mudanças financeiras.

Validação: 41 testes de backend e TypeScript do Admin passaram. Cobertura inclui autorização, duplicidade de CPF, falha de verificação, persistência canônica, foto/avisos aos clientes, campos adicionais e preservação de dados. Banco real, CPFHub real e renderização em navegador não foram executados neste ambiente; não é uma alegação de validação ponta a ponta.
