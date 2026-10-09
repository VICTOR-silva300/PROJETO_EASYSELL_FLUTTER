import 'package:flutter/material.dart';
import 'tema.dart';
import 'api_service.dart';

class EasyChat extends StatefulWidget {
  final VoidCallback aoVoltar;

  const EasyChat({
    super.key,
    required this.aoVoltar,
  });

  @override
  State<EasyChat> createState() => _EasyChatState();
}

class _EasyChatState extends State<EasyChat> {
  AppCores get c => context.cores;

  final TextEditingController pesquisaController =
      TextEditingController();

  final TextEditingController mensagemController =
      TextEditingController();

  final TextEditingController nomeContatoController =
      TextEditingController();

  final TextEditingController emailContatoController =
      TextEditingController();

  final TextEditingController cargoContatoController =
      TextEditingController();

  final ScrollController mensagensScroll =
      ScrollController();

  String conversaSelecionada = '';
  bool carregando = true;

  final List<Map<String, dynamic>> conversas = [];

  final Map<String, List<Map<String, dynamic>>> mensagens = {};

  @override
  void initState() {
    super.initState();
    _carregarContatos();
  }

  Future<void> _carregarContatos() async {
    try {
      final dados = await ApiService.funcionarios();
      if (!mounted) return;
      setState(() {
        conversas
          ..clear()
          ..addAll(dados.map((item) {
            final nome = item['name']?.toString() ?? 'Funcionário';
            final status = item['status']?.toString() ?? 'Ativo';
            return {
              ...item,
              'nome': nome,
              'email': '',
              'cargo': item['funcao']?.toString() ?? 'Vendedor',
              'mensagem': 'Nenhuma mensagem ainda.',
              'hora': '',
              'naoLidas': 0,
              'online': status == 'Ativo',
              'avatar': _gerarIniciais(nome),
            };
          }));
        mensagens.removeWhere((nome, _) => !conversas.any((c) => c['nome'] == nome));
        for (final conversa in conversas) {
          mensagens.putIfAbsent(conversa['nome'].toString(), () => []);
        }
        if (conversaSelecionada.isEmpty ||
            !conversas.any((c) => c['nome'] == conversaSelecionada)) {
          conversaSelecionada = conversas.isEmpty ? '' : conversas.first['nome'].toString();
        }
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
    mensagemController.dispose();
    nomeContatoController.dispose();
    emailContatoController.dispose();
    cargoContatoController.dispose();
    mensagensScroll.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get conversasFiltradas {
    final pesquisa =
        pesquisaController.text.toLowerCase().trim();

    if (pesquisa.isEmpty) {
      return conversas;
    }

    return conversas.where((conversa) {
      final nome =
          conversa['nome'].toString().toLowerCase();

      final mensagem =
          conversa['mensagem'].toString().toLowerCase();

      final cargo =
          conversa['cargo'].toString().toLowerCase();

      final email =
          conversa['email'].toString().toLowerCase();

      return nome.contains(pesquisa) ||
          mensagem.contains(pesquisa) ||
          cargo.contains(pesquisa) ||
          email.contains(pesquisa);
    }).toList();
  }

  List<Map<String, dynamic>> get mensagensAtuais {
    return mensagens[conversaSelecionada] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: c.fundo,
      body: Container(
        decoration: BoxDecoration(
          gradient: c.gradFundo,
        ),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    12,
                    19,
                    0,
                  ),
                  child: _cabecalho(),
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
              ),
              SliverToBoxAdapter(
                child: _barraPesquisa(),
              ),
              SliverToBoxAdapter(
                child: _resumoChat(),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    19,
                    4,
                    19,
                    12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Conversas da equipe',
                          style: TextStyle(
                            color: c.texto,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '${conversas.length} contatos',
                        style: TextStyle(
                          color: c.textoFraco,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (conversasFiltradas.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _estadoVazio(),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    19,
                    0,
                    19,
                    30,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final conversa =
                            conversasFiltradas[index];

                        return Padding(
                          padding:
                              const EdgeInsets.only(bottom: 10),
                          child: _cardConversa(conversa),
                        );
                      },
                      childCount: conversasFiltradas.length,
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
              border: Border.all(
                color: c.bordaMedia,
              ),
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
            boxShadow: [
              BoxShadow(
                color: c.roxo.withAlpha(66),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'MENSAGENS',
                style: TextStyle(
                  color: c.textoFraco,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'EasyChat',
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
          onTap: _carregarContatos,
          child: Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: c.superficie,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: c.bordaMedia,
              ),
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

  Widget _barraPesquisa() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        19,
        0,
        19,
        12,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: c.superficie,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: c.bordaMedia,
          ),
        ),
        child: TextField(
          controller: pesquisaController,
          onChanged: (_) {
            setState(() {});
          },
          cursorColor: c.roxoClaro,
          style: TextStyle(
            color: c.texto,
            fontSize: 13,
          ),
          decoration: InputDecoration(
            hintText: 'Pesquisar contatos...',
            hintStyle: TextStyle(
              color: c.textoFraco,
              fontSize: 11,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: c.textoSuave,
              size: 20,
            ),
            suffixIcon:
                pesquisaController.text.isNotEmpty
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
            contentPadding:
                const EdgeInsets.symmetric(
              vertical: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _resumoChat() {
    final online = conversas.where((conversa) {
      return conversa['online'] == true;
    }).length;

    final naoLidas = conversas.fold<int>(
      0,
      (total, conversa) {
        return total +
            (conversa['naoLidas'] as int);
      },
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        19,
        0,
        19,
        14,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: c.gradDestaque,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: c.roxo.withAlpha(58),
          ),
          boxShadow: [
            BoxShadow(
              color: c.roxo.withAlpha(37),
              blurRadius: 30,
              offset: const Offset(0, 13),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: AppCores.gradRoxo,
                borderRadius:
                    BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.forum_rounded,
                color: Colors.white,
                size: 21,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conversas da equipe',
                    style: TextStyle(
                      color: c.texto,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        color: c.verde,
                        size: 6,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$online pessoas online agora',
                        style: TextStyle(
                          color: c.textoSuave,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (naoLidas > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: c.roxo.withAlpha(40),
                  borderRadius:
                      BorderRadius.circular(10),
                  border: Border.all(
                    color: c.roxo.withAlpha(80),
                  ),
                ),
                child: Text(
                  '$naoLidas novas',
                  style: TextStyle(
                    color: c.roxoClaro,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _estadoVazio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(35),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                color: c.roxo.withAlpha(26),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                color: c.roxoClaro,
                size: 34,
              ),
            ),
            const SizedBox(height: 17),
            Text(
              'Nenhum contato encontrado',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.texto,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Cadastre funcionários na tela Equipe para iniciar uma conversa.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textoSuave,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardConversa(
    Map<String, dynamic> conversa,
  ) {
    final bool selecionada =
        conversa['nome'] == conversaSelecionada;

    final bool online =
        conversa['online'] == true;

    final int naoLidas =
        conversa['naoLidas'] as int;

    return GestureDetector(
      onTap: () {
        setState(() {
          conversaSelecionada =
              conversa['nome'];

          conversa['naoLidas'] = 0;
        });

        _abrirConversa(conversa);
      },
      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: _decoracaoCard(
          selecionada: selecionada,
        ),
        child: Row(
          children: [
            Stack(
              children: [
                _avatar(
                  conversa['avatar'],
                  53,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: online
                          ? c.verde
                          : c.textoFraco,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: c.fundo2,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversa['nome'],
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.texto,
                            fontSize: 14,
                            fontWeight:
                                naoLidas > 0
                                    ? FontWeight.w900
                                    : FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        conversa['hora'],
                        style: TextStyle(
                          color: naoLidas > 0
                              ? c.roxoClaro
                              : c.textoFraco,
                          fontSize: 9,
                          fontWeight:
                              naoLidas > 0
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conversa['cargo'],
                    style: TextStyle(
                      color: c.roxoClaro,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conversa['mensagem'],
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: TextStyle(
                            color: naoLidas > 0
                                ? c.texto
                                : c.textoSuave,
                            fontSize: 11,
                            fontWeight:
                                naoLidas > 0
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (naoLidas > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            gradient:
                                AppCores.gradRoxo,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$naoLidas',
                              style:
                                  const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight:
                                    FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _decoracaoCard({
    bool selecionada = false,
    double raio = 21,
  }) {
    return BoxDecoration(
      gradient: c.gradCard,
      borderRadius:
          BorderRadius.circular(raio),
      border: Border.all(
        color: selecionada
            ? c.roxo.withAlpha(90)
            : c.bordaSutil,
      ),
    );
  }

  void _abrirAdicionarContato() {
    nomeContatoController.clear();
    emailContatoController.clear();
    cargoContatoController.clear();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom:
                MediaQuery.of(modalContext)
                    .viewInsets
                    .bottom,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: c.gradSheet,
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.fromLTRB(
                  22,
                  12,
                  22,
                  28,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    _alca(),
                    const SizedBox(height: 24),
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient:
                              AppCores.gradRoxo,
                          borderRadius:
                              BorderRadius.circular(
                            20,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  c.roxo.withAlpha(
                                55,
                              ),
                              blurRadius: 22,
                              offset:
                                  const Offset(
                                0,
                                8,
                              ),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons
                              .person_add_alt_1_rounded,
                          color: Colors.white,
                          size: 29,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Center(
                      child: Text(
                        'Adicionar contato',
                        style: TextStyle(
                          color: c.texto,
                          fontSize: 22,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Center(
                      child: Text(
                        'Cadastre um membro da sua equipe',
                        textAlign:
                            TextAlign.center,
                        style: TextStyle(
                          color: c.textoSuave,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _campoContato(
                      controller:
                          nomeContatoController,
                      titulo: 'Nome completo',
                      dica: 'Ex: João da Silva',
                      icone:
                          Icons.person_outline_rounded,
                      teclado:
                          TextInputType.name,
                    ),
                    const SizedBox(height: 12),
                    _campoContato(
                      controller:
                          emailContatoController,
                      titulo: 'E-mail',
                      dica:
                          'Ex: joao@email.com',
                      icone:
                          Icons.email_outlined,
                      teclado:
                          TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _campoContato(
                      controller:
                          cargoContatoController,
                      titulo: 'Cargo / Função',
                      dica: 'Ex: Vendedor',
                      icone:
                          Icons.badge_outlined,
                      teclado:
                          TextInputType.text,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          _adicionarContato(
                            modalContext,
                          );
                        },
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor: c.roxo,
                          foregroundColor:
                              Colors.white,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              17,
                            ),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                          children: [
                            Icon(
                              Icons
                                  .person_add_alt_1_rounded,
                              size: 20,
                            ),
                            SizedBox(width: 9),
                            Text(
                              'Adicionar contato',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(
                            modalContext,
                          );
                        },
                        style:
                            OutlinedButton.styleFrom(
                          foregroundColor:
                              c.textoSuave,
                          side: BorderSide(
                            color: c.bordaMedia,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              17,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _campoContato({
    required TextEditingController controller,
    required String titulo,
    required String dica,
    required IconData icone,
    required TextInputType teclado,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: TextStyle(
            color: c.texto,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          decoration: BoxDecoration(
            color: c.superficie,
            borderRadius:
                BorderRadius.circular(16),
            border: Border.all(
              color: c.bordaMedia,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: teclado,
            cursorColor: c.roxoClaro,
            style: TextStyle(
              color: c.texto,
              fontSize: 13,
            ),
            decoration: InputDecoration(
              hintText: dica,
              hintStyle: TextStyle(
                color: c.textoFraco,
                fontSize: 11,
              ),
              prefixIcon: Icon(
                icone,
                color: c.textoSuave,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _adicionarContato(
    BuildContext modalContext,
  ) {
    final nome =
        nomeContatoController.text.trim();

    final email =
        emailContatoController.text.trim();

    final cargo =
        cargoContatoController.text.trim();

    if (nome.isEmpty ||
        email.isEmpty ||
        cargo.isEmpty) {
      _mensagem(
        'Preencha todos os campos.',
      );
      return;
    }

    final contatoExistente =
        conversas.any((contato) {
      return contato['email']
              .toString()
              .toLowerCase() ==
          email.toLowerCase();
    });

    if (contatoExistente) {
      _mensagem(
        'Este e-mail já está cadastrado.',
      );
      return;
    }

    final avatar = _gerarIniciais(nome);

    final novoContato =
        <String, dynamic>{
      'nome': nome,
      'email': email,
      'cargo': cargo,
      'mensagem':
          'Nenhuma mensagem ainda.',
      'hora': '',
      'naoLidas': 0,
      'online': false,
      'avatar': avatar,
    };

    setState(() {
      conversas.add(novoContato);
      mensagens[nome] = [];
      conversaSelecionada = nome;
    });

    Navigator.pop(modalContext);

    _mensagem(
      '$nome foi adicionado aos contatos.',
    );
  }

  String _gerarIniciais(String nome) {
    final partes =
        nome.trim().split(RegExp(r'\s+'));

    if (partes.isEmpty) {
      return '?';
    }

    if (partes.length == 1) {
      return partes.first
          .substring(
            0,
            partes.first.length >= 2
                ? 2
                : 1,
          )
          .toUpperCase();
    }

    final primeira =
        partes.first.substring(0, 1);

    final ultima =
        partes.last.substring(0, 1);

    return '$primeira$ultima'
        .toUpperCase();
  }

  void _abrirConversa(
    Map<String, dynamic> conversa,
  ) {
    mensagemController.clear();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (modalContext) {
        return StatefulBuilder(
          builder:
              (modalContext, setModalState) {
            return Container(
              height:
                  MediaQuery.of(context)
                          .size
                          .height *
                      0.88,
              decoration: BoxDecoration(
                gradient: c.gradSheet,
                borderRadius:
                    const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  _cabecalhoConversa(
                    conversa,
                    modalContext,
                  ),
                  Expanded(
                    child: _listaMensagens(),
                  ),
                  _campoMensagem(
                    () {
                      _enviarMensagem();
                      setModalState(() {});
                      _rolarParaFim();
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _rolarParaFim() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mensagensScroll.hasClients) {
        return;
      }

      mensagensScroll.animateTo(
        mensagensScroll
            .position
            .maxScrollExtent,
        duration:
            const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _cabecalhoConversa(
    Map<String, dynamic> conversa,
    BuildContext modalContext,
  ) {
    final bool online =
        conversa['online'] == true;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        12,
        14,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: c.bordaSutil,
          ),
        ),
      ),
      child: Column(
        children: [
          _alca(),
          const SizedBox(height: 16),
          Row(
            children: [
              _avatar(
                conversa['avatar'],
                46,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversa['nome'],
                      style: TextStyle(
                        color: c.texto,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration:
                              BoxDecoration(
                            color: online
                                ? c.verde
                                : c.textoFraco,
                            shape:
                                BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          online
                              ? 'Online'
                              : 'Offline',
                          style: TextStyle(
                            color: online
                                ? c.verde
                                : c.textoFraco,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '• ${conversa['cargo']}',
                          style: TextStyle(
                            color: c.textoFraco,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pop(
                    modalContext,
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration:
                      BoxDecoration(
                    color: c.superficie,
                    borderRadius:
                        BorderRadius.circular(
                      12,
                    ),
                    border: Border.all(
                      color: c.bordaMedia,
                    ),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: c.textoSuave,
                    size: 19,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _listaMensagens() {
    final lista = mensagensAtuais;

    if (lista.isEmpty) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(25),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width: 65,
                height: 65,
                decoration:
                    BoxDecoration(
                  color:
                      c.roxo.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons
                      .chat_bubble_outline_rounded,
                  color: c.roxoClaro,
                  size: 29,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Comece uma conversa',
                style: TextStyle(
                  color: c.texto,
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Envie uma mensagem para este contato.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.textoSuave,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: mensagensScroll,
      padding:
          const EdgeInsets.fromLTRB(
        16,
        18,
        16,
        15,
      ),
      physics:
          const BouncingScrollPhysics(),
      itemCount: lista.length,
      itemBuilder:
          (context, index) {
        final mensagem =
            lista[index];

        return _mensagemChat(
          mensagem['texto'],
          mensagem['hora'],
          mensagem['minha'],
        );
      },
    );
  }

  Widget _mensagemChat(
    String texto,
    String hora,
    bool minha,
  ) {
    return Align(
      alignment: minha
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(
          maxWidth:
              MediaQuery.of(context)
                      .size
                      .width *
                  0.78,
        ),
        margin:
            const EdgeInsets.only(
          bottom: 10,
        ),
        padding:
            const EdgeInsets.fromLTRB(
          14,
          10,
          14,
          8,
        ),
        decoration:
            BoxDecoration(
          gradient: minha
              ? AppCores.gradRoxo
              : c.gradCard,
          borderRadius:
              BorderRadius.only(
            topLeft:
                const Radius.circular(
              18,
            ),
            topRight:
                const Radius.circular(
              18,
            ),
            bottomLeft:
                Radius.circular(
              minha ? 18 : 4,
            ),
            bottomRight:
                Radius.circular(
              minha ? 4 : 18,
            ),
          ),
          border: minha
              ? null
              : Border.all(
                  color: c.bordaSutil,
                ),
        ),
        child: Column(
          crossAxisAlignment:
              minha
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
          children: [
            Text(
              texto,
              style: TextStyle(
                color: minha
                    ? Colors.white
                    : c.texto,
                fontSize: 13,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              hora,
              style: TextStyle(
                color: minha
                    ? Colors.white70
                    : c.textoFraco,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campoMensagem(
    VoidCallback aoEnviar,
  ) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.of(context)
                .viewInsets
                .bottom +
            12,
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: c.bordaSutil,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              _mensagem(
                'Anexos em breve.',
              );
            },
            icon: Icon(
              Icons
                  .add_circle_outline_rounded,
              color: c.textoSuave,
            ),
          ),
          Expanded(
            child: Container(
              decoration:
                  BoxDecoration(
                color: c.superficie,
                borderRadius:
                    BorderRadius.circular(
                  16,
                ),
                border: Border.all(
                  color: c.bordaMedia,
                ),
              ),
              child: TextField(
                controller:
                    mensagemController,
                cursorColor:
                    c.roxoClaro,
                style: TextStyle(
                  color: c.texto,
                  fontSize: 13,
                ),
                minLines: 1,
                maxLines: 4,
                textInputAction:
                    TextInputAction.newline,
                decoration:
                    InputDecoration(
                  hintText:
                      'Digite uma mensagem...',
                  hintStyle:
                      TextStyle(
                    color:
                        c.textoFraco,
                    fontSize: 12,
                  ),
                  border:
                      InputBorder.none,
                  contentPadding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: aoEnviar,
            child: Container(
              width: 44,
              height: 44,
              decoration:
                  BoxDecoration(
                gradient:
                    AppCores.gradRoxo,
                borderRadius:
                    BorderRadius.circular(
                  14,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        c.roxo.withAlpha(
                      66,
                    ),
                    blurRadius: 14,
                    offset:
                        const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _enviarMensagem() {
    final texto =
        mensagemController.text.trim();

    if (texto.isEmpty) {
      return;
    }

    final hora = _horaAtual();

    setState(() {
      mensagens.putIfAbsent(
        conversaSelecionada,
        () => [],
      );

      mensagens[
          conversaSelecionada]!.add({
        'texto': texto,
        'minha': true,
        'hora': hora,
      });

      final conversa =
          conversas.firstWhere(
        (item) =>
            item['nome'] ==
            conversaSelecionada,
      );

      conversa['mensagem'] = texto;
      conversa['hora'] = hora;
    });

    mensagemController.clear();
  }

  Widget _avatar(
    String iniciais,
    double tamanho,
  ) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration:
          BoxDecoration(
        gradient:
            AppCores.gradRoxo,
        borderRadius:
            BorderRadius.circular(
          tamanho * 0.32,
        ),
      ),
      child: Center(
        child: Text(
          iniciais,
          style: TextStyle(
            color: Colors.white,
            fontSize:
                tamanho * 0.3,
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _alca() {
    return Center(
      child: Container(
        width: 45,
        height: 4,
        decoration:
            BoxDecoration(
          color: c.textoFraco,
          borderRadius:
              BorderRadius.circular(
            20,
          ),
        ),
      ),
    );
  }

  String _horaAtual() {
    final agora =
        DateTime.now();

    final hora =
        agora.hour
            .toString()
            .padLeft(2, '0');

    final minuto =
        agora.minute
            .toString()
            .padLeft(2, '0');

    return '$hora:$minuto';
  }

  void _mensagem(
    String texto,
  ) {
    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(
      SnackBar(
        content: Text(
          texto,
          style: TextStyle(
            color: c.texto,
            fontSize: 12,
            fontWeight:
                FontWeight.w600,
          ),
        ),
        behavior:
            SnackBarBehavior.floating,
        backgroundColor:
            c.superficie,
        duration:
            const Duration(
          milliseconds: 1600,
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
        ),
      ),
    );
  }
}