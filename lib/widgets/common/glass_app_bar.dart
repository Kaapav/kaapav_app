import 'dart:ui';

import 'package:flutter/material.dart';

import '../../config/theme.dart';

class KaapavGlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool isDark;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final EdgeInsetsGeometry padding;
  final double height;
  final Color? accentColor;

  const KaapavGlassAppBar({
    super.key,
    required this.title,
    required this.isDark,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.padding = const EdgeInsets.fromLTRB(16, 10, 16, 10),
    this.height = 74,
    this.accentColor,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? KaapavTheme.gold;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(26),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      Colors.black.withValues(alpha: 0.38),
                      accent.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.035),
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.72),
                      accent.withValues(alpha: 0.07),
                    ],
            ),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.62),
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.05),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.25,
                        color: isDark ? KaapavTheme.white : KaapavTheme.dark,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? KaapavTheme.grayLight
                              : KaapavTheme.gray,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ...actions,
            ],
          ),
        ),
      ),
    );
  }
}

class KaapavGlassIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;
  final Color? color;
  final int? badgeCount;

  const KaapavGlassIconButton({
    super.key,
    required this.icon,
    required this.isDark,
    this.onTap,
    this.color,
    this.badgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? KaapavTheme.goldLight;
    final showBadge = badgeCount != null && badgeCount! > 0;

    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [
                          Colors.white.withValues(alpha: 0.10),
                          fg.withValues(alpha: 0.10),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.78),
                          fg.withValues(alpha: 0.08),
                        ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.65),
                ),
                boxShadow: [
                  BoxShadow(
                    color: fg.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, size: 20, color: fg),
            ),
            if (showBadge)
              Positioned(
                right: -3,
                top: -3,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 17),
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: KaapavTheme.rose,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark ? KaapavTheme.bgDeep : KaapavTheme.white,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    badgeCount! > 99 ? '99+' : '${badgeCount!}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: KaapavTheme.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}