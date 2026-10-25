import 'package:flutter/material.dart';

class AsyncElevatedButton extends StatelessWidget {
  const AsyncElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.style,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: isLoading
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator.adaptive(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : child,
    );
  }
}
