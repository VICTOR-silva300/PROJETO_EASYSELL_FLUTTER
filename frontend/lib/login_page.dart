import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cadastro.dart';
import 'esqueci_senha.dart';
import 'home.dart';
import 'tema.dart';
import 'api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final senhaController = TextEditingController();

  bool mostrarSenha = false;
  bool carregando = false;

  AppCores get c => context.cores;

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> entrar() async {
    final email = emailController.text.trim();
    final senha = senhaController.text;

    if (email.isEmpty || senha.isEmpty) {
      _mensagem('Preencha o e-mail e a senha.');
      return;
    }
    if (carregando) return;

    setState(() => carregando = true);
    try {
      await ApiService.login(email, senha);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Home()));
    } catch (e) {
      if (!mounted) return;
      _mensagem(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => carregando = false);
    }
  }

  void _mensagem(String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: c.fundo2, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
    );
  }

  void abrirCadastro() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Cadastro()),
    );
  }

  void abrirEsqueciSenha() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EsqueciSenha()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: c.fundo,
      body: Stack(
        children: [
          Positioned(top: -150, left: -120, child: _brilho(c.roxo, 340)),
          Positioned(top: 260, right: -180, child: _brilho(c.azul, 360)),
          Positioned(bottom: -180, left: 80, child: _brilho(c.roxoClaro, 330)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    children: [
                      _cabecalho(),
                      const SizedBox(height: 38),
                      _cardLogin(),
                      const SizedBox(height: 18),
                      _seguranca(),
                      const SizedBox(height: 25),
                      _rodape(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _brilho(Color cor, double tamanho) {
    return IgnorePointer(
      child: Container(
        width: tamanho,
        height: tamanho,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: cor.withAlpha(32),
              blurRadius: 120,
              spreadRadius: 35,
            ),
          ],
        ),
      ),
    );
  }

  Widget _cabecalho() {
    return Column(
      children: [
        Text(
          'EASYSELL',
          style: GoogleFonts.montserrat(
            color: c.texto,
            fontSize: 43,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.5,
            height: 1,
          ),
        ),

        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.transparent, c.roxo]),
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(width: 10),

            Text(
              'GESTÃO INTELIGENTE',
              style: GoogleFonts.montserrat(
                color: c.textoFraco,
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),

            const SizedBox(width: 10),

            Container(
              width: 28,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [c.roxo, Colors.transparent]),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _cardLogin() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(21, 23, 21, 21),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.superficie, c.fundo2],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: c.bordaMedia),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(55),
            blurRadius: 35,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: c.roxo.withAlpha(18),
            blurRadius: 40,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [c.roxo.withAlpha(55), c.roxoClaro.withAlpha(25)],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: c.roxo.withAlpha(45)),
                ),
                child: Icon(
                  Icons.lock_open_rounded,
                  color: c.roxoClaro,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bem-vindo de volta!',
                      style: TextStyle(
                        color: c.texto,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Entre para continuar gerenciando seu negócio.',
                      style: TextStyle(color: c.textoSuave, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          _linhaDecorativa(),
          const SizedBox(height: 23),
          _label('E-mail'),
          const SizedBox(height: 8),
          _campo(
            controller: emailController,
            hint: 'Digite seu e-mail',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 17),
          _label('Senha'),
          const SizedBox(height: 8),
          _campo(
            controller: senhaController,
            hint: 'Digite sua senha',
            icon: Icons.lock_outline_rounded,
            obscureText: !mostrarSenha,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  mostrarSenha = !mostrarSenha;
                });
              },
              splashRadius: 20,
              icon: Icon(
                mostrarSenha
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: c.textoFraco,
                size: 19,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: abrirEsqueciSenha,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Esqueceu sua senha?',
                style: TextStyle(
                  color: c.roxoClaro,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 17),
          _botaoEntrar(),
          const SizedBox(height: 13),
          _botaoCadastro(),
        ],
      ),
    );
  }

  Widget _linhaDecorativa() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: c.bordaSutil)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: c.roxoClaro,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: c.roxo.withAlpha(100), blurRadius: 8),
              ],
            ),
          ),
        ),
        Expanded(child: Container(height: 1, color: c.bordaSutil)),
      ],
    );
  }

  Widget _label(String texto) {
    return Text(
      texto,
      style: TextStyle(
        color: c.texto,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _campo({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: TextStyle(
        color: c.texto,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      cursorColor: c.roxoClaro,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textoFraco, fontSize: 10),
        prefixIcon: Container(
          width: 46,
          alignment: Alignment.center,
          child: Icon(icon, color: c.roxoClaro.withAlpha(190), size: 18),
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 46,
          minHeight: 46,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: c.fundo.withAlpha(190),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: c.bordaSutil, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: c.roxo.withAlpha(190), width: 1.4),
        ),
      ),
    );
  }

  Widget _botaoEntrar() {
    return SizedBox(
      width: double.infinity,
      height: 53,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppCores.gradRoxo,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: c.roxo.withAlpha(75),
              blurRadius: 22,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: entrar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Entrar',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 9),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botaoCadastro() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: abrirCadastro,
        style: OutlinedButton.styleFrom(
          foregroundColor: c.texto,
          side: BorderSide(color: c.bordaMedia, width: 1),
          backgroundColor: c.superficie.withAlpha(80),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_alt_1_rounded, color: c.textoSuave, size: 17),
            const SizedBox(width: 8),
            const Text(
              'Criar uma nova conta',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _seguranca() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: c.verde.withAlpha(10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.verde.withAlpha(25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_outlined, color: c.verde, size: 15),
          const SizedBox(width: 8),
          Text(
            'Ambiente seguro e protegido',
            style: TextStyle(
              color: c.textoSuave,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _rodape() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: c.roxoClaro,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'EASYSELL',
              style: TextStyle(
                color: c.textoFraco,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: c.roxoClaro,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          'Sua gestão. Mais simples. Mais inteligente.',
          style: TextStyle(color: c.textoFraco, fontSize: 8),
        ),
      ],
    );
  }
}
