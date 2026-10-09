import 'package:flutter/material.dart';

import 'tema.dart'; // Mesmas cores usadas na tela de login

// ============================================================
// TELA DE RECUPERAR SENHA
// Versão mais limpa: sem efeitos de fundo, sem card pesado e
// com textos em tamanho legível. Segue a paleta do tema e a
// mesma lógica de antes (validação, estado "enviado", voltar).
// ============================================================
class EsqueciSenha extends StatefulWidget {
  const EsqueciSenha({super.key});

  @override
  State<EsqueciSenha> createState() => _EsqueciSenhaState();
}

class _EsqueciSenhaState extends State<EsqueciSenha> {
  // Guarda o e-mail digitado
  final emailController = TextEditingController();

  // true = mostra a mensagem de "instruções enviadas"
  bool enviado = false;

  // Atalho para as cores do tema (igual à tela de login)
  AppCores get c => context.cores;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  // Valida o e-mail e mostra a confirmação
  void enviarLink() {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Digite seu e-mail para continuar.'),
          backgroundColor: c.fundo2,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() {
      enviado = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: c.fundo,
      // AppBar simples com seta de voltar (padrão de apps reais)
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: c.texto,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ícone discreto, sem brilho nem gradiente
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: c.roxo.withAlpha(28),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.lock_reset_rounded,
                      color: c.roxoClaro,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título e explicação alinhados à esquerda
                  Text(
                    'Recuperar senha',
                    style: TextStyle(
                      color: c.texto,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Informe o e-mail cadastrado e enviaremos as '
                    'instruções para você criar uma nova senha.',
                    style: TextStyle(
                      color: c.textoSuave,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Campo de e-mail
                  Text(
                    'E-mail',
                    style: TextStyle(
                      color: c.texto,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _campoEmail(),
                  const SizedBox(height: 20),

                  // Botão principal em cor sólida
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: enviarLink,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.roxo,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Enviar link de recuperação',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  // Mensagem de sucesso (só depois de enviar)
                  if (enviado) ...[
                    const SizedBox(height: 20),
                    _sucesso(),
                  ],

                  const SizedBox(height: 24),

                  // Link simples para voltar ao login
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Voltar para o login',
                        style: TextStyle(
                          color: c.textoSuave,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Campo de e-mail com o mesmo estilo dos campos do login
  Widget _campoEmail() {
    return TextField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done, // Botão "ok" do teclado
      onSubmitted: (_) => enviarLink(),
      // Voltou a digitar? Esconde a mensagem de sucesso
      onChanged: (_) {
        if (enviado) {
          setState(() {
            enviado = false;
          });
        }
      },
      style: TextStyle(color: c.texto, fontSize: 15),
      cursorColor: c.roxoClaro,
      decoration: InputDecoration(
        hintText: 'voce@empresa.com',
        hintStyle: TextStyle(color: c.textoFraco, fontSize: 15),
        prefixIcon: Icon(Icons.email_outlined, color: c.textoFraco, size: 20),
        filled: true,
        fillColor: c.superficie,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.bordaSutil),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c.roxo, width: 1.5),
        ),
      ),
    );
  }

  // Aviso de confirmação, simples e legível
  Widget _sucesso() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.verde.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_outline, color: c.verde, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Enviamos as instruções para o seu e-mail. '
              'Verifique também a caixa de spam.',
              style: TextStyle(
                color: c.texto,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
