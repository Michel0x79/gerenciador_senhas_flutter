import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  bool _biometricEnabled = false;
  bool _canUseBiometric = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final canUse = await _authService.canUseBiometric();
      final enabled = await _authService.isBiometricEnabled();

      setState(() {
        _canUseBiometric = canUse;
        _biometricEnabled = enabled;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      setState(() => _isLoading = true);

      final authenticated = await _authService.authenticateWithBiometric();

      if (authenticated) {
        await _authService.setBiometricEnabled(true);
        setState(() {
          _biometricEnabled = true;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Autenticação biométrica ativada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Falha na autenticação biométrica'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      await _authService.setBiometricEnabled(false);
      setState(() => _biometricEnabled = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autenticação biométrica desativada')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                const ListTile(
                  title: Text(
                    'Segurança',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (_canUseBiometric)
                  SwitchListTile(
                    title: const Text('Autenticação Biométrica'),
                    subtitle: Text(
                      _biometricEnabled
                          ? 'Desbloqueio rápido ativado'
                          : 'Use digital ou face para desbloquear',
                    ),
                    value: _biometricEnabled,
                    onChanged: _toggleBiometric,
                    secondary: Icon(
                      _biometricEnabled
                          ? Icons.fingerprint
                          : Icons.fingerprint_outlined,
                      color: _biometricEnabled ? Colors.green : null,
                    ),
                  )
                else
                  const ListTile(
                    leading: Icon(
                      Icons.fingerprint_outlined,
                      color: Colors.grey,
                    ),
                    title: Text('Autenticação Biométrica'),
                    subtitle: Text(
                      'Configure a biometria nas configurações do dispositivo para usar este recurso',
                    ),
                    enabled: false,
                  ),
                const Divider(),
                const ListTile(
                  title: Text(
                    'Sobre',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const ListTile(title: Text('Versão'), subtitle: Text('1.2.0')),
                const ListTile(
                  title: Text('Desenvolvido com Flutter e amor ❤️'),
                  subtitle: Text(
                    'Gerenciador de senhas seguro e local (sem internet).\nCódigo aberto no GitHub.\nFeito por Michel.',
                  ),
                ),
              ],
            ),
    );
  }
}
