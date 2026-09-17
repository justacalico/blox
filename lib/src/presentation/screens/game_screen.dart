import 'dart:async';
import 'dart:math';

import 'package:blox/l10n/generated/app_localizations.dart';
import 'package:blox/src/game/board.dart';
import 'package:blox/src/game/game_engine.dart';
import 'package:blox/src/game/piece.dart';
import 'package:blox/src/game/piece_shape.dart';
import 'package:blox/src/haptics.dart';
import 'package:blox/src/presentation/board_layout.dart';
import 'package:blox/src/presentation/widgets/board_view.dart';
import 'package:blox/src/presentation/widgets/hud.dart';
import 'package:blox/src/presentation/widgets/overlays.dart';
import 'package:blox/src/presentation/widgets/particle_layer.dart';
import 'package:blox/src/presentation/widgets/piece_view.dart';
import 'package:blox/src/presentation/widgets/score_popup.dart';
import 'package:blox/src/presentation/widgets/tray_view.dart';
import 'package:blox/src/settings.dart';
import 'package:blox/src/sound.dart';
import 'package:blox/src/theme/blox_theme.dart';
import 'package:flutter/material.dart' show Scaffold;
import 'package:flutter/widgets.dart';

/// State of an in-progress drag, in stack coordinates.
final class _Drag {
  _Drag({
    required this.trayIndex,
    required this.piece,
    required this.pointer,
    required this.grabFraction,
  });

  final int trayIndex;
  final Piece piece;
  Offset pointer;

  /// Where inside the piece the finger grabbed it, 0..1 across the piece.
  Offset grabFraction;

  CellPos? anchor;
  bool anchorValid = false;
  ({List<int> rows, List<int> cols}) preview = (rows: const [], cols: const []);
}

final class _Popup {
  _Popup({required this.text, required this.pos, this.color = BloxColors.ink});

  final String text;
  final Offset pos;
  final Color color;
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.settings, this.engine, this.random});

  final SettingsStore settings;

  /// Injectable for tests; defaults to a seeded-by-time engine.
  final GameEngine? engine;
  final Random? random;

  @override
  State<GameScreen> createState() => GameScreenState();
}

class GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  late final GameEngine _engine =
      widget.engine ?? GameEngine(scoreStore: widget.settings);
  late final BloxHaptics _haptics =
      BloxHaptics(enabled: widget.settings.haptics);
  late final BloxSound _sound =
      BloxSound(enabled: widget.settings.sound);
  late final Random _random = widget.random ?? Random();

  final _boardKey = GlobalKey();
  final _stackKey = GlobalKey();
  final _slotKeys = List.generate(GameEngine.traySize, (_) => GlobalKey());
  final _pieceKeys = List.generate(GameEngine.traySize, (_) => GlobalKey());
  final _particlesKey = GlobalKey<ParticleLayerState>();

  late final AnimationController _clearController;
  late final AnimationController _popController;

  @override
  void initState() {
    super.initState();
    _clearController = AnimationController(
      vsync: this,
      duration: BloxMotion.clear,
    )..addListener(_rebuild);
    _popController = AnimationController(
      vsync: this,
      duration: BloxMotion.pop,
    )..addListener(_rebuild);
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  _Drag? _drag;
  ClearAnimation? _clearing;
  Set<CellPos> _popCells = const {};
  final List<_Popup> _popups = [];
  bool _paused = false;
  bool _gameOverShown = false;

  GameEngine get engine => _engine;

  // --- geometry -----------------------------------------------------------

  RenderBox? _boxOf(GlobalKey key) =>
      key.currentContext?.findRenderObject() as RenderBox?;

  BoardLayout get _layout {
    final box = _boxOf(_boardKey)!;
    return BoardLayout(boardPx: box.size.width, cells: _engine.board.size);
  }

  Offset _toStack(Offset global) {
    final stack = _boxOf(_stackKey)!;
    return stack.globalToLocal(global);
  }

  double get _lift => _layout.cellPx * 1.7 + 12;

  // --- dragging -----------------------------------------------------------

  void _onDragStart(int index, Offset global) {
    if (_paused || _engine.isGameOver) return;
    final piece = _engine.tray[index];
    if (piece == null) return;

    final pieceBox = _boxOf(_pieceKeys[index]);
    var grab = const Offset(0.5, 0.5);
    if (pieceBox != null) {
      final topLeft = pieceBox.localToGlobal(Offset.zero);
      grab = Offset(
        ((global.dx - topLeft.dx) / pieceBox.size.width).clamp(0.0, 1.0),
        ((global.dy - topLeft.dy) / pieceBox.size.height).clamp(0.0, 1.0),
      );
    }
    setState(() {
      _drag = _Drag(
        trayIndex: index,
        piece: piece,
        pointer: global,
        grabFraction: grab,
      );
    });
    _updateAnchor();
    _haptics.tap();
  }

  void _onDragUpdate(Offset global) {
    if (_drag == null) return;
    setState(() => _drag!.pointer = global);
    _updateAnchor();
  }

  void _onDragEnd(Offset global) {
    final d = _drag;
    if (d == null) return;
    _drag!.pointer = global;
    _updateAnchor();
    final anchor = d.anchor;
    if (d.anchorValid && anchor != null) {
      _place(d.trayIndex, anchor);
    }
    setState(() => _drag = null);
  }

  /// Where the dragged piece's top-left would sit on the board, in
  /// board-local pixels.
  Offset _pieceTopLeftOnBoard() {
    final d = _drag!;
    final layout = _layout;
    final boardOrigin = _boxOf(_boardKey)!.localToGlobal(Offset.zero);
    final pieceW = d.piece.shape.width * layout.cellPx;
    final pieceH = d.piece.shape.height * layout.cellPx;
    final topLeftGlobal = Offset(
      d.pointer.dx - d.grabFraction.dx * pieceW,
      d.pointer.dy - d.grabFraction.dy * pieceH - _lift,
    );
    return topLeftGlobal - boardOrigin;
  }

  void _updateAnchor() {
    final d = _drag;
    final boardBox = _boxOf(_boardKey);
    if (d == null || boardBox == null) return;
    final anchor = _layout.anchorFor(_pieceTopLeftOnBoard());
    d.anchor = anchor;
    d.anchorValid = _engine.canPlaceAt(d.trayIndex, anchor.row, anchor.col);
    d.preview = d.anchorValid
        ? _engine.board.previewClears(
            d.piece.shape,
            anchor.row,
            anchor.col,
          )
        : (rows: const [], cols: const []);
  }

  // --- placement + juice ---------------------------------------------------

  void _place(int trayIndex, CellPos anchor) {
    final placedColor = _engine.tray[trayIndex]!.colorIndex;
    final boardBefore = _engine.board.copy();
    final result = _engine.place(trayIndex, anchor.row, anchor.col);
    if (result == null) {
      setState(() {});
      return;
    }

    _haptics.tap();
    _sound.click();
    setState(() {
      _popCells = result.placedCells.toSet();
    });
    _popController.forward(from: 0);

    if (result.clearedAnything) {
      if (result.clearedRows.length + result.clearedColumns.length >= 2 ||
          result.combo >= 3) {
        _haptics.thud();
      } else {
        _haptics.clear();
      }
      _spawnClearEffects(result, boardBefore, placedColor);
    }

    if (result.newBest) {
      _haptics.thud();
    }
    if (result.gameOver) {
      _haptics.gameOver();
      Timer(BloxMotion.clear + const Duration(milliseconds: 250), () {
        if (mounted) setState(() => _gameOverShown = true);
      });
    }
  }

  void _spawnClearEffects(
    PlacementResult result,
    Board before,
    int placedColor,
  ) {
    final layout = _layout;
    final boardOrigin = _boxOf(_boardKey)!.localToGlobal(Offset.zero);

    // Cells placed this move were empty in `before`; they carry the placed
    // piece's color.
    final cells = <CellPos, int>{
      for (final c in result.clearedCells)
        c: before.colorAt(c.row, c.col) ?? placedColor,
    };
    setState(() {
      _clearing = ClearAnimation(cells: cells, progress: 0);
    });
    _clearController.forward(from: 0).whenComplete(() {
      if (mounted) setState(() => _clearing = null);
    });

    // Particles from a handful of cleared cells.
    final particles = _particlesKey.currentState;
    if (particles != null) {
      final sample = result.clearedCells.length > 8
          ? result.clearedCells.sublist(0, 8)
          : result.clearedCells;
      for (final c in sample) {
        final center = boardOrigin + layout.cellRect(c.row, c.col).center;
        particles.burst(
          _toStack(center),
          PieceView.colorOf(
            before.colorAt(c.row, c.col) ?? placedColor,
          ),
          count: 6,
        );
      }
    }

    // Points popup at the centroid of the clear.
    var cx = 0.0, cy = 0.0;
    for (final c in result.clearedCells) {
      final center = boardOrigin + layout.cellRect(c.row, c.col).center;
      cx += center.dx;
      cy += center.dy;
    }
    final centroid = _toStack(
      Offset(cx / result.clearedCells.length, cy / result.clearedCells.length),
    );
    final l10n = AppLocalizations.of(context);
    _addPopup(
      _Popup(
        text: l10n.pointsEarned(result.clearPoints + result.placementPoints),
        pos: centroid,
      ),
    );
    if (result.combo >= 2) {
      _addPopup(
        _Popup(
          text: l10n.combo(result.combo),
          pos: centroid - const Offset(0, 48),
          color: BloxColors.crown,
        ),
      );
    }
  }

  void _addPopup(_Popup popup) {
    setState(() => _popups.add(popup));
  }

  // --- build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: _engine,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: BloxColors.backdropBottom,
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [BloxColors.backdropTop, BloxColors.backdropBottom],
              ),
            ),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final boardPx = min(
                    constraints.maxWidth - 24,
                    constraints.maxHeight * 0.62,
                  );
                  return Stack(
                    key: _stackKey,
                    children: [
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Hud(
                              score: _engine.score,
                              best: _engine.best,
                              onPause: () =>
                                  setState(() => _paused = true),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: BoardView(
                                key: _boardKey,
                                board: _engine.board,
                                boardPx: boardPx,
                                drag: _drag != null &&
                                        _drag!.anchorValid &&
                                        _drag!.anchor != null
                                    ? DragPreview(
                                        piece: _drag!.piece,
                                        anchor: _drag!.anchor!,
                                        clearingRows: _drag!.preview.rows,
                                        clearingColumns:
                                            _drag!.preview.cols,
                                      )
                                    : null,
                                clearing: _clearing,
                                popCells: _popCells,
                                popProgress: _popController.value,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: BloxMetrics.traySlot + 16,
                            child: TrayView(
                              pieces: _engine.tray,
                              placeable: _engine.trayPlaceability,
                              slotKeys: _slotKeys,
                              pieceKeys: _pieceKeys,
                              draggingIndex: _drag?.trayIndex,
                              onDragStart: _onDragStart,
                              onDragUpdate: _onDragUpdate,
                              onDragEnd: _onDragEnd,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Text(
                              l10n.dragHint,
                              style: BloxText.label(13),
                            ),
                          ),
                        ],
                      ),
                      ParticleLayer(key: _particlesKey, random: _random),
                      for (final popup in _popups)
                        Positioned(
                          key: ValueKey(popup),
                          left: popup.pos.dx - 80,
                          top: popup.pos.dy - 20,
                          width: 160,
                          child: Center(
                            child: ScorePopup(
                              text: popup.text,
                              color: popup.color,
                              onDone: () => setState(
                                () => _popups.remove(popup),
                              ),
                            ),
                          ),
                        ),
                      if (_drag != null) _buildDraggedPiece(),
                      if (_paused) _buildPauseOverlay(context),
                      if (_gameOverShown) _buildGameOverOverlay(context),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggedPiece() {
    final d = _drag!;
    final layout = _layout;
    final local = _toStack(
      Offset(
        d.pointer.dx -
            d.grabFraction.dx * d.piece.shape.width * layout.cellPx,
        d.pointer.dy -
            d.grabFraction.dy * d.piece.shape.height * layout.cellPx -
            _lift,
      ),
    );
    return Positioned(
      left: local.dx,
      top: local.dy,
      child: IgnorePointer(
        child: PieceView(
          piece: d.piece,
          cellPx: layout.cellPx - layout.gap,
        ),
      ),
    );
  }

  Widget _buildPauseOverlay(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OverlayPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.pause, style: BloxText.display(34)),
          const SizedBox(height: 20),
          SettingsToggles(settings: widget.settings),
          const SizedBox(height: 20),
          BloxRowButton(
            label: l10n.resume,
            color: BloxColors.ctaTeal,
            deepColor: BloxColors.ctaTealDeep,
            onPressed: () => setState(() => _paused = false),
          ),
          const SizedBox(height: 12),
          BloxRowButton(
            label: l10n.restart,
            onPressed: () {
              _engine.newGame();
              setState(() {
                _paused = false;
                _gameOverShown = false;
              });
            },
          ),
          const SizedBox(height: 12),
          BloxRowButton(
            label: l10n.backToMenu,
            color: BloxColors.ctaBlue,
            deepColor: BloxColors.ctaBlueDeep,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Widget _buildGameOverOverlay(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return OverlayPanel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.gameOver, style: BloxText.display(36)),
          const SizedBox(height: 4),
          Text(l10n.noMoves, style: BloxText.label(14)),
          const SizedBox(height: 18),
          Text('${_engine.score}', style: BloxText.display(56)),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.best, style: BloxText.label(14)),
              const SizedBox(width: 6),
              Text('${_engine.best}', style: BloxText.display(20)),
            ],
          ),
          const SizedBox(height: 22),
          BloxRowButton(
            label: l10n.playAgain,
            onPressed: () {
              _engine.newGame();
              setState(() => _gameOverShown = false);
            },
          ),
          const SizedBox(height: 12),
          BloxRowButton(
            label: l10n.backToMenu,
            color: BloxColors.ctaBlue,
            deepColor: BloxColors.ctaBlueDeep,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _clearController.dispose();
    _popController.dispose();
    super.dispose();
  }
}
