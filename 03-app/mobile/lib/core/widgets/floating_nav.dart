import 'package:flutter/material.dart';

import '../theme/tokens.g.dart';

class FloatingNav extends StatelessWidget {
  const FloatingNav({super.key, required this.index, required this.onTap})
    : assert(index >= 0 && index < 5);

  final int index;
  final ValueChanged<int> onTap;

  static const _tabs = [
    ('الرئيسية', Icons.home_outlined),
    ('التقارير', Icons.description_outlined),
    ('التقويم', Icons.calendar_month_outlined),
    ('المساعد', Icons.chat_bubble_outline),
    ('حسابي', Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        RSpace.s4,
        RSpace.s0,
        RSpace.s4,
        RSpace.s3,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.surfaceRaised,
          border: Border.all(color: c.border, width: RBorderWidth.thin),
          borderRadius: BorderRadius.circular(RRadius.full),
          boxShadow: RShadow.xl,
        ),
        child: Material(
          color: c.surfaceRaised,
          borderRadius: BorderRadius.circular(RRadius.full),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: RSpace.s2,
            ),
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: Semantics(
                      key: ValueKey('nav-$i'),
                      button: true,
                      enabled: true,
                      selected: i == index,
                      child: InkWell(
                        onTap: () => onTap(i),
                        borderRadius: BorderRadius.circular(RRadius.full),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: RSpace.s16,
                            minWidth: RSpace.s12,
                          ),
                          child: Padding(
                            padding: const EdgeInsetsDirectional.symmetric(
                              vertical: RSpace.s1,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: RSpace.s14,
                                  height: RSpace.s7,
                                  child: Center(
                                    child: Icon(
                                      _tabs[i].$2,
                                      size: RSpace.s6,
                                      color: i == index
                                          ? c.primary
                                          : c.textSecondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: RSpace.s0_5),
                                Text(
                                  _tabs[i].$1,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: RType.label.copyWith(
                                    fontSize: RSpace.s3,
                                    fontWeight: i == index
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: i == index
                                        ? c.primary
                                        : c.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
