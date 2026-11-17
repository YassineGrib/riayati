import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'theme/tokens.g.dart';
import 'widgets/floating_nav.dart';

class Shell extends StatelessWidget {
  const Shell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: TextDirection.rtl,
    child: Scaffold(
      backgroundColor: context.c.bg,
      body: SafeArea(bottom: false, child: navigationShell),
      bottomNavigationBar: SafeArea(
        top: false,
        child: FloatingNav(
          index: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(index),
        ),
      ),
    ),
  );
}
