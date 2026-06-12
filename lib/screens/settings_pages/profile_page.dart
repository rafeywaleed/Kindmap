import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../controllers/user_controller.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/settings_widgets.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _nameFocus = FocusNode();

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _currentVisible = false;
  bool _newVisible = false;
  bool _confirmVisible = false;
  bool _changingPassword = false;
  bool _savingName = false;

  late AnimationController _pulseCtrl;
  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _ringScale = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _ringOpacity = Tween<double>(begin: 0.45, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _nameController.dispose();
    _nameFocus.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool success = false}) {
    final theme = KMTheme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? theme.success : null,
      ),
    );
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty || _savingName) return;

    FocusScope.of(context).unfocus();
    setState(() => _savingName = true);
    try {
      await context.read<ProfileProvider>().updateName(newName);
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await UserController().changeUserName(uid, newName);
      }
      _nameController.clear();
      if (mounted) _showSnack('Name updated', success: true);
    } catch (_) {
      if (mounted) _showSnack('Could not update name. Please try again.');
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  String _authErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Current password is incorrect';
      case 'weak-password':
        return 'New password is too weak';
      case 'requires-recent-login':
        return 'Please log out and back in, then try again';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }

  Future<void> _changePassword() async {
    final current = _currentPasswordController.text;
    final newPass = _newPasswordController.text;
    final confirm = _confirmPasswordController.text;

    if (current.isEmpty || newPass.isEmpty || confirm.isEmpty) {
      _showSnack('Please fill in all password fields');
      return;
    }
    if (newPass.length < 6) {
      _showSnack('New password must be at least 6 characters');
      return;
    }
    if (newPass != confirm) {
      _showSnack('New passwords do not match');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _changingPassword = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email;
      if (user == null || email == null) {
        throw FirebaseAuthException(
          code: 'no-user',
          message: 'No signed-in user',
        );
      }

      final credential =
          EmailAuthProvider.credential(email: email, password: current);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPass);

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      if (mounted) _showSnack('Password updated successfully', success: true);
    } on FirebaseAuthException catch (e) {
      _showSnack(_authErrorMessage(e));
    } catch (_) {
      _showSnack('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _changingPassword = false);
    }
  }

  Future<void> _onAvatarDoubleTap() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Avatar?'),
        content: const Text('Do you want to change your avatar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      Navigator.of(context).pushNamed('/avatars');
    }
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
    Widget? suffixIcon,
  }) {
    final theme = KMTheme.of(context);
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
          borderSide: BorderSide(color: color, width: width),
          borderRadius: BorderRadius.circular(12),
        );

    return InputDecoration(
      hintText: hint,
      hintStyle: theme.labelMedium.copyWith(
        fontFamily: 'Readex Pro',
        letterSpacing: 0,
      ),
      filled: true,
      fillColor: theme.secondaryBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      enabledBorder: border(theme.primaryText.withOpacity(0.12), 1),
      focusedBorder: border(theme.primary, 1.4),
      errorBorder: border(theme.error, 1),
      focusedErrorBorder: border(theme.error, 1.4),
      suffixIcon: suffixIcon,
    );
  }

  Widget _visibilityToggle(bool visible, VoidCallback onTap) {
    return IconButton(
      icon: Icon(
        visible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        size: 20,
      ),
      onPressed: onTap,
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    final profile = context.watch<ProfileProvider>();
    final size = MediaQuery.of(context).size;
    final avatarSize = size.width * 0.26;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.secondaryBackground,
        appBar: settingsAppBar(context, 'Profile'),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              FadeSlideIn(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                  child: Column(
                    children: [
                      GestureDetector(
                        onDoubleTap: _onAvatarDoubleTap,
                        child: SizedBox(
                          width: avatarSize + 20,
                          height: avatarSize + 20,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _pulseCtrl,
                                builder: (_, __) => Transform.scale(
                                  scale: _ringScale.value,
                                  child: Opacity(
                                    opacity: _ringOpacity.value,
                                    child: Container(
                                      width: avatarSize + 8,
                                      height: avatarSize + 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: theme.primary,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Hero(
                                tag: 'profile-avatar',
                                child: Container(
                                  width: avatarSize,
                                  height: avatarSize,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: theme.primary.withOpacity(0.7),
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.primary.withOpacity(0.2),
                                        blurRadius: 20,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: FittedBox(
                                    child: Image.asset(
                                      'assets/images/avatar${profile.user?.avatarIndex ?? 1}.png',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        profile.user?.name ?? 'User Name',
                        style: theme.headlineSmall.copyWith(
                          fontFamily: 'Outfit',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.user?.email ?? 'user@example.com',
                        style: theme.bodySmall.copyWith(
                          color: theme.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Double-tap your avatar to change it',
                        style: theme.labelSmall.copyWith(
                          color: theme.secondaryText.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 60),
                child: SettingsCard(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.asset(
                              'assets/images/trophy.png',
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'People you\'ve helped',
                                  style: theme.labelMedium.copyWith(
                                    color: theme.secondaryText,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  profile.user?.helped.toString() ?? '0',
                                  style: theme.headlineLarge.copyWith(
                                    fontFamily: 'Outfit',
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const FadeSlideIn(
                delay: Duration(milliseconds: 110),
                child: SettingsSectionLabel('Account'),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 130),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.primaryBackground,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: theme.primaryText.withOpacity(0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.badge_outlined,
                                size: 18, color: theme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Display name',
                              style: theme.bodyMedium.copyWith(
                                fontFamily: 'Readex Pro',
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _nameController,
                          focusNode: _nameFocus,
                          style: theme.bodyMedium.copyWith(
                            fontFamily: 'Readex Pro',
                            letterSpacing: 0,
                          ),
                          textInputAction: TextInputAction.done,
                          decoration: _inputDecoration(
                            context,
                            hint: profile.user?.name ?? 'New name',
                            suffixIcon: _savingName
                                ? const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                  )
                                : IconButton(
                                    icon: Icon(Icons.check_rounded,
                                        color: theme.primary),
                                    onPressed: _saveName,
                                  ),
                          ),
                          onFieldSubmitted: (_) => _saveName(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const FadeSlideIn(
                delay: Duration(milliseconds: 170),
                child: SettingsSectionLabel('Security'),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 190),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.accent4,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          Border.all(color: theme.primaryText.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lock_outline_rounded,
                                size: 18, color: theme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'Change password',
                              style: theme.bodyMedium.copyWith(
                                fontFamily: 'Readex Pro',
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: !_currentVisible,
                          style: theme.bodyMedium.copyWith(
                            fontFamily: 'Readex Pro',
                            letterSpacing: 0,
                          ),
                          decoration: _inputDecoration(
                            context,
                            hint: 'Current password',
                            suffixIcon: _visibilityToggle(
                              _currentVisible,
                              () => setState(
                                  () => _currentVisible = !_currentVisible),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: !_newVisible,
                          style: theme.bodyMedium.copyWith(
                            fontFamily: 'Readex Pro',
                            letterSpacing: 0,
                          ),
                          decoration: _inputDecoration(
                            context,
                            hint: 'New password',
                            suffixIcon: _visibilityToggle(
                              _newVisible,
                              () => setState(() => _newVisible = !_newVisible),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: !_confirmVisible,
                          style: theme.bodyMedium.copyWith(
                            fontFamily: 'Readex Pro',
                            letterSpacing: 0,
                          ),
                          decoration: _inputDecoration(
                            context,
                            hint: 'Confirm new password',
                            suffixIcon: _visibilityToggle(
                              _confirmVisible,
                              () => setState(
                                  () => _confirmVisible = !_confirmVisible),
                            ),
                          ),
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _changePassword(),
                        ),
                        const SizedBox(height: 16),
                        Opacity(
                          opacity: _changingPassword ? 0.7 : 1,
                          child: AbsorbPointer(
                            absorbing: _changingPassword,
                            child: SettingsPrimaryButton(
                              text: _changingPassword
                                  ? 'Updating...'
                                  : 'Change Password',
                              onPressed: _changePassword,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              FadeSlideIn(
                delay: const Duration(milliseconds: 240),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  child: Center(
                    child: Text(
                      'Joined KindMap on ${_formatDate(profile.user?.joinedDate)}',
                      style: theme.labelSmall.copyWith(
                        color: theme.secondaryText.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
