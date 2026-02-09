import 'package:flutter/foundation.dart';
import '../models/password_entry.dart';
import '../services/database_service.dart';
import '../services/encryption_service.dart';

class PasswordProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();
  final EncryptionService _encryptionService = EncryptionService();

  List<PasswordEntry> _passwords = [];
  bool _isLoading = false;
  String? _lastError;

  List<PasswordEntry> get passwords => _passwords;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  Future<void> loadPasswords() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      _passwords = await _dbService.getAllPasswords();
    } catch (e) {
      _passwords = [];
      _lastError = 'Erro ao carregar senhas: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPassword({
    required String serviceName,
    required String username,
    required String password,
  }) async {
    try {
      _lastError = null;
      final encryptedPassword = _encryptionService.encryptPassword(password);
      final entry = PasswordEntry(
        serviceName: serviceName,
        username: username,
        encryptedPassword: encryptedPassword,
        createdAt: DateTime.now(),
      );

      await _dbService.insertPassword(entry);
      await loadPasswords();
      return true;
    } catch (e) {
      _lastError = 'Erro ao adicionar senha: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePassword({
    required int id,
    required String serviceName,
    required String username,
    required String password,
  }) async {
    try {
      _lastError = null;
      final encryptedPassword = _encryptionService.encryptPassword(password);
      final entry = PasswordEntry(
        id: id,
        serviceName: serviceName,
        username: username,
        encryptedPassword: encryptedPassword,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _dbService.updatePassword(entry);
      await loadPasswords();
      return true;
    } catch (e) {
      _lastError = 'Erro ao atualizar senha: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePassword(int id) async {
    try {
      _lastError = null;
      await _dbService.deletePassword(id);
      await loadPasswords();
      return true;
    } catch (e) {
      _lastError = 'Erro ao deletar senha: $e';
      notifyListeners();
      return false;
    }
  }

  String decryptPassword(String encryptedPassword) {
    try {
      return _encryptionService.decryptPassword(encryptedPassword);
    } catch (e) {
      _lastError = 'Erro ao descriptografar: $e';
      return '***erro***';
    }
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}
