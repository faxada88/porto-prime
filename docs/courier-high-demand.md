# Alta demanda: adicional na entrega e repasse integral

ON/OFF manual ou Automático, valor configurável de R$ 0,01 a R$ 100,00. Automático liga com 10 pedidos pagos sem motoboy e desliga abaixo de 10. Modos manuais mantêm a escolha do Admin.

Novos pedidos: taxa da rota (R$ 5,50 até 3 km + R$ 2,50/km excedente, valores configuráveis) + adicional vigente de alta demanda. Exemplo: R$ 5,50 + R$ 2,50 = R$ 8,00 de entrega; com R$ 20,00 de produtos o Stripe cobra R$ 28,00. A cotação mostra o adicional antes de confirmar. O pedido congela o valor; ofertas usam esse registro mesmo se o Admin mudar/desligar o modo. Na conclusão, a carteira recebe a taxa final uma vez, com 100% do adicional e sem comissão sobre ele. Há trava transacional e nova confirmação quando a taxa ou o adicional mudam antes da gravação.

Compatibilidade: pedidos anteriores não são reprecificados. Bônus prometidos pelo modelo anterior permanecem pagos pela distribuidora, usando demandSurchargeIncluded=false. Novos pedidos recebem true. Crédito idempotente e Stripe existente são preservados.

Eventos públicos mantêm clientes/visitantes atualizados; delivery.pricing.updated invalida cotações quando valores mudam. O aviso geral do cliente não mostra valores; o resumo financeiro mostra o adicional cobrado. O motoboy recebe um aviso operacional compacto, sem linguagem publicitária.

Instalação única: scripts/update-demand-surcharge.sh, banco iniciado. Inclui SQL idempotente, Prisma, Nest, Admin e Flutter. Reinicie os três processos após instalar. Verificações locais: builds Nest/Admin, testes de preço/crédito/Stripe/ofertas e análise sintática Dart. Validar renderização e pagamento real no Codespaces.
