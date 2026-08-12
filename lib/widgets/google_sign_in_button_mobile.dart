import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Native Android/iOS Google sign-in: `GoogleSignIn().signIn()` opens the
/// platform's own account picker, so a plain button triggering it is fine
/// here (unlike the web popup flow, which is deprecated and gets stuck).
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({super.key});

  Future<void> _submit(BuildContext context, AuthProvider auth) async {
    final ok = await auth.signInWithGoogle();
    if (!ok && context.mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return OutlinedButton.icon(
      onPressed: auth.isLoading ? null : () => _submit(context, auth),
      icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
      label: const Text('Continue with Google'),
      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
    );
  }
}
