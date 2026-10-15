# Entrada e foto do motoboy

A entrada mantém os mesmos controladores, recuperação de senha, erro/loading e chamada de autenticação. O novo sheet limita a largura, desconta o teclado da altura disponível e mantém campos e ações dentro de uma rolagem. O botão não tem altura rígida para permitir fonte ampliada.

A foto mantém image_picker, câmera frontal, galeria, dimensões de 320 × 320, qualidade 55, limite de 60 KB, JPEG/PNG e confirmação anterior ao envio. Somente as telas do app para escolher origem, conferir foto e apresentar o perfil foram redesenhadas. Interfaces nativas do navegador/sistema e suas permissões continuam sob controle do image_picker.

A escolha de origem usa um sheet responsivo com ícones de câmera/galeria e fechamento explícito. A confirmação usa um diálogo com largura limitada e rolagem, foto centralizada e botões empilhados. O cadastro continua recebendo a foto pelo callback; o perfil mantém o mesmo PATCH e refresh.

Validação local: sintaxe Dart, símbolos Lucide e comparação dos blocos de autenticação, captura, validação e envio. Novos testes abrangem larguras 320/390/768/1280, fontes 1/2, teclado e callbacks de escolha. Flutter runtime não executado localmente; o atualizador executa testes e build no Codespaces antes de substituir o app atual.
