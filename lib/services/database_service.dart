import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/password_entry.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'password_manager.db');

      return await openDatabase(
        path,
        version: 2, // INCREMENTAR VERSÃO
        onCreate: _onCreate,
        onUpgrade: _onUpgrade, // ADICIONAR MIGRAÇÃO
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE passwords(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        serviceName TEXT NOT NULL,
        username TEXT NOT NULL,
        encryptedPassword TEXT NOT NULL,
        iv TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT
      )
    ''');
  }

  // NOVA FUNÇÃO DE MIGRAÇÃO
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Adicionar coluna iv se não existir
      await db.execute('ALTER TABLE passwords ADD COLUMN iv TEXT');
    }
  }

  Future<int> insertPassword(PasswordEntry entry) async {
    try {
      final db = await database;
      return await db.insert(
        'passwords',
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<PasswordEntry>> getAllPasswords() async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'passwords',
        orderBy: 'serviceName ASC',
      );
      return List.generate(maps.length, (i) => PasswordEntry.fromMap(maps[i]));
    } catch (e) {
      return [];
    }
  }

  Future<PasswordEntry?> getPasswordById(int id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'passwords',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isEmpty) return null;
      return PasswordEntry.fromMap(maps.first);
    } catch (e) {
      return null;
    }
  }

  Future<int> updatePassword(PasswordEntry entry) async {
    try {
      final db = await database;
      return await db.update(
        'passwords',
        entry.toMap(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<int> deletePassword(int id) async {
    try {
      final db = await database;
      return await db.delete('passwords', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
