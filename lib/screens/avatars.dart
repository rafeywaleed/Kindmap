import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:provider/provider.dart";

import "../config/app_theme.dart";
import "../config/route_observer.dart";
import "../controllers/user_controller.dart";
import "../providers/profile_provider.dart";
import "../widgets/settings_widgets.dart";

class Avatars extends StatefulWidget {
  final bool fromSignUp;

  const Avatars({super.key, this.fromSignUp = false});

  @override
  State<Avatars> createState() => _AvatarsState();
}

class _AvatarsState extends State<Avatars> with TickerProviderStateMixin {
  late int selectedAvatarIndex;
  late AnimationController _entranceCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;
  late List<AnimationController> _itemCtrlsAnim;
  late int initialAvatarIndex;

  @override
  void initState() {
    super.initState();

    // Get current avatar if not from sign-up
    final profile = context.read<ProfileProvider>();
    initialAvatarIndex =
        widget.fromSignUp ? -1 : (profile.user?.avatarIndex ?? 1) - 1;
    selectedAvatarIndex = initialAvatarIndex;

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _ringScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _ringOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );

    _itemCtrlsAnim = List.generate(8, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      );
    });

    _entranceCtrl.forward();

    Future.delayed(const Duration(milliseconds: 150), () {
      for (int i = 0; i < _itemCtrlsAnim.length; i++) {
        Future.delayed(Duration(milliseconds: i * 60), () {
          if (mounted) _itemCtrlsAnim[i].forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pulseCtrl.dispose();
    for (var ctrl in _itemCtrlsAnim) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _confirmAvatarChange() async {
    final theme = KMTheme.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.primaryText.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: theme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.primary.withOpacity(0.15),
                        ),
                      ),
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        color: theme.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Change Avatar?',
                      style: theme.headlineSmall.copyWith(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Update your profile with this new avatar',
                      textAlign: TextAlign.center,
                      style: theme.bodyMedium.copyWith(
                        color: theme.secondaryText,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: theme.primaryText.withOpacity(0.12),
                              ),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: theme.bodyMedium.copyWith(
                              fontFamily: 'Readex Pro',
                              fontWeight: FontWeight.w600,
                              color: theme.primaryText,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Confirm',
                            style: theme.bodyMedium.copyWith(
                              fontFamily: 'Readex Pro',
                              fontWeight: FontWeight.w600,
                              color: theme.primaryBtnText,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await _uploadAvatar();
    }
  }

  Future<void> _uploadAvatar() async {
    final theme = KMTheme.of(context);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: theme.primaryBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.primaryText.withOpacity(0.08)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(theme.primary),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Updating avatar...',
                  style: theme.bodyMedium.copyWith(
                    fontFamily: 'Readex Pro',
                    fontWeight: FontWeight.w500,
                    color: theme.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await context
            .read<ProfileProvider>()
            .updateAvatarIndex(selectedAvatarIndex + 1);
        await UserController()
            .changeUserAvatar(user.uid, selectedAvatarIndex + 1);

        if (mounted) {
          // Close loading dialog
          Navigator.of(context).pop();

          // Navigate based on flow
          // if (widget.fromSignUp) {
          // Coming from sign-up flow, go to home
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          );
          // } else {
          //   // Coming from settings, just pop back
          //   Navigator.of(context).pop();
          // }
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating avatar: $e'),
            backgroundColor: theme.error,
          ),
        );
      }
      debugPrint('Error uploading avatar index: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !widget.fromSignUp,
      onPopInvokedWithResult: (didPop, result) {
        if (!widget.fromSignUp && didPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: theme.secondaryBackground,
        appBar: !widget.fromSignUp
            ? settingsAppBar(context, 'Select Avatar')
            : null,
        body: SafeArea(
          child: FadeTransition(
            opacity:
                CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                widget.fromSignUp ? 32 : 16,
                20,
                40,
              ),
              children: [
                if (widget.fromSignUp)
                  Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: theme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.primary.withOpacity(0.15),
                          ),
                        ),
                        child: Icon(
                          Icons.sentiment_satisfied_alt_rounded,
                          color: theme.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Choose Your Avatar',
                        style: theme.headlineSmall.copyWith(
                          fontFamily: 'Outfit',
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pick an avatar that represents you best',
                        textAlign: TextAlign.center,
                        style: theme.bodyMedium.copyWith(
                          color: theme.secondaryText,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  )
                else
                  Column(
                    children: [
                      Text(
                        'Select a new avatar',
                        style: theme.bodyMedium.copyWith(
                          color: theme.secondaryText,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    final isSelected = selectedAvatarIndex == index;

                    return ScaleTransition(
                      scale: Tween<double>(begin: 0.85, end: 1.0).animate(
                        CurvedAnimation(
                          parent: _itemCtrlsAnim[index],
                          curve: Curves.easeOutBack,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => selectedAvatarIndex = index);
                          HapticFeedback.selectionClick();

                          // Only show confirm dialog if changing avatar
                          if (!widget.fromSignUp &&
                              index != initialAvatarIndex) {
                            _confirmAvatarChange();
                          }
                        },
                        child: Container(
                          // decoration: BoxDecoration(
                          //   borderRadius: BorderRadius.circular(20),
                          //   color: isSelected
                          //       ? theme.primary.withOpacity(0.08)
                          //       : theme.primaryBackground,
                          //   border: Border.all(
                          //     color: isSelected
                          //         ? theme.primaryText.withOpacity(0.08)
                          //         : theme.primaryText.withOpacity(0.05),
                          //     width: 1.2,
                          //   ),
                          // ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pulsing ring (only when selected)
                              if (isSelected)
                                AnimatedBuilder(
                                  animation: _pulseCtrl,
                                  builder: (_, __) => Transform.scale(
                                    scale: _ringScale.value,
                                    child: Opacity(
                                      opacity: _ringOpacity.value,
                                      child: Container(
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
                              // Avatar image
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Image.asset(
                                  'assets/images/avatar${index + 1}.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                              // Checkmark indicator
                              // if (isSelected)
                              //   Positioned(
                              //     top: 12,
                              //     right: 12,
                              //     child: Container(
                              //       width: 32,
                              //       height: 32,
                              //       decoration: BoxDecoration(
                              //         shape: BoxShape.circle,
                              //         color: theme.primary,
                              //         boxShadow: [
                              //           BoxShadow(
                              //             color: theme.primary.withOpacity(0.4),
                              //             blurRadius: 12,
                              //             offset: const Offset(0, 4),
                              //           ),
                              //         ],
                              //       ),
                              //       child: Icon(
                              //         Icons.check_rounded,
                              //         color: theme.primaryBtnText,
                              //         size: 18,
                              //       ),
                              //     ),
                              //   ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                if (widget.fromSignUp) ...[
                  const SizedBox(height: 32),
                  if (selectedAvatarIndex >= 0)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                          await _uploadAvatar();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                              color: theme.primaryBtnText,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Continue',
                              style: theme.titleSmall.copyWith(
                                fontFamily: 'Readex Pro',
                                color: theme.primaryBtnText,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryText.withOpacity(0.1),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'Select an avatar to continue',
                          style: theme.titleSmall.copyWith(
                            fontFamily: 'Readex Pro',
                            color: theme.primaryText.withOpacity(0.4),
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
