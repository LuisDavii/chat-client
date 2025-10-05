import 'package:flutter/material.dart';
import 'login_page.dart';

class HomePage extends StatelessWidget {
  
  final String username;

  const HomePage({
    super.key,
    required this.username, 
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        title: Text('Bem-vindo, $username!'),
        automaticallyImplyLeading: false, 
        actions: [

          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),

      body: Center(
        child: Text(
          'chat p2p',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}