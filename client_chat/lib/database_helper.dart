// lib/database_helper.dart

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:client_chat/models/chat_models.dart';

class DatabaseHelper {

  static const table = 'conversas';
  static const columnId = '_id';
  static const columnRemetente = 'remetente';
  static const columnDestinatario = 'destinatario';
  static const columnConteudo = 'conteudo';
  static const columnTimestamp = 'timestamp';

  // Torna esta classe um singleton
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // Apenas uma referência à base de dados
  Database? _database;
  String? _currentUser;

  Future<void> initForUser(String username) async {
    if (_currentUser == username && _database != null) {
      // Já está inicializado para este usuário
      return;
    }
    _currentUser = username;
    // O nome do ficheiro agora inclui o nome do usuário
    final dbName = 'Chat_${username}.db';
    String path = join(await getDatabasesPath(), dbName);
    _database = await openDatabase(path, version: 1, onCreate: _onCreate);
    print("Banco de dados inicializado para o usuário: $username em $path");
  }

   Future<Database> get database async {
    if (_database == null || _currentUser == null) {
      throw Exception("DatabaseHelper não foi inicializado. Chame initForUser() após o login.");
    }
    return _database!;
  }

  // SQL para criar a tabela
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnRemetente TEXT NOT NULL,
            $columnDestinatario TEXT NOT NULL,
            $columnConteudo TEXT NOT NULL,
            $columnTimestamp INTEGER NOT NULL
          )
          ''');
  }

  // Método para inserir uma mensagem
  Future<int> insertMessage(ChatMessage message, String destinatario) async {
    Database db = await instance.database;
    return await db.insert(table, {
      columnRemetente: message.from,
      columnDestinatario: destinatario,
      columnConteudo: message.content,
      columnTimestamp: DateTime.now().millisecondsSinceEpoch,
    });
  }

  // Método para buscar o histórico de uma conversa entre dois usuários
  Future<List<ChatMessage>> getConversationHistory(String user1, String user2) async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(table,
        where: '($columnRemetente = ? AND $columnDestinatario = ?) OR ($columnRemetente = ? AND $columnDestinatario = ?)',
        whereArgs: [user1, user2, user2, user1],
        orderBy: '$columnTimestamp ASC');

    return List.generate(maps.length, (i) {
      return ChatMessage(
        from: maps[i][columnRemetente],
        content: maps[i][columnConteudo],
      );
    });
  }
}