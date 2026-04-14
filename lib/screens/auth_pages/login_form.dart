import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../services/auth_fn.dart';
import '../../config/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════
// FIREBASE ERROR HANDLER  ← centralised, call from anywhere
// ═══════════════════════════════════════════════════════════════════════
class _FirebaseErrorHandler {
  /// Returns a human-readable message for every Firebase Auth error code.
  static String message(FirebaseAuthException e) {
    switch (e.code) {
      // ── Credential / email ──────────────────────────────────
      case 'invalid-email':
        return 'That email address isn\'t valid. Please check it and try again.';
      case 'email-already-in-use':
        return 'An account already exists for that email. Try signing in instead.';
      case 'user-not-found':
        return 'No account found for that email address. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again or reset your password.';
      case 'invalid-credential':
        // Firebase v10+ unifies wrong-password + user-not-found
        return 'Email or password is incorrect. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Your account is temporarily locked. Try again later or reset your password.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled. Please contact support.';

      // ── Password reset ──────────────────────────────────────
      case 'missing-email':
        return 'Please enter your email address first.';
      case 'auth/missing-email':
        return 'Please enter your email address first.';

      // ── Google / OAuth ──────────────────────────────────────
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but a different sign-in method. Try signing in with email/password.';
      case 'credential-already-in-use':
        return 'This credential is already linked to a different account.';
      case 'popup-closed-by-user':
        return 'Sign-in window was closed. Please try again.';
      case 'cancelled-popup-request':
        return 'Only one sign-in window can be open at a time.';
      case 'popup-blocked':
        return 'Sign-in popup was blocked by the browser.';
      case 'unauthorized-domain':
        return 'This domain is not authorised for OAuth operations.';

      // ── Network ─────────────────────────────────────────────
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'timeout':
        return 'The request timed out. Please check your connection.';
      case 'web-context-cancelled':
        return 'The operation was cancelled. Please try again.';

      // ── Token / session ─────────────────────────────────────
      case 'requires-recent-login':
        return 'For security, please sign out and sign in again before continuing.';
      case 'user-token-expired':
        return 'Your session has expired. Please sign in again.';
      case 'invalid-user-token':
        return 'Your session is invalid. Please sign in again.';

      // ── Multi-factor ────────────────────────────────────────
      case 'multi-factor-auth-required':
        return 'This account requires multi-factor authentication.';
      case 'second-factor-already-in-use':
        return 'This second factor is already enrolled on another account.';
      case 'maximum-second-factor-count-exceeded':
        return 'Maximum number of second factors reached.';

      // ── Weak password ───────────────────────────────────────
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password (min. 6 characters).';

      // ── App check ───────────────────────────────────────────
      case 'app-not-authorized':
        return 'App is not authorised to use Firebase Authentication.';
      case 'app-not-installed':
        return 'The required app is not installed on this device.';
      case 'captcha-check-failed':
        return 'reCAPTCHA verification failed. Please try again.';

      // ── Phone ───────────────────────────────────────────────
      case 'invalid-phone-number':
        return 'The phone number is not valid.';
      case 'invalid-verification-code':
        return 'The verification code is incorrect. Please try again.';
      case 'invalid-verification-id':
        return 'The verification ID is invalid. Please request a new code.';
      case 'missing-phone-number':
        return 'Please enter a phone number.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'session-expired':
        return 'Your verification session has expired. Please request a new code.';

      // ── Fallback ────────────────────────────────────────────
      default:
        // Surfaces the raw Firebase message as last resort
        return e.message ?? 'An unexpected error occurred. Please try again.';
    }
  }

  /// Whether the error is severe enough to warrant an AlertDialog.
  static bool requiresAlert(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-disabled':
      case 'operation-not-allowed':
      case 'too-many-requests':
      case 'requires-recent-login':
      case 'account-exists-with-different-credential':
      case 'app-not-authorized':
        return true;
      default:
        return false;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PARTICLE MODEL
// ═══════════════════════════════════════════════════════════════════════
class _Particle {
  double centerX, centerY;
  double ampX, ampY;
  double freqX, freqY;
  double phaseX, phaseY;
  double size;
  double opacity;

  _Particle({
    required this.centerX,
    required this.centerY,
    required this.ampX,
    required this.ampY,
    required this.freqX,
    required this.freqY,
    required this.phaseX,
    required this.phaseY,
    required this.size,
    required this.opacity,
  });
}

// ═══════════════════════════════════════════════════════════════════════
// FLOATING PARTICLES PAINTER
// ═══════════════════════════════════════════════════════════════════════
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = progress * 2 * math.pi;
      final dx =
          (p.centerX + p.ampX * math.cos(t * p.freqX + p.phaseX)) * size.width;
      final dy =
          (p.centerY + p.ampY * math.sin(t * p.freqY + p.phaseY)) * size.height;

      final paint = Paint()
        ..color = color.withOpacity(
          p.opacity * (0.4 + 0.6 * math.sin(t * p.freqX + p.phaseX).abs()),
        )
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(dx, dy), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => true;
}

// ═══════════════════════════════════════════════════════════════════════
// GEOMETRIC ARCS PAINTER
// ═══════════════════════════════════════════════════════════════════════
class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isDark;

  _ArcPainter(
      {required this.progress, required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final arcs = [
      _ArcDef(cx: -0.1, cy: 0.18, r: 0.55, start: -0.3, sweep: 1.1, op: 0.07),
      _ArcDef(cx: 1.1, cy: 0.12, r: 0.48, start: 1.8, sweep: 1.3, op: 0.06),
      _ArcDef(cx: 0.5, cy: -0.05, r: 0.72, start: 0.0, sweep: 0.9, op: 0.05),
      _ArcDef(cx: -0.15, cy: 0.5, r: 0.35, start: 0.5, sweep: 1.8, op: 0.08),
    ];

    for (int i = 0; i < arcs.length; i++) {
      final a = arcs[i];
      final animOffset = math.sin(progress * math.pi * 2 + i * 0.9) * 0.04;
      paint.color = color.withOpacity(a.op + animOffset.abs() * 0.03);
      final rect = Rect.fromCircle(
        center:
            Offset((a.cx + animOffset * 0.5) * size.width, a.cy * size.height),
        radius: a.r * size.width,
      );
      canvas.drawArc(rect, a.start * math.pi, a.sweep * math.pi, false, paint);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) => old.progress != progress;
}

class _ArcDef {
  final double cx, cy, r, start, sweep, op;
  const _ArcDef(
      {required this.cx,
      required this.cy,
      required this.r,
      required this.start,
      required this.sweep,
      required this.op});
}

// ═══════════════════════════════════════════════════════════════════════
// MAIN LOGIN FORM
// ═══════════════════════════════════════════════════════════════════════
class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String email = '', password = '', fullname = '';
  bool login = true;
  bool _passwordVisible = false;
  int attempts = 0;
  bool _isLoading = false;

  late List<_Particle> _particles;
  final _rng = math.Random(42);

  late AnimationController _bgAmbientCtrl;
  late AnimationController _entranceCtrl;
  late AnimationController _modeCtrl;
  late AnimationController _btnCtrl;
  late AnimationController _logoOrbitCtrl;
  late AnimationController _shakeCtrl;

  late Animation<double> _bgFade;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<Offset> _logoSlide;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;
  late Animation<double> _pillFade;
  late Animation<Offset> _pillSlide;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _socialFade;
  late Animation<Offset> _socialSlide;
  late Animation<double> _modeAnim;
  late Animation<double> _btnScale;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _buildParticles();

    _bgAmbientCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..repeat();

    _logoOrbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _bgFade = _interval(0.0, 0.25);
    _logoFade = _interval(0.0, 0.35);
    _logoScale = Tween<double>(begin: 0.72, end: 1.0)
        .animate(_intervalCurve(0.0, 0.45, Curves.easeOutBack));
    _logoSlide = Tween<Offset>(begin: const Offset(0, -0.06), end: Offset.zero)
        .animate(_intervalCurve(0.0, 0.45, Curves.easeOutCubic));
    _taglineFade = _interval(0.22, 0.5);
    _taglineSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(_intervalCurve(0.22, 0.52, Curves.easeOutCubic));
    _pillFade = _interval(0.35, 0.6);
    _pillSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(_intervalCurve(0.35, 0.62, Curves.easeOutCubic));
    _cardFade = _interval(0.48, 0.75);
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(_intervalCurve(0.48, 0.80, Curves.easeOutCubic));
    _socialFade = _interval(0.70, 1.0);
    _socialSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(_intervalCurve(0.70, 1.0, Curves.easeOutCubic));

    _modeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _modeAnim =
        CurvedAnimation(parent: _modeCtrl, curve: Curves.easeInOutCubic);

    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _btnScale = Tween<double>(begin: 1.0, end: 0.958)
        .animate(CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut));

    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -4.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -4.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _entranceCtrl.forward();
  }

  void _buildParticles() {
    _particles = List.generate(22, (i) {
      return _Particle(
        centerX: _rng.nextDouble(),
        centerY: _rng.nextDouble(),
        ampX: 0.15 + _rng.nextDouble() * 0.25,
        ampY: 0.12 + _rng.nextDouble() * 0.22,
        freqX: 0.8 + _rng.nextDouble() * 0.7,
        freqY: 0.9 + _rng.nextDouble() * 0.6,
        phaseX: _rng.nextDouble() * 2 * math.pi,
        phaseY: _rng.nextDouble() * 2 * math.pi,
        size: 1.4 + _rng.nextDouble() * 2.2,
        opacity: 0.15 + _rng.nextDouble() * 0.35,
      );
    });
  }

  Animation<double> _interval(double s, double e) => CurvedAnimation(
        parent: _entranceCtrl,
        curve: Interval(s, e, curve: Curves.easeOut),
      );

  Animation<double> _intervalCurve(double s, double e, Curve c) =>
      CurvedAnimation(parent: _entranceCtrl, curve: Interval(s, e, curve: c));

  @override
  void dispose() {
    _bgAmbientCtrl.dispose();
    _entranceCtrl.dispose();
    _modeCtrl.dispose();
    _btnCtrl.dispose();
    _logoOrbitCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    HapticFeedback.selectionClick();
    setState(() => login = !login);
    login ? _modeCtrl.reverse() : _modeCtrl.forward();
  }

  // ════════════════════════════════════════════════════════════════
  // SNACKBAR / ALERT HELPERS
  // ════════════════════════════════════════════════════════════════

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(_snack(msg, isError: isError));
  }

  void _showErrorAlert({
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final theme = KMTheme.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E2428) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: theme.error, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark ? Colors.white : const Color(0xFF0E1214),
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontFamily: 'Readex Pro',
              fontSize: 13.5,
              height: 1.55,
              color: isDark
                  ? Colors.white.withOpacity(0.65)
                  : Colors.black.withOpacity(0.6),
            ),
          ),
          actions: [
            if (onAction != null && actionLabel != null)
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  onAction();
                },
                child: Text(
                  actionLabel,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600,
                    color: theme.primary,
                  ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                onAction != null ? 'Cancel' : 'OK',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withOpacity(0.55)
                      : Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Central dispatcher: decides snackbar vs alert based on error severity.
  void _handleFirebaseError(FirebaseAuthException e) {
    HapticFeedback.vibrate();
    _shakeCtrl.forward(from: 0);

    final msg = _FirebaseErrorHandler.message(e);

    if (_FirebaseErrorHandler.requiresAlert(e)) {
      // Determine if we should offer a recovery action
      String? actionLabel;
      VoidCallback? onAction;

      if (e.code == 'too-many-requests') {
        actionLabel = 'Reset Password';
        onAction = () => _sendPasswordReset();
      } else if (e.code == 'requires-recent-login') {
        actionLabel = 'Sign Out';
        onAction = () => FirebaseAuth.instance.signOut();
      }

      _showErrorAlert(
        title: _alertTitle(e.code),
        message: msg,
        actionLabel: actionLabel,
        onAction: onAction,
      );
    } else {
      _showSnack(msg, isError: true);
    }
  }

  String _alertTitle(String code) {
    switch (code) {
      case 'user-disabled':
        return 'Account Disabled';
      case 'operation-not-allowed':
        return 'Sign-in Unavailable';
      case 'too-many-requests':
        return 'Account Temporarily Locked';
      case 'requires-recent-login':
        return 'Re-authentication Required';
      case 'account-exists-with-different-credential':
        return 'Account Conflict';
      case 'app-not-authorized':
        return 'App Not Authorised';
      default:
        return 'Authentication Error';
    }
  }

  // ════════════════════════════════════════════════════════════════
  // SUBMIT
  // ════════════════════════════════════════════════════════════════

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.vibrate();
      _shakeCtrl.forward(from: 0);
      return;
    }
    _formKey.currentState!.save();
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);

    try {
      if (login) {
        await AuthServices.signinUser(email, password, context);
      } else {
        await AuthServices.signupUser(email, password, fullname, context);
      }

      // Only reached on success
      attempts++;
      try {
        await FirebaseMessaging.instance.subscribeToTopic('need_help');
      } catch (_) {
        // Non-critical — messaging errors don't block the auth flow
      }
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } on FirebaseException catch (e) {
      // Non-auth Firebase errors (Firestore, Storage, etc.)
      _showSnack(
        e.message ?? 'A Firebase error occurred. Please try again.',
        isError: true,
      );
    } catch (e) {
      // Any other unexpected error
      _showSnack(
        'Something went wrong. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ════════════════════════════════════════════════════════════════
  // FORGOT PASSWORD / RESET EMAIL
  // ════════════════════════════════════════════════════════════════

  Future<void> _sendPasswordReset() async {
    // Guard: email field must have a value
    if (email.trim().isEmpty) {
      _showErrorAlert(
        title: 'Email Required',
        message:
            'Please enter your email address in the field above, then tap "Forgot password?" again.',
      );
      return;
    }

    // Basic client-side email validation before hitting Firebase
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email.trim())) {
      _showSnack('Please enter a valid email address first.', isError: true);
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
      _showSnack('Password reset email sent! Check your inbox.');
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          // Security note: some apps deliberately don't reveal this.
          // We surface it here for better UX — adjust to your policy.
          _showSnack(
            'No account found for that email address.',
            isError: true,
          );
          break;
        case 'invalid-email':
          _showSnack('That email address is not valid.', isError: true);
          break;
        case 'too-many-requests':
          _showSnack(
            'Too many reset attempts. Please wait a while before trying again.',
            isError: true,
          );
          break;
        case 'missing-email':
        case 'auth/missing-email':
          _showSnack('Please enter your email address first.', isError: true);
          break;
        default:
          _showSnack(
            _FirebaseErrorHandler.message(e),
            isError: true,
          );
      }
    } catch (_) {
      _showSnack('Could not send reset email. Please try again.',
          isError: true);
    }
  }

  // ════════════════════════════════════════════════════════════════
  // GOOGLE SIGN-IN  (wraps AuthServices so we can catch errors here)
  // ════════════════════════════════════════════════════════════════

  Future<void> _googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await AuthServices.signInWithGoogle(context);
      try {
        await FirebaseMessaging.instance.subscribeToTopic('need_help');
      } catch (_) {}
    } on FirebaseAuthException catch (e) {
      _handleFirebaseError(e);
    } on FirebaseException catch (e) {
      _showSnack(
        e.message ?? 'A Firebase error occurred. Please try again.',
        isError: true,
      );
    } catch (e) {
      final msg = e.toString();
      // User cancelled Google sign-in sheet — silent, no error shown
      if (msg.contains('sign_in_canceled') ||
          msg.contains('canceled') ||
          msg.contains('PlatformException(sign_in_canceled')) {
        return;
      }
      // Google Play Services not available on device
      if (msg.contains('ApiException: 7') || msg.contains('network_error')) {
        _showSnack(
          'Network error during Google sign-in. Check your connection.',
          isError: true,
        );
        return;
      }
      _showSnack('Google sign-in failed. Please try again.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0E1214) : const Color(0xFFF5EFEE),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            FadeTransition(
              opacity: _bgFade,
              child: AnimatedBuilder(
                animation: _bgAmbientCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _ArcPainter(
                    progress: _bgAmbientCtrl.value,
                    color: theme.primary,
                    isDark: isDark,
                  ),
                  size: Size(size.width, size.height),
                ),
              ),
            ),
            FadeTransition(
              opacity: _bgFade,
              child: AnimatedBuilder(
                animation: _bgAmbientCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    progress: _bgAmbientCtrl.value,
                    color: theme.primary,
                  ),
                  size: Size(size.width, size.height),
                ),
              ),
            ),
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height),
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.07),
                    _buildLogoSection(theme, size, isDark),
                    SizedBox(height: size.height * 0.032),
                    SlideTransition(
                      position: _pillSlide,
                      child: FadeTransition(
                        opacity: _pillFade,
                        child: _buildModePill(theme, isDark),
                      ),
                    ),
                    SizedBox(height: size.height * 0.028),
                    AnimatedBuilder(
                      animation: _shakeAnim,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(_shakeAnim.value, 0),
                        child: child,
                      ),
                      child: SlideTransition(
                        position: _cardSlide,
                        child: FadeTransition(
                          opacity: _cardFade,
                          child: _buildFormCard(theme, size, isDark),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.022),
                    SlideTransition(
                      position: _socialSlide,
                      child: FadeTransition(
                        opacity: _socialFade,
                        child: _buildSocialSection(theme, isDark),
                      ),
                    ),
                    SizedBox(height: size.height * 0.06),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // LOGO SECTION
  // ════════════════════════════════════════════════════════════════
  Widget _buildLogoSection(KMTheme theme, Size size, bool isDark) {
    final logoSize = size.width * 0.24;

    return SlideTransition(
      position: _logoSlide,
      child: FadeTransition(
        opacity: _logoFade,
        child: ScaleTransition(
          scale: _logoScale,
          child: Column(
            children: [
              SizedBox(
                width: logoSize + 60,
                height: logoSize + 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _logoOrbitCtrl,
                      builder: (_, __) {
                        return SizedBox(
                          width: logoSize + 52,
                          height: logoSize + 52,
                          child: Stack(
                            alignment: Alignment.center,
                            children: List.generate(8, (i) {
                              final angle = (i / 8) * math.pi * 2 +
                                  _logoOrbitCtrl.value * math.pi * 2;
                              final r = (logoSize + 52) / 2 - 6;
                              return Transform.translate(
                                offset: Offset(
                                  math.cos(angle) * r,
                                  math.sin(angle) * r,
                                ),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 400),
                                  width: i.isEven ? 4.5 : 2.8,
                                  height: i.isEven ? 4.5 : 2.8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: theme.primary
                                        .withOpacity(i.isEven ? 0.55 : 0.25),
                                  ),
                                ),
                              );
                            }),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: logoSize + 26,
                      height: logoSize + 26,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.primary.withOpacity(0.12),
                          width: 1.2,
                        ),
                      ),
                    ),
                    AnimatedBuilder(
                      animation: _bgAmbientCtrl,
                      builder: (_, __) {
                        final pulse =
                            math.sin(_bgAmbientCtrl.value * math.pi * 2) * 0.5 +
                                0.5;
                        return Container(
                          width: logoSize + 12,
                          height: logoSize + 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.primary
                                    .withOpacity(0.15 + pulse * 0.18),
                                blurRadius: 20 + pulse * 16,
                                spreadRadius: 2 + pulse * 4,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Container(
                      width: logoSize,
                      height: logoSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? const Color(0xFF1E1416)
                            : const Color(0xFFFAC6C3),
                        border: Border.all(
                          color: theme.primary.withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primary.withOpacity(0.22),
                            blurRadius: 28,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(isDark ? 0.4 : 0.10),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Image.asset(
                            'assets/images/KindMap-logo-f.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: isDark
                      ? [Colors.white, Colors.white.withOpacity(0.82)]
                      : [
                          const Color(0xFF1A0A0A),
                          const Color(0xFF3D1818),
                        ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                child: const Text(
                  'KindMap',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -2.0,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SlideTransition(
                position: _taglineSlide,
                child: FadeTransition(
                  opacity: _taglineFade,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 1.5,
                        decoration: BoxDecoration(
                          color: theme.primary.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Connecting Hearts, Changing Lives',
                        style: TextStyle(
                          fontFamily: 'Readex Pro',
                          color: isDark
                              ? Colors.white.withOpacity(0.38)
                              : const Color(0xFF1A0A0A).withOpacity(0.42),
                          fontSize: 12.5,
                          letterSpacing: 0.4,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 24,
                        height: 1.5,
                        decoration: BoxDecoration(
                          color: theme.primary.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // MODE PILL
  // ════════════════════════════════════════════════════════════════
  Widget _buildModePill(KMTheme theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.055),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.09)
                : Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOutCubic,
              alignment: login ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(isDark ? 0.52 : 0.38),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.primary.withOpacity(0.25),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.38),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              children: ['Sign In', 'Sign Up'].asMap().entries.map((e) {
                final isActive = (e.key == 0) == login;
                return Expanded(
                  child: GestureDetector(
                    onTap: (e.key == 0) == login ? null : _toggleMode,
                    child: Center(
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 300),
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.white
                              : (isDark
                                  ? Colors.white.withOpacity(0.35)
                                  : Colors.black.withOpacity(0.35)),
                          letterSpacing: -0.1,
                        ),
                        child: Text(e.value),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // FORM CARD
  // ════════════════════════════════════════════════════════════════
  Widget _buildFormCard(KMTheme theme, Size size, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF161C1F).withOpacity(0.96)
              : Colors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.07)
                : Colors.black.withOpacity(0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.45)
                  : Colors.black.withOpacity(0.09),
              blurRadius: 40,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: theme.primary.withOpacity(isDark ? 0.08 : 0.05),
              blurRadius: 60,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 32,
                right: 32,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        isDark
                            ? Colors.white.withOpacity(0.12)
                            : Colors.white.withOpacity(0.9),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 380),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: _buildCardHeading(theme, isDark),
                      ),
                      const SizedBox(height: 26),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeInOutCubic,
                        child: login
                            ? const SizedBox.shrink()
                            : Column(children: [
                                _KMField(
                                  key: const ValueKey('name'),
                                  theme: theme,
                                  isDark: isDark,
                                  label: 'Full Name',
                                  icon: Icons.person_outline_rounded,
                                  keyboardType: TextInputType.name,
                                  validator: (v) => v!.trim().isEmpty
                                      ? 'Enter your name'
                                      : null,
                                  onSaved: (v) => fullname = v!,
                                ),
                                const SizedBox(height: 14),
                              ]),
                      ),
                      _KMField(
                        key: const ValueKey('email'),
                        theme: theme,
                        isDark: isDark,
                        label: 'Email address',
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter your email address';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(v.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                        onSaved: (v) => email = v!.trim(),
                      ),
                      const SizedBox(height: 14),
                      _KMPasswordField(
                        theme: theme,
                        isDark: isDark,
                        visible: _passwordVisible,
                        onToggle: () {
                          HapticFeedback.selectionClick();
                          setState(() => _passwordVisible = !_passwordVisible);
                        },
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                        onSaved: (v) => password = v!,
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeOut,
                        child: (login && attempts > 0)
                            ? _buildForgotPassword(theme)
                            : const SizedBox(height: 24),
                      ),
                      _buildCTA(theme, isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardHeading(KMTheme theme, bool isDark) {
    return Column(
      key: ValueKey(login),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 18,
              height: 2.5,
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              login ? 'WELCOME BACK' : 'GET STARTED',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: theme.primary.withOpacity(0.75),
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          login ? 'Sign in to\ncontinue' : 'Create your\naccount',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0E1214),
            letterSpacing: -0.9,
            height: 1.12,
          ),
        ),
      ],
    );
  }

  Widget _buildForgotPassword(KMTheme theme) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: _sendPasswordReset,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Forgot password?',
          style: TextStyle(
            fontFamily: 'Readex Pro',
            fontSize: 12.5,
            color: theme.primary.withOpacity(0.75),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCTA(KMTheme theme, bool isDark) {
    return ScaleTransition(
      scale: _btnScale,
      child: GestureDetector(
        onTapDown: (_) => _btnCtrl.forward(),
        onTapUp: (_) {
          _btnCtrl.reverse();
          _submit();
        },
        onTapCancel: () => _btnCtrl.reverse(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 58,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(isDark ? 1 : 0.6),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: theme.primary.withOpacity(_isLoading ? 0.2 : 0.4),
                blurRadius: _isLoading ? 2 : 4,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 28,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0x11FFFFFF),
                    ),
                  ),
                ),
                Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(
                        scale:
                            Tween<double>(begin: 0.78, end: 1.0).animate(anim),
                        child: child,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            key: ValueKey('load'),
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            key: ValueKey(login),
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                login
                                    ? Icons.arrow_forward_rounded
                                    : Icons.person_add_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                login ? 'Sign In' : 'Create Account',
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // SOCIAL
  // ════════════════════════════════════════════════════════════════
  Widget _buildSocialSection(KMTheme theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.transparent,
                      isDark
                          ? Colors.white.withOpacity(0.12)
                          : Colors.black.withOpacity(0.10),
                    ]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or continue with',
                  style: TextStyle(
                    fontFamily: 'Readex Pro',
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.3),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      isDark
                          ? Colors.white.withOpacity(0.12)
                          : Colors.black.withOpacity(0.10),
                      Colors.transparent,
                    ]),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _SocialTile(
                  icon: FontAwesomeIcons.google,
                  label: 'Google',
                  isDark: isDark,
                  theme: theme,
                  // ← uses the new wrapper with full error handling
                  onTap: _googleSignIn,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SocialTile(
                  icon: FontAwesomeIcons.apple,
                  label: 'Apple',
                  isDark: isDark,
                  theme: theme,
                  iconSize: 21,
                  onTap: () =>
                      debugPrint('Apple sign-in — not yet implemented'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // SNACKBAR FACTORY
  // ════════════════════════════════════════════════════════════════
  SnackBar _snack(String msg, {bool isError = false}) {
    final theme = KMTheme.of(context);
    return SnackBar(
      content: Row(children: [
        Icon(
          isError ? Icons.error_outline : Icons.check_circle_outline,
          color: Colors.white,
          size: 17,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            msg,
            style: const TextStyle(fontFamily: 'Readex Pro', fontSize: 13),
          ),
        ),
      ]),
      backgroundColor: isError ? theme.error : Colors.green.shade600,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: Duration(seconds: isError ? 4 : 3),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// KM TEXT FIELD
// ═══════════════════════════════════════════════════════════════════════
class _KMField extends StatefulWidget {
  final KMTheme theme;
  final bool isDark;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<String>? autofillHints;
  final String? Function(String?) validator;
  final void Function(String?) onSaved;

  const _KMField({
    super.key,
    required this.theme,
    required this.isDark,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.autofillHints,
    required this.validator,
    required this.onSaved,
  });

  @override
  State<_KMField> createState() => _KMFieldState();
}

class _KMFieldState extends State<_KMField>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusCtrl;
  late Animation<double> _focusAnim;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _focusAnim = CurvedAnimation(parent: _focusCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _focusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _focusAnim,
      builder: (_, child) => Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: child,
      ),
      child: Focus(
        onFocusChange: (f) {
          setState(() => _focused = f);
          f ? _focusCtrl.forward() : _focusCtrl.reverse();
        },
        child: TextFormField(
          keyboardType: widget.keyboardType,
          autofillHints: widget.autofillHints,
          style: TextStyle(
            fontFamily: 'Readex Pro',
            fontSize: 14.5,
            color: widget.isDark ? Colors.white : const Color(0xFF0E1214),
            fontWeight: FontWeight.w400,
          ),
          decoration: _decor(widget.theme, widget.isDark),
          validator: widget.validator,
          onSaved: widget.onSaved,
        ),
      ),
    );
  }

  InputDecoration _decor(KMTheme theme, bool isDark) {
    final borderColor = _focused
        ? theme.primary.withOpacity(0.65)
        : (isDark
            ? Colors.white.withOpacity(0.09)
            : Colors.black.withOpacity(0.09));

    return InputDecoration(
      labelText: widget.label,
      labelStyle: TextStyle(
        fontFamily: 'Readex Pro',
        fontSize: 13,
        color: _focused
            ? theme.primary.withOpacity(0.8)
            : (isDark
                ? Colors.white.withOpacity(0.38)
                : Colors.black.withOpacity(0.38)),
      ),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 18, right: 12),
        child: Icon(
          widget.icon,
          size: 18,
          color: _focused
              ? theme.primary.withOpacity(0.75)
              : (isDark
                  ? Colors.white.withOpacity(0.28)
                  : Colors.black.withOpacity(0.28)),
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      filled: true,
      fillColor: isDark
          ? Colors.white.withOpacity(_focused ? 0.06 : 0.04)
          : Colors.black.withOpacity(_focused ? 0.04 : 0.025),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: borderColor, width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide:
            BorderSide(color: theme.primary.withOpacity(0.6), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.error.withOpacity(0.6), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.error, width: 1.5),
      ),
      errorStyle: TextStyle(
        fontFamily: 'Readex Pro',
        fontSize: 11,
        color: theme.error,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// KM PASSWORD FIELD
// ═══════════════════════════════════════════════════════════════════════
class _KMPasswordField extends StatefulWidget {
  final KMTheme theme;
  final bool isDark;
  final bool visible;
  final VoidCallback onToggle;
  final String? Function(String?) validator;
  final void Function(String?) onSaved;

  const _KMPasswordField({
    required this.theme,
    required this.isDark,
    required this.visible,
    required this.onToggle,
    required this.validator,
    required this.onSaved,
  });

  @override
  State<_KMPasswordField> createState() => _KMPasswordFieldState();
}

class _KMPasswordFieldState extends State<_KMPasswordField>
    with SingleTickerProviderStateMixin {
  late AnimationController _focusCtrl;
  late Animation<double> _focusAnim;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _focusAnim = CurvedAnimation(parent: _focusCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _focusCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = widget.isDark;

    final borderColor = _focused
        ? theme.primary.withOpacity(0.65)
        : (isDark
            ? Colors.white.withOpacity(0.09)
            : Colors.black.withOpacity(0.09));

    return AnimatedBuilder(
      animation: _focusAnim,
      builder: (_, child) => Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: child,
      ),
      child: Focus(
        onFocusChange: (f) {
          setState(() => _focused = f);
          f ? _focusCtrl.forward() : _focusCtrl.reverse();
        },
        child: TextFormField(
          obscureText: !widget.visible,
          style: TextStyle(
            fontFamily: 'Readex Pro',
            fontSize: 14.5,
            color: isDark ? Colors.white : const Color(0xFF0E1214),
          ),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: TextStyle(
              fontFamily: 'Readex Pro',
              fontSize: 13,
              color: _focused
                  ? theme.primary.withOpacity(0.8)
                  : (isDark
                      ? Colors.white.withOpacity(0.38)
                      : Colors.black.withOpacity(0.38)),
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 18, right: 12),
              child: Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: _focused
                    ? theme.primary.withOpacity(0.75)
                    : (isDark
                        ? Colors.white.withOpacity(0.28)
                        : Colors.black.withOpacity(0.28)),
              ),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: GestureDetector(
              onTap: widget.onToggle,
              child: Padding(
                padding: const EdgeInsets.only(right: 14),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: anim,
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    widget.visible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    key: ValueKey(widget.visible),
                    size: 19,
                    color: isDark
                        ? Colors.white.withOpacity(0.3)
                        : Colors.black.withOpacity(0.3),
                  ),
                ),
              ),
            ),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(_focused ? 0.06 : 0.04)
                : Colors.black.withOpacity(_focused ? 0.04 : 0.025),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: theme.primary.withOpacity(0.6), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide:
                  BorderSide(color: theme.error.withOpacity(0.6), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.error, width: 1.5),
            ),
            errorStyle: TextStyle(
              fontFamily: 'Readex Pro',
              fontSize: 11,
              color: theme.error,
            ),
          ),
          validator: widget.validator,
          onSaved: widget.onSaved,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SOCIAL TILE
// ═══════════════════════════════════════════════════════════════════════
class _SocialTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final KMTheme theme;
  final VoidCallback onTap;
  final double iconSize;

  const _SocialTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.theme,
    required this.onTap,
    this.iconSize = 17,
  });

  @override
  State<_SocialTile> createState() => _SocialTileState();
}

class _SocialTileState extends State<_SocialTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _pressing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final theme = widget.theme;

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) {
          _ctrl.forward();
          setState(() => _pressing = true);
        },
        onTapUp: (_) {
          _ctrl.reverse();
          setState(() => _pressing = false);
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        onTapCancel: () {
          _ctrl.reverse();
          setState(() => _pressing = false);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 52,
          decoration: BoxDecoration(
            color: _pressing
                ? (isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.05))
                : (isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.03)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.09)
                  : Colors.black.withOpacity(0.09),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                widget.icon,
                size: widget.iconSize,
                color: isDark
                    ? Colors.white.withOpacity(0.7)
                    : Colors.black.withOpacity(0.65),
              ),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withOpacity(0.7)
                      : Colors.black.withOpacity(0.65),
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
