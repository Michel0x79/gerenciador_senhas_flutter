import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/password_generator_service.dart';

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({super.key});

  @override
  State<PasswordGeneratorScreen> createState() =>
      _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  final _generatorService = PasswordGeneratorService();
  String _generatedPassword = '';
  double _length = 16;
  bool _includeUppercase = true;
  bool _includeLowercase = true;
  bool _includeNumbers = true;
  bool _includeSpecial = true;

  @override
  void initState() {
    super.initState();
    _generatePassword();
  }

  void _generatePassword() {
    try {
      final password = _generatorService.generatePassword(
        length: _length.toInt(),
        includeUppercase: _includeUppercase,
        includeLowercase: _includeLowercase,
        includeNumbers: _includeNumbers,
        includeSpecial: _includeSpecial,
      );
      setState(() => _generatedPassword = password);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatedPassword));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Senha copiada!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerador de Senhas'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _generatedPassword,
                          style: const TextStyle(
                            fontSize: 20,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: _copyToClipboard,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Gerar Nova Senha'),
                      onPressed: _generatePassword,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tamanho: ${_length.toInt()} caracteres',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Slider(
            value: _length,
            min: 4,
            max: 32,
            divisions: 28,
            label: _length.toInt().toString(),
            onChanged: (value) {
              setState(() => _length = value);
              _generatePassword();
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Opções:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Letras Maiúsculas (A-Z)'),
            value: _includeUppercase,
            onChanged: (value) {
              setState(() => _includeUppercase = value);
              _generatePassword();
            },
          ),
          SwitchListTile(
            title: const Text('Letras Minúsculas (a-z)'),
            value: _includeLowercase,
            onChanged: (value) {
              setState(() => _includeLowercase = value);
              _generatePassword();
            },
          ),
          SwitchListTile(
            title: const Text('Números (0-9)'),
            value: _includeNumbers,
            onChanged: (value) {
              setState(() => _includeNumbers = value);
              _generatePassword();
            },
          ),
          SwitchListTile(
            title: const Text('Caracteres Especiais (!@#\$...)'),
            value: _includeSpecial,
            onChanged: (value) {
              setState(() => _includeSpecial = value);
              _generatePassword();
            },
          ),
        ],
      ),
    );
  }
}
