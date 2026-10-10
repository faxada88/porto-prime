# Alta Demanda — configuração, avisos e remuneração

Admin: ON manual, OFF manual e Automático. Bônus configurável de R$ 0,01 a R$ 100,00, padrão R$ 2,50. Automático ativa com 10 pedidos pagos sem entregador (PENDING, CONFIRMED, PREPARING, READY_FOR_PICKUP ou SEARCHING_COURIER) e desativa abaixo de 10. Checkout não pago e pedidos cancelados não contam. Verificação a cada 3 segundos, com trava transacional entre instâncias.

O adicional é custeado pela distribuidora; taxa, total do cliente e Stripe permanecem iguais. Cada oferta registra seu bônus. No aceite, ele é copiado ao pedido; alterações posteriores não retiram o incentivo prometido. Ao concluir a entrega, o crédito idempotente existente inclui o bônus integral, sem comissão sobre o adicional. Pedidos e ofertas anteriores à atualização começam com bônus zero. A seleção, rotação, expiração e confirmação por PIN continuam iguais.

WebSocket privado comunica valor e motivo ao Admin/motoboy. Canal público /catalog transmite apenas enabled/revision/updatedAt, inclusive para visitantes. GET /operations/demand permite recompor o estado após reconexão; polling existente é o fallback. O cliente vê apenas o aviso de prazo, sem valores.

Instalar scripts/update-admin-demand.sh primeiro, com banco iniciado, depois scripts/update-mobile-demand.sh; reiniciar Nest, Admin e Flutter. SQL é idempotente e não apaga dados. Script não reinicia processos. Builds de Nest/Admin e testes unitários são executados no ambiente de desenvolvimento; validar entrega real e renderização Flutter no Codespaces.
