import 'package:flutter/material.dart';
import '../utils/constants.dart';

class ActionButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isSecondary;
  final bool isOutline;

  const ActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isSecondary = false,
    this.isOutline = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutline) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: appOrange,
          side: const BorderSide(color: appOrange, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
        label: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
        onPressed: onPressed,
      );
    }

    final bgColor = isSecondary ? appYellow : appOrange;
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 0,
      ),
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(text,
          style:
              const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.3)),
      onPressed: onPressed,
    );
  }
}
