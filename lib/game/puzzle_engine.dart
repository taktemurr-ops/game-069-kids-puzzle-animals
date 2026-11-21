import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/rng.dart';
import 'kids_data.dart';

/// Picture puzzle: an animal scene cut into g x g tiles.
class PuzzleLevel {
  final String animal;
  final String en;
  final String tr;
  final int grid;

  /// Tray order: tray[k] = tile id shown at tray position k.
  final List<int> tray;

  /// Quarter turns per tile id (rotation mechanic), all 0 otherwise.
  final List<int> turns;

  /// Faint picture behind the board.
  final bool ghost;

  /// Scene background colors (ARGB hex).
  final int bgTop;
  final int bgBottom;
  final String deco;
  const PuzzleLevel(
    this.animal,
    this.en,
    this.tr,
    this.grid,
    this.tray,
    this.turns,
    this.ghost,
    this.bgTop,
    this.bgBottom,
    this.deco,
  );
  int get tiles => grid * grid;
}

int puzzleGrid(int d) => d <= 2 ? 2 : (d <= 6 ? 3 : 4);

const _skies = [
  (0xFF81D4FA, 0xFFA5D6A7),
  (0xFFFFE082, 0xFFFFAB91),
  (0xFFB39DDB, 0xFF80CBC4),
  (0xFF90CAF9, 0xFF4FC3F7),
  (0xFFF8BBD0, 0xFFC5E1A5),
];
const _decos = ['☀️', '🌈', '☁️', '🌸', '⭐', '🌙', '🍀', '🌻'];

PuzzleLevel generatePuzzle(LevelSpec spec) {
  final r = SeededRandom(spec.seed);
  final d = spec.difficulty;
  final pool = d <= 3 ? kAnimals.sublist(0, 30) : kAnimals;
  final a = r.pick(pool);
  final g = puzzleGrid(d);
  final tray = [for (var i = 0; i < g * g; i++) i];
  do {
    r.shuffle(tray);
  } while (tray.asMap().entries.where((e) => e.key == e.value).length > g ~/ 2);
  final rotate = spec.has('rotate') || d >= 9;
  final turns = [for (var i = 0; i < g * g; i++) rotate ? r.nextInt(4) : 0];
  if (rotate && turns.every((t) => t == 0)) turns[0] = 1;
  final sky = r.pick(_skies);
  return PuzzleLevel(a.$1, a.$2, a.$3, g, tray, turns, d <= 4 || spec.has('ghost'), sky.$1, sky.$2, r.pick(_decos));
}

String? checkPuzzle(PuzzleLevel l) {
  if (l.grid < 2 || l.grid > 5) return 'bad grid';
  if (l.tray.length != l.tiles || l.tray.toSet().length != l.tiles) return 'tray is not a permutation';
  if (l.tray.any((t) => t < 0 || t >= l.tiles)) return 'bad tile';
  var same = 0;
  for (var i = 0; i < l.tiles; i++) {
    if (l.tray[i] == i) same++;
  }
  if (same == l.tiles) return 'not shuffled';
  if (l.turns.length != l.tiles || l.turns.any((t) => t < 0 || t > 3)) return 'bad turns';
  return null;
}

class PuzzleGame {
  final PuzzleLevel level;

  /// board[slot] = tile id placed there or -1.
  late final List<int> board;
  late final List<int> turns;
  int mistakes = 0;
  int moves = 0;
  PuzzleGame(this.level) {
    board = List.filled(level.tiles, -1);
    turns = [...level.turns];
  }

  bool get done => board.asMap().entries.every((e) => e.value == e.key);
  bool placed(int tile) => board.contains(tile);
  List<int> get trayLeft => [
    for (final t in level.tray)
      if (!placed(t)) t,
  ];

  void rotate(int tile) {
    turns[tile] = (turns[tile] + 1) % 4;
    moves++;
  }

  /// Tries to drop [tile] on [slot]. Wrong slot or wrong rotation bounces back.
  bool place(int tile, int slot) {
    moves++;
    if (placed(tile) || board[slot] >= 0) return false;
    if (tile != slot || turns[tile] != 0) {
      mistakes++;
      return false;
    }
    board[slot] = tile;
    return true;
  }

  /// Puts one remaining tile in place (hint / booster).
  int autoPlace(SeededRandom r) {
    final left = trayLeft;
    if (left.isEmpty) return -1;
    final t = r.pick(left);
    turns[t] = 0;
    board[t] = t;
    return t;
  }

  String serialize() => '$mistakes;$moves;${board.join(',')};${turns.join(',')}';

  static PuzzleGame restore(PuzzleLevel l, String s) {
    final g = PuzzleGame(l);
    final p = s.split(';');
    if (p.length == 4) {
      g.mistakes = int.tryParse(p[0]) ?? 0;
      g.moves = int.tryParse(p[1]) ?? 0;
      final b = p[2].split(','), t = p[3].split(',');
      if (b.length == l.tiles && t.length == l.tiles) {
        for (var i = 0; i < l.tiles; i++) {
          g.board[i] = int.tryParse(b[i]) ?? -1;
          g.turns[i] = (int.tryParse(t[i]) ?? 0) % 4;
        }
      }
    }
    return g;
  }
}
