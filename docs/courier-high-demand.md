# Aviso manual de alta demanda

## Admin

Cabeçalhos alinhados no início da área de conteúdo. Corrigida margem automática que centralizava verticalmente abas curtas. Banners mais compactos, cards de aprovação mais limpos e hierarquia de botões preservada.

O controle Alta demanda aparece no cabeçalho de todas as abas. Somente administrador autenticado pode ativar/desativar. O estado fica salvo no singleton CourierDemandSignal (tabela separada), com revisão monotônica, data e último administrador. Não participa de preços, pagamentos, distribuição, carteira ou online/offline. Não é detecção automática de demanda e não anuncia bônus ou número de ofertas fictícios.

GET /api/admin/operations/demand e PATCH do mesmo caminho. O corpo do PATCH deve conter enabled boolean. GET /api/couriers/operations/demand é exclusivo de motoboy autenticado. As consultas nunca criam configurações.

## Motoboy

Aviso visual na Home abaixo do hero, inclusive quando offline, sem acionamento automático de disponibilidade. Removido quando o Admin desativa. Evento courier.demand.updated entregue somente aos papéis ADMIN/COURIER. Consultas de reconciliação acompanham o refresh existente do motoboy; falha do novo endpoint não bloqueia entregas ou login. Revisões antigas são ignoradas. O estado local é limpo ao sair ou revogar sessão.

## Instalação

Banco iniciado antes de scripts/update-admin-demand.sh. Script instala dependências existentes, aplica SQL aditivo idempotente somente na tabela nova, gera Prisma e compila Nest/Admin. Reinicie Nest e Admin após executar.

Depois execute scripts/update-mobile-demand.sh e reinicie Flutter. Esse script instala as dependências existentes e compila o frontend. A alteração de estado no servidor pode ser consultada por novas sessões após reinício e por polling após reconexão.

## Verificação

36 testes backend passaram, incluindo acesso por papel, ativar/desativar, corpo inválido, persistência, revisão e broadcasts. Geração do Prisma, build Nest e TypeScript/build de produção Admin passaram; sintaxe dos quatro arquivos Dart validada. Flutter, banco PostgreSQL e navegador não estão disponíveis neste ambiente para teste integrado de execução.
