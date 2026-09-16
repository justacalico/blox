import 'package:blox/src/game/piece_shape.dart';

/// Number of distinct block colors. The UI palette must expose exactly this
/// many entries; a widget test pins the two together.
const int kBlockColorCount = 7;

/// A dealt piece: a shape plus a color index into the theme's block palette.
final class Piece {
  const Piece(this.shape, this.colorIndex);

  final PieceShape shape;
  final int colorIndex;
}
