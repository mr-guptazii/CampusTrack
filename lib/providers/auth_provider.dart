import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../repositories/firebase_repository.dart';
import '../repositories/local_repository.dart';
import '../core/constants/app_constants.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Handles email/password + Google sign-in, and keeps a synced UserModel
/// profile. Persistent login is provided for free by FirebaseAuth's own
/// session persistence; we just listen to authStateChanges().
class AuthProvider extends ChangeNotifier {
  AuthProvider() {
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  // google_sign_in_web has no meta-tag fallback wired up in web/index.html,
  // so the web OAuth client id (from Firebase Auth's Google provider config)
  // must be passed explicitly here, or GoogleSignIn() throws on construction
  // for every web page load, not just when Google sign-in is actually used.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '201233177226-eios8ecd0ikejoajomuli41qskt88h90.apps.googleusercontent.com' : null,
  );

  AuthStatus status = AuthStatus.unknown;
  UserModel? currentUser;
  String? errorMessage;
  bool isLoading = false;

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      status = AuthStatus.unauthenticated;
      currentUser = null;
      notifyListeners();
      return;
    }
    var profile = await FirebaseRepository.instance.getUser(user.uid);
    profile ??= UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? (user.email?.split('@').first ?? 'Student'),
      photoUrl: user.photoURL,
      defaultTargetPercentage: AppDefaults.targetPercentage,
    );
    await FirebaseRepository.instance.upsertUser(profile);
    currentUser = profile;
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<bool> signUp(String email, String password, String name) async {
    return _guarded(() async {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);
      await cred.user?.updateDisplayName(name);
      final profile = UserModel(
        uid: cred.user!.uid,
        email: email.trim(),
        displayName: name,
        defaultTargetPercentage: AppDefaults.targetPercentage,
      );
      await FirebaseRepository.instance.upsertUser(profile);
      currentUser = profile;
    });
  }

  Future<bool> signIn(String email, String password) async {
    return _guarded(() async {
      await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    });
  }

  Future<bool> signInWithGoogle() async {
    return _guarded(() async {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(code: 'cancelled', message: 'Sign-in cancelled');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
    });
  }

  Future<void> resetPassword(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await LocalRepository.instance.clearAll();
  }

  Future<void> updateTargetPercentage(double target) async {
    if (currentUser == null) return;
    currentUser = currentUser!.copyWith(defaultTargetPercentage: target);
    await FirebaseRepository.instance.upsertUser(currentUser!);
    notifyListeners();
  }

  Future<void> updateNotificationsEnabled(bool enabled) async {
    if (currentUser == null) return;
    currentUser = currentUser!.copyWith(notificationsEnabled: enabled);
    await FirebaseRepository.instance.upsertUser(currentUser!);
    notifyListeners();
  }

  Future<void> updateDarkMode(bool enabled) async {
    if (currentUser == null) return;
    currentUser = currentUser!.copyWith(darkModeEnabled: enabled);
    await FirebaseRepository.instance.upsertUser(currentUser!);
    notifyListeners();
  }

  Future<bool> _guarded(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      errorMessage = e.message ?? 'Authentication failed';
      isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
