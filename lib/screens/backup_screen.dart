import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import '../services/backup_service.dart';
import '../services/auth_service.dart';
import '../providers/password_provider.dart';
import 'package:file_picker/file_picker.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _backupService = BackupService();
  final _authService = AuthService();
  bool _isLoading = false;
  List<File> _backupFiles = [];

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
  }

  Future<void> _loadBackupFiles() async {
    final files = await _backupService.getBackupFiles();
    setState(() => _backupFiles = files);
  }

  Future<void> _exportPasswords() async {
    // Pedir senha mestra
    final password = await _showPasswordDialog(
      title: 'Confirmar Exportação',
      message: 'Digite sua senha mestra para exportar',
    );

    if (password == null) return;

    // Verificar senha
    final isValid = await _authService.verifyMasterPassword(password);
    if (!isValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Senha incorreta!'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final file = await _backupService.exportPasswords(
        masterPassword: password,
      );

      if (file != null && mounted) {
        setState(() => _isLoading = false);

        // Perguntar o que fazer com o arquivo
        final action = await _showExportOptionsDialog(file);

        if (action == 'share') {
          await Share.shareXFiles(
            [XFile(file.path)],
            subject: 'Backup de Senhas',
            text: 'Backup criptografado do Gerenciador de Senhas',
          );
        }

        await _loadBackupFiles();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Backup criado: ${file.path.split('/').last}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _importPasswords() async {
    try {
      // Escolher arquivo
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['gpwd'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);

      // Perguntar se quer substituir ou adicionar
      final replaceExisting = await _showImportOptionsDialog();
      if (replaceExisting == null) return;

      // Pedir senha mestra
      final password = await _showPasswordDialog(
        title: 'Confirmar Importação',
        message: 'Digite a senha mestra do backup',
      );

      if (password == null) return;

      setState(() => _isLoading = true);

      final count = await _backupService.importPasswords(
        backupFile: file,
        masterPassword: password,
        replaceExisting: replaceExisting,
      );

      // Recarregar senhas
      if (mounted) {
        await Provider.of<PasswordProvider>(
          context,
          listen: false,
        ).loadPasswords();
      }

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $count senhas importadas com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<String?> _showPasswordDialog({
    required String title,
    required String message,
  }) async {
    final controller = TextEditingController();
    bool obscure = true;

    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: obscure,
                decoration: InputDecoration(
                  labelText: 'Senha Mestra',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showExportOptionsDialog(File file) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Backup Criado'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              'Arquivo: ${file.path.split('/').last}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'keep'),
            child: const Text('Manter no App'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, 'share'),
            icon: const Icon(Icons.share),
            label: const Text('Compartilhar'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showImportOptionsDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Como Importar?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [Text('Escolha como deseja importar as senhas:')],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Adicionar às Existentes'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Substituir Tudo'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBackup(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Backup'),
        content: Text('Deseja excluir o backup ${file.path.split('/').last}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _backupService.deleteBackupFile(file);
      await _loadBackupFiles();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Backup excluído')));
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Backup e Restauração')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_upload,
                          size: 64,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Exportar Senhas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Crie um backup criptografado de todas as suas senhas.\nO arquivo pode ser compartilhado ou armazenado com segurança.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _exportPasswords,
                            icon: const Icon(Icons.save_alt),
                            label: const Text('Exportar Agora'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_download,
                          size: 64,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Importar Senhas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Restaure suas senhas de um backup anterior.\n A SENHA MESTRA há de ser identica à do backup para funcionar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _importPasswords,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('Escolher Arquivo'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Backups Salvos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (_backupFiles.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'Nenhum backup encontrado',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                else
                  ..._backupFiles.map((file) {
                    final stat = file.statSync();
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.backup, color: Colors.blue),
                        title: Text(file.path.split('/').last),
                        subtitle: Text(
                          '${_formatDate(stat.modified)} • ${_formatFileSize(stat.size)}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteBackup(file),
                        ),
                        onTap: () async {
                          final result = await showDialog<String>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Ações'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ListTile(
                                    leading: const Icon(Icons.share),
                                    title: const Text('Compartilhar'),
                                    onTap: () =>
                                        Navigator.pop(context, 'share'),
                                  ),
                                  ListTile(
                                    leading: const Icon(Icons.restore),
                                    title: const Text('Restaurar'),
                                    onTap: () =>
                                        Navigator.pop(context, 'restore'),
                                  ),
                                ],
                              ),
                            ),
                          );

                          if (result == 'share') {
                            await Share.shareXFiles([XFile(file.path)]);
                          } else if (result == 'restore') {
                            // Implementar restauração
                          }
                        },
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}
