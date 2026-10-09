import 'package:flutter/material.dart';

import 'tema.dart';
import 'api_service.dart';

class Equipe extends StatefulWidget {
  const Equipe({super.key});

  @override
  State<Equipe> createState() => _EquipeState();
}

class _EquipeState extends State<Equipe> {
  AppCores get c => context.cores;

  // ---------------------------------------------------------------
  // Dados
  // ---------------------------------------------------------------
  static const List<String> cargos = ['Vendedor', 'Gerente', 'Atendimento'];

  static const List<String> statusOpcoes = ['Ativo', 'Férias'];

  final pesquisaController = TextEditingController();

  String filtro = 'Todos';

  final List<Map<String, dynamic>> funcionarios = [];
  List<Map<String, dynamic>> vendas = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarEquipe();
  }

  Future<void> _carregarEquipe() async {
    try {
      final dados = await Future.wait([
        ApiService.funcionarios(),
        ApiService.vendas(),
      ]);
      if (!mounted) return;
      setState(() {
        vendas = (dados[1] as List).cast<Map<String, dynamic>>();
        funcionarios
          ..clear()
          ..addAll((dados[0] as List).cast<Map<String, dynamic>>().map(_mapFuncionario));
        _atualizarDesempenhos();
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => carregando = false);
      _mensagem(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Map<String, dynamic> _mapFuncionario(Map<String, dynamic> item) {
    final id = item['_id']?.toString() ?? '';
    final vendasFuncionario = vendas.where((venda) {
      return venda['funcionarioId']?.toString() == id &&
          (venda['status']?.toString() ?? 'Concluída') == 'Concluída';
    }).toList();
    final faturamentoFuncionario = vendasFuncionario.fold<double>(
      0,
      (total, venda) => total + _numero(venda['Preco_gasto']),
    );

    return {
      ...item,
      'id': id,
      'nome': item['name']?.toString() ?? '',
      'cpf': item['cpf']?.toString() ?? '',
      'cargo': item['funcao']?.toString() ?? 'Vendedor',
      'vendas': vendasFuncionario.length,
      'faturamento': faturamentoFuncionario,
      'desempenho': 0,
      'status': item['status']?.toString() ?? 'Ativo',
    };
  }

  double _numero(dynamic valor) {
    return valor is num
        ? valor.toDouble()
        : double.tryParse(valor?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }

  void _atualizarDesempenhos() {
    final maior = funcionarios.fold<double>(
      0,
      (maiorAtual, item) =>
          (item['faturamento'] as num).toDouble() > maiorAtual
              ? (item['faturamento'] as num).toDouble()
              : maiorAtual,
    );

    for (final item in funcionarios) {
      final faturamentoItem = (item['faturamento'] as num).toDouble();
      item['desempenho'] = maior <= 0 ? 0 : ((faturamentoItem / maior) * 100).round();
    }
  }

  List<Map<String, dynamic>> get listaFiltrada {
    final busca = pesquisaController.text.toLowerCase().trim();

    return funcionarios.where((item) {
      final nome = item['nome'].toString().toLowerCase();
      final cargo = item['cargo'].toString().toLowerCase();

      final pesquisa =
          busca.isEmpty || nome.contains(busca) || cargo.contains(busca);

      final cargoFiltro = filtro == 'Todos' || item['cargo'] == filtro;

      return pesquisa && cargoFiltro;
    }).toList();
  }

  int get ativos =>
      funcionarios.where((item) => item['status'] == 'Ativo').length;

  int get emFerias =>
      funcionarios.where((item) => item['status'] == 'Férias').length;

  double get faturamento {
    return funcionarios.fold<double>(
      0,
      (total, item) => total + (item['faturamento'] as num).toDouble(),
    );
  }

  double get desempenho {
    if (funcionarios.isEmpty) return 0;

    final total = funcionarios.fold<int>(
      0,
      (total, item) => total + (item['desempenho'] as int),
    );

    return total / funcionarios.length;
  }

  @override
  void dispose() {
    pesquisaController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Helpers de estilo
  // ---------------------------------------------------------------
  Color corClara(Color cor, int alpha) => cor.withAlpha(alpha);

  Color _corDesempenho(num valor) {
    if (valor >= 85) return c.verde;
    if (valor >= 70) return c.amarelo;
    return c.vermelho;
  }

  String _rotuloDesempenho(num valor) {
    if (valor >= 85) return 'Excelente';
    if (valor >= 70) return 'Bom desempenho';
    if (valor >= 50) return 'Desempenho regular';
    return 'Precisa melhorar';
  }

  BoxDecoration _decoracaoCard({double raio = 24}) {
    return BoxDecoration(
      gradient: c.gradCard,
      borderRadius: BorderRadius.circular(raio),
      border: Border.all(color: c.bordaSutil),
    );
  }

  // ---------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final lista = listaFiltrada;

    return Scaffold(
      backgroundColor: c.fundo,
      floatingActionButton: _botaoAdicionar(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: c.gradFundo),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(19, 15, 19, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _cabecalho(),
                    const SizedBox(height: 27),
                    _saudacao(),
                    const SizedBox(height: 21),
                    _cardDesempenho(),
                    const SizedBox(height: 22),
                    _indicadores(),
                    const SizedBox(height: 22),
                    _pesquisa(),
                    const SizedBox(height: 14),
                    _filtros(),
                    const SizedBox(height: 26),
                    _titulo(
                      'Membros da equipe',
                      'Resultados e informações',
                      '${lista.length} '
                          '${lista.length == 1 ? 'pessoa' : 'pessoas'}',
                    ),
                    const SizedBox(height: 13),
                    if (lista.isEmpty)
                      _vazio()
                    else
                      ...lista.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _funcionario(item),
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

  // ---------------------------------------------------------------
  // Cabeçalho
  // ---------------------------------------------------------------
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
          child: const Center(
            child: Icon(Icons.groups_rounded, color: Colors.white, size: 25),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GERENCIAMENTO DE EQUIPE',
                style: TextStyle(
                  color: c.textoFraco,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Equipe',
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
          icon: Icons.refresh_rounded,
          onTap: _carregarEquipe,
        ),
        const SizedBox(width: 8),
        _botaoCabecalho(
          icon: Icons.notifications_rounded,
          notificacao: true,
          onTap: _notificacoes,
        ),
        const SizedBox(width: 8),
        _botaoCabecalho(icon: Icons.more_horiz_rounded, onTap: _menu),
      ],
    );
  }

  Widget _botaoCabecalho({
    required IconData icon,
    required VoidCallback onTap,
    bool notificacao = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: c.superficie,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.bordaMedia),
            ),
            child: Icon(icon, color: c.texto, size: 20),
          ),
          if (notificacao)
            Positioned(
              top: 5,
              right: 5,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: c.vermelho,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.superficie, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Saudação
  // ---------------------------------------------------------------
  Widget _saudacao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Sua equipe 👥',
                style: TextStyle(
                  color: c.texto,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0x1834D399),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: const Color(0x2634D399)),
              ),
              child: Row(
                children: [
                  Icon(Icons.circle, color: c.verde, size: 6),
                  const SizedBox(width: 5),
                  Text(
                    '$ativos ativos',
                    style: TextStyle(
                      color: c.verde,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          'Acompanhe o desempenho da sua equipe.',
          style: TextStyle(color: c.textoSuave, fontSize: 12),
        ),
        const SizedBox(height: 15),
        Container(
          width: 44,
          height: 4,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [c.roxo, c.roxoClaro]),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------
  // Card principal de desempenho
  // ---------------------------------------------------------------
  Widget _cardDesempenho() {
    final cor = _corDesempenho(desempenho);
    final total = funcionarios.length;

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
                  Icons.groups_rounded,
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
                      'Desempenho da equipe',
                      style: TextStyle(
                        color: c.texto,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Média geral dos funcionários',
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
                  color: corClara(cor, 28),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up_rounded, color: cor, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      _rotuloDesempenho(desempenho),
                      style: TextStyle(
                        color: cor,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            '${desempenho.toStringAsFixed(0)}%',
            style: TextStyle(
              color: c.texto,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Média de desempenho da equipe',
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
                    widthFactor: (desempenho / 100).clamp(0.0, 1.0),
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
                '$ativos de $total ativos',
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
                'Vendas',
                '${_totalVendas()}',
                c.azul,
                Icons.shopping_bag_outlined,
              ),
              _infoDestaque(
                'Faturamento',
                'R\$ ${_dinheiro(faturamento)}',
                c.verde,
                Icons.attach_money_rounded,
              ),
              _infoDestaque(
                'Férias',
                '$emFerias',
                c.amarelo,
                Icons.beach_access_outlined,
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

  // ---------------------------------------------------------------
  // Indicadores
  // ---------------------------------------------------------------
  Widget _indicadores() {
    final percentualAtivos = funcionarios.isEmpty
        ? 0
        : (ativos * 100 / funcionarios.length).round();

    return Row(
      children: [
        Expanded(
          child: _indicador(
            icon: Icons.groups_outlined,
            titulo: 'Funcionários',
            valor: '${funcionarios.length}',
            detalhe: 'total',
            cor: c.roxoClaro,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _indicador(
            icon: Icons.person_outline_rounded,
            titulo: 'Ativos',
            valor: '$ativos',
            detalhe: '$percentualAtivos%',
            cor: c.verde,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _indicador(
            icon: Icons.shopping_bag_outlined,
            titulo: 'Vendas',
            valor: '${_totalVendas()}',
            detalhe: 'total',
            cor: c.azul,
          ),
        ),
      ],
    );
  }

  Widget _indicador({
    required IconData icon,
    required String titulo,
    required String valor,
    required String detalhe,
    required Color cor,
  }) {
    return Container(
      height: 133,
      padding: const EdgeInsets.all(13),
      decoration: _decoracaoCard(raio: 21),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Icon(Icons.arrow_upward_rounded, color: cor, size: 13),
            ],
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
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.textoSuave, fontSize: 9),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                decoration: BoxDecoration(
                  color: corClara(cor, 25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  detalhe,
                  style: TextStyle(
                    color: cor,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Pesquisa e filtros
  // ---------------------------------------------------------------
  Widget _pesquisa() {
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
        style: TextStyle(color: c.texto, fontSize: 12),
        cursorColor: c.roxoClaro,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'Pesquisar na equipe...',
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
    const opcoes = ['Todos', ...cargos];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: opcoes.length,
        itemBuilder: (context, index) {
          final item = opcoes[index];

          return _chipSelecao(
            item,
            filtro == item,
            () => setState(() => filtro = item),
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
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selecionado ? c.texto : c.textoSuave,
              fontSize: 10,
              fontWeight: selecionado ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Título de seção (mesmo da Home)
  // ---------------------------------------------------------------
  Widget _titulo(String titulo, String subtitulo, String extra) {
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

  // ---------------------------------------------------------------
  // Card de funcionário
  // ---------------------------------------------------------------
  Widget _funcionario(Map<String, dynamic> item) {
    final nota = item['desempenho'] as int;
    final ativo = item['status'] == 'Ativo';
    final cor = _corDesempenho(nota);
    final corStatus = ativo ? c.verde : c.amarelo;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _detalhes(item),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: _decoracaoCard(),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: corClara(c.roxoClaro, 30),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: corClara(c.roxoClaro, 38)),
                    ),
                    child: Center(
                      child: Text(
                        _iniciais(item['nome']),
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
                          item['nome'],
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
                          item['cargo'],
                          style: TextStyle(color: c.textoFraco, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
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
                    child: Text(
                      item['status'],
                      style: TextStyle(
                        color: corStatus,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    color: c.sheetA,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: c.bordaSutil),
                    ),
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: c.textoSuave,
                      size: 18,
                    ),
                    onSelected: (valor) {
                      if (valor == 'editar') {
                        _editar(item);
                      } else {
                        _excluir(item);
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'editar',
                        child: Text(
                          'Editar',
                          style: TextStyle(color: c.texto, fontSize: 12),
                        ),
                      ),
                      PopupMenuItem(
                        value: 'excluir',
                        child: Text(
                          'Excluir',
                          style: TextStyle(color: c.vermelho, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 12,
                ),
                decoration: BoxDecoration(
                  color: c.fundo2,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: c.bordaSutil),
                ),
                child: Row(
                  children: [
                    _miniInfo(
                      Icons.shopping_bag_outlined,
                      '${item['vendas']}',
                      'Vendas',
                      c.azul,
                    ),
                    _miniInfo(
                      Icons.attach_money_rounded,
                      'R\$ ${_dinheiro(item['faturamento'])}',
                      'Faturamento',
                      c.verde,
                    ),
                    _miniInfo(
                      Icons.trending_up_rounded,
                      '$nota%',
                      'Desempenho',
                      cor,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              Row(
                children: [
                  Text(
                    'Desempenho',
                    style: TextStyle(color: c.textoFraco, fontSize: 9),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: corClara(cor, 28),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (nota / 100).clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$nota%',
                    style: TextStyle(
                      color: cor,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
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

  Widget _miniInfo(IconData icon, String valor, String titulo, Color cor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: cor, size: 13),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.texto,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(titulo, style: TextStyle(color: c.textoFraco, fontSize: 9)),
        ],
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
            child: Icon(Icons.groups_outlined, color: c.roxoClaro, size: 28),
          ),
          const SizedBox(height: 15),
          Text(
            'Nenhum funcionário encontrado',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.texto,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tente mudar a pesquisa ou o filtro.',
            textAlign: TextAlign.center,
            style: TextStyle(color: c.textoSuave, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Botão flutuante
  // ---------------------------------------------------------------
  Widget _botaoAdicionar() {
    return Container(
      width: 58,
      height: 58,
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
          onTap: _adicionar,
          borderRadius: BorderRadius.circular(19),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
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

  // ---------------------------------------------------------------
  // Bottom sheet padrão (mesmo estilo da Home)
  // ---------------------------------------------------------------
  Future<void> _sheet({required Widget child, double alturaMaxima = 0.86}) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * alturaMaxima,
          ),
          decoration: BoxDecoration(
            gradient: c.gradSheet,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                22,
                12,
                22,
                28 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Column(
                children: [
                  Container(
                    width: 45,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.textoFraco,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  const SizedBox(height: 24),
                  child,
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

  Widget _itemLista({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required Color cor,
    VoidCallback? onTap,
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
                if (onTap != null)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: c.textoFraco,
                    size: 15,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Adicionar / editar
  // ---------------------------------------------------------------
  void _adicionar() {
    _formulario(
      titulo: 'Novo funcionário',
      subtitulo: 'Cadastre um novo membro da equipe',
      botao: 'Adicionar funcionário',
      nomeInicial: '',
      cpfInicial: '',
      cargoInicial: cargos.first,
      statusInicial: 'Ativo',
      salvar: (nome, cpf, cargo, status) async {
        try {
          final criado = await ApiService.criarFuncionario(nome: nome, cpf: cpf, funcao: cargo, status: status);
          if (!mounted) return;
          setState(() {
            funcionarios.insert(0, _mapFuncionario(criado));
            _atualizarDesempenhos();
          });
          _mensagem('Funcionário adicionado!');
        } catch (e) {
          _mensagem(e.toString().replaceFirst('Exception: ', ''));
        }
      },
    );
  }

  void _editar(Map<String, dynamic> item) {
    final cargoAtual = item['cargo'].toString();
    _formulario(
      titulo: 'Editar funcionário',
      subtitulo: 'Atualize as informações do membro',
      botao: 'Salvar alterações',
      nomeInicial: item['nome'].toString(),
      cpfInicial: item['cpf'].toString(),
      cargoInicial: cargos.contains(cargoAtual) ? cargoAtual : cargos.first,
      statusInicial: item['status'].toString(),
      salvar: (nome, cpf, cargo, status) async {
        final id = item['id']?.toString();
        if (id == null || id.isEmpty) {
          _mensagem('Funcionário sem identificador no banco.');
          return;
        }
        try {
          final atualizado = await ApiService.atualizarFuncionario(id, nome: nome, cpf: cpf, funcao: cargo, status: status);
          if (!mounted) return;
          setState(() {
            final index = funcionarios.indexOf(item);
            if (index >= 0) {
              funcionarios[index] = _mapFuncionario(atualizado);
              _atualizarDesempenhos();
            }
          });
          _mensagem('Funcionário atualizado!');
        } catch (e) {
          _mensagem(e.toString().replaceFirst('Exception: ', ''));
        }
      },
    );
  }

  void _formulario({
    required String titulo,
    required String subtitulo,
    required String botao,
    required String nomeInicial,
    required String cpfInicial,
    required String cargoInicial,
    required String statusInicial,
    required Future<void> Function(String nome, String cpf, String cargo, String status) salvar,
  }) {
    final nomeController = TextEditingController(text: nomeInicial);
    final cpfController = TextEditingController(text: cpfInicial);
    String cargoSel = cargoInicial;
    String statusSel = statusInicial;
    String? erro;

    _sheet(
      alturaMaxima: 0.92,
      child: StatefulBuilder(
        builder: (context, setSheet) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tituloSheet(titulo, subtitulo),
              const SizedBox(height: 21),
              _rotuloCampo('Nome completo'),
              const SizedBox(height: 8),
              _campo(
                nomeController,
                'Ex.: João da Silva',
                Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
              _rotuloCampo('CPF'),
              const SizedBox(height: 8),
              _campo(
                cpfController,
                'Somente números',
                Icons.badge_outlined,
                teclado: TextInputType.number,
              ),
              if (erro != null) ...[
                const SizedBox(height: 8),
                Text(
                  erro!,
                  style: TextStyle(
                    color: c.vermelho,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              _rotuloCampo('Função'),
              const SizedBox(height: 10),
              Wrap(
                children: cargos
                    .map(
                      (cargo) => _chipSelecao(
                        cargo,
                        cargoSel == cargo,
                        () => setSheet(() => cargoSel = cargo),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
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
              const SizedBox(height: 24),
              _botaoPrincipal(
                label: botao,
                icon: Icons.check_rounded,
                onTap: () {
                  final nome = nomeController.text.trim();
                  final cpf = cpfController.text.replaceAll(RegExp(r'\D'), '');

                  if (nome.isEmpty) {
                    setSheet(() => erro = 'Informe o nome do funcionário.');
                    return;
                  }
                  if (cpf.length != 11) {
                    setSheet(() => erro = 'Informe um CPF com 11 números.');
                    return;
                  }

                  salvar(nome, cpf, cargoSel, statusSel);
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      nomeController.dispose();
      cpfController.dispose();
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

  Widget _campo(TextEditingController controller, String hint, IconData icon, {TextInputType? teclado}) {
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

  // ---------------------------------------------------------------
  // Detalhes
  // ---------------------------------------------------------------
  void _detalhes(Map<String, dynamic> item) {
    final nota = item['desempenho'] as int;
    final ativo = item['status'] == 'Ativo';
    final corStatus = ativo ? c.verde : c.amarelo;

    _sheet(
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: AppCores.gradRoxo,
              borderRadius: BorderRadius.circular(24),
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
                _iniciais(item['nome']),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            item['nome'],
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.texto,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item['cargo'],
                style: TextStyle(color: c.textoSuave, fontSize: 12),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: corClara(corStatus, 24),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: corClara(corStatus, 40)),
                ),
                child: Text(
                  item['status'],
                  style: TextStyle(
                    color: corStatus,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _detalhe(
                'Vendas',
                '${item['vendas']}',
                Icons.shopping_bag_outlined,
                c.azul,
              ),
              const SizedBox(width: 10),
              _detalhe(
                'Desempenho',
                '$nota%',
                Icons.trending_up_rounded,
                _corDesempenho(nota),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _detalhe(
                'Faturamento',
                'R\$ ${_dinheiro(item['faturamento'])}',
                Icons.attach_money_rounded,
                c.verde,
              ),
              const SizedBox(width: 10),
              _detalhe(
                'Status',
                item['status'],
                Icons.circle_outlined,
                corStatus,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Builder(
            builder: (sheetContext) {
              return _botaoPrincipal(
                label: 'Editar funcionário',
                icon: Icons.edit_outlined,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _editar(item);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _detalhe(String titulo, String valor, IconData icon, Color cor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
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
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Excluir
  // ---------------------------------------------------------------
  void _excluir(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: c.cardA,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: c.bordaSutil),
          ),
          title: Text(
            'Excluir funcionário?',
            style: TextStyle(
              color: c.texto,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: Text(
            'Deseja realmente excluir ${item['nome']} da equipe?',
            style: TextStyle(color: c.textoSuave, fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancelar', style: TextStyle(color: c.textoSuave)),
            ),
            TextButton(
              onPressed: () async {
                final id = item['id']?.toString();
                if (id == null || id.isEmpty) {
                  Navigator.pop(dialogContext);
                  _mensagem('Funcionário sem identificador no banco.');
                  return;
                }
                try {
                  await ApiService.excluirFuncionario(id);
                  if (!mounted) return;
                  setState(() => funcionarios.remove(item));
                  Navigator.pop(dialogContext);
                  _mensagem('Funcionário removido.');
                } catch (e) {
                  Navigator.pop(dialogContext);
                  _mensagem(e.toString().replaceFirst('Exception: ', ''));
                }
              },
              child: Text(
                'Excluir',
                style: TextStyle(
                  color: c.vermelho,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ---------------------------------------------------------------
  // Notificações e menu
  // ---------------------------------------------------------------
  void _notificacoes() {
    _sheet(
      alturaMaxima: 0.78,
      child: Column(
        children: [
          _tituloSheet('Notificações', 'Acompanhe as novidades da sua equipe'),
          const SizedBox(height: 20),
          _itemLista(
            icon: Icons.groups_rounded,
            titulo: 'Equipe atualizada',
            subtitulo: '${funcionarios.length} membros, $ativos ativos.',
            cor: c.roxoClaro,
          ),
          _itemLista(
            icon: Icons.trending_up_rounded,
            titulo: 'Desempenho geral',
            subtitulo:
                'Média de ${desempenho.toStringAsFixed(0)}% entre os funcionários.',
            cor: _corDesempenho(desempenho),
          ),
          if (emFerias > 0)
            _itemLista(
              icon: Icons.beach_access_outlined,
              titulo: 'Equipe em férias',
              subtitulo:
                  '$emFerias ${emFerias == 1 ? 'funcionário está' : 'funcionários estão'} de férias.',
              cor: c.amarelo,
            ),
        ],
      ),
    );
  }

  void _menu() {
    _sheet(
      alturaMaxima: 0.6,
      child: Builder(
        builder: (sheetContext) {
          return Column(
            children: [
              _tituloSheet(
                'Ações da equipe',
                'Gerencie os membros rapidamente',
              ),
              const SizedBox(height: 21),
              _itemLista(
                icon: Icons.person_add_rounded,
                titulo: 'Adicionar funcionário',
                subtitulo: 'Cadastre um novo membro',
                cor: c.roxoClaro,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _adicionar();
                },
              ),
              _itemLista(
                icon: Icons.filter_alt_off_outlined,
                titulo: 'Limpar pesquisa e filtros',
                subtitulo: 'Voltar a mostrar toda a equipe',
                cor: c.azul,
                onTap: () {
                  Navigator.pop(sheetContext);
                  pesquisaController.clear();
                  setState(() => filtro = 'Todos');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------
  // Utilidades
  // ---------------------------------------------------------------
  int _totalVendas() {
    return funcionarios.fold<int>(
      0,
      (total, item) => total + (item['vendas'] as int),
    );
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
    final partes = (valor as num).toStringAsFixed(2).split('.');
    final inteiro = partes[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => '.',
    );

    return '$inteiro,${partes[1]}';
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: c.bordaSutil),
          ),
        ),
      );
  }
}
