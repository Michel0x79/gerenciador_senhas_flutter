import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/encryption_service.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isCreatingPassword = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _canUseBiometric = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkExistingPassword();
    _checkBiometric();
  }

  Future<void> _checkExistingPassword() async {
    final hasPassword = await _authService.hasMasterPassword();
    setState(() {
      _isCreatingPassword = !hasPassword;
    });
  }

  Future<void> _checkBiometric() async {
    final canUse = await _authService.canUseBiometric();
    final enabled = await _authService.isBiometricEnabled();
    setState(() {
      _canUseBiometric = canUse;
      _biometricEnabled = enabled;
    });

    // Tentar autenticação automática se estiver habilitada
    if (enabled && canUse && !_isCreatingPassword) {
      await _tryBiometric();
    }
  }

  Future<void> _tryBiometric() async {
    if (!mounted) return;

    final authenticated = await _authService.authenticateWithBiometric();
    if (authenticated) {
      // Recuperar a senha mestra armazenada
      final masterPassword = await _authService.getMasterPassword();
      if (masterPassword != null && mounted) {
        EncryptionService().initializeKey(masterPassword);
        _navigateToHome();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Erro ao recuperar senha mestra. Use a senha manual.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    setState(() => _isLoading = true);
    await _tryBiometric();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isCreatingPassword) {
        await _authService.setMasterPassword(_passwordController.text);
        EncryptionService().initializeKey(_passwordController.text);
        if (mounted) _navigateToHome();
      } else {
        final isValid = await _authService.verifyMasterPassword(
          _passwordController.text,
        );
        if (isValid) {
          EncryptionService().initializeKey(_passwordController.text);
          if (mounted) _navigateToHome();
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Senha incorreta!'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 80,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isCreatingPassword
                        ? 'Criar Senha Mestra'
                        : 'Gerenciador de Senhas',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isCreatingPassword
                        ? 'Crie uma senha forte para proteger suas credenciais'
                        : 'Digite sua senha mestra para continuar',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Botão de biometria (se disponível e habilitado)
                  if (!_isCreatingPassword &&
                      _canUseBiometric &&
                      _biometricEnabled) ...[
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleBiometricLogin,
                      icon: const Icon(Icons.fingerprint, size: 32),
                      label: const Text('Usar Biometria'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('OU'),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Senha Mestra',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite a senha';
                      }
                      if (_isCreatingPassword && value.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  if (_isCreatingPassword) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Senha',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'As senhas não coincidem';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSubmit,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(_isCreatingPassword ? 'Criar' : 'Entrar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
