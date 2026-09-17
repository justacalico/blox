import 'package:blox/src/game/piece.dart';
import 'package:blox/src/presentation/widgets/piece_view.dart';
import 'package:blox/src/theme/blox_theme.dart';
import 'package:flutter/widgets.dart';

/// The three dealt pieces waiting under the board.
///
/// Purely presentational: the parent owns drag gestures so it can coordinate
/// with the board. Each slot reports its piece widget bounds through
/// [slotKeys].
class TrayView extends StatelessWidget {
  const TrayView({
    super.key,
    required this.pieces,
    required this.placeable,
    required this.slotKeys,
    required this.draggingIndex,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
    this.pieceKeys,
    this.cellPx = 20,
  });

  final List<Piece?> pieces;
  final List<bool> placeable;
  final List<GlobalKey> slotKeys;

  /// Optional keys on each piece widget, for measuring grab position.
  final List<GlobalKey>? pieceKeys;
  final int? draggingIndex;
  final double cellPx;

  final void Function(int index, Offset globalPosition) onDragStart;
  final void Function(Offset globalPosition) onDragUpdate;
  final void Function(Offset globalPosition) onDragEnd;
  final VoidCallback onDragCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (var i = 0; i < pieces.length; i++)
          _TraySlot(
            key: slotKeys[i],
            pieceKey: pieceKeys != null ? pieceKeys![i] : null,
            piece: pieces[i],
            placeable: i < placeable.length ? placeable[i] : false,
            cellPx: cellPx,
            hidden: draggingIndex == i,
            onDragStart: (pos) => onDragStart(i, pos),
            onDragUpdate: onDragUpdate,
            onDragEnd: onDragEnd,
            onDragCancel: onDragCancel,
          ),
      ],
    );
  }
}

class _TraySlot extends StatelessWidget {
  const _TraySlot({
    super.key,
    this.pieceKey,
    required this.piece,
    required this.placeable,
    required this.cellPx,
    required this.hidden,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onDragCancel,
  });

  final GlobalKey? pieceKey;
  final Piece? piece;
  final bool placeable;
  final double cellPx;
  final bool hidden;
  final void Function(Offset globalPosition) onDragStart;
  final void Function(Offset globalPosition) onDragUpdate;
  final void Function(Offset globalPosition) onDragEnd;
  final VoidCallback onDragCancel;

  @override
  Widget build(BuildContext context) {
    final p = piece;
    return Listener(
      onPointerDown: p == null
          ? null
          : (e) => onDragStart(e.position),
      onPointerMove: p == null ? null : (e) => onDragUpdate(e.position),
      onPointerUp: p == null ? null : (e) => onDragEnd(e.position),
      onPointerCancel: p == null ? null : (_) => onDragCancel(),
      child: SizedBox(
        width: BloxMetrics.traySlot,
        height: BloxMetrics.traySlot,
        child: Center(
          child: p == null
              ? const SizedBox.shrink()
              : AnimatedOpacity(
                  duration: BloxMotion.snap,
                  opacity: hidden ? 0.15 : 1,
                  child: PieceView(
                    key: pieceKey,
                    piece: p,
                    cellPx: cellPx,
                    dimmed: !placeable,
                  ),
                ),
        ),
      ),
    );
  }
}
