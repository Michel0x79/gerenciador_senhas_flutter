import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  encrypt_pkg.Key? _key;
  final _iv = encrypt_pkg.IV.fromLength(16);

  void initializeKey(String masterPassword) {
    final bytes = utf8.encode(masterPassword);
    final hash = sha256.convert(bytes);
    _key = encrypt_pkg.Key.fromBase64(base64.encode(hash.bytes));
  }

  String encryptPassword(String password) {
    if (_key == null) {
      throw Exception(
        'Chave de criptografia não inicializada. Faça login novamente.',
      );
    }
    final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(_key!));
    final encrypted = encrypter.encrypt(password, iv: _iv);
    return encrypted.base64;
  }

  String decryptPassword(String encryptedPassword) {
    if (_key == null) {
      throw Exception(
        'Chave de criptografia não inicializada. Faça login novamente.',
      );
    }
    final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(_key!));
    final decrypted = encrypter.decrypt64(encryptedPassword, iv: _iv);
    return decrypted;
  }

  void clearKey() {
    _key = null;
  }
}
