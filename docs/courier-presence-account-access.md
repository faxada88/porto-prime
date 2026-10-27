# Presença e acesso do motoboy

Disponibilidade operacional depende de uma sessão não revogada, ainda válida, com intenção online e heartbeat recente. O heartbeat do app ocorre a cada 5 segundos. A validade máxima é de 20 segundos; o ciclo de reconciliação ocorre a cada 2 segundos. O WebSocket detecta conexões perdidas com ping de 5 segundos e timeout de 5 segundos. Perdas abruptas de rede exigem esse intervalo de detecção; não são instantâneas.

Logout e revogação invalidam apenas a presença da sessão correspondente. Outra sessão online do mesmo motoboy continua válida. O comando explícito de ficar offline desativa a disponibilidade em todos os dispositivos daquele motoboy; ficar online ativa somente o dispositivo solicitante. Um heartbeat comum não desfaz uma escolha offline concorrente.

A reconciliação serializa alterações pelo registro do motoboy. Ao ficar indisponível, ofertas pendentes são canceladas e a referência de oferta ativa do pedido é liberada, permitindo que o ciclo de despacho tente outros motoboys. Entregas já aceitas não são canceladas ou reatribuídas. Tanto a seleção quanto a confirmação de uma nova oferta verificam disponibilidade, sessão e aprovação.

Contas de motoboy PENDING, SUSPENDED e BLOCKED podem fazer login, renovar sua sessão e consultar a conta. A exceção de autenticação é explícita nos endpoints de conta e suporte; os endpoints operacionais continuam exigindo conta ativa/aprovada. Outros papéis não recebem essa exceção.

Pendências aparecem na conta autenticada com título, descrição, andamento e resposta. Respostas pertencem ao motoboy autenticado; não é necessário reenviar CPF. Imagens JPEG/PNG de documentos usam o validador existente (até 60 KB e 1024 × 1024), são vistas pelo titular e Admin e não aparecem na consulta pública por CPF. Contas bloqueadas/suspensas ficam em consulta e suporte. O Admin pode informar o motivo ao suspender/bloquear na lista de motoboys. Dados antigos sem motivo específico exibem a orientação de procurar suporte, sem inventar uma justificativa.

Após resolver exigências e aprovar a conta, o evento atualiza o acesso na sessão existente. O motoboy escolhe ficar online novamente. A consulta periódica recupera eventos perdidos. Carteira, pagamentos, pedidos aceitos e credenciais permanecem inalterados; não há migração de banco.

Validação: build da API, suíte de testes da API e build do Admin. Novos testes cobrem sessão expirada/revogada, múltiplos dispositivos, cancelamento de ofertas pendentes, preservação de entregas aceitas, login restrito, restauração de acesso, propriedade de exigências e desconexão de sockets. Testes Flutter verificam tela restrita em 320/390/768 px, escala de texto 1×/2×, consulta, resposta e ausência de controles operacionais. O script de atualização executa os testes Flutter no ambiente com SDK antes de instalar o APK.

Atualização Windows: `scripts/update-courier-access.ps1 -DeviceId emulator-5554`. Recompila API/Admin/app, testa, reinicia apenas processos Node identificados neste checkout e instala com `adb install -r`. Banco, rotas, Stripe e dados do aplicativo são preservados. O emulador deve estar aberto e inicializado.
