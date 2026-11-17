import 'package:flutter/material.dart';

import '../theme/tokens.g.dart';
import 'watermark.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    this.title,
    this.leading,
    required this.body,
    this.showWatermark = true,
    this.bottom,
  });

  final String? title;
  final Widget? leading;
  final Widget body;
  final bool showWatermark;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: context.c.bg,
        body: SafeArea(
          child: Stack(
            children: [
              if (showWatermark) const Positioned.fill(child: Watermark()),
              Column(
                children: [
                  if (title != null || leading != null)
                    SizedBox(
                      height: RSpace.s14,
                      child: Padding(
                        padding: const EdgeInsetsDirectional.symmetric(
                          horizontal: RSpace.s6,
                        ),
                        child: Row(
                          children: [
                            if (leading != null) ...[
                              leading!,
                              const SizedBox(width: RSpace.s2),
                            ],
                            if (title != null)
                              Expanded(
                                child: Text(
                                  title!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: RType.heading3.copyWith(
                                    fontFamily: RType.display.fontFamily,
                                    color: context.c.textPrimary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: RSpace.s6,
                      ),
                      child: body,
                    ),
                  ),
                  ?bottom,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
