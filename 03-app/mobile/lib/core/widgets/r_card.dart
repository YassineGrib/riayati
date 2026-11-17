import 'package:flutter/material.dart';

import '../theme/tokens.g.dart';

class RCard extends StatelessWidget {
  const RCard({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(RRadius.x2xl),
        side: BorderSide(color: context.c.border, width: RBorderWidth.thin),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: RSpace.s12,
            minWidth: RSpace.s12,
          ),
          child: Padding(
            padding: const EdgeInsetsDirectional.all(RSpace.cardPaddingSm),
            child: child,
          ),
        ),
      ),
    );
  }
}
