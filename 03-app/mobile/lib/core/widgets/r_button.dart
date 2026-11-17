import 'package:flutter/material.dart';

import '../theme/tokens.g.dart';

enum RButtonKind { primary, secondary, sos, text }

class RButton extends StatelessWidget {
  const RButton({
    super.key,
    required this.label,
    this.onPressed,
    this.kind = RButtonKind.primary,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final RButtonKind kind;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final foreground = switch (kind) {
      RButtonKind.primary => c.onPrimary,
      RButtonKind.secondary => c.textPrimary,
      RButtonKind.sos => c.sosTextOnBg,
      RButtonKind.text => c.textLink,
    };
    final background = switch (kind) {
      RButtonKind.primary => c.primary,
      RButtonKind.sos => c.sos,
      RButtonKind.secondary ||
      RButtonKind.text => c.surface.withValues(alpha: 0),
    };
    return Semantics(
      value: loading ? 'جارٍ التحميل' : null,
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: loading ? null : onPressed,
          style: TextButton.styleFrom(
            minimumSize: Size(
              RSpace.s12,
              kind == RButtonKind.text ? RSpace.s12 : RSpace.s14,
            ),
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: RSpace.componentButtonPaddingX,
              vertical: RSpace.componentButtonPaddingY,
            ),
            backgroundColor: background,
            foregroundColor: foreground,
            disabledBackgroundColor: c.surfaceDisabled,
            disabledForegroundColor: c.textDisabled,
            textStyle: kind == RButtonKind.text
                ? RType.label.copyWith(decoration: TextDecoration.underline)
                : RType.body.copyWith(fontWeight: FontWeight.w600),
            side: kind == RButtonKind.secondary && onPressed != null && !loading
                ? BorderSide(color: c.borderStrong, width: RBorderWidth.thin)
                : BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(RRadius.xl),
            ),
            animationDuration: RMotion.base,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (loading) ...[
                SizedBox.square(
                  dimension: RSpace.s5,
                  child: CircularProgressIndicator(
                    strokeWidth: RBorderWidth.medium,
                    color: c.textDisabled,
                  ),
                ),
                const SizedBox(width: RSpace.s2),
              ] else if (icon != null) ...[
                Icon(icon, size: RSpace.s6),
                const SizedBox(width: RSpace.s2),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          ),
        ),
      ),
    );
  }
}
