# Porto Prime — identidade visual do Admin

Atualização exclusivamente visual: design-tokens.css, admin-premium.css e uma importação no layout.tsx. Nenhuma mudança em page.tsx, componentes de operação, handlers, chamadas de API, rotas, autenticação, permissões, backend, banco, pagamentos ou despacho.

A camada visual atende visão geral, pedidos, aprovações, diretório de motoboys, clientes, parceiros, catálogo, pagamentos, saques/carteiras, entrega/configurações e respectivos modais. Identidade compartilhada com Flutter: azul profundo, turquesa, coral e amarelo. Hierarquia de botões, ações destrutivas distintas, tabelas, métricas e histórico com números legíveis e superfícies consistentes. A navegação mobile usa os mesmos controles em faixa horizontal rolável; todos continuam acessíveis. Não há novos recursos ou dados de operação.

CSS validada com PostCSS, TypeScript sem erros e build de produção Next.js concluído com sucesso. Não foi possível inspecionar em navegador: o ambiente não tem o executável Chromium. Responsividade foi revisada no CSS para desktop, tablet e mobile, mas exige conferência visual no dispositivo. O script de atualização compila novamente a versão instalada.

Reinicie somente o processo Next.js do Admin após instalar. O backend e Flutter não precisam de atualização por esta mudança.
