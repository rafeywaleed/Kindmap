import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../controllers/user_controller.dart';
import '../models/user_model.dart';

class AuthServices {
  /// Creates a new Firebase account and the matching backend profile.
  ///
  /// FirebaseAuthExceptions (weak-password, email-already-in-use, etc.) are
  /// intentionally left to propagate — the caller (LoginForm) has a
  /// centralised handler that maps every error code to a user-friendly
  /// message/dialog.
  static Future<void> signupUser(
      String email, String password, String name, BuildContext context) async {
    final userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    await userCredential.user!.updateDisplayName(name);

    // Best-effort: create the backend profile + register the FCM token.
    // The Firebase account already exists at this point, so a backend hiccup
    // shouldn't block the user from entering the app.
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      await UserController().addUser(User(
        userId: userCredential.user!.uid,
        name: name,
        email: email,
        joinedDate: DateTime.now(),
        avatarIndex: 1,
        helped: 0,
        token: fcmToken ?? '',
        subscribedGridIds: [],
      ));
    } catch (e) {
      debugPrint('Failed to create backend profile: $e');
    }

    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/introScreens');
  }

  /// Signs an existing user in. FirebaseAuthExceptions (wrong-password,
  /// user-not-found, invalid-credential, too-many-requests, etc.) propagate
  /// to the caller's centralised error handler.
  static Future<void> signinUser(
      String email, String password, BuildContext context) async {
    await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    // Best-effort FCM token refresh — non-critical if it fails.
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      await UserController().updateFCMToken(
          FirebaseAuth.instance.currentUser!.uid, fcmToken ?? '');
    } catch (e) {
      debugPrint('Failed to update FCM token: $e');
    }

    if (!context.mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  /// Signs in with Google (popup on web, native sheet on mobile).
  /// Creates the backend profile for first-time Google users. Errors
  /// (including user-cancelled flows) propagate to the caller.
  ///
  /// If an account with the same email already exists via email/password
  /// (account-exists-with-different-credential), the user is prompted for
  /// their password so the Google credential can be linked to that
  /// existing account instead of failing with a conflict error.
  static Future<void> signInWithGoogle(BuildContext context) async {
    UserCredential userCredential;

    if (kIsWeb) {
      // GoogleSignIn().signIn() isn't supported on web; Firebase Auth's
      // popup flow handles the OAuth exchange directly.
      try {
        userCredential =
            await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      } on FirebaseAuthException catch (e) {
        if (e.code != 'account-exists-with-different-credential') rethrow;
        final linked = await _linkGoogleToExistingAccount(
            context, e, e.credential);
        if (linked == null) return;
        userCredential = linked;
      }
    } else {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled the Google Sign-In flow.
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      try {
        userCredential =
            await FirebaseAuth.instance.signInWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code != 'account-exists-with-different-credential') rethrow;
        final linked = await _linkGoogleToExistingAccount(
            context, e, credential);
        if (linked == null) return;
        userCredential = linked;
      }
    }

    final user = userCredential.user!;
    final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

    // Best-effort backend sync — non-critical if it fails.
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (isNewUser) {
        await UserController().addUser(User(
          userId: user.uid,
          name: user.displayName ?? 'KindMap User',
          email: user.email ?? '',
          joinedDate: DateTime.now(),
          avatarIndex: 1,
          helped: 0,
          token: fcmToken ?? '',
          subscribedGridIds: [],
        ));
      } else {
        await UserController().updateFCMToken(user.uid, fcmToken ?? '');
      }
    } catch (e) {
      debugPrint('Failed to sync backend profile: $e');
    }

    if (!context.mounted) return;
    Navigator.pushReplacementNamed(
        context, isNewUser ? '/introScreens' : '/home');
  }

  /// Resolves an `account-exists-with-different-credential` error by
  /// prompting the user for their existing password, signing them in with
  /// it, then linking the Google credential to that account.
  ///
  /// Returns the signed-in [UserCredential] on success, or `null` if the
  /// user cancelled the prompt. Rethrows [error] if the existing account
  /// isn't password-based or no Google credential is available to link.
  static Future<UserCredential?> _linkGoogleToExistingAccount(
    BuildContext context,
    FirebaseAuthException error,
    AuthCredential? googleCredential,
  ) async {
    final email = error.email;
    if (email == null || googleCredential == null) {
      throw error;
    }

    final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
    if (!methods.contains('password')) {
      throw error;
    }

    if (!context.mounted) throw error;
    final password = await _askForLinkPassword(context, email);
    if (password == null) return null;

    final userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    await userCredential.user!.linkWithCredential(googleCredential);
    return userCredential;
  }

  /// Shows a dialog asking the user for the password of their existing
  /// email/password account so it can be linked with Google sign-in.
  static Future<String?> _askForLinkPassword(
      BuildContext context, String email) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Link your accounts'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'An account already exists for $email with a password. '
              'Enter that password to link it with Google sign-in.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }
}
