import '../core/game_rules.dart';
import '../core/level_plan.dart';
import '../core/missions.dart';
import '../core/stats.dart';
import 'puzzle_engine.dart';

class PuzzleRules extends GameRules<PuzzleLevel> {
  @override
  String get gameId => 'game-069-kids-puzzle-animals';

  @override
  List<String> get optionalMechanics => const ['rotate', 'ghost'];

  @override
  List<GameModeId> get modes => const [GameModeId.campaign, GameModeId.endless, GameModeId.timeAttack, GameModeId.daily, GameModeId.weekly, GameModeId.challenge, GameModeId.zen];

  @override
  List<GameStat> get gameStats => const [
        GameStat('pieces_placed', 'Yerleşen parça', 'Pieces placed', scale: 200),
        GameStat('puzzles_done', 'Biten yapboz', 'Puzzles done', scale: 10),
        GameStat('perfect_puzzles', 'Hatasız yapboz', 'Perfect puzzles', scale: 3),
      ];

  @override
  List<MissionTemplate> get missionTemplates => const [
        MissionTemplate('m1', 'pieces_placed', [10, 25, 50]),
        MissionTemplate('m2', 'puzzles_done', [1, 3, 5], coinReward: 80),
      ];

  @override
  PuzzleLevel generate(LevelSpec spec) => generatePuzzle(spec);

  @override
  Validation validate(PuzzleLevel l, LevelSpec spec) {
    final e = checkPuzzle(l);
    return e == null ? Validation.ok(l.tiles) : Validation.fail(e);
  }
}

GameRules createRules() => PuzzleRules();
