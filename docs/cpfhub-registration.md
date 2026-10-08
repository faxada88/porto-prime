# Consulta de CPF no cadastro de motoboy

Somente o cadastro COURIER exige esta nova verificação. Cliente e parceiro mantêm seus fluxos. Sem alterações de schema, dependências, pagamento, aprovação administrativa ou despacho.

## Configuração

Execute `bash scripts/configure-cpfhub.sh` no repositório. Cole a chave no prompt oculto. A chave fica apenas em `apps/api/.env` como `CPFHUB_API_KEY`; não é incluída no Flutter nem no Git. Reinicie API e Flutter. Alternativamente, injete `CPFHUB_API_KEY` no ambiente do servidor.

## Contrato

`POST /api/auth/courier-cpf` recebe `{ "cpf": "...", "birthDate": "DD/MM/AAAA" }`. O servidor valida os dígitos, data e duplicidade antes de chamar `POST https://api.cpfhub.io/cpf/realtime` com `x-api-key`. Esta consulta exige CPF **e nascimento**, conforme https://www.cpfhub.io/documentacao/referencia/cpf-tempo-real. O resultado contém apenas CPF, nome, nascimento, situação cadastral e `regular`. Não expõe comprovantes públicos, chave nem mensagens técnicas do fornecedor.

O formulário espera os dois campos completos, aplica debounce de 650 ms, mostra espera e nome somente leitura, ignora respostas antigas e limpa resultados quando os campos mudam. Só permite avançar após REGULAR e ausência de óbito. Situações não regulares mostram orientação para regularizar junto à Receita Federal. Indisponibilidade e dados divergentes bloqueiam sem afirmar que o CPF é irregular.

No envio final, o backend exige novamente a verificação e grava o nome retornado pelo fornecedor, ignorando um nome ou situação adulterados pelo cliente. A situação confirmada fica no JSON `onboardingData` já existente. O cache de memória de 10 minutos evita cobrar duas consultas durante o mesmo cadastro; reinícios ou expiração podem exigir nova consulta. Consultas simultâneas idênticas são agrupadas; limite local de cinco novas consultas por IP por minuto e cinco em andamento. Para múltiplas réplicas, os limites/caches são independentes; configure também limites no proxy de entrada. O IP depende da configuração de proxy já existente.

Timeout do fornecedor: 60 s; chamada Flutter: 70 s; envio final do motoboy: 75 s. Os demais timeouts são preservados. Sem retentativa automática de consultas pagas; nova tentativa requer ação do usuário. Não é consulta de débitos fiscais nem comprovação de identidade/CNH.

## Validação

20 testes de contrato com respostas simuladas cobrem regularidade, situações irregulares, óbito, formato/data inválidos, respostas incompletas/divergentes, cache, requisições concorrentes, chave ausente, limitação e falhas. Nenhum CPF real foi consultado e nenhum crédito foi consumido. A consulta real exige a chave configurada, saldo e dados corretos de CPF/nascimento no formulário.
