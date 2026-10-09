import 'package:flutter/material.dart';

import 'home.dart';
import 'tema.dart';
import 'api_service.dart'; // Mesmas cores usadas no login e na recuperação de senha

// ============================================================
// TELA DE CADASTRO
// Layout em duas seções ("Seus dados" e "Segurança"), com
// indicador de força da senha e navegação pelo teclado.
// A lógica é a mesma de antes: valida campos vazios, confere
// se as senhas são iguais e então abre a Home.
// ============================================================
class Cadastro extends StatefulWidget {
  const Cadastro({super.key});

  @override
  State<Cadastro> createState() => _CadastroState();
}

class _CadastroState extends State<Cadastro> {
  // Controllers: guardam o que foi digitado em cada campo
  final nomeController = TextEditingController();
  final emailController = TextEditingController();
  final senhaController = TextEditingController();
  final confirmarSenhaController = TextEditingController();

  // Controlam o "olhinho" de cada campo de senha
  bool mostrarSenha = false;
  bool mostrarConfirmarSenha = false;
  bool carregando = false;

  // Atalho para as cores do tema
  AppCores get c => context.cores;

  @override
  void dispose() {
    nomeController.dispose();
    emailController.dispose();
    senhaController.dispose();
    confirmarSenhaController.dispose();
    super.dispose();
  }

  // Mostra um aviso flutuante no mesmo estilo das outras telas
  void _aviso(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: c.fundo2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // Ação do botão "Criar minha conta"
  Future<void> cadastrar() async {
    final nome = nomeController.text.trim();
    final email = emailController.text.trim();
    final senha = senhaController.text;
    final confirmarSenha = confirmarSenhaController.text;

    if (nome.isEmpty || email.isEmpty || senha.isEmpty || confirmarSenha.isEmpty) {
      _aviso('Preencha todos os campos.');
      return;
    }
    if (senha != confirmarSenha) {
      _aviso('As senhas não são iguais.');
      return;
    }
    if (senha.length < 6) {
      _aviso('A senha deve ter pelo menos 6 caracteres.');
      return;
    }
    if (carregando) return;

    setState(() => carregando = true);
    try {
      await ApiService.register(nome, email, senha);
      await ApiService.login(email, senha);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const Home()), (_) => false);
    } catch (e) {
      if (!mounted) return;
      _aviso(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  // Volta para a tela de login
  void voltarLogin() {
    Navigator.pop(context);
  }

  // Calcula a força da senha: 0 (vazia) a 4 (forte)
  int get _forcaSenha {
    final s = senhaController.text;
    if (s.isEmpty) return 0;
    int pontos = 0;
    if (s.length >= 6) pontos++;
    if (s.length >= 10) pontos++;
    if (RegExp(r'[A-Z]').hasMatch(s) && RegExp(r'[a-z]').hasMatch(s)) pontos++;
    if (RegExp(r'[0-9]').hasMatch(s) && RegExp(r'[^A-Za-z0-9]').hasMatch(s)) {
      pontos++;
    }
    return pontos == 0 ? 1 : pontos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: c.fundo,
      // Seta de voltar no topo, padrão de apps reais
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: c.texto,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: voltarLogin,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _cabecalho(),
                  const SizedBox(height: 32),

                  // ---------- Seção 1: dados pessoais ----------
                  _secao('Seus dados'),
                  const SizedBox(height: 14),
                  _campo(
                    rotulo: 'Nome',
                    controller: nomeController,
                    hint: 'Como você quer ser chamado',
                    icon: Icons.person_outline_rounded,
                    capitalizacao: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  _campo(
                    rotulo: 'E-mail',
                    controller: emailController,
                    hint: 'voce@empresa.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 28),

                  // ---------- Seção 2: senha ----------
                  _secao('Segurança'),
                  const SizedBox(height: 14),
                  _campo(
                    rotulo: 'Senha',
                    controller: senhaController,
                    hint: 'Crie uma senha',
                    icon: Icons.lock_outline_rounded,
                    obscureText: !mostrarSenha,
                    // Atualiza a barra de força a cada letra digitada
                    onChanged: (_) => setState(() {}),
                    suffixIcon: _olhinho(
                      visivel: mostrarSenha,
                      aoTocar: () =>
                          setState(() => mostrarSenha = !mostrarSenha),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _indicadorForca(),
                  const SizedBox(height: 16),
                  _campo(
                    rotulo: 'Confirmar senha',
                    controller: confirmarSenhaController,
                    hint: 'Digite a senha novamente',
                    icon: Icons.lock_outline_rounded,
                    obscureText: !mostrarConfirmarSenha,
                    ultimo: true, // Botão "ok" do teclado envia o cadastro
                    suffixIcon: _olhinho(
                      visivel: mostrarConfirmarSenha,
                      aoTocar: () => setState(
                        () => mostrarConfirmarSenha = !mostrarConfirmarSenha,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  _botaoCriar(),
                  const SizedBox(height: 18),
                  _linkEntrar(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Marca + título + subtítulo
  Widget _cabecalho() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: AppCores.gradRoxo,
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Center(
            child: Text(
              'E',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Criar sua conta',
          style: TextStyle(
            color: c.texto,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Preencha seus dados para começar a gerenciar suas vendas.',
          style: TextStyle(color: c.textoSuave, fontSize: 14, height: 1.45),
        ),
      ],
    );
  }

  // Título de seção com linha ao lado
  Widget _secao(String titulo) {
    return Row(
      children: [
        Text(
          titulo,
          style: TextStyle(
            color: c.roxoClaro,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Container(height: 1, color: c.bordaSutil)),
      ],
    );
  }

  // Campo de texto reutilizável: rótulo em cima + campo embaixo
  Widget _campo({
    required String rotulo,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    bool ultimo = false,
    TextInputType? keyboardType,
    TextCapitalization capitalizacao = TextCapitalization.none,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: TextStyle(
            color: c.texto,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textCapitalization: capitalizacao,
          onChanged: onChanged,
          // "próximo" pula para o campo seguinte; no último, envia
          textInputAction: ultimo ? TextInputAction.done : TextInputAction.next,
          onSubmitted: ultimo ? (_) => cadastrar() : null,
          style: TextStyle(color: c.texto, fontSize: 15),
          cursorColor: c.roxoClaro,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: c.textoFraco, fontSize: 15),
            prefixIcon: Icon(icon, color: c.textoFraco, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: c.superficie,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.bordaSutil),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: c.roxo, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // Botão de mostrar/ocultar senha
  Widget _olhinho({required bool visivel, required VoidCallback aoTocar}) {
    return IconButton(
      onPressed: aoTocar,
      icon: Icon(
        visivel ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: c.textoFraco,
        size: 20,
      ),
    );
  }

  // Barrinhas que indicam a força da senha (só aparecem ao digitar)
  Widget _indicadorForca() {
    final forca = _forcaSenha;
    if (forca == 0) return const SizedBox.shrink();

    // Cor e texto de acordo com a força
    final Color cor = forca <= 1
        ? Colors.redAccent
        : forca == 2
            ? Colors.orangeAccent
            : c.verde;
    final String texto = forca <= 1
        ? 'Senha fraca'
        : forca == 2
            ? 'Senha razoável'
            : 'Senha forte';

    return Row(
      children: [
        // 4 barrinhas: as preenchidas usam a cor da força
        for (int i = 1; i <= 4; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i <= forca ? cor : c.bordaSutil,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          if (i < 4) const SizedBox(width: 6),
        ],
        const SizedBox(width: 12),
        Text(
          texto,
          style: TextStyle(
            color: cor,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Botão principal em gradiente roxo (igual ao do login)
  Widget _botaoCriar() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppCores.gradRoxo,
          borderRadius: BorderRadius.circular(14),
        ),
        child: ElevatedButton(
          onPressed: cadastrar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Criar minha conta',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // "Já tem uma conta? Entrar" (faz o mesmo que o antigo botão Voltar)
  Widget _linkEntrar() {
    return Center(
      child: TextButton(
        onPressed: voltarLogin,
        child: Text.rich(
          TextSpan(
            text: 'Já tem uma conta? ',
            style: TextStyle(color: c.textoSuave, fontSize: 14),
            children: [
              TextSpan(
                text: 'Entrar',
                style: TextStyle(
                  color: c.roxoClaro,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}