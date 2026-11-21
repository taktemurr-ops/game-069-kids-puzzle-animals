import 'package:flutter/material.dart';

import 'package:studio_core/app/game_api.dart';
import 'puzzle_view.dart';
import 'rules.dart';

/// Kids & Family game: kidsMode treats every player as a child (no
/// personalized ads, no analytics, child-directed ad requests, parental
/// gate in the shop).
final gameConfig = GameConfig(
  gameId: 'game-069-kids-puzzle-animals',
  title: const ['Hayvanlı Yapboz', 'Kids Puzzle Animals', 'Tier-Puzzle', 'Puzle de Animales', 'Puzzle Animaux'],
  tagline: const ['Parçaları yerleştir, hayvanı tamamla!', 'Place the pieces and finish the animal!', 'Lege die Teile!', '¡Coloca las piezas!', 'Place les pièces !'],
  seedColor: const Color(0xFFFB8500),
  icon: Icons.extension,
  rules: PuzzleRules(),
  buildPlay: (ctx) => PuzzleView(ctx: ctx),
  kidsMode: true,
  tutorial: const [
    TutorialStep(Icons.pan_tool, ['Parçayı sürükle ve bırak.', 'Drag and drop the piece.', 'Teil ziehen und ablegen.', 'Arrastra la pieza.', 'Glisse la pièce.']),
    TutorialStep(Icons.rotate_right, ['Dönük parçaya iki kez dokunarak çevir.', 'Tap a turned piece twice to rotate it.', 'Zweimal tippen zum Drehen.', 'Toca dos veces para girar.', 'Touche deux fois pour tourner.']),
    TutorialStep(Icons.image, ['Silik resim sana yol gösterir.', 'The faint picture guides you.', 'Das blasse Bild hilft.', 'La imagen tenue te guía.', 'L\'image pâle te guide.']),
  ],
);
