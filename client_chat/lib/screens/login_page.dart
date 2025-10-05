import 'dart:io'; 
import 'dart:convert';
import 'package:flutter/material.dart';
import 'register_page.dart'; 
import 'home_page.dart';
import 'package:crypto/crypto.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Login Demo',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  //carregamento
  bool _isLoading = false;

  //login
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });

    String username = _userNameController.text;
    String password = _passwordController.text;

    var bytes = utf8.encode(password); 
    var digest = sha256.convert(bytes);
    String hashedPassword = digest.toString();

    //se for usar dispositivo real, alterar o IP para o do servidor
    const serverHost = '10.0.2.2';
    const serverPort = 12345;
    String serverResponse = '';

    try {
      // Conecta ao socket
      Socket socket = await Socket.connect(serverHost, serverPort, timeout: Duration(seconds: 5));

      socket.write("LOGIN");
      await Future.delayed(Duration(milliseconds: 100));
      socket.write(username);
      await Future.delayed(Duration(milliseconds: 100));
      socket.write(hashedPassword);

      await socket.listen((List<int> data) {
        serverResponse = utf8.decode(data);
      }).asFuture(); 
      socket.destroy();

    } on SocketException catch (e) {
      
      serverResponse = "CONNECTION_ERROR";
    } catch (e) {
      
      serverResponse = "UNKNOWN_ERROR";
    } finally {
      
      setState(() {
        _isLoading = false;
      });
    }

    // Exibe a resposta do servidor
    String feedbackMessage;
    if (serverResponse == 'LOGIN_SUCCESS') {
      feedbackMessage = 'Login bem-sucedido!';
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            // Cria a HomePage e passa o username 
            builder: (context) => HomePage(username: username),
          ),
        );
      }
    } else if (serverResponse == 'LOGIN_FAILED') {
      feedbackMessage = 'Usuário ou senha incorretos.';
    } else if (serverResponse == 'CONNECTION_ERROR') {
      feedbackMessage =
          'Não foi possível conectar ao servidor. Verifique o IP e a sua conexão.';
    } else {
      feedbackMessage = 'Ocorreu um erro desconhecido.';
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(feedbackMessage)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(title: const Text('Tela de Login'), centerTitle: true),
      body: Padding(

        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(

          key: _formKey,
          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              const Text(
                'Bem-vindo!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              //username
              const SizedBox(height: 30),
              TextFormField(
                controller: _userNameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o seu e-mail';
                  }
                  return null;
                },
              ),

              //senha
              const SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira a sua senha';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              // Botão de Login 
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _login, // Chama a nossa nova função _login
                      child: const Text(
                        'Entrar',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),

              const SizedBox(height: 20),

              // Botão para navegar para a tela de cadastro
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterPage(),
                    ),
                  );
                },
                child: const Text('Ainda não tem uma conta? Cadastre-se'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
