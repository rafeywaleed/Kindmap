import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/app_theme.dart';

// ═══════════════════════════════════════════════════════════════
// Shared building blocks for the "side" screens — Contact, About,
// Notifications, Help, Privacy Policy, Permissions, Profile.
// Mirrors the look & feel of the home app bar / drawer / pin pages.
// ═══════════════════════════════════════════════════════════════

/// Animated back button matching the drawer / app bar press style.
class SettingsBackButton extends StatefulWidget {
  const SettingsBackButton({super.key});

  @override
  State<SettingsBackButton> createState() => _SettingsBackButtonState();
}

class _SettingsBackButtonState extends State<SettingsBackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 250),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
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
    final theme = KMTheme.of(context);
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          HapticFeedback.lightImpact();
          Navigator.of(context).maybePop();
        },
        onTapCancel: () => _ctrl.reverse(),
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
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: theme.primaryText,
          ),
        ),
      ),
    );
  }
}

/// Consistent app bar for side screens — transparent over the page
/// background, with the same back-button styling as the home app bar.
PreferredSizeWidget settingsAppBar(BuildContext context, String title) {
  final theme = KMTheme.of(context);
  return AppBar(
    backgroundColor: theme.secondaryBackground,
    automaticallyImplyLeading: false,
    elevation: 0,
    scrolledUnderElevation: 0,
    leadingWidth: 64,
    leading: const Padding(
      padding: EdgeInsets.only(left: 12),
      child: SettingsBackButton(),
    ),
    title: Text(
      title,
      style: theme.headlineSmall.copyWith(
        fontFamily: 'Outfit',
        fontSize: 22,
        letterSpacing: 0,
      ),
    ),
    centerTitle: false,
  );
}

/// Subtle fade + slide-up entrance, used to stagger sections in.
class FadeSlideIn extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Big icon + title + subtitle header, used at the top of side screens.
class SettingsHeroHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const SettingsHeroHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: theme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.primary.withOpacity(0.15)),
            ),
            child: Icon(icon, color: theme.primary, size: 26),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.headlineSmall.copyWith(
              fontFamily: 'Outfit',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.bodyMedium.copyWith(
              color: theme.secondaryText,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small caps section label, e.g. "NOTIFICATION TYPES".
class SettingsSectionLabel extends StatelessWidget {
  final String text;

  const SettingsSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 20, 10),
      child: Text(
        text.toUpperCase(),
        style: theme.labelMedium.copyWith(
          fontFamily: 'Readex Pro',
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: theme.secondaryText.withOpacity(0.7),
          fontSize: 12,
        ),
      ),
    );
  }
}

/// Rounded container that groups a set of [SettingsTile] / [SettingsSwitchTile].
class SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  const SettingsCard({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: 20),
  });

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    return Container(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primaryText.withOpacity(0.06)),
      ),
      child: Column(children: children),
    );
  }
}

/// Thin divider that aligns with the text column of a [SettingsTile].
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 68),
      child: Container(
        height: 1,
        color: KMTheme.of(context).primaryText.withOpacity(0.06),
      ),
    );
  }
}

/// Tappable row with a leading icon chip, title/subtitle and trailing
/// chevron (or custom trailing widget). Has a light press-scale animation.
class SettingsTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showChevron;
  final Color? iconColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.showChevron = true,
    this.iconColor,
  });

  @override
  State<SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<SettingsTile> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    final iconColor = widget.iconColor ?? theme.primary;

    return GestureDetector(
      onTapDown: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: widget.onTap == null
          ? null
          : (_) => setState(() => _pressed = false),
      onTapCancel: widget.onTap == null
          ? null
          : () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          color: _pressed
              ? theme.primaryText.withOpacity(0.03)
              : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(widget.icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: theme.bodyMedium.copyWith(
                        fontFamily: 'Readex Pro',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: 0,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: theme.labelSmall.copyWith(
                          color: theme.secondaryText,
                          height: 1.3,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null)
                widget.trailing!
              else if (widget.showChevron && widget.onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.secondaryText.withOpacity(0.6),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row with a leading icon chip, title/subtitle and a trailing [Switch].
class SettingsSwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SettingsSwitchTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    final enabled = onChanged != null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1.0 : 0.45,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 18, color: theme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.bodyMedium.copyWith(
                      fontFamily: 'Readex Pro',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      letterSpacing: 0,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: theme.labelSmall.copyWith(
                        color: theme.secondaryText,
                        height: 1.3,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: theme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Expand / collapse card used for FAQ-style content, with an animated
/// chevron rotation and AnimatedSize body reveal.
class ExpandableInfoCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool initiallyExpanded;

  const ExpandableInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.initiallyExpanded = false,
  });

  @override
  State<ExpandableInfoCard> createState() => _ExpandableInfoCardState();
}

class _ExpandableInfoCardState extends State<ExpandableInfoCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _ctrl;
  late Animation<double> _rotate;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: _expanded ? 1 : 0,
    );
    _rotate = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    if (_expanded) {
      _ctrl.forward();
    } else {
      _ctrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryText.withOpacity(_expanded ? 0.1 : 0.06),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: _toggle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: theme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(widget.icon, size: 18, color: theme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.bodyMedium.copyWith(
                        fontFamily: 'Readex Pro',
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: _rotate,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(68, 0, 16, 16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        widget.body,
                        style: theme.bodyMedium.copyWith(
                          color: theme.secondaryText,
                          height: 1.5,
                          fontSize: 13.5,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }
}

/// Primary call-to-action button shared across side screens.
class SettingsPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? color;

  const SettingsPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = KMTheme.of(context);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? theme.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: theme.primaryBtnText),
              const SizedBox(width: 8),
            ],
            Text(
              text,
              style: theme.titleSmall.copyWith(
                fontFamily: 'Readex Pro',
                color: theme.primaryBtnText,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
