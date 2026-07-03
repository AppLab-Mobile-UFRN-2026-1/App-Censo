import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../widgets/app_text_field.dart';
import '../widgets/auth_shell.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  static const routeName = '/register';

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cadastro realizado com sucesso.')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Falha no cadastro: $error')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: 'Criar conta',
      subtitle:
          'Use um e-mail e senha para registrar ocorrencias no municipio.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'E-mail',
              hintText: 'Digite seu e-mail',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: Icons.mail_outline,
              validator: _validateEmail,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Senha',
              hintText: 'Crie uma senha',
              controller: _passwordController,
              obscureText: true,
              prefixIcon: Icons.lock_outline,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Informe a senha.';
                if (value.length < 6) return 'Use no minimo 6 caracteres.';
                return null;
              },
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Confirmar senha',
              hintText: 'Repita sua senha',
              controller: _confirmController,
              obscureText: true,
              prefixIcon: Icons.verified_user_outlined,
              validator: (value) {
                if (value != _passwordController.text) {
                  return 'As senhas nao conferem.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Cadastrar',
              icon: Icons.person_add_alt_1_outlined,
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _loading ? null : () => Navigator.of(context).pop(),
              child: const Text('Ja tenho conta'),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Informe o e-mail.';
    if (!email.contains('@') || !email.contains('.')) {
      return 'Informe um e-mail valido.';
    }
    return null;
  }
}
