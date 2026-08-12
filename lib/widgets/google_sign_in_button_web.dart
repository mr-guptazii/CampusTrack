import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// google_sign_in_web's `signIn()` popup flow is deprecated: it polls
/// `window.closed`, which Chrome's Cross-Origin-Opener-Policy blocks by
/// default, leaving sign-in stuck forever. The package's own recommended fix
/// is to render Google's native button (via GIS) and react to account
/// changes instead of imperatively calling `signIn()`.
class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({super.key});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  StreamSubscription<GoogleSignInAccount?>? _sub;
  bool _handling = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _sub = auth.googleSignIn.onCurrentUserChanged.listen((account) async {
      if (account == null || _handling) return;
      _handling = true;
      final ok = await auth.signInWithGoogleAccount(account);
      if (!ok && mounted && auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.errorMessage!)),
        );
      }
      _handling = false;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plugin = GoogleSignInPlatform.instance;
    if (plugin is! GoogleSignInPlugin) return const SizedBox.shrink();
    return SizedBox(
      height: 44,
      width: double.infinity,
      child: plugin.renderButton(
        configuration: GSIButtonConfiguration(
          type: GSIButtonType.standard,
          theme: GSIButtonTheme.outline,
          text: GSIButtonText.continueWith,
          shape: GSIButtonShape.rectangular,
        ),
      ),
    );
  }
}
