# Foto de perfil do motoboy

O Pulso da operação, mapa de demanda, cálculo de eficiência e atualização do radar foram removidos. Hero e navegação inferior permanecem.

O motoboy escolhe câmera/selfie ou galeria, confirma a prévia e salva em PATCH /api/couriers/profile/photo. image_picker 1.2.4 oficial do Flutter, com redimensionamento solicitado para 320 × 320 e qualidade 55. Fotos JPEG/PNG até 60 KB e 1024 × 1024 são validadas no servidor; imagens maiores ou formatos incompatíveis recebem mensagem para escolher outra imagem. Permissões de câmera/fototeca iOS e seleção de arquivos macOS adicionadas.

Foto armazenada no onboardingData existente, sem migration. Endpoint autenticado só altera o próprio motoboy; transação com bloqueio de linha preserva outros dados. Atualização notifica motoboy, Admin e clientes das entregas ativas.

Foto válida obrigatória ao ativar online manualmente. Heartbeat comum não muda disponibilidade nem exige novo envio. Não coloca motoboys automaticamente offline e não bloqueia a conclusão de uma entrega já em andamento.

Cliente recebe apenas profilePhoto junto aos dados operacionais já existentes; onboardingData, CPF, documentos e PIX não são serializados no pedido. A foto pode ser ampliada no acompanhamento. É uma referência visual enviada pelo usuário, sem reconhecimento facial, prova de identidade ou garantia biométrica.

18 testes simulados de validação/autorização/persistência/notificações e despacho passaram. TypeScript do Admin passou. SDK Flutter indisponível neste ambiente: compilação e câmera/galeria em dispositivos ainda não validadas. A atualização deve incluir flutter pub get e reinício de Nest/Flutter.
