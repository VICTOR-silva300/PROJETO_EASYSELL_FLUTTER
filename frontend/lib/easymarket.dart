import 'package:flutter/material.dart';

import 'tema.dart';

class EasyMarket extends StatefulWidget {
  final VoidCallback aoVoltar;

  const EasyMarket({
    super.key,
    required this.aoVoltar,
  });

  @override
  State<EasyMarket> createState() => _EasyMarketState();
}

class _EasyMarketState extends State<EasyMarket> {
  AppCores get c => context.cores;

  static const List<String> categorias = [
    'Todos',
    'Kits',
    'Planos',
    'Pacotes',
    'Serviços',
  ];

  final TextEditingController pesquisaController = TextEditingController();

  String categoriaSelecionada = 'Todos';

  final List<Map<String, dynamic>> produtos = [
    {
      'nome': 'Kit Premium',
      'categoria': 'Kits',
      'preco': 245.00,
      'estoque': 24,
      'descricao':
          'Kit completo para empresas que precisam de uma solução profissional.',
      'avaliacao': 4.9,
      'vendas': 128,
      'icone': Icons.inventory_2_rounded,
      'favorito': true,
    },
    {
      'nome': 'Plano Profissional',
      'categoria': 'Planos',
      'preco': 189.90,
      'estoque': 18,
      'descricao': 'Plano ideal para pequenos negócios que querem crescer.',
      'avaliacao': 4.8,
      'vendas': 96,
      'icone': Icons.workspace_premium_rounded,
      'favorito': false,
    },
    {
      'nome': 'Pacote Básico',
      'categoria': 'Pacotes',
      'preco': 120.00,
      'estoque': 8,
      'descricao': 'Pacote essencial para começar a organizar seu negócio.',
      'avaliacao': 4.6,
      'vendas': 74,
      'icone': Icons.inventory_outlined,
      'favorito': false,
    },
    {
      'nome': 'Consultoria',
      'categoria': 'Serviços',
      'preco': 320.00,
      'estoque': 5,
      'descricao': 'Consultoria personalizada para melhorar seus resultados.',
      'avaliacao': 4.9,
      'vendas': 52,
      'icone': Icons.support_agent_rounded,
      'favorito': true,
    },
    {
      'nome': 'Plano Empresarial',
      'categoria': 'Planos',
      'preco': 450.00,
      'estoque': 15,
      'descricao': 'Solução completa para empresas em crescimento.',
      'avaliacao': 4.8,
      'vendas': 41,
      'icone': Icons.business_center_rounded,
      'favorito': false,
    },
    {
      'nome': 'Pacote Avançado',
      'categoria': 'Pacotes',
      'preco': 279.90,
      'estoque': 11,
      'descricao': 'Recursos avançados para melhorar a operação.',
      'avaliacao': 4.7,
      'vendas': 37,
      'icone': Icons.auto_awesome_rounded,
      'favorito': false,
    },
  ];

  final List<Map<String, dynamic>> carrinho = [];

  @override
  void dispose() {
    pesquisaController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Lógica
  // ---------------------------------------------------------------
  List<Map<String, dynamic>> get produtosFiltrados {
    final pesquisa = pesquisaController.text.toLowerCase().trim();

    return produtos.where((produto) {
      final nome = produto['nome'].toString().toLowerCase();
      final categoria = produto['categoria'].toString().toLowerCase();

      final correspondePesquisa =
          nome.contains(pesquisa) || categoria.contains(pesquisa);

      final correspondeCategoria = categoriaSelecionada == 'Todos' ||
          produto['categoria'] == categoriaSelecionada;

      return correspondePesquisa && correspondeCategoria;
    }).toList();
  }

  double get totalCarrinho {
    return carrinho.fold<double>(
      0,
      (total, produto) => total + (produto['preco'] as num).toDouble(),
    );
  }

  int get totalFavoritos =>
      produtos.where((produto) => produto['favorito'] == true).length;

  Color _corCategoria(String categoria) {
    switch (categoria) {
      case 'Planos':
        return c.azul;
      case 'Pacotes':
        return c.verde;
      case 'Serviços':
        return c.amarelo;
      default:
        return c.roxoClaro;
    }
  }

  Color _clara(Color cor, int alpha) => cor.withAlpha(alpha);

  
  String _preco(dynamic valor) {
    final partes = (valor as num).toStringAsFixed(2).split('.');
    final inteiro = partes[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => '.',
    );

    return '$inteiro,${partes[1]}';
  }

  BoxDecoration _decoracaoCard({double raio = 21}) {
    return BoxDecoration(
      gradient: c.gradCard,
      borderRadius: BorderRadius.circular(raio),
      border: Border.all(color: c.bordaSutil),
    );
  }

  void _adicionarCarrinho(Map<String, dynamic> produto) {
    setState(() => carrinho.add(produto));
    _mensagem('${produto['nome']} adicionado ao carrinho.');
  }

  void _mensagem(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            mensagem,
            style: const TextStyle(
              color: Color(0xFFF8FAFC),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF181F31),
          duration: const Duration(milliseconds: 1400),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0x18FFFFFF)),
          ),
        ),
      );
  }

  // ---------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final lista = produtosFiltrados;

    return Scaffold(
      backgroundColor: c.fundo,
      body: Container(
        decoration: BoxDecoration(gradient: c.gradFundo),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(19, 15, 19, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _cabecalho(),
                    const SizedBox(height: 24),
                    _banner(),
                    const SizedBox(height: 20),
                    _barraPesquisa(),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
              SliverToBoxAdapter(child: _categorias()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(19, 24, 19, 14),
                sliver: SliverToBoxAdapter(
                  child: _titulo(
                    'Produtos e serviços',
                    '${lista.length} item(s) disponível(is)',
                  ),
                ),
              ),
              if (lista.isEmpty)
                SliverToBoxAdapter(child: _vazio())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(19, 0, 19, 30),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 11,
                      mainAxisSpacing: 11,
                      childAspectRatio: 0.66,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _cardProduto(lista[index]),
                      childCount: lista.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cabecalho() {
  return Row(
    children: [
      GestureDetector(
        onTap: widget.aoVoltar,
        child: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: c.superficie,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.bordaMedia),
          ),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: c.texto,
            size: 18,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: AppCores.gradRoxo,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
              color: Color(0x422563EB),
              blurRadius: 22,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.storefront_rounded,
          color: Colors.white,
          size: 23,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MARKETPLACE',
              style: TextStyle(
                color: c.textoFraco,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'EasyMarket',
              style: TextStyle(
                color: c.texto,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
      _botaoCabecalho(
        icon: Icons.shopping_cart_outlined,
        quantidade: carrinho.length,
        onTap: _abrirCarrinho,
      ),
    ],
  );
}

  Widget _botaoCabecalho({
    required IconData icon,
    required int quantidade,
    required VoidCallback onTap,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: c.superficie,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.bordaMedia),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: Icon(icon, color: c.texto, size: 20),
            ),
          ),
        ),
        if (quantidade > 0)
          Positioned(
            top: -5,
            right: -5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.roxoClaro,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: c.fundo, width: 2),
              ),
              child: Text(
                quantidade > 99 ? '99+' : '$quantidade',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // Banner
  // ---------------------------------------------------------------
  Widget _banner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: c.gradDestaque,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: const Color(0x3A7C3AED)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x252563EB),
            blurRadius: 30,
            offset: Offset(0, 13),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppCores.gradRoxo,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.shopping_bag_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tudo para o seu negócio',
                      style: TextStyle(
                        color: c.texto,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Produtos, planos e serviços em um só lugar',
                      style: TextStyle(color: c.textoFraco, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: c.bordaSutil),
          const SizedBox(height: 16),
          Row(
            children: [
              _bannerInfo(
                'Produtos',
                '${produtos.length}',
                c.roxoClaro,
                Icons.inventory_2_rounded,
              ),
              _bannerInfo(
                'Favoritos',
                '$totalFavoritos',
                c.vermelho,
                Icons.favorite_rounded,
              ),
              _bannerInfo(
                'Carrinho',
                '${carrinho.length}',
                c.verde,
                Icons.shopping_cart_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerInfo(String titulo, String valor, Color cor, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _clara(cor, 30),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: cor, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(color: c.textoFraco, fontSize: 9),
                ),
                const SizedBox(height: 3),
                Text(
                  valor,
                  style: TextStyle(
                    color: cor,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Pesquisa e categorias
  // ---------------------------------------------------------------
  Widget _barraPesquisa() {
    return Container(
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.bordaMedia),
      ),
      child: TextField(
        controller: pesquisaController,
        onChanged: (_) => setState(() {}),
        style: TextStyle(color: c.texto, fontSize: 13),
        cursorColor: c.roxoClaro,
        decoration: InputDecoration(
          hintText: 'Buscar produtos, planos ou serviços...',
          hintStyle: TextStyle(color: c.textoFraco, fontSize: 12),
          prefixIcon: Icon(Icons.search_rounded, color: c.textoSuave, size: 20),
          suffixIcon: pesquisaController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    pesquisaController.clear();
                    setState(() {});
                  },
                  icon: Icon(
                    Icons.close_rounded,
                    color: c.textoSuave,
                    size: 18,
                  ),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _categorias() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 19),
        itemCount: categorias.length,
        itemBuilder: (context, index) {
          final categoria = categorias[index];
          final selecionada = categoriaSelecionada == categoria;

          return GestureDetector(
            onTap: () => setState(() => categoriaSelecionada = categoria),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: selecionada
                    ? const LinearGradient(
                        colors: [
                          Color(0x322563EB),
                          Color(0x182563EB),
                        ],
                      )
                    : null,
                color: selecionada ? null : c.superficie,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selecionada
                      ? const Color(0x552563EB)
                      : c.bordaSutil,
                ),
              ),
              child: Center(
                child: Text(
                  categoria,
                  style: TextStyle(
                    color: selecionada ? c.texto : c.textoSuave,
                    fontSize: 11,
                    fontWeight:
                        selecionada ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _titulo(String titulo, String subtitulo) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 4,
          height: 34,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [c.roxoClaro, c.roxo]),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: TextStyle(
                  color: c.texto,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitulo,
                style: TextStyle(color: c.textoFraco, fontSize: 10),
              ),
            ],
          ),
        ),
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: c.roxoClaro,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // Card de produto
  // ---------------------------------------------------------------
  Widget _cardProduto(Map<String, dynamic> produto) {
    final bool favorito = produto['favorito'];
    final int estoque = produto['estoque'];
    final Color cor = _corCategoria(produto['categoria']);

    return GestureDetector(
      onTap: () => _detalhesProduto(produto),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: _decoracaoCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 94,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_clara(cor, 46), _clara(cor, 12)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: _clara(cor, 38)),
                  ),
                  child: Icon(produto['icone'], color: cor, size: 38),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        produto['favorito'] = !produto['favorito'];
                      });
                    },
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: c.superficie,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.bordaMedia),
                      ),
                      child: Icon(
                        favorito
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: favorito ? c.vermelho : c.texto,
                        size: 15,
                      ),
                    ),
                  ),
                ),
                if (estoque <= 8)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: _clara(c.amarelo, 32),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: _clara(c.amarelo, 53)),
                      ),
                      child: Text(
                        'Pouco estoque',
                        style: TextStyle(
                          color: c.amarelo,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              (produto['categoria'] as String).toUpperCase(),
              style: TextStyle(
                color: cor,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              produto['nome'],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.texto,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Icon(Icons.star_rounded, color: c.amarelo, size: 13),
                const SizedBox(width: 3),
                Text(
                  '${produto['avaliacao']}',
                  style: TextStyle(
                    color: c.textoSuave,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${produto['vendas']} vendas',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.textoFraco, fontSize: 9),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'R\$ ${_preco(produto['preco'])}',
                      style: TextStyle(
                        color: c.texto,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _adicionarCarrinho(produto),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: AppCores.gradRoxo,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Sheets
  // ---------------------------------------------------------------
  Widget _sheet({required Widget child, double altura = 0.86}) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * altura,
      ),
      decoration: BoxDecoration(
        gradient: c.gradSheet,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: child,
        ),
      ),
    );
  }

  Widget _alca() {
    return Center(
      child: Container(
        width: 45,
        height: 4,
        decoration: BoxDecoration(
          color: c.textoFraco,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _botaoPrincipal({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppCores.gradRoxo,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x367C3AED),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _detalhesProduto(Map<String, dynamic> produto) {
    final Color cor = _corCategoria(produto['categoria']);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return _sheet(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _alca(),
                const SizedBox(height: 24),
                Center(
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_clara(cor, 50), _clara(cor, 14)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _clara(cor, 45)),
                    ),
                    child: Icon(produto['icone'], color: cor, size: 40),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  (produto['categoria'] as String).toUpperCase(),
                  style: TextStyle(
                    color: cor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  produto['nome'],
                  style: TextStyle(
                    color: c.texto,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  produto['descricao'],
                  style: TextStyle(
                    color: c.textoSuave,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _detalheProduto(
                      Icons.star_rounded,
                      '${produto['avaliacao']}',
                      'Avaliação',
                      c.amarelo,
                    ),
                    const SizedBox(width: 8),
                    _detalheProduto(
                      Icons.shopping_bag_outlined,
                      '${produto['vendas']}',
                      'Vendas',
                      c.roxoClaro,
                    ),
                    const SizedBox(width: 8),
                    _detalheProduto(
                      Icons.inventory_2_outlined,
                      '${produto['estoque']}',
                      'Estoque',
                      c.verde,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preço',
                            style: TextStyle(
                              color: c.textoFraco,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'R\$ ${_preco(produto['preco'])}',
                            style: TextStyle(
                              color: c.texto,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _botaoPrincipal(
                      label: 'Adicionar',
                      icon: Icons.add_shopping_cart_rounded,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _adicionarCarrinho(produto);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _detalheProduto(
    IconData icone,
    String valor,
    String titulo,
    Color cor,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.fundo2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.bordaSutil),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _clara(cor, 30),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icone, color: cor, size: 15),
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: TextStyle(
                color: c.texto,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              titulo,
              style: TextStyle(color: c.textoFraco, fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirCarrinho() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _sheet(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _alca(),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Seu carrinho',
                              style: TextStyle(
                                color: c.texto,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Revise os itens antes de finalizar',
                              style: TextStyle(
                                color: c.textoSuave,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x182563EB),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x357C3AED)),
                        ),
                        child: Text(
                          '${carrinho.length} item(s)',
                          style: TextStyle(
                            color: c.roxoClaro,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (carrinho.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Column(
                        children: [
                          Container(
                            width: 70,
                            height: 70,
                            decoration: const BoxDecoration(
                              color: Color(0x1A7C3AED),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.shopping_cart_outlined,
                              color: c.roxoClaro,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Seu carrinho está vazio',
                            style: TextStyle(
                              color: c.texto,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Adicione produtos para continuar.',
                            style: TextStyle(
                              color: c.textoSuave,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: carrinho.length,
                        itemBuilder: (context, index) {
                          final produto = carrinho[index];
                          final cor = _corCategoria(produto['categoria']);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(13),
                            decoration: BoxDecoration(
                              color: c.fundo2,
                              borderRadius: BorderRadius.circular(19),
                              border: Border.all(color: c.bordaSutil),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: BoxDecoration(
                                    color: _clara(cor, 30),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: _clara(cor, 38)),
                                  ),
                                  child: Icon(
                                    produto['icone'],
                                    color: cor,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        produto['nome'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: c.texto,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'R\$ ${_preco(produto['preco'])}',
                                        style: TextStyle(
                                          color: c.textoSuave,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() => carrinho.removeAt(index));
                                    setModalState(() {});
                                  },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: _clara(c.vermelho, 28),
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: Icon(
                                      Icons.delete_outline_rounded,
                                      color: c.vermelho,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  if (carrinho.isNotEmpty)
                    Column(
                      children: [
                        const SizedBox(height: 6),
                        Divider(color: c.bordaSutil),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(
                                color: c.textoSuave,
                                fontSize: 12,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'R\$ ${_preco(totalCarrinho)}',
                              style: TextStyle(
                                color: c.texto,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: _botaoPrincipal(
                            label: 'Finalizar pedido',
                            icon: Icons.check_rounded,
                            onTap: () {
                              Navigator.pop(sheetContext);
                              _mensagem('Pedido criado com sucesso!');
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------
  // Vazio
  // ---------------------------------------------------------------
  Widget _vazio() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(35, 40, 35, 60),
      child: Column(
        children: [
          Container(
            width: 75,
            height: 75,
            decoration: const BoxDecoration(
              color: Color(0x1A7C3AED),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search_off_rounded, color: c.roxoClaro, size: 34),
          ),
          const SizedBox(height: 17),
          Text(
            'Nenhum produto encontrado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.texto,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Tente pesquisar outro produto ou categoria.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textoSuave, fontSize: 12),
          ),
        ],
      ),
    );
  }
}