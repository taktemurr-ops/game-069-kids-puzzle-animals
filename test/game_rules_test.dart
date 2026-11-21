import 'package:flutter_test/flutter_test.dart';
import 'package:studio_core/core/level_plan.dart';
import 'package:studio_core/core/rng.dart';
import 'package:game_069_kids_puzzle_animals/game/puzzle_engine.dart';
import 'package:game_069_kids_puzzle_animals/game/rules.dart';

void main() {
  final rules = PuzzleRules();
  final planner = LevelPlanner(gameId: rules.gameId, optionalMechanics: rules.optionalMechanics);

  test('puzzles are shuffled permutations sized by difficulty', () {
    for (final n in [1, 2, 10, 99, 1234, 20000, 49999, 52000]) {
      final s = planner.spec(n);
      final l = rules.build(s).puzzle;
      expect(checkPuzzle(l), isNull, reason: 'level $n');
      expect(l.grid, puzzleGrid(s.difficulty));
    }
  });

  test('right pieces (after turning) complete the picture, wrong slots bounce', () {
    final l = generatePuzzle(planner.spec(77).copyWith(difficulty: 9, mechanics: const ['rotate']));
    final g = PuzzleGame(l);
    final t = l.tray.first;
    expect(g.place(t, (t + 1) % l.tiles), isFalse);
    expect(g.mistakes, 1);
    for (final x in l.tray) {
      while (g.turns[x] != 0) {
        g.rotate(x);
      }
      expect(g.place(x, x), isTrue);
    }
    expect(g.done, isTrue);
    expect(PuzzleGame.restore(l, g.serialize()).serialize(), g.serialize());
  });

  test('magic pieces finish a puzzle', () {
    final l = rules.build(planner.spec(5)).puzzle;
    final g = PuzzleGame(l);
    final r = SeededRandom(4);
    while (!g.done) {
      expect(g.autoPlace(r), greaterThanOrEqualTo(0));
    }
  });

  test('levels 1..80 valid', () {
    for (var n = 1; n <= 80; n++) {
      expect(rules.build(planner.spec(n)).validation.ok, isTrue, reason: 'level $n');
    }
  });
}
