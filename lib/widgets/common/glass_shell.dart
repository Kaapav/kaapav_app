import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../config/theme.dart';
import 'glass_card.dart';

class KaapavGlassShell extends StatefulWidget {
  final Widget child;
  final bool isDark;
  final bool useSafeArea;
  final EdgeInsetsGeometry padding;

  const KaapavGlassShell({
    super.key,
    required this.child,
    required this.isDark,
    this.useSafeArea = true,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<KaapavGlassShell> createState() => _KaapavGlassShellState();
}

class _KaapavGlassShellState extends State<KaapavGlassShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 9),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: widget.padding,
      child: widget.child,
    );

    final body = widget.useSafeArea ? SafeArea(child: content) : content;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final wave = math.sin(t * math.pi * 2);

        return Container(
          decoration: BoxDecoration(
            gradient: widget.isDark
                ? KaapavTheme.darkBgGradient
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFFFFBF2),
                      Color(0xFFF7F3EA),
                      Color(0xFFF1E7D5),
                    ],
                  ),
          ),
          child: Stack(
            children: [
              KaapavGlassOrb(
                alignment: Alignment.topRight,
                color: KaapavTheme.gold,
                size: 260,
                opacity: widget.isDark ? 0.18 : 0.14,
                offset: Offset(24 + wave * 12, -46 + wave * 8),
              ),
              KaapavGlassOrb(
                alignment: Alignment.bottomLeft,
                color: KaapavTheme.amethyst,
                size: 230,
                opacity: widget.isDark ? 0.12 : 0.08,
                offset: Offset(-42 + wave * 10, 34 - wave * 8),
              ),
              KaapavGlassOrb(
                alignment: Alignment.centerRight,
                color: KaapavTheme.teal,
                size: 190,
                opacity: widget.isDark ? 0.10 : 0.06,
                offset: Offset(78 - wave * 14, 14 + wave * 10),
              ),
              KaapavGlassOrb(
                alignment: Alignment.bottomRight,
                color: KaapavTheme.rose,
                size: 170,
                opacity: widget.isDark ? 0.08 : 0.05,
                offset: Offset(44 + wave * 8, 84 - wave * 10),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(
                          -0.18 + wave * 0.10,
                          -0.62 + wave * 0.05,
                        ),
                        radius: 1.35,
                        colors: [
                          Colors.white.withValues(
                            alpha: widget.isDark ? 0.035 : 0.12,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              body,
            ],
          ),
        );
      },
    );
  }
}