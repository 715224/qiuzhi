import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/pixel_theme.dart';

class PixelPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final bool shadow;

  const PixelPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderColor,
    this.shadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.pixelPalette;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor ?? palette.ink, width: 2),
        borderRadius: BorderRadius.circular(3),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: palette.ink,
                  offset: const Offset(4, 4),
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: Material(
        color: color ?? palette.white,
        borderRadius: BorderRadius.circular(1),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class PixelPageTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;

  const PixelPageTitle({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.pixelPalette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 9,
          height: 36,
          margin: const EdgeInsets.only(top: 3, right: 12),
          color: palette.accent,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle.toUpperCase(),
                style: TextStyle(
                  color: palette.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class PixelTag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool filled;

  const PixelTag(this.label, {super.key, this.icon, this.filled = false});

  @override
  Widget build(BuildContext context) {
    final palette = context.pixelPalette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? palette.accent : palette.soft,
        border: Border.all(color: palette.ink, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: palette.ink),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class PixelSectionTitle extends StatelessWidget {
  final String text;
  final String? index;

  const PixelSectionTitle(this.text, {super.key, this.index});

  @override
  Widget build(BuildContext context) {
    final palette = context.pixelPalette;
    return Row(
      children: [
        if (index != null) ...[
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            color: palette.ink,
            child: Text(
              index!,
              style: TextStyle(
                color: palette.white,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: .5,
          ),
        ),
        const SizedBox(width: 8),
        const Expanded(child: Divider(thickness: 2)),
      ],
    );
  }
}

class PixelProgressBar extends StatelessWidget {
  final double value;
  final int segments;
  final double height;

  const PixelProgressBar({
    super.key,
    required this.value,
    this.segments = 6,
    this.height = 18,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.pixelPalette;
    final active = (value.clamp(0, 1) * segments).ceil();
    return Row(
      children: List.generate(segments, (index) {
        return Expanded(
          child: Container(
            height: height,
            margin: EdgeInsets.only(right: index == segments - 1 ? 0 : 3),
            decoration: BoxDecoration(
              color: index < active ? palette.accent : palette.white,
              border: Border.all(color: palette.ink, width: 1.5),
            ),
          ),
        );
      }),
    );
  }
}

class PixelEmptyState extends StatelessWidget {
  final String title;
  final String message;

  const PixelEmptyState({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.pixelPalette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ThemeMascot(size: 118, variant: 1),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.muted, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mascot used throughout the UI. The classic cyan theme keeps the original
/// pixel cat; the pink theme rotates through the supplied mascot series.
class ThemeMascot extends StatelessWidget {
  final double size;
  final int variant;

  const ThemeMascot({super.key, this.size = 150, this.variant = 2});

  @override
  Widget build(BuildContext context) {
    final pink = context.pixelPalette.accent == PixelPalette.pink.accent;
    if (!pink) return PixelCat(size: size);
    final safeVariant = variant.clamp(1, 2);
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.pixelPalette.white,
        border: Border.all(color: context.pixelPalette.line, width: 2),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: context.pixelPalette.accent.withValues(alpha: .35),
            offset: const Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Image.asset(
        'assets/pink_mascot/pink_mascot_pixel_0$safeVariant.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.none,
      ),
    );
  }
}

class PixelCat extends StatelessWidget {
  final double size;

  const PixelCat({super.key, this.size = 150});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: const _PixelCatPainter(),
    );
  }
}

class _PixelCatPainter extends CustomPainter {
  const _PixelCatPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final u = size.width / 18;
    final ink = Paint()
      ..color = PixelColors.ink
      ..isAntiAlias = false
      ..style = PaintingStyle.fill;
    final cyan = Paint()
      ..color = PixelColors.cyan
      ..isAntiAlias = false;
    final light = Paint()
      ..color = PixelColors.mint
      ..isAntiAlias = false;
    final white = Paint()
      ..color = PixelColors.white
      ..isAntiAlias = false;

    Rect r(num x, num y, num w, num h) =>
        Rect.fromLTWH(x * u, y * u, w * u, h * u);

    // Pixel shadow and tail.
    canvas.drawRect(r(5, 15, 10, 1), light);
    for (final cell in const [
      [4, 9],
      [3, 9],
      [2, 10],
      [2, 11],
      [2, 12],
      [3, 13],
      [4, 13]
    ]) {
      canvas.drawRect(r(cell[0], cell[1], 1, 1), ink);
    }
    canvas.drawRect(r(3, 10, 1, 3), cyan);

    // Body and head are built from hard-edged grid blocks.
    canvas.drawRect(r(6, 8, 7, 7), ink);
    canvas.drawRect(r(5, 10, 9, 4), ink);
    canvas.drawRect(r(6, 9, 7, 5), white);
    canvas.drawRect(r(5, 3, 9, 7), ink);
    canvas.drawRect(r(6, 2, 2, 2), ink);
    canvas.drawRect(r(12, 2, 2, 2), ink);
    canvas.drawRect(r(6, 4, 7, 5), white);
    canvas.drawRect(r(7, 3, 1, 2), white);
    canvas.drawRect(r(12, 3, 1, 2), white);
    canvas.drawRect(r(7, 3, 1, 1), cyan);
    canvas.drawRect(r(12, 3, 1, 1), cyan);

    // Cyan scarf.
    canvas.drawRect(r(5, 8, 9, 2), ink);
    canvas.drawRect(r(6, 8, 7, 1), cyan);
    canvas.drawRect(r(12, 9, 2, 1), cyan);
    canvas.drawRect(r(13, 10, 1, 3), cyan);
    canvas.drawRect(r(14, 12, 1, 2), ink);

    // Face.
    canvas.drawRect(r(7, 6, 1, 1), ink);
    canvas.drawRect(r(11, 6, 1, 1), ink);
    canvas.drawRect(r(9, 7, 1, 1), ink);
    canvas.drawRect(r(8, 8, 1, 1), ink);
    canvas.drawRect(r(10, 8, 1, 1), ink);

    // Paws and cyan sparkle.
    canvas.drawRect(r(6, 13, 2, 2), ink);
    canvas.drawRect(r(7, 13, 1, 1), white);
    canvas.drawRect(r(11, 13, 2, 2), ink);
    canvas.drawRect(r(11, 13, 1, 1), white);
    canvas.drawRect(r(15, 4, 1, 3), cyan);
    canvas.drawRect(r(14, 5, 3, 1), cyan);
    canvas.drawRect(r(15.35, 5.35, .3, .3), white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

double pixelClampTextScale(BuildContext context) {
  return math.min(MediaQuery.textScalerOf(context).scale(1), 1.25);
}
