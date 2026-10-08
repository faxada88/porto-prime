# Rodadas contínuas de despacho

O filtro anterior excluía para sempre qualquer motoboy que já tivesse recebido oferta do pedido. Após todos recusarem ou expirarem, não havia mais candidatos.

O despacho agora mantém o histórico e consulta a última oferta de cada motoboy naquele pedido. Entre elegíveis, quem nunca recebeu vem primeiro; depois, quem recebeu há mais tempo. O score existente continua como desempate, seguido do ID para ordenação estável. Com dois motoboys disponíveis: A → B → A → B; com quatro: A → B → C → D → A. Não existe limite de rodadas enquanto o pedido continua procurando e há candidatos elegíveis. Quem estiver offline, sem heartbeat válido, não aprovado, com usuário inativo ou ocupado continua excluído.

Sem alterações de schema, dependências, carteira, pagamentos ou Flutter. O ID da oferta muda a cada tentativa, permitindo ao app reapresentar o mesmo pedido. A criação transacional da oferta e os handlers de aceite, recusa, expiração e redisparo permanecem intactos. O loop periódico existente volta a procurar se não há ninguém disponível; um pedido aceito deixa de participar.

O limite de até 100 candidatos por consulta existente foi preservado. Rodadas usam histórico persistido no banco, não contadores de memória, e sobrevivem ao reinício da API.

Validação: oito testes executam o DispatchService com banco/eventos simulados. Cobrem três rodadas com 1/2/3/4 motoboys, oferta ativa única, parada após atribuição, indisponíveis/ocupados/heartbeat vencido, retomada quando alguém fica disponível e entrada de candidato sem oferta anterior. Não houve teste multiusuário real nem alteração de transações. Reinicie somente Nest após aplicar.
