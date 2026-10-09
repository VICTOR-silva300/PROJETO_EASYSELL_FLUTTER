import 'package:flutter/material.dart';
import 'login_page.dart';
import 'tema.dart';


void main() => runApp(const EasySellApp());

class EasySellApp extends StatelessWidget {
  const EasySellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTema.modo,
      builder: (context, modo, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          
          themeMode: modo,
          theme: AppTema.temaClaro,
          darkTheme: AppTema.temaEscuro,

          
          home: const LoginPage(), 
          // routes: { ... },
        );
      },
    );
  }
}