import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
// import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  static const String _masterPasswordKey = 'master_password_hash';
  static const String _masterPasswordEncryptedKey = 'master_password_encrypted';
  static const String _biometricEnabledKey = 'biometric_enabled';

  Future<bool> hasMasterPassword() async {
    final hash = await _storage.read(key: _masterPasswordKey);
    return hash != null;
  }

  Future<void> setMasterPassword(String password) async {
    final hash = _hashPassword(password);
    await _storage.write(key: _masterPasswordKey, value: hash);
    // Armazenar a senha original de forma segura para uso com biometria
    await _storage.write(key: _masterPasswordEncryptedKey, value: password);
  }

  Future<bool> verifyMasterPassword(String password) async {
    final storedHash = await _storage.read(key: _masterPasswordKey);
    if (storedHash == null) return false;
    final hash = _hashPassword(password);
    return hash == storedHash;
  }

  Future<String?> getMasterPassword() async {
    return await _storage.read(key: _masterPasswordEncryptedKey);
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  Future<bool> canUseBiometric() async {
    try {
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();

      if (canCheckBiometrics) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        return availableBiometrics.isNotEmpty;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final enabled = await _storage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  Future<bool> authenticateWithBiometric() async {
    try {
      final canAuthenticate = await canUseBiometric();
      if (!canAuthenticate) {
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Autentique-se para acessar suas senhas',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );

      return authenticated;
    } on PlatformException {
      return false;
    } catch (e) {
      return false;
    }
  }
}
