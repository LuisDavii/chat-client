import 'package:crypto/crypto.dart';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    String username = _userNameController.text;
    String password = _passwordController.text;

    var bytes = utf8.encode(password); 
    var digest = sha256.convert(bytes); 
    String hashedPassword = digest.toString();

    const serverHost = '10.0.2.2'; // se for fisico mudar para o IP do servidor
    const serverPort = 12345;
    String serverResponse = '';

    try {
      Socket socket = await Socket.connect(serverHost, serverPort, timeout: Duration(seconds: 5));

      socket.write("REGISTER");
      await Future.delayed(Duration(milliseconds: 100)); 

      socket.write(username);
      await Future.delayed(Duration(milliseconds: 100));
      socket.write(hashedPassword);

      await socket.listen((List<int> data) {
        serverResponse = utf8.decode(data);
      }).asFuture();
      
      socket.destroy();
    } catch (e) {
      serverResponse = "CONNECTION_ERROR";
    } finally {
      setState(() { _isLoading = false; });
    }

    String feedbackMessage;
    if (serverResponse == 'REGISTER_SUCCESS') {
      feedbackMessage = 'Usuário registado com sucesso! Agora pode fazer o login.';
      if (mounted) Navigator.pop(context);
    } else if (serverResponse == 'REGISTER_FAILED:USERNAME_EXISTS') {
      feedbackMessage = 'Este nome de usuário já está em uso.';
    } else {
      feedbackMessage = 'Erro no registo. Tente novamente.';
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(feedbackMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar Conta')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Crie a sua conta', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextFormField(
                controller: _userNameController,
                decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outlined)),
                validator: (value) {return null; },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha', prefixIcon: Icon(Icons.lock_outline)),
                validator: (value) {return null; },
              ),
              const SizedBox(height: 30),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Cadastrar', style: TextStyle(fontSize: 18)),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}