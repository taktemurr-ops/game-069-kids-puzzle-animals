import 'package:flutter/material.dart';

import '../app/game_api.dart';
import 'kids_geom.dart';

/// Shared widgets for the Kids & Family games: big, round, friendly.
bool isTr(PlayContext ctx) => ctx.lang == 'tr';

String tx(PlayContext ctx, String en, String tr) => isTr(ctx) ? tr : en;

Color hexColor(String hex) => Color(int.parse('FF$hex', radix: 16));

const _cheersEn = ['Great job!', 'Super!', 'Well done!', 'Awesome!', 'You did it!', 'Bravo!'];
const _cheersTr = ['Aferin!', 'Süpersin!', 'Harika!', 'Çok iyi!', 'Başardın!', 'Bravo!'];
const _tryEn = ['Try again!', 'Almost!', 'Look again!'];
const _tryTr = ['Tekrar dene!', 'Az kaldı!', 'Bir daha bak!'];

String cheer(PlayContext ctx, int n) => (isTr(ctx) ? _cheersTr : _cheersEn)[n % 6];
String tryAgain(PlayContext ctx, int n) => (isTr(ctx) ? _tryTr : _tryEn)[n % 3];

/// Soft bubbly background (also the play screen's CustomPaint).
class KidsBackdrop extends StatelessWidget {
  final Widget child;
  final List<Color> colors;
  const KidsBackdrop({super.key, required this.child, required this.colors});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _Bubbles(colors.isEmpty ? [Colors.orange, Colors.lightBlue] : colors), child: child);
}

class _Bubbles extends CustomPainter {
  final List<Color> colors;
  _Bubbles(this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (var i = 0; i < 16; i++) {
      p.color = colors[i % colors.length].withValues(alpha: 0.09);
      final x = (i * 73 % 100) / 100 * size.width;
      final y = (i * 41 % 100) / 100 * size.height;
      canvas.drawCircle(Offset(x, y), 18.0 + (i * 17 % 46), p);
    }
  }

  @override
  bool shouldRepaint(covariant _Bubbles old) => false;
}

Path polyPath(List<double> p, Size s) {
  final path = Path();
  for (var i = 0; i < p.length; i += 2) {
    final o = Offset(p[i] * s.width, p[i + 1] * s.height);
    i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
  }
  return path..close();
}

class ShapePainter extends CustomPainter {
  final String shape;
  final Color color;
  ShapePainter(this.shape, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = polyPath(shapePoly(shape), size);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.black54,
    );
  }

  @override
  bool shouldRepaint(covariant ShapePainter old) => old.shape != shape || old.color != color;
}

/// Renders one content token (see kids_quiz_engine.dart).
class KidTok extends StatelessWidget {
  final String token;
  final double size;
  final bool tr;
  const KidTok(this.token, {super.key, this.size = 64, required this.tr});

  String _txt(String s) {
    final p = s.split('|');
    return tr && p.length > 1 ? p[1] : p[0];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final i = token.indexOf(':');
    final kind = i < 0 ? 't' : token.substring(0, i);
    final v = i < 0 ? token : token.substring(i + 1);
    switch (kind) {
      case 'e':
        return Text(
          v,
          style: TextStyle(fontSize: size * .8),
          semanticsLabel: v,
        );
      case 'm':
        final j = v.indexOf(':');
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(v.substring(0, j), style: TextStyle(fontSize: size * .6)),
            Text(
              _txt(v.substring(j + 1)),
              style: TextStyle(fontSize: size * .2, fontWeight: FontWeight.w700),
            ),
          ],
        );
      case 'c':
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: hexColor(v),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black26, width: 3),
          ),
        );
      case 's':
        final p = v.split(':');
        return SizedBox(
          width: size,
          height: size,
          child: Semantics(
            label: p[0],
            child: CustomPaint(painter: ShapePainter(p[0], hexColor(p.length > 1 ? p[1] : 'FFFFFF'))),
          ),
        );
      case 'n':
      case 'l':
        return Text(
          v,
          style: TextStyle(fontSize: size * .7, fontWeight: FontWeight.w900, color: cs.primary),
        );
      case 'd':
        final p = v.split(':');
        final n = int.parse(p[0]);
        final per = n <= 3 ? n : (n <= 6 ? 3 : (n <= 8 ? 4 : 5));
        final s = n <= 3 ? size * .42 : size * .3;
        return SizedBox(
          width: per * s * 1.15,
          child: Wrap(
            alignment: WrapAlignment.center,
            children: [for (var k = 0; k < n; k++) Text(p[1], style: TextStyle(fontSize: s * .85))],
          ),
        );
      case 'x':
        return ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.black87, BlendMode.srcIn),
          child: Text(v, style: TextStyle(fontSize: size * .8)),
        );
      case 'z':
        final p = v.split(':');
        final sc = double.tryParse(p[1]) ?? 1;
        return SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(p[0], style: TextStyle(fontSize: size * .8 * sc)),
          ),
        );
      default:
        return Text(
          _txt(v),
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: (size * .32).clamp(14, 30), fontWeight: FontWeight.w800, color: cs.onSurface),
        );
    }
  }
}

/// Big rounded answer card with a bounce when wrong.
class KidCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final bool faded;
  final String label;
  const KidCard({super.key, required this.child, this.onTap, this.color, this.faded = false, this.label = ''});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: faded ? .25 : 1,
        child: Material(
          color: color ?? cs.surface,
          elevation: 3,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: faded ? null : onTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Center(child: FittedBox(child: child)),
            ),
          ),
        ),
      ),
    );
  }
}

/// Row of stars for progress inside a level.
class StarTrail extends StatelessWidget {
  final int done;
  final int total;
  const StarTrail({super.key, required this.done, required this.total});

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    children: [
      for (var i = 0; i < total; i++)
        Icon(
          i < done ? Icons.star_rounded : Icons.star_border_rounded,
          color: i < done ? Colors.amber : Colors.black26,
          size: 26,
        ),
    ],
  );
}

/// Short cheering line.
class CheerLine extends StatelessWidget {
  final String text;
  final bool good;
  const CheerLine(this.text, {super.key, this.good = true});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 34,
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Text(
        text,
        key: ValueKey(text),
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: good ? Colors.green.shade700 : Colors.orange.shade800,
        ),
      ),
    ),
  );
}
