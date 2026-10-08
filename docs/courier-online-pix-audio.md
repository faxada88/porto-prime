# Preferência online, PIX e avisos de oferta

## Online é escolha do motoboy

`CourierProfile.isOnline` permanece como escolha manual, independente de AVAILABLE/OFFERED/DELIVERING. O heartbeat não envia mais a preferência local e não altera `isOnline`. Apenas a ação explícita online/offline escreve essa preferência; ela sincroniza os dispositivos e continua após nova sessão. Aceitar, avançar, finalizar, recusar ou expirar uma oferta não desliga nem religa automaticamente o motoboy. O loop não derruba a preferência quando o heartbeat vence.

Para receber uma nova oferta, continuam obrigatórios aprovação, usuário ativo, conexão recente e ausência de entrega ativa. Uma desconexão não mostra offline, mas o despacho aguarda a reconexão. Bloqueio/rejeição/pendência administrativa continuam impedindo ofertas pelas permissões, sem apagar a preferência online. `isOnline: true` é verificado também na reserva transacional da oferta, impedindo que uma preferência desligada seja ignorada por um status AVAILABLE antigo. Motoboys já desligados pela versão anterior precisam escolher online uma vez; não ligamos indiscriminadamente quem escolheu offline.

## PIX e saque

O cadastro grava chave e tipo nos campos existentes de CourierProfile, além do JSON de onboarding. Novo cadastro dispõe de seletor de tipo. Ao solicitar saque com campos antigos ausentes, a API recupera a chave do JSON e normaliza CPF/CNPJ/email/celular/chave aleatória. Nenhuma chave é inventada quando o cadastro não tem uma.

O saque conserva reserva financeira, snapshot da chave e autorização de administrador. Na aba Saques do Admin: Pendente → Em processamento → Confirmar PIX realizado; também é possível rejeitar. Marcar pago é confirmação administrativa de transferência externa, não execução automática de PIX. A alteração usa bloqueio da linha do saque dentro da transação para evitar estados finais conflitantes. Rejeição estorna uma vez e estados finais não podem ser substituídos.

## Som

Novas ofertas reproduzem um toque original curto, de três notas suaves, no navegador. O mesmo ID de oferta não dispara repetidamente; nova rodada com outro ID pode tocar novamente. Usa Web Audio sem pacote adicional ou asset externo. O contexto é habilitado por interação com a página; autoplay, volume, silêncio do dispositivo e navegador em segundo plano podem impedir áudio. Nos apps nativos, usa alerta do sistema e vibração, com comportamento dependente da plataforma. Falha de áudio nunca bloqueia o modal ou o aceite.

## Aplicação e verificação

Sem schema novo, migrations ou dependências novas. Reinicie API, Admin e Flutter e recarregue a página após aplicar, pois há JavaScript novo no HTML de entrada.

56 testes simulados passaram (incluindo nove de PIX/saque e dez de despacho), mais verificações executadas do toque e cinco cenários do checkout JavaScript. Não houve movimentação financeira real, teste multiusuário com Postgres nem build Flutter. Este ambiente não dispõe do SDK Flutter e do cliente Prisma/dependências completos; a validação real continua no Codespaces.
