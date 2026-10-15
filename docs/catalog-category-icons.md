# Categorias: iconografia e exclusão

O catálogo tem 28 opções de ícones vetoriais consistentes. Churrasco/carnes, fitness, frutas, legumes, peixes, padaria, café, laticínios, doces, pizzas, lanches, naturais, farmácia, pets, limpeza e beleza passam a ter identificação própria, além das categorias de bebidas existentes.

O Admin sugere um ícone pelo nome e oferece escolha explícita com prévia. Nomes que não correspondem à curadoria exigem seleção antes de publicar. O ícone fica no campo opcional `Category.iconKey`; a migração é aditiva. Imagens próprias informadas no catálogo têm prioridade sobre o ícone. Categorias antigas desconhecidas recebem uma marca com iniciais no app, em vez da caixa genérica.

A rota autenticada `DELETE /api/admin/categories/:id` exige Admin. Se houver produtos, o painel exige outra categoria de destino. O backend transfere todos os produtos e exclui a categoria em uma transação serializável. IDs de produtos, preços, estoque, pedidos e histórico financeiro permanecem. Falhas de concorrência ou vínculo desfazem a operação e retornam uma mensagem para atualizar a lista.

Criação, edição e exclusão usam o evento de catálogo já existente. O endpoint `/products/categories` inclui `iconKey`, e o app revalida a categoria selecionada com a lógica de sincronização existente.

Validação concluída localmente: build de produção do Admin, TypeScript estrito do painel, nove cenários da exclusão em harness transpilado com transação simulada, correspondência dos nomes e consistência dos símbolos nos pacotes Lucide existentes. Não foi executado banco real nem runtime Flutter local. Os atualizadores executam migração, geração Prisma, teste Vitest e build Nest no Codespaces; o atualizador mobile executa testes de layout/iconografia e build antes de substituir o bundle.

Nenhuma dependência adicionada. Pagamento, despacho, carteira e autenticação permanecem fora do escopo.
