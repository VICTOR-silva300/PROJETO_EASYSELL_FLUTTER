import 'package:flutter/material.dart';

import 'tema.dart';
import 'api_service.dart';

class EasyCrew extends StatefulWidget {
  final VoidCallback aoVoltar;

  const EasyCrew({
    super.key,
    required this.aoVoltar,
  });

  @override
  State<EasyCrew> createState() => _EasyCrewState();
}

class _EasyCrewState extends State<EasyCrew> {
  AppCores get c => context.cores;

  static const List<String> cargos = ['Vendedor', 'Gerente', 'Atendimento'];

  final TextEditingController pesquisaController = TextEditingController();

  String filtroSelecionado = 'Todos';

  // ---------------------------------------------------------------
  // Dados
  // ---------------------------------------------------------------
  final List<Map<String, dynamic>> membros = [];

  final List<Map<String, dynamic>> tarefas = [];
  bool carregando = true;

  @override
  void initState() {
    super.initState();
    _carregarMembros();
  }

  Future<void> _carregarMembros() async {
    try {
      final dados = await ApiService.funcionarios();
      if (!mounted) return;
      setState(() {
        membros
          ..clear()
          ..addAll(dados.map((item) {
            final nome = item['name']?.toString() ?? 'Funcionário';
            final statusBanco = item['status']?.toString() ?? 'Ativo';
            return {
              ...item,
              'id': item['_id']?.toString(),
              'nome': nome,
              'cargo': item['funcao']?.toString() ?? 'Vendedor',
              'status': statusBanco == 'Ativo' ? 'Online' : 'Ausente',
              'tarefas': 0,
              'concluidas': 0,
              'avatar': _iniciais(nome),
            };
          }));
        carregando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => carregando = false);
      _mensagem(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  void dispose() {
    pesquisaController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------
  List<Map<String, dynamic>> get membrosFiltrados {
    final pesquisa = pesquisaController.text.toLowerCase().trim();

    return membros.where((membro) {
      final nome = membro['nome'].toString().toLowerCase();
      final cargo = membro['cargo'].toString().toLowerCase();

      final correspondePesquisa =
          nome.contains(pesquisa) || cargo.contains(pesquisa);

      final correspondeFiltro =
          filtroSelecionado == 'Todos' || membro['cargo'] == filtroSelecionado;

      return correspondePesquisa && correspondeFiltro;
    }).toList();
  }

  int get totalTarefas => tarefas.length;

  int get tarefasConcluidas =>
      tarefas.where((tarefa) => tarefa['concluida'] == true).length;

  int get tarefasPendentes =>
      tarefas.where((tarefa) => tarefa['concluida'] == false).length;

  int get membrosOnline =>
      membros.where((membro) => membro['status'] == 'Online').length;

  // ---------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------
  Color corClara(Color cor, int alpha) => cor.withAlpha(alpha);

  BoxDecoration _decoracaoCard({double raio = 24}) {
    return BoxDecoration(
      gradient: c.gradCard,
      borderRadius: BorderRadius.circular(raio),
      border: Border.all(color: c.bordaSutil),
    );
  }

  Color _corPrioridade(String prioridade) {
    if (prioridade == 'Alta') return c.vermelho;
    if (prioridade == 'Média') return c.amarelo;
    return c.verde;
  }

  // ---------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final membrosLista = membrosFiltrados;
    final todos = filtroSelecionado == 'Todos';

    return Scaffold(
      backgroundColor: c.fundo,
      floatingActionButton: _botaoNovaTarefa(),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: c.gradFundo),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(19, 15, 19, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _cabecalho(),
                    const SizedBox(height: 27),
                    _painelResumo(),
                    const SizedBox(height: 18),
                    _atalhos(),
                    const SizedBox(height: 20),
                    _barraPesquisa(),
                    const SizedBox(height: 14),
                    _filtros(),
                    const SizedBox(height: 26),
                    if (todos) ...[
                      _titulo(
                        'Tarefas de hoje',
                        '$tarefasPendentes pendentes',
                        extra: 'Ver todas',
                        onExtra: _mostrarTarefas,
                      ),
                      const SizedBox(height: 13),
                      ...tarefas
                          .take(3)
                          .map(
                            (tarefa) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _cardTarefa(tarefa),
                            ),
                          ),
                      const SizedBox(height: 16),
                    ],
                    _titulo(
                      'Membros da equipe',
                      'Progresso e disponibilidade',
                      extra: '${membrosLista.length} membros',
                    ),
                    const SizedBox(height: 13),
                    if (membrosLista.isEmpty)
                      _vazio()
                    else
                      ...membrosLista.map(
                        (membro) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _cardMembro(membro),
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
          Icons.diversity_3_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'COLABORAÇÃO',
              style: TextStyle(
                color: c.textoFraco,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'EasyCrew',
              style: TextStyle(
                color: c.texto,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
      GestureDetector(
        onTap: _carregarMembros,
        child: Container(
          width: 43,
          height: 43,
          decoration: BoxDecoration(
            color: c.superficie,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.bordaMedia),
          ),
          child: Icon(
            Icons.refresh_rounded,
            color: c.roxoClaro,
            size: 20,
          ),
        ),
      ),
    ],
  );
}

  // ---------------------------------------------------------------
  // Painel principal
  // ---------------------------------------------------------------
  Widget _painelResumo() {
    final progresso = totalTarefas == 0
        ? 0.0
        : tarefasConcluidas / totalTarefas;

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
                      'Minha equipe',
                      style: TextStyle(
                        color: c.texto,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$membrosOnline pessoas online agora',
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
                  color: corClara(c.verde, 28),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.circle, color: c.verde, size: 6),
                    const SizedBox(width: 5),
                    Text(
                      'Ativa',
                      style: TextStyle(
                        color: c.verde,
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
            '${(progresso * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              color: c.texto,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Das tarefas da equipe concluídas',
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
                    widthFactor: progresso.clamp(0.0, 1.0),
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
                '$tarefasConcluidas de $totalTarefas',
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
              _resumoItem(
                '${membros.length}',
                'Membros',
                Icons.groups_outlined,
                c.roxoClaro,
              ),
              _resumoItem(
                '$totalTarefas',
                'Tarefas',
                Icons.task_alt_rounded,
                c.azul,
              ),
              _resumoItem(
                '$tarefasConcluidas',
                'Concluídas',
                Icons.check_circle_outline,
                c.verde,
              ),
              _resumoItem(
                '$tarefasPendentes',
                'Pendentes',
                Icons.schedule_rounded,
                c.amarelo,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resumoItem(String valor, String titulo, IconData icone, Color cor) {
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
            child: Icon(icone, color: cor, size: 13),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.textoFraco, fontSize: 8),
                ),
                const SizedBox(height: 3),
                Text(
                  valor,
                  style: TextStyle(
                    color: cor,
                    fontSize: 11,
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
  // Atalhos
  // ---------------------------------------------------------------
  Widget _atalhos() {
    return Row(
      children: [
        _atalho('Tarefas', Icons.checklist_rounded, c.azul, _mostrarTarefas),
        const SizedBox(width: 8),
        _atalho(
          'Equipe',
          Icons.groups_outlined,
          c.roxoClaro,
          () => setState(() => filtroSelecionado = 'Todos'),
        ),
        const SizedBox(width: 8),
        _atalho(
          'Atividade',
          Icons.timeline_rounded,
          c.verde,
          _mostrarAtividade,
        ),
        const SizedBox(width: 8),
        _atalho(
          'Convites',
          Icons.mail_outline_rounded,
          c.amarelo,
          _mostrarConvites,
        ),
      ],
    );
  }

  Widget _atalho(String titulo, IconData icone, Color cor, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: _decoracaoCard(raio: 18),
          child: Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: corClara(cor, 27),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icone, color: cor, size: 17),
              ),
              const SizedBox(height: 7),
              Text(
                titulo,
                style: TextStyle(
                  color: c.textoSuave,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Pesquisa e filtros
  // ---------------------------------------------------------------
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
          hintText: 'Buscar membro ou função...',
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: opcoes.map((item) {
          return _chipSelecao(
            item,
            filtroSelecionado == item,
            () => setState(() => filtroSelecionado = item),
          );
        }).toList(),
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

  // ---------------------------------------------------------------
  // Título de seção (mesmo da Home)
  // ---------------------------------------------------------------
  Widget _titulo(
    String titulo,
    String subtitulo, {
    String? extra,
    VoidCallback? onExtra,
  }) {
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
          GestureDetector(
            onTap: onExtra,
            child: Container(
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
          ),
      ],
    );
  }

  Widget _vazio() {
    return Container(
      width: double.infinity,
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
            'Nenhum membro encontrado',
            style: TextStyle(
              color: c.texto,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tente mudar a pesquisa ou o filtro.',
            style: TextStyle(color: c.textoSuave, fontSize: 10),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Cards
  // ---------------------------------------------------------------
  Widget _cardMembro(Map<String, dynamic> membro) {
    final int tarefasMembro = membro['tarefas'] as int;
    final int concluidas = membro['concluidas'] as int;
    final double progresso = tarefasMembro == 0
        ? 0
        : concluidas / tarefasMembro;
    final bool online = membro['status'] == 'Online';
    final Color corProgresso = progresso >= 0.8 ? c.verde : c.azul;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _detalhesMembro(membro),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: _decoracaoCard(),
          child: Row(
            children: [
              Stack(
                children: [
                  _avatar(membro['avatar'], 51),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: online ? c.verde : c.textoSuave,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.cardA, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      membro['nome'],
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
                      membro['cargo'],
                      style: TextStyle(color: c.textoFraco, fontSize: 10),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: corClara(corProgresso, 30),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progresso.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: corProgresso,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$concluidas/$tarefasMembro',
                          style: TextStyle(
                            color: c.textoSuave,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: c.textoFraco, size: 19),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardTarefa(Map<String, dynamic> tarefa) {
    final bool concluida = tarefa['concluida'] == true;
    final String prioridade = tarefa['prioridade'].toString();
    final Color corPrioridade = _corPrioridade(prioridade);
    final Color corIcone = concluida ? c.verde : c.roxoClaro;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => tarefa['concluida'] = !concluida),
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: _decoracaoCard(raio: 21),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: corClara(corIcone, 28),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  concluida ? Icons.check_rounded : Icons.task_alt_rounded,
                  color: corIcone,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tarefa['titulo'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: concluida ? c.textoSuave : c.texto,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        decoration: concluida
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: c.textoSuave,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tarefa['responsavel'],
                      style: TextStyle(color: c.textoFraco, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: corClara(corPrioridade, 26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: corClara(corPrioridade, 42)),
                ),
                child: Text(
                  prioridade,
                  style: TextStyle(
                    color: corPrioridade,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatar(String iniciais, double tamanho) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        gradient: AppCores.gradRoxo,
        borderRadius: BorderRadius.circular(tamanho * 0.32),
      ),
      child: Center(
        child: Text(
          iniciais,
          style: TextStyle(
            color: Colors.white,
            fontSize: tamanho * 0.25,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------
  // Botões
  // ---------------------------------------------------------------
  Widget _botaoNovaTarefa() {
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
          onTap: _novaTarefa,
          borderRadius: BorderRadius.circular(19),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_task_rounded, color: Colors.white, size: 20),
                SizedBox(width: 9),
                Text(
                  'Nova tarefa',
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

  // ---------------------------------------------------------------
  // Sheet padrão (mesmo estilo da Home)
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
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
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

  Widget _campo(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
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
  // Detalhes do membro
  // ---------------------------------------------------------------
  void _detalhesMembro(Map<String, dynamic> membro) {
    final int tarefasMembro = membro['tarefas'] as int;
    final int concluidas = membro['concluidas'] as int;
    final double progresso = tarefasMembro == 0
        ? 0
        : concluidas / tarefasMembro;

    _sheet(
      child: Column(
        children: [
          _avatar(membro['avatar'], 76),
          const SizedBox(height: 14),
          Text(
            membro['nome'],
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.texto,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            membro['cargo'],
            style: TextStyle(color: c.textoSuave, fontSize: 12),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _detalheMembro(
                '$tarefasMembro',
                'Tarefas',
                Icons.task_alt_rounded,
                c.azul,
              ),
              const SizedBox(width: 10),
              _detalheMembro(
                '$concluidas',
                'Concluídas',
                Icons.check_circle_outline,
                c.verde,
              ),
              const SizedBox(width: 10),
              _detalheMembro(
                '${(progresso * 100).toStringAsFixed(0)}%',
                'Progresso',
                Icons.trending_up_rounded,
                c.roxoClaro,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Builder(
            builder: (sheetContext) {
              return _botaoPrincipal(
                label: 'Enviar mensagem',
                icon: Icons.chat_bubble_outline_rounded,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _mensagem('Mensagem enviada para ${membro['nome']}.');
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _detalheMembro(
    String valor,
    String titulo,
    IconData icone,
    Color cor,
  ) {
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
              child: Icon(icone, color: cor, size: 16),
            ),
            const SizedBox(height: 10),
            Text(titulo, style: TextStyle(color: c.textoFraco, fontSize: 9)),
            const SizedBox(height: 4),
            Text(
              valor,
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
  // Nova tarefa
  // ---------------------------------------------------------------
  void _novaTarefa() {
    if (membros.isEmpty) {
      _mensagem('Cadastre um funcionário na tela Equipe primeiro.');
      return;
    }

    final tituloController = TextEditingController();

    String responsavel = membros.first['nome'];
    String prioridade = 'Média';
    String? erro;

    _sheet(
      alturaMaxima: 0.94,
      child: StatefulBuilder(
        builder: (context, setSheet) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tituloSheet('Nova tarefa', 'Crie uma atividade para sua equipe'),
              const SizedBox(height: 21),
              _rotuloCampo('Título'),
              const SizedBox(height: 8),
              _campo(
                tituloController,
                'Ex.: Atualizar estoque',
                Icons.task_alt_rounded,
              ),
              const SizedBox(height: 16),
              _rotuloCampo('Responsável'),
              const SizedBox(height: 10),
              Wrap(
                children: membros
                    .map((membro) => membro['nome'].toString())
                    .map(
                      (nome) => _chipSelecao(
                        nome,
                        responsavel == nome,
                        () => setSheet(() => responsavel = nome),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              _rotuloCampo('Prioridade'),
              const SizedBox(height: 10),
              Wrap(
                children: ['Alta', 'Média', 'Baixa']
                    .map(
                      (p) => _chipSelecao(
                        p,
                        prioridade == p,
                        () => setSheet(() => prioridade = p),
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
                label: 'Criar tarefa',
                icon: Icons.check_rounded,
                onTap: () {
                  final titulo = tituloController.text.trim();

                  if (titulo.isEmpty) {
                    setSheet(() => erro = 'Digite um título.');
                    return;
                  }

                  setState(() {
                    tarefas.add({
                      'titulo': titulo,
                      'responsavel': responsavel,
                      'prioridade': prioridade,
                      'concluida': false,
                    });
                  });

                  Navigator.pop(context);
                  _mensagem('Tarefa criada!');
                },
              ),
            ],
          );
        },
      ),
    ).whenComplete(tituloController.dispose);
  }

  // ---------------------------------------------------------------
  // Adicionar membro
  // ---------------------------------------------------------------
  void _adicionarMembro() {
    final nomeController = TextEditingController();

    String cargoSel = cargos.first;
    String? erro;

    _sheet(
      alturaMaxima: 0.9,
      child: StatefulBuilder(
        builder: (context, setSheet) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tituloSheet(
                'Convidar membro',
                'Adicione uma pessoa ao seu EasyCrew',
              ),
              const SizedBox(height: 21),
              _rotuloCampo('Nome completo'),
              const SizedBox(height: 8),
              _campo(
                nomeController,
                'Ex.: João da Silva',
                Icons.person_outline_rounded,
              ),
              const SizedBox(height: 16),
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
                label: 'Adicionar membro',
                icon: Icons.person_add_rounded,
                onTap: () {
                  final nome = nomeController.text.trim();

                  if (nome.isEmpty) {
                    setSheet(() => erro = 'Informe o nome do membro.');
                    return;
                  }

                  setState(() {
                    membros.add({
                      'nome': nome,
                      'cargo': cargoSel,
                      'status': 'Online',
                      'tarefas': 0,
                      'concluidas': 0,
                      'avatar': _iniciais(nome),
                    });
                  });

                  Navigator.pop(context);
                  _mensagem('Membro adicionado à equipe!');
                },
              ),
            ],
          );
        },
      ),
    ).whenComplete(nomeController.dispose);
  }

  // ---------------------------------------------------------------
  // Tarefas, atividade e convites
  // ---------------------------------------------------------------
  void _mostrarTarefas() {
    _sheet(
      child: StatefulBuilder(
        builder: (context, setSheet) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tituloSheet(
                'Todas as tarefas',
                'Toque em uma tarefa para concluir ou reabrir',
              ),
              const SizedBox(height: 20),
              if (tarefas.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text(
                      'Nenhuma tarefa cadastrada.',
                      style: TextStyle(color: c.textoSuave, fontSize: 12),
                    ),
                  ),
                )
              else
                ...tarefas.map(
                  (tarefa) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        setSheet(() {});
                      },
                      child: _cardTarefaSheet(tarefa, setSheet),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _cardTarefaSheet(Map<String, dynamic> tarefa, StateSetter setSheet) {
    final bool concluida = tarefa['concluida'] == true;
    final String prioridade = tarefa['prioridade'].toString();
    final Color corPrioridade = _corPrioridade(prioridade);
    final Color corIcone = concluida ? c.verde : c.roxoClaro;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => tarefa['concluida'] = !concluida);
          setSheet(() {});
        },
        borderRadius: BorderRadius.circular(21),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.fundo2,
            borderRadius: BorderRadius.circular(21),
            border: Border.all(color: c.bordaSutil),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: corClara(corIcone, 28),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  concluida ? Icons.check_rounded : Icons.task_alt_rounded,
                  color: corIcone,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tarefa['titulo'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: concluida ? c.textoSuave : c.texto,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        decoration: concluida
                            ? TextDecoration.lineThrough
                            : null,
                        decorationColor: c.textoSuave,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tarefa['responsavel'],
                      style: TextStyle(color: c.textoFraco, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: corClara(corPrioridade, 26),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: corClara(corPrioridade, 42)),
                ),
                child: Text(
                  prioridade,
                  style: TextStyle(
                    color: corPrioridade,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarAtividade() {
    _sheet(
      alturaMaxima: 0.6,
      child: Column(
        children: [
          _tituloSheet('Atividade da equipe', 'Resumo das tarefas'),
          const SizedBox(height: 21),
          _linhaResumo(
            Icons.check_circle_outline,
            'Tarefas concluídas',
            '$tarefasConcluidas',
            c.verde,
          ),
          _linhaResumo(
            Icons.schedule_rounded,
            'Tarefas pendentes',
            '$tarefasPendentes',
            c.amarelo,
          ),
          _linhaResumo(
            Icons.groups_outlined,
            'Pessoas online',
            '$membrosOnline',
            c.azul,
          ),
        ],
      ),
    );
  }

  Widget _linhaResumo(IconData icone, String titulo, String valor, Color cor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: c.fundo2,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: c.bordaSutil),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: corClara(cor, 28),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icone, color: cor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              titulo,
              style: TextStyle(
                color: c.texto,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              color: cor,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarConvites() {
    _sheet(
      alturaMaxima: 0.5,
      child: Column(
        children: [
          _tituloSheet('Convites', 'Pessoas aguardando para entrar'),
          const SizedBox(height: 28),
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: corClara(c.roxoClaro, 27),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mail_outline_rounded,
              color: c.roxoClaro,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Nenhum convite pendente',
            style: TextStyle(
              color: c.texto,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Não existem novos convites no momento.',
            style: TextStyle(color: c.textoSuave, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------
  // Utilidades
  // ---------------------------------------------------------------
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

  void _mensagem(String mensagem) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            mensagem,
            style: const TextStyle(color: Color(0xFFF8FAFC), fontSize: 12),
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
}
