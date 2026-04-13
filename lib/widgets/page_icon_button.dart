import 'package:flutter/material.dart';
import 'package:kindmap/config/app_theme.dart';

class PageIconButton extends StatefulWidget {
  final IconData icon;
  final KMTheme theme;
  final VoidCallback onTap;

  const PageIconButton({
    required this.icon,
    required this.theme,
    required this.onTap,
  });

  @override
  State<PageIconButton> createState() => _PageIconButtonState();
}

class _PageIconButtonState extends State<PageIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.87).animate(
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
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: widget.theme.primaryText.withOpacity(0.06),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: widget.theme.primaryText.withOpacity(0.08),
              width: 1,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 17,
            color: widget.theme.primaryText.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}
