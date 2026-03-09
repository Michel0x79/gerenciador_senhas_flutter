import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../models/password_entry.dart';
import 'database_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseService _dbService = DatabaseService();
  
  // Chave única do app para criptografia de backup
  static const String _appSecretKey = 'GerenciadorSenhas2024SecretKey!@#';
  static const String _backupVersion = '1.0';

  encrypt_pkg.Key _getBackupKey() {
    final bytes = utf8.encode(_appSecretKey);
    final hash = sha256.convert(bytes);
    return encrypt_pkg.Key.fromBase64(base64.encode(hash.bytes));
  }

  Future<File?> exportPasswords({required String masterPassword}) async {
    try {
      // Buscar todas as senhas do banco
      final passwords = await _dbService.getAllPasswords();
      
      if (passwords.isEmpty) {
        throw Exception('Nenhuma senha para exportar');
      }

      // Criar estrutura de dados para exportação
      final backupData = {
        'version': _backupVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'passwordHash': _hashPassword(masterPassword),
        'entries': passwords.map((entry) => entry.toMap()).toList(),
      };

      // Converter para JSON
      final jsonData = json.encode(backupData);

      // Criptografar os dados
      final key = _getBackupKey();
      final iv = encrypt_pkg.IV.fromLength(16);
      final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key));
      final encrypted = encrypter.encrypt(jsonData, iv: iv);

      // Criar arquivo com dados criptografados
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'senhas_backup_$timestamp.gpwd';
      final file = File('${directory.path}/$fileName');
      
      // Salvar IV + dados criptografados
      final finalData = '${iv.base64}:${encrypted.base64}';
      await file.writeAsString(finalData);

      return file;
    } catch (e) {
      throw Exception('Erro ao exportar senhas: $e');
    }
  }

  Future<int> importPasswords({
    required File backupFile,
    required String masterPassword,
    required bool replaceExisting,
  }) async {
    try {
      // Ler arquivo
      final fileContent = await backupFile.readAsString();
      final parts = fileContent.split(':');
      
      if (parts.length != 2) {
        throw Exception('Arquivo de backup inválido');
      }

      final ivBase64 = parts[0];
      final encryptedBase64 = parts[1];

      // Descriptografar
      final key = _getBackupKey();
      final iv = encrypt_pkg.IV.fromBase64(ivBase64);
      final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(key));
      final decrypted = encrypter.decrypt64(encryptedBase64, iv: iv);

      // Parse JSON
      final backupData = json.decode(decrypted) as Map<String, dynamic>;

      // Verificar versão
      if (backupData['version'] != _backupVersion) {
        throw Exception('Versão do backup incompatível');
      }

      // Verificar senha mestra
      final storedHash = backupData['passwordHash'] as String;
      final providedHash = _hashPassword(masterPassword);
      
      if (storedHash != providedHash) {
        throw Exception('Senha mestra incorreta');
      }

      // Extrair senhas
      final entries = (backupData['entries'] as List)
          .map((e) => PasswordEntry.fromMap(e as Map<String, dynamic>))
          .toList();

      // Limpar banco se necessário
      if (replaceExisting) {
        final existingPasswords = await _dbService.getAllPasswords();
        for (var password in existingPasswords) {
          await _dbService.deletePassword(password.id!);
        }
      }

      // Importar senhas
      int importedCount = 0;
      for (var entry in entries) {
        await _dbService.insertPassword(
          PasswordEntry(
            serviceName: entry.serviceName,
            username: entry.username,
            encryptedPassword: entry.encryptedPassword,
            createdAt: entry.createdAt,
            updatedAt: DateTime.now(),
          ),
        );
        importedCount++;
      }

      return importedCount;
    } catch (e) {
      if (e.toString().contains('Senha mestra incorreta')) {
        rethrow;
      }
      throw Exception('Erro ao importar backup: Arquivo corrompido ou incompatível');
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<List<File>> getBackupFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.gpwd'))
          .toList();
      
      // Ordenar por data (mais recente primeiro)
      files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
      
      return files;
    } catch (e) {
      return [];
    }
  }

  Future<void> deleteBackupFile(File file) async {
    await file.delete();
  }
}