import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import 'dart:async';

import 'package:client_chat/models/chat_models.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  final String username;
  final Stream<dynamic> stream;
  final WebSocketSink sink;

  const HomePage({
    super.key,
    required this.username,
    required this.stream,
    required this.sink,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<ChatUser> _users = [];
  String? _currentChatPartner;
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();

  late final StreamSubscription _streamSubscription;

  @override
  void initState() {
    super.initState();

    _streamSubscription = widget.stream.listen(_handleServerMessage);

    widget.sink.add(jsonEncode({"type": "REQUEST_USER_LIST"}));
  }

  // processar todas as mensagens do servidor
  void _handleServerMessage(dynamic message) {
    final data = jsonDecode(message);
    if (mounted) {
      setState(() {
        if (data['type'] == 'user_list_update') {
          final List usersFromServer = data['users'];
          _users = usersFromServer
              .map(
                (user) => ChatUser(
                  username: user['username'],
                  isOnline: user['isOnline'],
                ),
              )
              .toList();
        } else if (data['type'] == 'chat_message') {
          if (data['from'] == _currentChatPartner) {
            _messages.add(
              ChatMessage(from: data['from'], content: data['content']),
            );
          }
        }
      });
    }
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty && _currentChatPartner != null) {
      widget.sink.add(
        jsonEncode({
          "type": "chat_message",
          "to": _currentChatPartner,
          "content": _controller.text,
        }),
      );
      setState(() {
        _messages.add(
          ChatMessage(from: widget.username, content: _controller.text),
        );
      });
      _controller.clear();
    }
  }

  void _startChatWith(String username) {
    setState(() {
      _currentChatPartner = username;
      _messages.clear();
    });
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _streamSubscription.cancel();
    widget.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentChatPartner ?? "Chat"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Text(
                'Usuários',
                style: const TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ..._users
                .where((u) => u.isOnline && u.username != widget.username)
                .map(
                  (user) => ListTile(
                    leading: const Icon(
                      Icons.circle,
                      color: Colors.green,
                      size: 14,
                    ),
                    title: Text(user.username),
                    onTap: () => _startChatWith(user.username),
                  ),
                ),
            ..._users
                .where((u) => !u.isOnline)
                .map(
                  (user) => ListTile(
                    leading: Icon(
                      Icons.circle_outlined,
                      color: Colors.grey,
                      size: 14,
                    ),
                    title: Text(user.username),
                    onTap: () => _startChatWith(user.username),
                  ),
                ),
          ],
        ),
      ),

      body: _currentChatPartner == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Selecione um usuário no menu à esquerda para começar a conversar.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages.reversed.toList()[index];
                      final isMe = message.from == widget.username;
                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe
                                ? Theme.of(context).primaryColorLight
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(message.content),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: 'Digite uma mensagem...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
