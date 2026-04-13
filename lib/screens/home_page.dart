import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:kindmap/widgets/location_dialog.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../providers/profile_provider.dart';
import '../services/permission_service.dart';
import '../providers/theme_provider.dart';
import '../widgets/map.dart';
import '../widgets/pin_someone.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  bool isGridSelectionMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  Future<void> _initializeApp() async {
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final hasNotification =
        await PermissionService.handleNotificationPermission();
    if (!hasNotification && mounted) {
      // Small delay so the map renders first — feels more intentional
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) showNotificationPermissionDialog(context);
    }
  }

  void _showPermissionDialog(String title, String message, String type) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (type == 'location') {
                await Geolocator.openLocationSettings();
              } else {
                await openAppSettings();
              }
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void toggleGridSelectionMode() {
    setState(() => isGridSelectionMode = !isGridSelectionMode);
  }

  void setGridSelectionMode(bool value) {
    setState(() => isGridSelectionMode = value);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final profile = context.watch<ProfileProvider>();

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: KMTheme.of(context).alternate,
        endDrawer: _KindMapDrawer(size: size, profile: profile),
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: _KindMapAppBar(profile: profile),
        ),
        // appBar: AppBar(
        //   scrolledUnderElevation: 0,
        //   backgroundColor: KMTheme.of(context).primaryBackground,
        //   iconTheme: IconThemeData(color: KMTheme.of(context).primaryText),
        //   automaticallyImplyLeading: true,
        //   leading: ClipRRect(
        //     borderRadius: BorderRadius.circular(8),
        //     child: Padding(
        //       padding: const EdgeInsets.all(8),
        //       child: Image.asset('assets/images/KindMap-logo-f.png',
        //           fit: BoxFit.cover),
        //     ),
        //   ),
        //   title: Align(
        //     alignment: const AlignmentDirectional(-1, 0),
        //     child: Text(
        //       'KindMap',
        //       style: KMTheme.of(context).titleMedium.copyWith(
        //             fontFamily: 'Plus Jakarta Sans',
        //             color: KMTheme.of(context).primaryText,
        //             fontSize: 24,
        //             letterSpacing: 0,
        //             fontWeight: FontWeight.w800,
        //           ),
        //     ),
        //   ),
        //   centerTitle: false,
        // ),
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              Maps(
                isGridSelectionMode: isGridSelectionMode,
                toggleGridSelectionMode: toggleGridSelectionMode,
                setGridSelectionMode: setGridSelectionMode,
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: KMTheme.of(context).primaryBackground,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: !isGridSelectionMode,
                child: pinSomeone(size, context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// DRAWER
// ═══════════════════════════════════════════════════════════════

class _KindMapDrawer extends StatefulWidget {
  final Size size;
  final ProfileProvider profile;
  const _KindMapDrawer({required this.size, required this.profile});

  @override
  State<_KindMapDrawer> createState() => _KindMapDrawerState();
}

class _KindMapDrawerState extends State<_KindMapDrawer>
    with TickerProviderStateMixin {
  // Master entrance controller
  late AnimationController _masterCtrl;

  // Background parallax / pulse
  late AnimationController _bgPulseCtrl;

  // Individual item controllers for hover
  final List<_NavItem> _navItems = [
    _NavItem(Icons.settings_outlined, 'Settings', '/settings'),
    _NavItem(Icons.mail_outline_rounded, 'Contact', '/contact'),
    _NavItem(Icons.info_outline_rounded, 'About', '/about'),
  ];

  // Entrance animations
  late Animation<double> _drawerFade;
  late Animation<Offset> _profileSlide;
  late Animation<double> _profileFade;
  late Animation<double> _dividerScaleAnim;
  late List<Animation<double>> _itemFades;
  late List<Animation<Offset>> _itemSlides;
  late Animation<double> _footerFade;
  late Animation<Offset> _footerSlide;

  @override
  void initState() {
    super.initState();

    _masterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _bgPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _drawerFade = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );

    _profileSlide = Tween<Offset>(
      begin: const Offset(0, -0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.05, 0.45, curve: Curves.easeOutCubic),
    ));

    _profileFade = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.05, 0.45, curve: Curves.easeOut),
    );

    _dividerScaleAnim = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.3, 0.55, curve: Curves.easeOut),
    );

    _itemFades = List.generate(_navItems.length, (i) {
      final s = 0.35 + i * 0.12;
      return CurvedAnimation(
        parent: _masterCtrl,
        curve: Interval(s, (s + 0.3).clamp(0, 1), curve: Curves.easeOut),
      );
    });

    _itemSlides = List.generate(_navItems.length, (i) {
      final s = 0.35 + i * 0.12;
      return Tween<Offset>(
        begin: const Offset(0.25, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _masterCtrl,
        curve: Interval(s, (s + 0.3).clamp(0, 1), curve: Curves.easeOutCubic),
      ));
    });

    _footerFade = CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.72, 1.0, curve: Curves.easeOut),
    );

    _footerSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _masterCtrl,
      curve: const Interval(0.72, 1.0, curve: Curves.easeOutCubic),
    ));

    _masterCtrl.forward();
  }

  @override
  void dispose() {
    _masterCtrl.dispose();
    _bgPulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = widget.size;

    return Drawer(
      width: size.width * 0.75,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(32)),
      ),
      elevation: 0,
      child: FadeTransition(
        opacity: _drawerFade,
        child: ClipRRect(
          borderRadius:
              const BorderRadius.horizontal(left: Radius.circular(32)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: theme.primaryBackground,
            ),
            child: Stack(
              children: [
                // ── Animated background logo ─────────────────────────
                _AnimatedBackground(
                  bgPulseCtrl: _bgPulseCtrl,
                  isDark: isDark,
                  theme: theme,
                  size: size,
                ),

                // ── Left accent bar ──────────────────────────────────
                _AccentBar(theme: theme, masterCtrl: _masterCtrl),

                // ── Content ──────────────────────────────────────────
                SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile
                      SlideTransition(
                        position: _profileSlide,
                        child: FadeTransition(
                          opacity: _profileFade,
                          child: _ProfileHeader(
                            size: size,
                            profile: widget.profile,
                            theme: theme,
                          ),
                        ),
                      ),

                      // Animated divider
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: AnimatedBuilder(
                          animation: _dividerScaleAnim,
                          builder: (_, __) => Transform.scale(
                            scaleX: _dividerScaleAnim.value,
                            alignment: Alignment.centerLeft,
                            child: Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.primary.withOpacity(0.5),
                                    theme.primaryText.withOpacity(0.06),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Nav items
                      ...List.generate(_navItems.length, (i) {
                        return FadeTransition(
                          opacity: _itemFades[i],
                          child: SlideTransition(
                            position: _itemSlides[i],
                            child: _NavTile(
                              item: _navItems[i],
                              theme: theme,
                              index: i,
                            ),
                          ),
                        );
                      }),

                      const Spacer(),

                      // Footer divider
                      FadeTransition(
                        opacity: _footerFade,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: AnimatedBuilder(
                            animation: _dividerScaleAnim,
                            builder: (_, __) => Container(
                              height: 1,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    theme.primaryText.withOpacity(0.06),
                                    theme.primary.withOpacity(0.3),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Theme switcher
                      SlideTransition(
                        position: _footerSlide,
                        child: FadeTransition(
                          opacity: _footerFade,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            child: _ThemeSwitcher(theme: theme, isDark: isDark),
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
      ),
    );
  }
}
// ═══════════════════════════════════════════════════════════════
// APP BAR
// ═══════════════════════════════════════════════════════════════

class _KindMapAppBar extends StatefulWidget implements PreferredSizeWidget {
  final ProfileProvider profile;
  const _KindMapAppBar({required this.profile});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  State<_KindMapAppBar> createState() => _KindMapAppBarState();
}

class _KindMapAppBarState extends State<_KindMapAppBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _entranceCtrl;
  late Animation<double> _logoFade;
  late Animation<Offset> _logoSlide;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _menuFade;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _logoFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _logoSlide = Tween<Offset>(
      begin: const Offset(-0.4, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
    ));
    _titleFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.15, 0.65, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(-0.2, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.15, 0.65, curve: Curves.easeOutCubic),
    ));
    _menuFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: const Interval(0.4, 0.9, curve: Curves.easeOut),
    );

    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.primaryBackground,
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Logo
                SlideTransition(
                  position: _logoSlide,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: Image.asset(
                          'assets/images/KindMap-logo-f.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                // Title
                SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleFade,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'KindMap',
                          style: theme.titleMedium.copyWith(
                            fontFamily: 'Plus Jakarta Sans',
                            color: theme.primaryText,
                            fontSize: 22,
                            letterSpacing: -0.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Help is near',
                          style: theme.bodySmall.copyWith(
                            color: theme.secondaryText.withOpacity(0.6),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Menu button (opens endDrawer)
                FadeTransition(
                  opacity: _menuFade,
                  child: _AppBarMenuButton(theme: theme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AppBarMenuButton extends StatefulWidget {
  final KMTheme theme;
  const _AppBarMenuButton({required this.theme});

  @override
  State<_AppBarMenuButton> createState() => _AppBarMenuButtonState();
}

class _AppBarMenuButtonState extends State<_AppBarMenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 250),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _pressCtrl.forward(),
        onTapUp: (_) {
          _pressCtrl.reverse();
          HapticFeedback.lightImpact();
          Scaffold.of(context).openEndDrawer();
        },
        onTapCancel: () => _pressCtrl.reverse(),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: theme.primaryText.withOpacity(0.06),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: theme.primaryText.withOpacity(0.07),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _MenuLine(width: 16, theme: theme),
              const SizedBox(height: 4),
              _MenuLine(width: 11, theme: theme),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuLine extends StatelessWidget {
  final double width;
  final KMTheme theme;
  const _MenuLine({required this.width, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 2,
      decoration: BoxDecoration(
        color: theme.primaryText.withOpacity(0.65),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
// ═══════════════════════════════════════════════════════════════
// ANIMATED BACKGROUND
// ═══════════════════════════════════════════════════════════════

class _AnimatedBackground extends StatelessWidget {
  final AnimationController bgPulseCtrl;
  final bool isDark;
  final KMTheme theme;
  final Size size;

  const _AnimatedBackground({
    required this.bgPulseCtrl,
    required this.isDark,
    required this.theme,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bgPulseCtrl,
      builder: (_, __) {
        final t = bgPulseCtrl.value;
        final scale = 1.0 + t * 0.04;
        final opacity = isDark
            ? 0.18 + t * 0.10 // dark: 0.18 → 0.28, clearly visible
            : 0.07 + t * 0.04; // light: subtle

        return Positioned.fill(
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Image.asset(
                'assets/images/img_menubar.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ACCENT BAR
// ═══════════════════════════════════════════════════════════════

class _AccentBar extends StatelessWidget {
  final KMTheme theme;
  final AnimationController masterCtrl;

  const _AccentBar({required this.theme, required this.masterCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: masterCtrl,
      builder: (_, __) {
        return Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(32)),
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.primary.withOpacity(0.9),
                    theme.primary.withOpacity(0.3),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PROFILE HEADER
// ═══════════════════════════════════════════════════════════════

class _ProfileHeader extends StatefulWidget {
  final Size size;
  final ProfileProvider profile;
  final KMTheme theme;

  const _ProfileHeader({
    required this.size,
    required this.profile,
    required this.theme,
  });

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _tapCtrl;
  late Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    _tapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _tapScale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _tapCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _tapCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final size = widget.size;
    final profile = widget.profile;

    return GestureDetector(
      onTapDown: (_) => _tapCtrl.forward(),
      onTapUp: (_) {
        _tapCtrl.reverse();
        Future.delayed(
          const Duration(milliseconds: 120),
          () => Navigator.of(context).pushNamed('/profile'),
        );
      },
      onTapCancel: () => _tapCtrl.reverse(),
      child: ScaleTransition(
        scale: _tapScale,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar with animated ring
              _PulsingAvatar(
                size: size,
                profile: profile,
                theme: theme,
              ),

              const SizedBox(height: 16),

              // Name
              Text(
                profile.user?.name ?? 'User Name',
                style: theme.bodyMedium.copyWith(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: theme.primaryText,
                ),
              ),

              const SizedBox(height: 5),

              // View profile row
              Row(
                children: [
                  Text(
                    'View profile',
                    style: theme.bodySmall.copyWith(
                      color: theme.primary.withOpacity(0.85),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: theme.primary.withOpacity(0.85),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PULSING AVATAR
// ═══════════════════════════════════════════════════════════════

class _PulsingAvatar extends StatefulWidget {
  final Size size;
  final ProfileProvider profile;
  final KMTheme theme;

  const _PulsingAvatar({
    required this.size,
    required this.profile,
    required this.theme,
  });

  @override
  State<_PulsingAvatar> createState() => _PulsingAvatarState();
}

class _PulsingAvatarState extends State<_PulsingAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _ringScale = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
    _ringOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarSize = widget.size.width * 0.17;
    final theme = widget.theme;

    return SizedBox(
      width: avatarSize + 20,
      height: avatarSize + 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse ring
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

          // Avatar
          Hero(
            tag: 'profile-avatar',
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.primary.withOpacity(0.7),
                  width: 2.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primary.withOpacity(0.25),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/avatar${widget.profile.avatarIndex ?? 1}.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// NAV ITEM MODEL
// ═══════════════════════════════════════════════════════════════

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem(this.icon, this.label, this.route);
}

// ═══════════════════════════════════════════════════════════════
// NAV TILE
// ═══════════════════════════════════════════════════════════════

class _NavTile extends StatefulWidget {
  final _NavItem item;
  final KMTheme theme;
  final int index;

  const _NavTile({
    required this.item,
    required this.theme,
    required this.index,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverCtrl;
  late Animation<double> _hoverAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _hoverAnim = CurvedAnimation(parent: _hoverCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: MouseRegion(
        onEnter: (_) => _hoverCtrl.forward(),
        onExit: (_) => _hoverCtrl.reverse(),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            Navigator.of(context).pushNamed(widget.item.route);
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedBuilder(
            animation: _hoverAnim,
            builder: (_, __) {
              return AnimatedScale(
                scale: _pressed ? 0.97 : 1.0,
                duration: const Duration(milliseconds: 120),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: _hoverAnim.value > 0
                        ? theme.primary.withOpacity(0.07 * _hoverAnim.value)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.primary.withOpacity(0.15 * _hoverAnim.value),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Animated icon box
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _hoverAnim.value > 0
                              ? theme.primary
                                  .withOpacity(0.14 * _hoverAnim.value + 0.06)
                              : theme.primaryText.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AnimatedRotation(
                          turns: _hoverAnim.value * 0.028,
                          duration: const Duration(milliseconds: 220),
                          child: Icon(
                            widget.item.icon,
                            size: 19,
                            color: Color.lerp(
                              theme.primaryText.withOpacity(0.55),
                              theme.primary,
                              _hoverAnim.value,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Label
                      Expanded(
                        child: Text(
                          widget.item.label,
                          style: theme.titleLarge.copyWith(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                            color: Color.lerp(
                              theme.primaryText.withOpacity(0.8),
                              theme.primaryText,
                              _hoverAnim.value,
                            ),
                          ),
                        ),
                      ),

                      // Animated chevron
                      AnimatedSlide(
                        offset: Offset(
                            _hoverAnim.value * 0.0 -
                                (1 - _hoverAnim.value) * 0.3,
                            0),
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        child: AnimatedOpacity(
                          opacity: _hoverAnim.value,
                          duration: const Duration(milliseconds: 220),
                          child: Icon(
                            Icons.chevron_right_rounded,
                            size: 18,
                            color: theme.primary.withOpacity(0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// THEME SWITCHER  ✦ the hero piece
// ═══════════════════════════════════════════════════════════════

class _ThemeSwitcher extends StatefulWidget {
  final KMTheme theme;
  final bool isDark;

  const _ThemeSwitcher({required this.theme, required this.isDark});

  @override
  State<_ThemeSwitcher> createState() => _ThemeSwitcherState();
}

class _ThemeSwitcherState extends State<_ThemeSwitcher>
    with TickerProviderStateMixin {
  // Orbit rotation for the sun rays / moon
  late AnimationController _orbitCtrl;
  // Press ripple
  late AnimationController _rippleCtrl;
  late Animation<double> _rippleScale;
  late Animation<double> _rippleOpacity;
  // Icon swap
  late AnimationController _iconSwapCtrl;
  late Animation<double> _iconScale;
  late Animation<double> _iconRotate;

  bool _pressing = false;

  @override
  void initState() {
    super.initState();

    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _rippleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rippleScale = Tween<double>(begin: 0.5, end: 2.2).animate(
      CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut),
    );
    _rippleOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _rippleCtrl, curve: Curves.easeOut),
    );

    _iconSwapCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _iconScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _iconSwapCtrl, curve: Curves.easeInOut));
    _iconRotate = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _iconSwapCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(_ThemeSwitcher old) {
    super.didUpdateWidget(old);
    if (old.isDark != widget.isDark) {
      _iconSwapCtrl.forward(from: 0);
      _rippleCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _rippleCtrl.dispose();
    _iconSwapCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = widget.isDark;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressing = true),
      onTapUp: (_) {
        setState(() => _pressing = false);
        _toggle();
      },
      onTapCancel: () => setState(() => _pressing = false),
      child: AnimatedScale(
        scale: _pressing ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1D2428) : const Color(0xFFF8F4F4),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? theme.primary.withOpacity(0.25)
                  : theme.primaryText.withOpacity(0.1),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? theme.primary.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Orbital icon sphere ──────────────────────────────
              SizedBox(
                width: 52,
                height: 52,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ripple on toggle
                    AnimatedBuilder(
                      animation: _rippleCtrl,
                      builder: (_, __) => Transform.scale(
                        scale: _rippleScale.value,
                        child: Opacity(
                          opacity: _rippleOpacity.value,
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.primary.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Orbiting dots (sun rays style)
                    AnimatedBuilder(
                      animation: _orbitCtrl,
                      builder: (_, __) {
                        return Stack(
                          alignment: Alignment.center,
                          children: List.generate(6, (i) {
                            final angle = (i / 6) * 2 * math.pi +
                                _orbitCtrl.value * 2 * math.pi;
                            final dx = math.cos(angle) * 22;
                            final dy = math.sin(angle) * 22;
                            return Transform.translate(
                              offset: Offset(dx, dy),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                width: isDark ? 3.5 : 2.5,
                                height: isDark ? 3.5 : 2.5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark
                                      ? theme.primary.withOpacity(0.4)
                                      : theme.primaryText.withOpacity(0.2),
                                ),
                              ),
                            );
                          }),
                        );
                      },
                    ),

                    // Center icon sphere
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? theme.primary.withOpacity(0.18)
                            : theme.primaryText.withOpacity(0.08),
                        border: Border.all(
                          color: isDark
                              ? theme.primary.withOpacity(0.4)
                              : theme.primaryText.withOpacity(0.12),
                          width: 1.5,
                        ),
                      ),
                      child: AnimatedBuilder(
                        animation: _iconSwapCtrl,
                        builder: (_, __) {
                          return Transform.rotate(
                            angle: _iconRotate.value * 2 * math.pi,
                            child: Transform.scale(
                              scale: _iconSwapCtrl.isAnimating
                                  ? _iconScale.value
                                  : 1.0,
                              child: Icon(
                                isDark
                                    ? Icons.wb_sunny_rounded
                                    : Icons.nights_stay_rounded,
                                size: 20,
                                color: isDark
                                    ? theme.primary
                                    : theme.primaryText.withOpacity(0.7),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 14),

              // ── Labels ──────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.4),
                            end: Offset.zero,
                          ).animate(anim),
                          child: child,
                        ),
                      ),
                      child: Text(
                        isDark ? 'Light Mode' : 'Dark Mode',
                        key: ValueKey(isDark),
                        style: theme.bodyMedium.copyWith(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: theme.primaryText,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: Text(
                        isDark ? 'Switch to light' : 'Switch to dark',
                        key: ValueKey('sub_$isDark'),
                        style: theme.bodySmall.copyWith(
                          fontSize: 11,
                          color: theme.primaryText.withOpacity(0.4),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Pill toggle ─────────────────────────────────────
              _AnimatedPill(isDark: isDark, theme: theme),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ANIMATED PILL
// ═══════════════════════════════════════════════════════════════

class _AnimatedPill extends StatefulWidget {
  final bool isDark;
  final KMTheme theme;

  const _AnimatedPill({required this.isDark, required this.theme});

  @override
  State<_AnimatedPill> createState() => _AnimatedPillState();
}

class _AnimatedPillState extends State<_AnimatedPill>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  late Animation<double> _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _shimmer = CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final isDark = widget.isDark;

    return AnimatedBuilder(
      animation: _shimmer,
      builder: (_, __) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          width: 50,
          height: 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isDark
                ? theme.primary.withOpacity(0.85 + _shimmer.value * 0.1)
                : theme.primaryText.withOpacity(0.12),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: theme.primary
                          .withOpacity(0.3 + _shimmer.value * 0.15),
                      blurRadius: 8 + _shimmer.value * 4,
                      spreadRadius: 0,
                    )
                  ]
                : [],
          ),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 380),
              curve: Curves.easeInOutBack,
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 380),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white
                      : theme.primaryText.withOpacity(0.45),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
