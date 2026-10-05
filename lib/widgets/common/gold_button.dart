import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

enum GoldButtonVariant { filled, outlined, ghost }

class GoldButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final GoldButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final double? width;
  final double height;

  const GoldButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = GoldButtonVariant.filled,
    this.icon,
    this.loading = false,
    this.width,
    this.height = 50,
  });

  const GoldButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.width,
    this.height = 50,
  }) : variant = GoldButtonVariant.outlined;

  const GoldButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.width,
    this.height = 50,
  }) : variant = GoldButtonVariant.ghost;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == GoldButtonVariant.filled ? kBlack : kGold,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label, style: _textStyle),
            ],
          );

    final size = Size(width ?? double.infinity, height);

    return switch (variant) {
      GoldButtonVariant.filled => ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: size,
            fixedSize: width != null ? size : null,
          ),
          child: child,
        ),
      GoldButtonVariant.outlined => OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: size,
            fixedSize: width != null ? size : null,
          ),
          child: child,
        ),
      GoldButtonVariant.ghost => TextButton(
          onPressed: loading ? null : onPressed,
          style: TextButton.styleFrom(
            minimumSize: size,
            fixedSize: width != null ? size : null,
          ),
          child: child,
        ),
    };
  }

  TextStyle get _textStyle => switch (variant) {
    GoldButtonVariant.filled   => AppText.button,
    GoldButtonVariant.outlined => AppText.button.copyWith(color: kGold),
    GoldButtonVariant.ghost    => AppText.button.copyWith(color: kGold),
  };
}
