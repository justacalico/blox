import 'package:blox/src/game/piece_shape.dart';

/// Every piece shape that can be dealt, roughly mirroring the classic
/// block-puzzle roster: lines, squares, corners, Ls, Ts and zigzags.
abstract final class PieceCatalog {
  static PieceShape _line(String id, int length, {required bool horizontal}) {
    return PieceShape(
      id,
      List.generate(
        length,
        (i) => horizontal ? (row: 0, col: i) : (row: i, col: 0),
      ),
    );
  }

  static PieceShape _rect(String id, int rows, int cols) {
    return PieceShape(
      id,
      [
        for (var r = 0; r < rows; r++)
          for (var c = 0; c < cols; c++) (row: r, col: c),
      ],
    );
  }

  /// All four rotations/reflections of a corner: a `size`-long column plus a
  /// `size`-long foot row sharing the bottom-left cell.
  static List<PieceShape> _corners(String id, int size) {
    final cells = <CellPos>[
      for (var r = 0; r < size; r++) (row: r, col: 0),
      for (var c = 1; c < size; c++) (row: size - 1, col: c),
    ];
    return [
      PieceShape(id, cells),
      PieceShape('${id}_tr', [
        for (var r = 0; r < size; r++) (row: r, col: size - 1),
        for (var c = 0; c < size - 1; c++) (row: size - 1, col: c),
      ]),
      PieceShape('${id}_bl', [
        for (var c = 0; c < size; c++) (row: 0, col: c),
        for (var r = 1; r < size; r++) (row: r, col: 0),
      ]),
      PieceShape('${id}_br', [
        for (var c = 0; c < size; c++) (row: 0, col: c),
        for (var r = 1; r < size; r++) (row: r, col: size - 1),
      ]),
    ];
  }

  static final List<PieceShape> all = [
    PieceShape('dot', const [(row: 0, col: 0)]),
    _line('line2h', 2, horizontal: true),
    _line('line2v', 2, horizontal: false),
    _line('line3h', 3, horizontal: true),
    _line('line3v', 3, horizontal: false),
    _line('line4h', 4, horizontal: true),
    _line('line4v', 4, horizontal: false),
    _line('line5h', 5, horizontal: true),
    _line('line5v', 5, horizontal: false),
    _rect('square2', 2, 2),
    _rect('square3', 3, 3),
    _rect('rect2x3', 2, 3),
    _rect('rect3x2', 3, 2),
    // Corners: 2x2 minus one cell.
    ..._corners('corner2', 2),
    // Corners: 3x3 L with 3-long legs.
    ..._corners('corner3', 3),
    // T pieces: a 3 bar with a center stem, four orientations.
    PieceShape('t_down', const [
      (row: 0, col: 0),
      (row: 0, col: 1),
      (row: 0, col: 2),
      (row: 1, col: 1),
    ]),
    PieceShape('t_up', const [
      (row: 0, col: 1),
      (row: 1, col: 0),
      (row: 1, col: 1),
      (row: 1, col: 2),
    ]),
    PieceShape('t_right', const [
      (row: 0, col: 0),
      (row: 1, col: 0),
      (row: 1, col: 1),
      (row: 2, col: 0),
    ]),
    PieceShape('t_left', const [
      (row: 0, col: 1),
      (row: 1, col: 0),
      (row: 1, col: 1),
      (row: 2, col: 1),
    ]),
    // Zigzags, horizontal and vertical.
    PieceShape('s', const [
      (row: 0, col: 1),
      (row: 0, col: 2),
      (row: 1, col: 0),
      (row: 1, col: 1),
    ]),
    PieceShape('z', const [
      (row: 0, col: 0),
      (row: 0, col: 1),
      (row: 1, col: 1),
      (row: 1, col: 2),
    ]),
    PieceShape('s_v', const [
      (row: 0, col: 0),
      (row: 1, col: 0),
      (row: 1, col: 1),
      (row: 2, col: 1),
    ]),
    PieceShape('z_v', const [
      (row: 0, col: 1),
      (row: 1, col: 0),
      (row: 1, col: 1),
      (row: 2, col: 0),
    ]),
    // Plus sign.
    PieceShape('plus', const [
      (row: 0, col: 1),
      (row: 1, col: 0),
      (row: 1, col: 1),
      (row: 1, col: 2),
      (row: 2, col: 1),
    ]),
  ];
}
