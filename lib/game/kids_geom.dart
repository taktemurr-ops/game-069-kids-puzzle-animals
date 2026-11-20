import 'dart:math' as math;

/// Pure-Dart geometry shared by shape tokens and the coloring pages.
/// Polygons are flat lists [x0, y0, x1, y1, ...].

List<double> ellipsePoly(
  double cx,
  double cy,
  double rx,
  double ry, {
  int n = 40,
  double from = 0,
  double to = 2 * math.pi,
}) {
  final out = <double>[];
  final closed = (to - from) >= 2 * math.pi - 1e-9;
  final steps = closed ? n : n + 1;
  for (var i = 0; i < steps; i++) {
    final a = from + (to - from) * i / n;
    out
      ..add(cx + rx * math.cos(a))
      ..add(cy + ry * math.sin(a));
  }
  return out;
}

List<double> rectPoly(double x, double y, double w, double h) => [x, y, x + w, y, x + w, y + h, x, y + h];

List<double> regularPoly(double cx, double cy, double r, int sides, {double rot = -math.pi / 2}) => [
  for (var i = 0; i < sides; i++) ...[
    cx + r * math.cos(rot + 2 * math.pi * i / sides),
    cy + r * math.sin(rot + 2 * math.pi * i / sides),
  ],
];

List<double> starPoly(double cx, double cy, double r, {int points = 5, double inner = 0.45}) => [
  for (var i = 0; i < points * 2; i++) ...[
    cx + (i.isEven ? r : r * inner) * math.cos(-math.pi / 2 + math.pi * i / points),
    cy + (i.isEven ? r : r * inner) * math.sin(-math.pi / 2 + math.pi * i / points),
  ],
];

List<double> heartPoly(double cx, double cy, double r, {int n = 48}) {
  final out = <double>[];
  for (var i = 0; i < n; i++) {
    final t = 2 * math.pi * i / n;
    final x = 16 * math.pow(math.sin(t), 3);
    final y = 13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t);
    out
      ..add(cx + r * x / 17)
      ..add(cy - r * y / 17 + r * 0.1);
  }
  return out;
}

/// Unit polygon (inside 0..1) for a named kid shape.
List<double> shapePoly(String id) {
  switch (id) {
    case 'circle':
      return ellipsePoly(.5, .5, .45, .45);
    case 'oval':
      return ellipsePoly(.5, .5, .47, .3);
    case 'square':
      return rectPoly(.1, .1, .8, .8);
    case 'rectangle':
      return rectPoly(.03, .25, .94, .5);
    case 'triangle':
      return [.5, .07, .95, .88, .05, .88];
    case 'star':
      return starPoly(.5, .54, .48);
    case 'heart':
      return heartPoly(.5, .5, .46);
    case 'diamond':
      return [.5, .03, .85, .5, .5, .97, .15, .5];
    case 'pentagon':
      return regularPoly(.5, .54, .46, 5);
    case 'hexagon':
      return regularPoly(.5, .5, .47, 6, rot: 0);
    case 'semicircle':
      return ellipsePoly(.5, .72, .46, .46, from: math.pi, to: 2 * math.pi);
    case 'trapezoid':
      return [.28, .22, .72, .22, .95, .8, .05, .8];
  }
  return rectPoly(.1, .1, .8, .8);
}

bool polyContains(List<double> p, double x, double y) {
  var inside = false;
  final n = p.length ~/ 2;
  for (var i = 0, j = n - 1; i < n; j = i++) {
    final xi = p[i * 2], yi = p[i * 2 + 1], xj = p[j * 2], yj = p[j * 2 + 1];
    if ((yi > y) != (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi) inside = !inside;
  }
  return inside;
}

double polyArea(List<double> p) {
  var a = 0.0;
  final n = p.length ~/ 2;
  for (var i = 0, j = n - 1; i < n; j = i++) {
    a += p[j * 2] * p[i * 2 + 1] - p[i * 2] * p[j * 2 + 1];
  }
  return a.abs() / 2;
}

(double, double, double, double) polyBounds(List<double> p) {
  var x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9;
  for (var i = 0; i < p.length; i += 2) {
    x0 = math.min(x0, p[i]);
    x1 = math.max(x1, p[i]);
    y0 = math.min(y0, p[i + 1]);
    y1 = math.max(y1, p[i + 1]);
  }
  return (x0, y0, x1, y1);
}
