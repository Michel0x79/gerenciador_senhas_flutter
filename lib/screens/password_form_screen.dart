import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/password_entry.dart';
import '../providers/password_provider.dart';

class PasswordFormScreen extends StatefulWidget {
  final PasswordEntry? entry;

  const PasswordFormScreen({super.key, this.entry});

  @override
  State<PasswordFormScreen> createState() => _PasswordFormScreenState();
}

class _PasswordFormScreenState extends State<PasswordFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _serviceController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _serviceController = TextEditingController(
      text: widget.entry?.serviceName ?? '',
    );
    _usernameController = TextEditingController(
      text: widget.entry?.username ?? '',
    );
    if (widget.entry != null) {
      try {
        final provider = Provider.of<PasswordProvider>(context, listen: false);
        _passwordController = TextEditingController(
          text: provider.decryptPassword(
            widget.entry!.encryptedPassword,
            widget.entry!.iv,
          ),
        );
      } catch (e) {
        _passwordController = TextEditingController();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao carregar senha: $e')),
            );
          }
        });
      }
    } else {
      _passwordController = TextEditingController();
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = Provider.of<PasswordProvider>(context, listen: false);
    bool success;

    try {
      if (widget.entry == null) {
        success = await provider.addPassword(
          serviceName: _serviceController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        success = await provider.updatePassword(
          id: widget.entry!.id!,
          serviceName: _serviceController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);

        if (success) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.entry == null
                    ? 'Senha adicionada com sucesso!'
                    : 'Senha atualizada com sucesso!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          final errorMsg =
              provider.lastError ?? 'Erro desconhecido ao salvar senha';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro inesperado: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry == null ? 'Nova Senha' : 'Editar Senha'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _serviceController,
              decoration: const InputDecoration(
                labelText: 'Nome do Serviço/Conta',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
                hintText: 'Ex: Gmail, Netflix, Facebook',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Digite o nome do serviço';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Usuário/Login/Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
                hintText: 'Ex: usuario@email.com',
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Digite o usuário';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Senha',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite a senha';
                }
                if (value.length < 3) {
                  return 'A senha deve ter pelo menos 3 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
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
                    : Text(
                        widget.entry == null
                            ? 'Adicionar Senha'
                            : 'Atualizar Senha',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
