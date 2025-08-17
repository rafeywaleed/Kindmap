import 'package:flutter/material.dart';

class CustomIconButton extends StatelessWidget {
  final Color borderColor;
  final double borderRadius;
  final double borderWidth;
  final double buttonSize;
  final Color fillColor;
  final Icon icon;
  final VoidCallback onPressed;

  const CustomIconButton({
    Key? key,
    required this.borderColor,
    required this.borderRadius,
    required this.borderWidth,
    required this.buttonSize,
    required this.fillColor,
    required this.icon,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: buttonSize,
      height: buttonSize,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: IconButton(
        icon: icon,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final Widget? icon;
  final double width;
  final double height;
  final EdgeInsetsDirectional padding;
  final EdgeInsetsDirectional iconPadding;
  final Color color;
  final TextStyle textStyle;
  final BorderSide borderSide;

  const CustomButton({
    Key? key,
    required this.onPressed,
    required this.text,
    this.icon,
    required this.width,
    required this.height,
    required this.padding,
    required this.iconPadding,
    required this.color,
    required this.textStyle,
    required this.borderSide,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: borderSide,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null)
                Padding(
                  padding: iconPadding,
                  child: icon,
                ),
              Text(text, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}
