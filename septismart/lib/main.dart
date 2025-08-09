// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'login_screen.dart'; // start here
// If HomeScreen is in lib/, you can still import it where needed in login_screen.dart

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SeptiSmartApp());
}

class SeptiSmartApp extends StatelessWidget {
  const SeptiSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SeptiSmart',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF0F3C1E),
      ),
      // 🔰 Always show Login first
      home: const LoginScreen(),
    );
  }
}
