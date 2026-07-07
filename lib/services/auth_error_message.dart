import 'package:supabase_flutter/supabase_flutter.dart';

String loginErrorMessage(Object error) {
  if (error is AuthException) {
    final normalizedMessage = error.message.toLowerCase();

    if (normalizedMessage.contains('invalid login credentials')) {
      return 'Senha incorreta. Verifique seus dados e tente novamente.';
    }
    if (error.code == 'email_not_confirmed') {
      return 'Confirme seu e-mail antes de entrar.';
    }
  }

  return 'Nao foi possivel entrar. Tente novamente.';
}

String registerErrorMessage(Object error) {
  if (error is AuthException) {
    final normalizedMessage = error.message.toLowerCase();

    if (error.code == 'user_already_exists' ||
        error.code == 'email_exists' ||
        normalizedMessage.contains('already registered')) {
      return 'Este e-mail ja possui uma conta cadastrada.';
    }
  }

  return 'Nao foi possivel concluir o cadastro. Tente novamente.';
}
