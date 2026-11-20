import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/game_api.dart';
import '../app/play_kit.dart';
import '../app/services/audio.dart';
import '../core/game_rules.dart';
import '../core/level_plan.dart';
import '../core/rng.dart';
import 'kids_ui.dart';
import 'puzzle_engine.dart';
import 'rules.dart';

/// The whole picture (scene + animal) at [size].
class PuzzleScene extends StatelessWidget {
  final PuzzleLevel level;
  final double size;
  const PuzzleScene({super.key, required this.level, required this.size});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(level.bgTop), Color(level.bgBottom)],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: size * .22,
          child: const DecoratedBox(decoration: BoxDecoration(color: Color(0xFF7CB342))),
        ),
        Positioned(
          left: size * .04,
          top: size * .04,
          child: Text(level.deco, style: TextStyle(fontSize: size * .16)),
        ),
        Positioned(
          right: size * .05,
          bottom: size * .05,
          child: Text('🌼', style: TextStyle(fontSize: size * .1)),
        ),
        Positioned(
          left: size * .06,
          bottom: size * .04,
          child: Text('🌿', style: TextStyle(fontSize: size * .11)),
        ),
        Center(
          child: Text(level.animal, style: TextStyle(fontSize: size * .55)),
        ),
      ],
    ),
  );
}

class PuzzleTile extends StatelessWidget {
  final PuzzleLevel level;
  final int tile;
  final double board;
  final int turns;
  final bool selected;
  const PuzzleTile({
    super.key,
    required this.level,
    required this.tile,
    required this.board,
    this.turns = 0,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final g = level.grid;
    final t = board / g;
    final col = tile % g, row = tile ~/ g;
    return Transform.rotate(
      angle: turns * math.pi / 2,
      child: Container(
        width: t,
        height: t,
        decoration: BoxDecoration(
          border: Border.all(color: selected ? Colors.amber : Colors.white, width: selected ? 4 : 1.5),
          boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.black26)],
        ),
        child: ClipRect(
          child: OverflowBox(
            maxWidth: board,
            maxHeight: board,
            minWidth: board,
            minHeight: board,
            alignment: Alignment(g == 1 ? 0 : -1 + 2 * col / (g - 1), g == 1 ? 0 : -1 + 2 * row / (g - 1)),
            child: PuzzleScene(level: level, size: board),
          ),
        ),
      ),
    );
  }
}

class PuzzleView extends StatefulWidget {
  final PlayContext ctx;
  const PuzzleView({super.key, required this.ctx});

  @override
  State<PuzzleView> createState() => _PuzzleViewState();
}

class _PuzzleViewState extends State<PuzzleView> with RoundClock {
  late PuzzleLevel level;
  late PuzzleGame game;
  late SeededRandom _r;
  int _hints = 0;
  int _rounds = 0;
  int _tilesTotal = 0;
  int _pictures = 0;
  int? _sel;
  bool _ended = false;
  bool _finishing = false;
  String _msg = '';
  bool _ok = true;

  PlayContext get ctx => widget.ctx;
  bool get _tr => isTr(ctx);
  bool get _chain => const [GameModeId.endless, GameModeId.timeAttack].contains(ctx.spec.mode);

  @override
  void initState() {
    super.initState();
    level = (ctx.generated as GeneratedLevel<PuzzleLevel>).puzzle;
    final snap = ctx.resume['snap'];
    game = snap is String ? PuzzleGame.restore(level, snap) : PuzzleGame(level);
    _hints = (ctx.resume['hints'] as num?)?.toInt() ?? 0;
    _rounds = (ctx.resume['solved'] as num?)?.toInt() ?? 0;
    _r = SeededRandom(mixSeed([ctx.spec.seed, 71]));
    startClock(
      initialSeconds: (ctx.resume['secs'] as num?)?.toInt() ?? 0,
      limit: ctx.spec.mode == GameModeId.timeAttack ? 150 : 0,
    );
  }

  @override
  void dispose() {
    stopClock();
    super.dispose();
  }

  @override
  void onTimeUp() => _end();

  void _persist() => ctx.saveResume({'snap': game.serialize(), 'secs': seconds, 'hints': _hints, 'solved': _rounds});

  void _trayTap(int t) {
    if (_finishing) return;
    final rotating = level.turns.any((x) => x != 0);
    setState(() {
      if (_sel == t && rotating) {
        game.rotate(t);
      } else if (_sel == t) {
        _sel = null;
      } else {
        _sel = t;
      }
    });
    ctx.sfx(Sfx.tap);
    _persist();
  }

  void _drop(int tile, int slot) {
    if (_finishing || _ended) return;
    final ok = game.place(tile, slot);
    if (ok) {
      _tilesTotal++;
      ctx.sfx(Sfx.place);
      setState(() {
        _sel = null;
        _msg = '';
        _ok = true;
      });
      if (game.done) _pictureDone();
    } else {
      ctx.sfx(Sfx.error);
      setState(() {
        _msg = game.turns[tile] != 0 && tile == slot
            ? (_tr ? 'Önce parçayı çevir! 🔄' : 'Turn the piece first! 🔄')
            : tryAgain(ctx, game.mistakes);
        _ok = false;
      });
    }
    _persist();
  }

  Future<void> _pictureDone() async {
    _finishing = true;
    _pictures++;
    ctx.sfx(Sfx.win);
    setState(() {
      _msg = '${cheer(ctx, _pictures)} ${_tr ? level.tr : level.en}!';
      _ok = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    _finishing = false;
    if (_chain) {
      _rounds++;
      final next = ctx.spec.copyWith(seed: mixSeed([ctx.spec.seed, _rounds]));
      setState(() {
        level = createRules().build(next).puzzle as PuzzleLevel;
        game = PuzzleGame(level);
        _msg = '';
      });
      _persist();
      return;
    }
    _end();
  }

  void _end() {
    if (_ended) return;
    _ended = true;
    stopClock();
    final m = game.mistakes;
    var stars = m <= 1 ? 3 : (m <= 4 ? 2 : 1);
    if (_chain) stars = _rounds >= 3 ? 3 : (_rounds >= 1 ? 2 : 1);
    ctx.finish(
      RoundResult(
        won: _pictures > 0 || game.done,
        score: _tilesTotal * 60 + _pictures * 400,
        stars: stars,
        seconds: seconds,
        moves: game.moves,
        hintsUsed: _hints,
        gameStats: {
          'pieces_placed': _tilesTotal,
          'puzzles_done': _pictures,
          'perfect_puzzles': game.done && m == 0 ? 1 : 0,
        },
      ),
    );
  }

  Future<void> _auto(int n, bool booster) async {
    if (_finishing || game.done) return;
    if (!await (booster ? ctx.requestBooster() : ctx.requestHint())) return;
    if (!booster) _hints++;
    setState(() {
      for (var k = 0; k < n; k++) {
        if (game.autoPlace(_r) >= 0) _tilesTotal++;
      }
      _sel = null;
    });
    ctx.sfx(Sfx.place);
    _persist();
    if (game.done) _pictureDone();
  }

  @override
  Widget build(BuildContext context) {
    final g = level.grid;
    return KidsBackdrop(
      colors: ctx.background,
      child: Column(
        children: [
          PlayHud(
            items: [
              if (ctx.spec.mode == GameModeId.timeAttack) (Icons.timer, timeText),
              (Icons.extension, '${game.board.where((b) => b >= 0).length}/${level.tiles}'),
              if (_chain) (Icons.emoji_events, '$_rounds'),
            ],
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                final board = math.min(c.maxWidth - 32, c.maxHeight * .58).clamp(120.0, 560.0);
                final tile = board / g;
                final trayTile = math.min(tile * .8, 96.0);
                return Column(
                  children: [
                    const SizedBox(height: 6),
                    SizedBox(
                      width: board,
                      height: board,
                      child: Stack(
                        children: [
                          if (level.ghost)
                            Opacity(
                              opacity: .25,
                              child: PuzzleScene(level: level, size: board),
                            ),
                          for (var s = 0; s < level.tiles; s++)
                            Positioned(
                              left: (s % g) * tile,
                              top: (s ~/ g) * tile,
                              width: tile,
                              height: tile,
                              child: DragTarget<int>(
                                onAcceptWithDetails: (d) => _drop(d.data, s),
                                builder: (context, cand, rej) => GestureDetector(
                                  onTap: () {
                                    if (_sel != null && game.board[s] < 0) _drop(_sel!, s);
                                  },
                                  child: game.board[s] >= 0
                                      ? PuzzleTile(level: level, tile: s, board: board)
                                      : Container(
                                          decoration: BoxDecoration(
                                            color: cand.isNotEmpty ? Colors.white54 : Colors.transparent,
                                            border: Border.all(color: Colors.white70, width: 1.5),
                                          ),
                                        ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    CheerLine(_msg, good: _ok),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final t in game.trayLeft)
                              Draggable<int>(
                                data: t,
                                feedback: Material(
                                  color: Colors.transparent,
                                  child: PuzzleTile(level: level, tile: t, board: board, turns: game.turns[t]),
                                ),
                                childWhenDragging: SizedBox(width: trayTile, height: trayTile),
                                child: GestureDetector(
                                  onTap: () => _trayTap(t),
                                  child: SizedBox(
                                    width: trayTile,
                                    height: trayTile,
                                    child: FittedBox(
                                      child: PuzzleTile(
                                        level: level,
                                        tile: t,
                                        board: board,
                                        turns: game.turns[t],
                                        selected: _sel == t,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          BoosterBar(
            buttons: [
              BoosterButton(Icons.lightbulb, ctx.t('hint'), () => _auto(1, false)),
              BoosterButton(Icons.auto_fix_high, _tr ? 'Sihirli parçalar' : 'Magic pieces', () => _auto(2, true)),
            ],
          ),
        ],
      ),
    );
  }
}
