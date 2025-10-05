// lib/main.dart

import 'package:flutter/material.dart';
import 'package:client_chat/screens/login_page.dart'; // Importe a sua login page

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login/Register Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      // A tela inicial agora é importada de outro ficheiro
      home: const LoginPage(),
    );
  }
}