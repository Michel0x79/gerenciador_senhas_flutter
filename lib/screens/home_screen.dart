import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/password_provider.dart';
import '../models/password_entry.dart';
import 'password_form_screen.dart';
import 'password_generator_screen.dart';
import 'settings_screen.dart';
import 'backup_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<int, bool> _visiblePasswords = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PasswordProvider>(context, listen: false).loadPasswords();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciador de Senhas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.vpn_key),
            tooltip: 'Gerador de Senhas',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PasswordGeneratorScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configurações',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.backup),
            tooltip: 'Backup',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BackupScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<PasswordProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.passwords.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.password, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma senha salva',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Toque no + para adicionar uma nova senha',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: provider.passwords.length,
            padding: const EdgeInsets.all(8),
            // Adicionar essa linha para melhor performance
            cacheExtent: 100,
            itemBuilder: (context, index) {
              final entry = provider.passwords[index];
              final isVisible = _visiblePasswords[entry.id] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                // Adicionar elevation para melhor visual
                elevation: 2,
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Text(
                      entry.serviceName[0].toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  title: Text(
                    entry.serviceName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(entry.username),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  isVisible
                                      ? provider.decryptPassword(
                                          entry.encryptedPassword,
                                          entry.iv,
                                        )
                                      : '••••••••',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                tooltip: isVisible
                                    ? 'Ocultar senha'
                                    : 'Mostrar senha',
                                onPressed: () {
                                  setState(() {
                                    _visiblePasswords[entry.id!] = !isVisible;
                                  });
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy),
                                tooltip: 'Copiar senha',
                                onPressed: () {
                                  final password = provider.decryptPassword(
                                    entry.encryptedPassword,
                                    entry.iv,
                                  );
                                  Clipboard.setData(
                                    ClipboardData(text: password),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Senha copiada!'),
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.edit),
                                label: const Text('Editar'),
                                onPressed: () =>
                                    _navigateToForm(context, entry),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                label: const Text(
                                  'Excluir',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: () => _confirmDelete(context, entry),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToForm(context, null),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navigateToForm(BuildContext context, PasswordEntry? entry) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PasswordFormScreen(entry: entry)),
    );
  }

  void _confirmDelete(BuildContext context, PasswordEntry entry) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja excluir a senha de ${entry.serviceName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await Provider.of<PasswordProvider>(
                context,
                listen: false,
              ).deletePassword(entry.id!);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Senha excluída!' : 'Erro ao excluir',
                    ),
                  ),
                );
              }
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
