import 'package:flutter/material.dart';
import 'tema.dart';
import 'api_service.dart';

class Vendas extends StatefulWidget {
  const Vendas({super.key});

  @override
  State<Vendas> createState() => _VendasState();
}

class _VendasState extends State<Vendas> {
  AppCores get c => context.cores;

  static const List<String> statusOpcoes = [
    'Concluída',
    'Pendente',
    'Cancelada',
  ];

  final TextEditingController pesquisaController = TextEditingController();

  String filtroSelecionado = 'Todas';

  final List<Map<String, dynamic>> vendas = [];
  List<Map<String, dynamic>> produtosDisponiveis = [];
  List<Map<String, dynamic>> funcionariosDisponiveis = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    try {
      final resultados = await Future.wait([
        ApiService.vendas(),
        ApiService.produtos(),
        ApiService.funcionarios(),
      ]);
      if (!mounted) return;
      setState(() {
        vendas
          ..clear()
          ..addAll((resultados[0] as List).cast<Map<String, dynamic>>().map(_mapVenda));
        produtosDisponiveis = (resultados[1] as List).cast<Map<String, dynamic>>();
        funcionariosDisponiveis = (resultados[2] as List).cast<Map<String, dynamic>>();
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => carregando = false);
      _mensagem(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Map<String, dynamic> _mapVenda(Map<String, dynamic> item) {
    final created = item['createdAt']?.toString();
    return {
      ...item,
      'id': item['_id']?.toString(),
      'cliente': item['name']?.toString() ?? 'Cliente',
      'pedido': '#${item['Numero']?.toString() ?? item['_id']?.toString().substring(0, 6) ?? '0'}',
      'valor': _numero(item['Preco_gasto']),
      'status': item['status']?.toString() ?? 'Concluída',
      'horario': created != null ? _formatarData(created) : 'Agora',
      'itens': _numero(item['Quantidade']).round(),
    };
  }

  double _numero(dynamic valor) => valor is num ? valor.toDouble() : double.tryParse(valor?.toString().replaceAll(',', '.') ?? '') ?? 0;

  String _formatarData(String valor) {
    final data = DateTime.tryParse(valor)?.toLocal();
    if (data == null) return 'Agora';
    return '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')} ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    pesquisaController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get vendasFiltradas {
    final pesquisa = pesquisaController.text.toLowerCase().trim();

    return vendas.where((venda) {
      final cliente = venda['cliente'].toString().toLowerCase();
      final pedido = venda['pedido'].toString().toLowerCase();

      final busca =
          pesquisa.isEmpty ||
          cliente.contains(pesquisa) ||
          pedido.contains(pesquisa);

      final filtro =
          filtroSelecionado == 'Todas' || venda['status'] == filtroSelecionado;

      return busca && filtro;
    }).toList();
  }

  double get faturamento {
    return vendas
        .where((v) => v['status'] == 'Concluída')
        .fold<double>(
          0,
          (total, venda) => total + (venda['valor'] as num).toDouble(),
        );
  }

  int _contar(String status) =>
      vendas.where((v) => v['status'] == status).length;

  int get vendasConcluidas => _contar('Concluída');
  int get vendasPendentes => _contar('Pendente');
  int get vendasCanceladas => _contar('Cancelada');

  int get itensVendidos {
    return vendas
        .where((v) => v['status'] == 'Concluída')
        .fold<int>(0, (total, v) => total + (v['itens'] as int));
  }

  double get ticketMedio {
    if (vendasConcluidas == 0) return 0;
    return faturamento / vendasConcluidas;
  }

  int get taxaConclusao {
    if (vendas.isEmpty) return 0;
    return (vendasConcluidas * 100 / vendas.length).round();
  }

  Color corClara(Color cor, int alpha) => cor.withAlpha(alpha);

  Color _corStatus(String status) {
    switch (status) {
      case 'Concluída':
        return c.verde;
      case 'Pendente':
        return c.amarelo;
      default:
        return c.vermelho;
    }
  }

  IconData _iconeStatus(String status) {
    switch (status) {
      case 'Concluída':
        return Icons.check_circle_outline_rounded;
      case 'Pendente':
        return Icons.schedule_rounded;
      default:
        return Icons.cancel_outlined;
    }
  }

  BoxDecoration _decoracaoCard({double raio = 24}) {
    return BoxDecoration(
      gradient: c.gradCard,
      borderRadius: BorderRadius.circular(raio),
      border: Border.all(color: c.bordaSutil),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lista = vendasFiltradas;

    return Scaffold(
      backgroundColor: c.fundo,
      floatingActionButton: _botaoNovaVenda(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: c.gradFundo),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(19, 15, 19, 110),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _cabecalho(),
                    const SizedBox(height: 25),
                    _cardFaturamento(),
                    const SizedBox(height: 20),
                    _indicadores(),
                    const SizedBox(height: 28),
                    _titulo(
                      'Desempenho',
                      'Acompanhe suas vendas durante a semana',
                    ),
                    const SizedBox(height: 13),
                    _grafico(),
                    const SizedBox(height: 28),
                    _titulo(
                      'Vendas recentes',
                      'Pedidos e movimentações realizadas',
                      extra:
                          '${lista.length} ${lista.length == 1 ? 'registro' : 'registros'}',
                    ),
                    const SizedBox(height: 15),
                    _barraPesquisa(),
                    const SizedBox(height: 12),
                    _filtros(),
                    const SizedBox(height: 12),
                    if (lista.isEmpty)
                      _vazio()
                    else
                      ...lista.map(
                        (venda) => Padding(
                          padding: const EdgeInsets.only(bottom: 11),
                          child: _cardVenda(venda),
                        ),
                      ),
                  ]),
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
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: AppCores.gradRoxo,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x422563EB),
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.point_of_sale_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GERENCIAMNETO DE VENDAS',
                style: TextStyle(
                  color: c.textoFraco,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Vendas',
                style: TextStyle(
                  color: c.texto,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _botaoCabecalho(
          icon: Icons.notifications_rounded,
          notificacao: true,
          onTap: _abrirNotificacoes,
        ),
        const SizedBox(width: 8),
        _botaoCabecalho(icon: Icons.more_horiz_rounded, onTap: _abrirOpcoes),
      ],
    );
  }

  Widget _botaoCabecalho({
    required IconData icon,
    required VoidCallback onTap,
    bool notificacao = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.basic,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            gradient: c.gradCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.bordaMedia),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(icon, color: c.texto, size: 20),
              if (notificacao)
                Positioned(
                  top: 7,
                  right: 7,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: c.vermelho,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.fundo, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardFaturamento() {
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
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
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
                      'Resumo das vendas',
                      style: TextStyle(
                        color: c.texto,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Acompanhe o desempenho do seu negócio',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.textoFraco, fontSize: 9),
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
                  color: const Color(0x1C34D399),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up_rounded, color: c.verde, size: 13),
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            _dinheiro(faturamento),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: c.texto,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Faturamento das vendas concluídas',
            style: TextStyle(color: c.textoSuave, fontSize: 10),
          ),
          const SizedBox(height: 19),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0x182563EB),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (taxaConclusao / 100).clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [c.roxo, c.roxoClaro]),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$taxaConclusao% concluídas',
                style: TextStyle(
                  color: c.roxoClaro,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(height: 1, color: c.bordaSutil),
          const SizedBox(height: 16),
          Row(
            children: [
              _infoDestaque(
                'Ticket médio',
                _dinheiro(ticketMedio),
                c.verde,
                Icons.account_balance_wallet_outlined,
              ),
              _infoDestaque(
                'Pedidos',
                '${vendas.length}',
                c.azul,
                Icons.receipt_long_outlined,
              ),
              _infoDestaque(
                'Itens',
                '$itensVendidos',
                c.roxoClaro,
                Icons.shopping_bag_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoDestaque(String titulo, String valor, Color cor, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: corClara(cor, 24),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: cor, size: 13),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(color: c.textoFraco, fontSize: 9),
                ),
                const SizedBox(height: 4),
                Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: cor,
                    fontSize: 10,
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

  Widget _indicadores() {
    return Row(
      children: [
        Expanded(
          child: _indicador(
            icon: Icons.check_circle_outline_rounded,
            titulo: 'Concluídas',
            valor: '$vendasConcluidas',
            cor: c.verde,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _indicador(
            icon: Icons.schedule_rounded,
            titulo: 'Pendentes',
            valor: '$vendasPendentes',
            cor: c.amarelo,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _indicador(
            icon: Icons.cancel_outlined,
            titulo: 'Canceladas',
            valor: '$vendasCanceladas',
            cor: c.vermelho,
          ),
        ),
      ],
    );
  }

  Widget _indicador({
    required IconData icon,
    required String titulo,
    required String valor,
    required Color cor,
  }) {
    return Container(
      height: 118,
      padding: const EdgeInsets.all(13),
      decoration: _decoracaoCard(raio: 21),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 37,
            height: 37,
            decoration: BoxDecoration(
              color: corClara(cor, 27),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: cor, size: 18),
          ),
          const Spacer(),
          Text(
            valor,
            style: TextStyle(
              color: c.texto,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: c.textoSuave, fontSize: 9),
          ),
        ],
      ),
    );
  }

  Widget _titulo(String titulo, String subtitulo, {String? extra}) {
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
        if (extra != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0x182563EB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              extra,
              style: TextStyle(
                color: c.roxoClaro,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }

  Widget _grafico() {
    return Container(
      height: 285,
      padding: const EdgeInsets.fromLTRB(17, 18, 17, 14),
      decoration: _decoracaoCard(),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0x1F7C3AED),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  color: c.roxoClaro,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vendas da semana',
                      style: TextStyle(
                        color: c.texto,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Quantidade de vendas por dia',
                      style: TextStyle(color: c.textoFraco, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Expanded(
            child: CustomPaint(
              painter: _GraficoVendasPainter(c.bordaSutil),
              child: const SizedBox.expand(),
            ),
          ),
          const SizedBox(height: 9),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _DiaSemana('Seg'),
              _DiaSemana('Ter'),
              _DiaSemana('Qua'),
              _DiaSemana('Qui'),
              _DiaSemana('Sex', destaque: true),
              _DiaSemana('Sáb'),
              _DiaSemana('Dom'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _barraPesquisa() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: c.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.bordaMedia),
      ),
      child: TextField(
        controller: pesquisaController,
        onChanged: (_) => setState(() {}),
        cursorColor: c.roxoClaro,
        style: TextStyle(color: c.texto, fontSize: 12),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Buscar venda, cliente ou pedido...',
          hintStyle: TextStyle(color: c.textoFraco, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          prefixIcon: Icon(Icons.search_rounded, color: c.textoFraco, size: 20),
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
        ),
      ),
    );
  }

  Widget _filtros() {
    const opcoes = ['Todas', ...statusOpcoes];

    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: opcoes.length,
        itemBuilder: (context, index) {
          final item = opcoes[index];

          return _chipSelecao(
            item,
            filtroSelecionado == item,
            () => setState(() => filtroSelecionado = item),
          );
        },
      ),
    );
  }

  Widget _chipSelecao(String label, bool selecionado, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          gradient: selecionado
              ? const LinearGradient(
                  colors: [Color(0x322563EB), Color(0x182563EB)],
                )
              : null,
          color: selecionado ? null : c.superficie,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selecionado ? const Color(0x357C3AED) : c.bordaSutil,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selecionado ? c.texto : c.textoSuave,
            fontSize: 10,
            fontWeight: selecionado ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _cardVenda(Map<String, dynamic> venda) {
    final status = venda['status'] as String;
    final corStatus = _corStatus(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _detalhesVenda(venda),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: _decoracaoCard(),
          child: Row(
            children: [
              Container(
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: corClara(c.roxoClaro, 30),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: corClara(c.roxoClaro, 38)),
                ),
                child: Center(
                  child: Text(
                    _iniciais(venda['cliente']),
                    style: TextStyle(
                      color: c.roxoClaro,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venda['cliente'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.texto,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${venda['pedido']} • ${venda['horario']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.textoFraco, fontSize: 10),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          color: c.textoFraco,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${venda['itens']} ${venda['itens'] == 1 ? 'item' : 'itens'}',
                          style: TextStyle(color: c.textoSuave, fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _dinheiro(venda['valor']),
                    style: TextStyle(
                      color: c.texto,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: corClara(corStatus, 24),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: corClara(corStatus, 40)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_iconeStatus(status), color: corStatus, size: 11),
                        const SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                            color: corStatus,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _vazio() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: _decoracaoCard(),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: corClara(c.roxoClaro, 27),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.search_off_rounded, color: c.roxoClaro, size: 28),
          ),
          const SizedBox(height: 15),
          Text(
            'Nenhuma venda encontrada',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.texto,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tente mudar os filtros ou pesquisar outro cliente.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textoSuave, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _botaoNovaVenda() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppCores.gradRoxo,
        borderRadius: BorderRadius.circular(19),
        boxShadow: const [
          BoxShadow(
            color: Color(0x552563EB),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _novaVenda,
          borderRadius: BorderRadius.circular(19),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_shopping_cart_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 9),
                Text(
                  'Nova venda',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
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

  Widget _botaoPrincipal({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
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
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
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

  Future<void> _sheet({required Widget child, double alturaMaxima = 0.86}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return FractionallySizedBox(
          heightFactor: alturaMaxima,
          child: Container(
            decoration: BoxDecoration(
              gradient: c.gradSheet,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 45,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.textoFraco,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        22,
                        0,
                        22,
                        28 + MediaQuery.of(sheetContext).viewInsets.bottom,
                      ),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _tituloSheet(String titulo, String subtitulo) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: c.texto,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(subtitulo, style: TextStyle(color: c.textoSuave, fontSize: 11)),
        ],
      ),
    );
  }

  void _abrirNotificacoes() {
    _sheet(
      alturaMaxima: 0.78,
      child: Column(
        children: [
          _tituloSheet(
            'Notificações',
            'Acompanhe os avisos importantes das suas vendas',
          ),
          const SizedBox(height: 21),
          if (vendasPendentes > 0)
            _notificacaoItem(
              icon: Icons.schedule_rounded,
              titulo: 'Venda pendente',
              descricao:
                  '$vendasPendentes ${vendasPendentes == 1 ? 'venda está' : 'vendas estão'} aguardando atenção.',
              cor: c.amarelo,
              horario: 'Agora',
            ),
          _notificacaoItem(
            icon: Icons.trending_up_rounded,
            titulo: 'Faturamento atualizado',
            descricao:
                'Seu faturamento atual é ${_dinheiro(faturamento)} em vendas concluídas.',
            cor: c.verde,
            horario: 'Hoje',
          ),
          _notificacaoItem(
            icon: Icons.receipt_long_rounded,
            titulo: 'Novos pedidos',
            descricao:
                '${vendas.length} pedidos registrados no histórico de vendas.',
            cor: c.roxoClaro,
            horario: 'Hoje',
          ),
          _notificacaoItem(
            icon: Icons.bar_chart_rounded,
            titulo: 'Desempenho semanal',
            descricao:
                'Confira o gráfico para acompanhar o desempenho das suas vendas.',
            cor: c.azul,
            horario: 'Hoje',
          ),
          _notificacaoItem(
            icon: Icons.trending_up_rounded,
            titulo: 'Meta de vendas',
            descricao: 'Seu desempenho semanal continua em evolução.',
            cor: c.roxoClaro,
            horario: '5h',
          ),
          _notificacaoItem(
            icon: Icons.check_circle_outline_rounded,
            titulo: 'Sistema atualizado',
            descricao: 'Os dados da tela de vendas estão atualizados.',
            cor: c.verde,
            horario: 'Ontem',
          ),
        ],
      ),
    );
  }

  Widget _notificacaoItem({
    required IconData icon,
    required String titulo,
    required String descricao,
    required Color cor,
    required String horario,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: c.fundo2,
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: c.bordaSutil),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: corClara(cor, 27),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: cor, size: 21),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          titulo,
                          style: TextStyle(
                            color: c.texto,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        horario,
                        style: TextStyle(color: c.textoFraco, fontSize: 9),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    descricao,
                    style: TextStyle(
                      color: c.textoSuave,
                      fontSize: 10,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _abrirOpcoes() {
    _sheet(
      alturaMaxima: 0.65,
      child: Column(
        children: [
          _tituloSheet(
            'Opções de vendas',
            'Acesse rapidamente os recursos desta tela',
          ),
          const SizedBox(height: 21),
          _itemOpcao(
            icon: Icons.filter_list_rounded,
            titulo: 'Filtrar vendas',
            subtitulo: 'Escolha quais pedidos deseja visualizar',
            cor: c.roxoClaro,
            onTap: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 180), _abrirFiltros);
            },
          ),
          _itemOpcao(
            icon: Icons.add_shopping_cart_rounded,
            titulo: 'Nova venda',
            subtitulo: 'Registre uma nova venda no EasySell',
            cor: c.verde,
            onTap: () {
              Navigator.pop(context);
              Future.delayed(const Duration(milliseconds: 180), _novaVenda);
            },
          ),
          _itemOpcao(
            icon: Icons.refresh_rounded,
            titulo: 'Atualizar dados',
            subtitulo: 'Atualize os indicadores e pedidos',
            cor: c.azul,
            onTap: () {
              Navigator.pop(context);
              setState(() {});
              _mensagem('Dados atualizados!');
            },
          ),
        ],
      ),
    );
  }

  Widget _itemOpcao({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: c.fundo2,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: c.bordaSutil),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: corClara(cor, 27),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: cor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          color: c.texto,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitulo,
                        style: TextStyle(color: c.textoSuave, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: c.textoFraco,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _abrirFiltros() {
    _sheet(
      alturaMaxima: 0.7,
      child: Column(
        children: [
          _tituloSheet(
            'Filtros de vendas',
            'Escolha quais vendas deseja visualizar',
          ),
          const SizedBox(height: 21),
          _itemFiltro(
            'Todas as vendas',
            '${vendas.length} pedidos no total',
            Icons.list_alt_rounded,
            'Todas',
            c.roxoClaro,
          ),
          _itemFiltro(
            'Concluídas',
            '$vendasConcluidas pedidos',
            Icons.check_circle_outline_rounded,
            'Concluída',
            c.verde,
          ),
          _itemFiltro(
            'Pendentes',
            '$vendasPendentes pedidos',
            Icons.schedule_rounded,
            'Pendente',
            c.amarelo,
          ),
          _itemFiltro(
            'Canceladas',
            '$vendasCanceladas pedidos',
            Icons.cancel_outlined,
            'Cancelada',
            c.vermelho,
          ),
        ],
      ),
    );
  }

  Widget _itemFiltro(
    String titulo,
    String subtitulo,
    IconData icon,
    String valor,
    Color cor,
  ) {
    final selecionado = filtroSelecionado == valor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => filtroSelecionado = valor);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(19),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: c.fundo2,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(
                color: selecionado ? const Color(0x552563EB) : c.bordaSutil,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: corClara(cor, 28),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: cor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          color: c.texto,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitulo,
                        style: TextStyle(color: c.textoSuave, fontSize: 10),
                      ),
                    ],
                  ),
                ),
                if (selecionado)
                  Icon(
                    Icons.check_circle_rounded,
                    color: c.roxoClaro,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _detalhesVenda(Map<String, dynamic> venda) {
    final statusOriginal = venda['status'] as String;
    String statusSel = statusOriginal;

    _sheet(
      child: StatefulBuilder(
        builder: (context, setSheet) {
          return Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      gradient: AppCores.gradRoxo,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x422563EB),
                          blurRadius: 22,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _iniciais(venda['cliente']),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          venda['cliente'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.texto,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${venda['pedido']} • ${venda['horario']}',
                          style: TextStyle(
                            color: c.roxoClaro,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  _detalhe(
                    'Valor',
                    _dinheiro(venda['valor']),
                    Icons.payments_outlined,
                    c.verde,
                  ),
                  const SizedBox(width: 10),
                  _detalhe(
                    'Itens',
                    '${venda['itens']}',
                    Icons.shopping_bag_outlined,
                    c.azul,
                  ),
                  const SizedBox(width: 10),
                  _detalhe(
                    'Status',
                    statusSel,
                    _iconeStatus(statusSel),
                    _corStatus(statusSel),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ALTERAR STATUS',
                  style: TextStyle(
                    color: c.textoFraco,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (int i = 0; i < statusOpcoes.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _opcaoStatus(
                      statusOpcoes[i],
                      statusSel == statusOpcoes[i],
                      () => setSheet(() => statusSel = statusOpcoes[i]),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 22),
              _botaoPrincipal(
                label: statusSel == statusOriginal
                    ? 'Fechar detalhes'
                    : 'Salvar alterações',
                icon: Icons.check_rounded,
                onTap: () {
                  if (statusSel == statusOriginal) {
                    Navigator.pop(context);
                    return;
                  }

                  final id = venda['id']?.toString();
                  if (id == null || id.isEmpty) {
                    Navigator.pop(context);
                    _mensagem('Venda sem identificador no banco.');
                    return;
                  }
                  () async {
                    try {
                      final atualizada = await ApiService.atualizarVenda(id, statusSel);
                      if (!mounted) return;
                      setState(() {
                        final index = vendas.indexOf(venda);
                        if (index >= 0) vendas[index] = _mapVenda(atualizada);
                      });
                      Navigator.pop(context);
                      _mensagem('Venda ${venda['pedido']} atualizada.');
                    } catch (e) {
                      setSheet(() => statusSel = statusOriginal);
                      _mensagem(e.toString().replaceFirst('Exception: ', ''));
                    }
                  }();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _opcaoStatus(String status, bool selecionado, VoidCallback onTap) {
    final cor = _corStatus(status);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: selecionado ? corClara(cor, 36) : c.fundo2,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selecionado ? corClara(cor, 130) : c.bordaSutil,
                width: selecionado ? 1.5 : 1,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _iconeStatus(status),
                  color: selecionado ? cor : c.textoFraco,
                  size: 21,
                ),
                const SizedBox(height: 7),
                Text(
                  status,
                  style: TextStyle(
                    color: selecionado ? cor : c.textoSuave,
                    fontSize: 10,
                    fontWeight: selecionado ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detalhe(String titulo, String valor, IconData icon, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: c.fundo2,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.bordaSutil),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: corClara(cor, 27),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: cor, size: 16),
            ),
            const SizedBox(height: 10),
            Text(titulo, style: TextStyle(color: c.textoFraco, fontSize: 9)),
            const SizedBox(height: 4),
            Text(
              valor,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.texto,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _novaVenda() {
    final clienteController = TextEditingController();
    final valorController = TextEditingController();
    final itensController = TextEditingController(text: '1');
    String? produtoIdSel = produtosDisponiveis.isNotEmpty ? produtosDisponiveis.first['_id']?.toString() : null;
    String? funcionarioIdSel = funcionariosDisponiveis.isNotEmpty ? funcionariosDisponiveis.first['_id']?.toString() : null;

    String statusSel = 'Concluída';
    String? erro;

    _sheet(
      alturaMaxima: 0.94,
      child: StatefulBuilder(
        builder: (context, setSheet) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tituloSheet('Nova venda', 'Registre uma nova venda no EasySell'),
              const SizedBox(height: 21),
              _rotuloCampo('Cliente'),
              const SizedBox(height: 8),
              _campo(
                clienteController,
                'Nome do cliente',
                Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              _rotuloCampo('Valor da venda'),
              const SizedBox(height: 8),
              _campo(
                valorController,
                'Ex.: 189,90',
                Icons.payments_outlined,
                teclado: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              _rotuloCampo('Quantidade de itens'),
              const SizedBox(height: 8),
              _campo(
                itensController,
                'Ex.: 3',
                Icons.shopping_bag_outlined,
                teclado: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _rotuloCampo('Produto'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: produtoIdSel,
                dropdownColor: c.fundo2,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.inventory_2_outlined, color: c.roxoClaro),
                  filled: true,
                  fillColor: c.fundo2,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: c.bordaSutil)),
                ),
                items: produtosDisponiveis.map((p) => DropdownMenuItem<String>(
                  value: p['_id']?.toString(),
                  child: Text(p['name']?.toString() ?? 'Produto', style: TextStyle(color: c.texto)),
                )).toList(),
                onChanged: (value) => setSheet(() => produtoIdSel = value),
              ),
              const SizedBox(height: 16),
              _rotuloCampo('Funcionário responsável'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: funcionarioIdSel,
                dropdownColor: c.fundo2,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.badge_outlined, color: c.roxoClaro),
                  hintText: funcionariosDisponiveis.isEmpty
                      ? 'Nenhum funcionário cadastrado'
                      : 'Selecione o funcionário',
                  hintStyle: TextStyle(color: c.textoFraco, fontSize: 11),
                  filled: true,
                  fillColor: c.fundo2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: c.bordaSutil),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: c.bordaSutil),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: c.roxoClaro),
                  ),
                ),
                items: funcionariosDisponiveis.map((funcionario) {
                  return DropdownMenuItem<String>(
                    value: funcionario['_id']?.toString(),
                    child: Text(
                      funcionario['name']?.toString() ?? 'Funcionário',
                      style: TextStyle(color: c.texto, fontSize: 11),
                    ),
                  );
                }).toList(),
                onChanged: funcionariosDisponiveis.isEmpty
                    ? null
                    : (value) => setSheet(() => funcionarioIdSel = value),
              ),
              const SizedBox(height: 16),
              _rotuloCampo('Status'),
              const SizedBox(height: 10),
              Wrap(
                children: statusOpcoes
                    .map(
                      (s) => _chipSelecao(
                        s,
                        statusSel == s,
                        () => setSheet(() => statusSel = s),
                      ),
                    )
                    .toList(),
              ),
              if (erro != null) ...[
                const SizedBox(height: 4),
                Text(
                  erro!,
                  style: TextStyle(
                    color: c.vermelho,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 22),
              _botaoPrincipal(
                label: 'Registrar venda',
                icon: Icons.check_rounded,
                onTap: () {
                  final cliente = clienteController.text.trim();
                  final valor = _lerValor(valorController.text);
                  final itens = int.tryParse(itensController.text.trim());

                  if (cliente.isEmpty) {
                    setSheet(() => erro = 'Informe o nome do cliente.');
                    return;
                  }

                  if (valor == null || valor <= 0) {
                    setSheet(() => erro = 'Digite um valor válido.');
                    return;
                  }

                  if (itens == null || itens <= 0) {
                    setSheet(() => erro = 'Informe a quantidade de itens.');
                    return;
                  }

                  if (produtoIdSel == null || produtoIdSel!.isEmpty) {
                    setSheet(() => erro = 'Cadastre pelo menos um produto antes de registrar a venda.');
                    return;
                  }
                  () async {
                    try {
                      final criada = await ApiService.criarVenda(
                        cliente: cliente,
                        pedido: _proximoPedido().toString(),
                        produtoId: produtoIdSel!,
                        valor: valor,
                        itens: itens,
                        status: statusSel,
                        funcionarioId: funcionarioIdSel,
                      );
                      if (!mounted) return;
                      setState(() => vendas.insert(0, _mapVenda(criada)));
                      Navigator.pop(context);
                      _mensagem('Venda registrada com sucesso!');
                    } catch (e) {
                      setSheet(() => erro = e.toString().replaceFirst('Exception: ', ''));
                    }
                  }();
                },
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      clienteController.dispose();
      valorController.dispose();
      itensController.dispose();
    });
  }

  Widget _rotuloCampo(String texto) {
    return Text(
      texto.toUpperCase(),
      style: TextStyle(
        color: c.textoFraco,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _campo(
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType? teclado,
  }) {
    return TextField(
      controller: controller,
      keyboardType: teclado,
      cursorColor: c.roxoClaro,
      style: TextStyle(color: c.texto, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textoFraco, fontSize: 12),
        prefixIcon: Icon(icon, color: c.roxoClaro, size: 19),
        filled: true,
        fillColor: c.fundo2,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c.bordaSutil),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x552563EB)),
        ),
      ),
    );
  }

  int _proximoPedido() {
    var maior = 1000;

    for (final venda in vendas) {
      final numero = int.tryParse(
        venda['pedido'].toString().replaceAll('#', ''),
      );

      if (numero != null && numero > maior) {
        maior = numero;
      }
    }

    return maior + 1;
  }

  double? _lerValor(String texto) {
    var t = texto.trim().replaceAll('R\$', '').replaceAll(' ', '');

    if (t.contains(',')) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    }

    return double.tryParse(t);
  }

  String _iniciais(String nome) {
    final partes = nome
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();

    if (partes.isEmpty) return '?';

    if (partes.length == 1) {
      final p = partes.first;
      return p.substring(0, p.length >= 2 ? 2 : 1).toUpperCase();
    }

    return '${partes.first[0]}${partes.last[0]}'.toUpperCase();
  }

  String _dinheiro(dynamic valor) {
    final numero = valor is num
        ? valor.toDouble()
        : double.tryParse(valor.toString()) ?? 0.0;

    final partes = numero.toStringAsFixed(2).split('.');

    final inteiro = partes[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => '.',
    );

    return 'R\$ $inteiro,${partes[1]}';
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            texto,
            style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 12),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF181F31),
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: c.bordaSutil),
          ),
        ),
      );
  }
}

class _DiaSemana extends StatelessWidget {
  final String texto;
  final bool destaque;

  const _DiaSemana(this.texto, {this.destaque = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: TextStyle(
        color: destaque ? context.cores.roxoClaro : context.cores.textoFraco,
        fontSize: 9,
        fontWeight: destaque ? FontWeight.w900 : FontWeight.w600,
      ),
    );
  }
}

class _GraficoVendasPainter extends CustomPainter {
  final Color corGrade;

  _GraficoVendasPainter(this.corGrade);

  final List<double> pontos = const [0.78, 0.62, 0.70, 0.48, 0.08, 0.58, 0.66];

  @override
  void paint(Canvas canvas, Size size) {
    final grade = Paint()
      ..color = corGrade
      ..strokeWidth = 1;

    for (int i = 0; i < 4; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grade);
    }

    final caminho = Path();
    final preenchimento = Path();

    for (int i = 0; i < pontos.length; i++) {
      final x = size.width * i / (pontos.length - 1);
      final y = size.height * pontos[i];

      if (i == 0) {
        caminho.moveTo(x, y);
        preenchimento.moveTo(x, size.height);
        preenchimento.lineTo(x, y);
      } else {
        caminho.lineTo(x, y);
        preenchimento.lineTo(x, y);
      }
    }

    preenchimento.lineTo(size.width, size.height);
    preenchimento.close();

    final area = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x447C3AED), Color(0x057C3AED)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(preenchimento, area);

    final brilho = Paint()
      ..color = const Color(0x407C3AED)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

    canvas.drawPath(caminho, brilho);

    final linha = Paint()
      ..color = const Color(0xFF60A5FA)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(caminho, linha);

    for (int i = 0; i < pontos.length; i++) {
      final x = size.width * i / (pontos.length - 1);
      final y = size.height * pontos[i];

      final destaque = i == 4;

      if (destaque) {
        canvas.drawCircle(
          Offset(x, y),
          9,
          Paint()
            ..color = const Color(0x4034D399)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );

        canvas.drawCircle(
          Offset(x, y),
          4.5,
          Paint()..color = const Color(0xFF34D399),
        );
      } else {
        canvas.drawCircle(
          Offset(x, y),
          3.5,
          Paint()..color = const Color(0xFFFFFFFF),
        );

        canvas.drawCircle(
          Offset(x, y),
          2,
          Paint()..color = const Color(0xFF2563EB),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _GraficoVendasPainter ||
        oldDelegate.corGrade != corGrade;
  }
}
