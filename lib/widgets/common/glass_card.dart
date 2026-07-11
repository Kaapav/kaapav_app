import 'dart:ui';

import 'package:flutter/material.dart';

import '../../config/theme.dart';

class KaapavGlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? borderColor;
  final Color? accentColor;
  final double blur;
  final double opacity;
  final bool glow;
  final double? width;
  final double? height;

  const KaapavGlassCard({
    super.key,
    required this.child,
    required this.isDark,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.radius = 20,
    this.onTap,
    this.gradient,
    this.borderColor,
    this.accentColor,
    this.blur = 20,
    this.opacity = 1,
    this.glow = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? KaapavTheme.gold;

    final fallbackGradient = isDark
        ? LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.090 * opacity),
              accent.withValues(alpha: 0.055 * opacity),
              Colors.black.withValues(alpha: 0.120 * opacity),
            ],
          )
        : LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.78 * opacity),
              accent.withValues(alpha: 0.07 * opacity),
            ],
          );

    final border = borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.115)
            : Colors.white.withValues(alpha: 0.62));

    final decoration = BoxDecoration(
      gradient: gradient ?? fallbackGradient,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.32 : 0.08),
          blurRadius: 28,
          spreadRadius: -8,
          offset: const Offset(0, 16),
        ),
        if (glow)
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.26 : 0.14),
            blurRadius: 34,
            spreadRadius: -6,
            offset: const Offset(0, 16),
          ),
      ],
    );

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            splashColor: accent.withValues(alpha: 0.08),
            highlightColor: accent.withValues(alpha: 0.04),
            child: Container(
              width: width,
              height: height,
              padding: padding,
              decoration: decoration,
              child: child,
            ),
          ),
        ),
      ),
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }

    return card;
  }
}

class KaapavGlassOrb extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final double size;
  final double opacity;
  final Offset offset;

  const KaapavGlassOrb({
    super.key,
    required this.alignment,
    required this.color,
    required this.size,
    this.opacity = 0.13,
    this.offset = Offset.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Transform.translate(
          offset: offset,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: opacity),
                  color.withValues(alpha: opacity * 0.44),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: opacity * 1.35),
                  blurRadius: size * 0.34,
                  spreadRadius: size * 0.09,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class KaapavStatusPill extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final bool isDark;

  const KaapavStatusPill({
    super.key,
    required this.text,
    required this.color,
    required this.isDark,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.16 : 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.34 : 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}