import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/text_styles.dart';

/// AppBar standard ImmoRoyal
/// Logo IMMO (blanc) + ROYAL (or) à gauche
class ImmoRoyalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget>? actions;
  final bool showBack;
  final String? title; // surcharge le logo si fourni

  const ImmoRoyalAppBar({
    super.key,
    this.actions,
    this.showBack = false,
    this.title,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: kNavBar,
      elevation: 0,
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: kWhite, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            )
          : null,
      title: title != null
          ? Text(title!, style: AppText.logoImmo)
          : _Logo(),
      centerTitle: false,
      actions: actions,
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/IMMOROYAL_4_1.png',
      height: 32,
      fit: BoxFit.contain,
    );
  }
}

/// SliverAppBar pour la Home (disparaît au scroll)
class ImmoRoyalSliverAppBar extends StatelessWidget {
  final List<Widget>? actions;
  const ImmoRoyalSliverAppBar({super.key, this.actions});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: kNavBar,
      pinned: true,
      floating: false,
      elevation: 0,
      title: _Logo(),
      centerTitle: false,
      actions: actions,
    );
  }
}
