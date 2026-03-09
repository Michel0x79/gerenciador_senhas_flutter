import 'package:encrypt/encrypt.dart' as encrypt_pkg;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  encrypt_pkg.Key? _key;

  void initializeKey(String masterPassword) {
    final bytes = utf8.encode(masterPassword);
    final hash = sha256.convert(bytes);
    _key = encrypt_pkg.Key.fromBase64(base64.encode(hash.bytes));
  }

  // Agora retorna um Map com password e iv
  Map<String, String> encryptPassword(String password) {
    if (_key == null) {
      throw Exception(
        'Chave de criptografia não inicializada. Faça login novamente.',
      );
    }

    // Gerar IV aleatório para cada senha
    final iv = encrypt_pkg.IV.fromSecureRandom(16);
    final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(_key!));
    final encrypted = encrypter.encrypt(password, iv: iv);

    return {'password': encrypted.base64, 'iv': iv.base64};
  }

  String decryptPassword(String encryptedPassword, String? ivBase64) {
    if (_key == null) {
      throw Exception(
        'Chave de criptografia não inicializada. Faça login novamente.',
      );
    }

    // Se não tem IV salvo (senhas antigas), usar IV padrão
    final iv = ivBase64 != null
        ? encrypt_pkg.IV.fromBase64(ivBase64)
        : encrypt_pkg.IV.fromLength(16);

    final encrypter = encrypt_pkg.Encrypter(encrypt_pkg.AES(_key!));
    final decrypted = encrypter.decrypt64(encryptedPassword, iv: iv);
    return decrypted;
  }

  void clearKey() {
    _key = null;
  }
}
