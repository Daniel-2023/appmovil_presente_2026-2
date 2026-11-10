import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'src/login.dart';
import 'src/docente/docente.dart';
import 'src/estudiante/estudinte.dart';
import 'src/registro/registro.dart';
import 'src/registro/recuperar_password.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MiAppEscolar());
}

class MiAppEscolar extends StatelessWidget {
  const MiAppEscolar({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const LoginScreen(),
      routes: {
        '/registro': (context) => const RegistroScreen(),
        '/recuperar': (context) => const RecuperarPasswordScreen(),
        '/estudiante': (context) => const PanelEstudianteScreen(),
        '/docente': (context) => const PanelDocenteScreen(),
      },
    );
  }
}