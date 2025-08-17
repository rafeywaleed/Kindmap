// Add this to your imports
import 'package:flutter/material.dart';
import 'package:kindmap/config/app_theme.dart';
import 'package:kindmap/screens/homescreen.dart';

class AnimatedPinButton extends StatefulWidget {
  final Future<void> Function() onPressed;
  final String text;
  final IconData icon;

  const AnimatedPinButton({
    super.key,
    required this.onPressed,
    required this.text,
    required this.icon,
  });

  @override
  State<AnimatedPinButton> createState() => _AnimatedPinButtonState();
}

class _AnimatedPinButtonState extends State<AnimatedPinButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _widthAnimation;

  bool _isLoading = false;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );

    _widthAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _isSuccess = false;
    });

    // Start collapse animation
    await _controller.forward();

    try {
      await widget.onPressed();

      // Show success state
      setState(() => _isSuccess = true);

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle,
                  color: KMTheme.of(context).primaryBtnText),
              const SizedBox(width: 8),
              Text('Pin created successfully!',
                  style: KMTheme.of(context).bodyMedium.copyWith(
                        color: KMTheme.of(context).primaryBtnText,
                      )),
            ],
          ),
          backgroundColor: KMTheme.of(context).success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Wait a bit before navigation to let user see success state
      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } catch (e) {
      // Show error state
      setState(() {
        _isLoading = false;
        _isSuccess = false;
      });

      // Reverse animation on error
      await _controller.reverse();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create pin: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'pin_button',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handlePress,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            height: 70,
            decoration: BoxDecoration(
              color: _isSuccess
                  ? KMTheme.of(context).success
                  : KMTheme.of(context).secondary,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Text and icon content
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Opacity(
                        opacity: _isLoading ? 0.0 : 1.0,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isSuccess ? Icons.check : widget.icon,
                              color: KMTheme.of(context).primaryText,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isSuccess ? 'Success!' : widget.text,
                              style: KMTheme.of(context).titleSmall.copyWith(
                                    fontFamily: 'Plus Jakarta Sans',
                                    color: KMTheme.of(context).primaryText,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                // Loading indicator
                if (_isLoading)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        KMTheme.of(context).primaryText,
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
}
