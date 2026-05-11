import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pet_widget.dart';
import 'pet_model.dart';
import 'storage_service.dart';
import 'level_up_dialog.dart';

// ─── Puzzle data ─────────────────────────────────────────────────

class _Puzzle {
  final String name;
  final List<Offset> nodes;
  final List<(int, int)> edges;
  final int xpReward;
  final int coinReward;

  const _Puzzle(this.name, this.nodes, this.edges, this.xpReward, this.coinReward);

  // Returns valid starting nodes (odd-degree for Eulerian path, all for circuit)
  List<int> get validStarts {
    final deg = List.filled(nodes.length, 0);
    for (final e in edges) { deg[e.$1]++; deg[e.$2]++; }
    final odds = [for (int i = 0; i < nodes.length; i++) if (deg[i].isOdd) i];
    return odds.isEmpty ? List.generate(nodes.length, (i) => i) : odds;
  }
}

// Puzzle 1 – 집 (house): 5 nodes, 6 edges, Eulerian path (nodes 1 ↔ 2)
final _puz1 = _Puzzle('🏠 집', const [
  Offset(0.50, 0.12),
  Offset(0.22, 0.44),
  Offset(0.78, 0.44),
  Offset(0.22, 0.82),
  Offset(0.78, 0.82),
], const [(0,1),(0,2),(1,2),(1,3),(2,4),(3,4)], 15, 5);

// Puzzle 2 – 별 (diamond+center): 5 nodes, 7 edges, Eulerian path (nodes 2 ↔ 3)
final _puz2 = _Puzzle('⭐ 별', const [
  Offset(0.50, 0.50),
  Offset(0.50, 0.12),
  Offset(0.88, 0.50),
  Offset(0.50, 0.88),
  Offset(0.12, 0.50),
], const [(0,1),(0,2),(0,3),(0,4),(1,2),(2,3),(3,4)], 25, 8);

// Puzzle 3 – 육각 (hexagon + inner triangle): 6 nodes, 9 edges, Eulerian circuit
final _puz3 = _Puzzle('🔷 육각', const [
  Offset(0.50, 0.10),
  Offset(0.85, 0.30),
  Offset(0.85, 0.70),
  Offset(0.50, 0.90),
  Offset(0.15, 0.70),
  Offset(0.15, 0.30),
], const [(0,1),(1,2),(2,3),(3,4),(4,5),(5,0),(0,2),(2,4),(4,0)], 40, 12);

// ─── Screen ──────────────────────────────────────────────────────

class MiniGameScreen extends StatefulWidget {
  final String petPrefix;
  final Color? characterColor;
  final String? accessoryAsset;

  const MiniGameScreen({
    super.key,
    this.petPrefix = 'pet',
    this.characterColor,
    this.accessoryAsset,
  });

  @override
  State<MiniGameScreen> createState() => _MiniGameScreenState();
}

class _MiniGameScreenState extends State<MiniGameScreen>
    with SingleTickerProviderStateMixin {
  final _puzzles = [_puz1, _puz2, _puz3];
  int _level = 0;
  int _currentNode = -1;
  final Set<String> _usedEdges = {};
  bool _isComplete = false;
  bool _isStuck = false;
  bool _rewarded = false;
  Offset? _fingerPos;

  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  _Puzzle get _puzzle => _puzzles[_level];

  String _edgeKey(int a, int b) => a < b ? '$a-$b' : '$b-$a';

  bool _hasEdge(int a, int b) =>
      _puzzle.edges.any((e) => (e.$1 == a && e.$2 == b) || (e.$1 == b && e.$2 == a));

  bool _hasValidMove() {
    for (final e in _puzzle.edges) {
      if (!_usedEdges.contains(_edgeKey(e.$1, e.$2))) {
        if (e.$1 == _currentNode || e.$2 == _currentNode) return true;
      }
    }
    return false;
  }

  void _reset() {
    setState(() {
      _currentNode = -1;
      _usedEdges.clear();
      _isComplete = false;
      _isStuck = false;
      _rewarded = false;
      _fingerPos = null;
    });
  }

  void _handle(Offset localPos, Size canvasSize) {
    if (_isComplete) return;

    final rel = Offset(localPos.dx / canvasSize.width, localPos.dy / canvasSize.height);
    int nearest = -1;
    double minD = double.infinity;
    for (int i = 0; i < _puzzle.nodes.length; i++) {
      final d = (_puzzle.nodes[i] - rel).distance;
      if (d < 0.13 && d < minD) { minD = d; nearest = i; }
    }
    if (nearest == -1) return;

    if (_currentNode == -1) {
      setState(() { _currentNode = nearest; });
      HapticFeedback.lightImpact();
      return;
    }
    if (nearest == _currentNode) return;
    if (!_hasEdge(_currentNode, nearest)) return;
    final key = _edgeKey(_currentNode, nearest);
    if (_usedEdges.contains(key)) return;

    HapticFeedback.lightImpact();
    setState(() {
      _usedEdges.add(key);
      _currentNode = nearest;
      _fingerPos = null;

      if (_usedEdges.length == _puzzle.edges.length) {
        _isComplete = true;
        _bounceCtrl.forward(from: 0);
        _grantReward();
        HapticFeedback.heavyImpact();
      } else if (!_hasValidMove()) {
        _isStuck = true;
        HapticFeedback.mediumImpact();
      }
    });
  }

  Future<void> _grantReward() async {
    if (_rewarded) return;
    _rewarded = true;
    final result = await StorageService.addMiniGameReward(_puzzle.xpReward, _puzzle.coinReward);
    if (mounted && result.leveledUp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showLevelUpDialog(context, result.newLevel);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _bounceAnim = CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut);
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF38B8F0),
      appBar: AppBar(
        backgroundColor: Colors.white.withOpacity(0.92),
        elevation: 0,
        centerTitle: true,
        title: const Text('한붓그리기 ✏️',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF5A3210))),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF5A3210)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(children: [
        const SizedBox(height: 12),
        _buildLevelBar(),
        const SizedBox(height: 12),
        Expanded(child: _buildCanvas()),
        const SizedBox(height: 10),
        _buildBottomBar(),
        const SizedBox(height: 16),
      ]),
    );
  }

  Widget _buildLevelBar() {
    const labels = ['🏠 집\n쉬움', '⭐ 별\n보통', '🔷 육각\n어려움'];
    const xps = ['15XP', '25XP', '40XP'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(3, (i) => Expanded(
          child: GestureDetector(
            onTap: () { setState(() => _level = i); _reset(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: _level == i
                    ? const LinearGradient(colors: [Color(0xFFFFB6D9), Color(0xFFFF85B3)])
                    : null,
                color: _level == i ? null : Colors.white.withOpacity(0.75),
                borderRadius: BorderRadius.circular(16),
                boxShadow: _level == i
                    ? [BoxShadow(color: const Color(0xFFFF85B3).withOpacity(0.4), blurRadius: 8, offset: const Offset(0,3))]
                    : null,
              ),
              child: Column(children: [
                Text(labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _level == i ? Colors.white : const Color(0xFF5A3210),
                        height: 1.3)),
                const SizedBox(height: 3),
                Text(xps[i],
                    style: TextStyle(
                        fontSize: 10,
                        color: _level == i ? Colors.white70 : Colors.black38)),
              ]),
            ),
          ),
        )),
      ),
    );
  }

  Widget _buildCanvas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.94),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 5)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: LayoutBuilder(builder: (ctx, constraints) {
          final sz = constraints.biggest;
          return GestureDetector(
            onTapDown: (d) => _handle(d.localPosition, sz),
            onPanStart: (d) => _handle(d.localPosition, sz),
            onPanUpdate: (d) {
              _handle(d.localPosition, sz);
              if (!_isComplete) setState(() => _fingerPos = d.localPosition);
            },
            onPanEnd: (_) => setState(() => _fingerPos = null),
            child: Stack(children: [
              // Graph
              CustomPaint(
                painter: _GraphPainter(
                  puzzle: _puzzle,
                  usedEdges: _usedEdges,
                  currentNode: _currentNode,
                  fingerPos: _fingerPos,
                  isComplete: _isComplete,
                ),
                child: SizedBox.expand(),
              ),
              // Hint text
              if (_currentNode == -1)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const SizedBox(height: 60),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF85B3).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFFF85B3).withOpacity(0.3)),
                        ),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text('✏️ 동그라미를 눌러서 시작!',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFCC3366))),
                          const SizedBox(height: 4),
                          const Text('모든 선을 한 번씩만 그어보세요',
                              style: TextStyle(fontSize: 12, color: Colors.black45)),
                          if (_puzzle.validStarts.length < _puzzle.nodes.length) ...[
                            const SizedBox(height: 4),
                            Text('힌트: 굵은 테두리 노드에서 시작하세요',
                                style: TextStyle(fontSize: 11, color: Colors.orange[700], fontWeight: FontWeight.w600)),
                          ],
                        ]),
                      ),
                    ]),
                  ),
                ),
              // Character at current node
              if (_currentNode >= 0)
                Positioned(
                  left: _puzzle.nodes[_currentNode].dx * sz.width - 35,
                  top: _puzzle.nodes[_currentNode].dy * sz.height - 68,
                  child: IgnorePointer(
                    child: PetWidget(
                      state: _isComplete ? PetState.happy : PetState.normal,
                      size: 70,
                      petPrefix: widget.petPrefix,
                      characterColor: widget.characterColor,
                      accessoryAsset: widget.accessoryAsset,
                    ),
                  ),
                ),
              // Complete banner
              if (_isComplete)
                Positioned(
                  bottom: 24,
                  left: 0, right: 0,
                  child: Center(
                    child: ScaleTransition(
                      scale: _bounceAnim,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFFFB6D9), Color(0xFFD4AAFF)]),
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF85B3).withOpacity(0.5),
                              blurRadius: 18, spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Text('🎉 완성!',
                              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('+${_puzzle.xpReward}XP  +${_puzzle.coinReward}🪙',
                              style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ),
                ),
              // Stuck message
              if (_isStuck && !_isComplete)
                Positioned(
                  bottom: 20, left: 20, right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange[300]!),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text('😅 막혔어요! ',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                      GestureDetector(
                        onTap: _reset,
                        child: const Text('다시 시작하기 →',
                            style: TextStyle(color: Colors.deepOrange, decoration: TextDecoration.underline, fontWeight: FontWeight.bold)),
                      ),
                    ]),
                  ),
                ),
            ]),
          );
        }),
      ),
    );
  }

  Widget _buildBottomBar() {
    final total = _puzzle.edges.length;
    final done = _usedEdges.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              const Text('✏️', style: TextStyle(fontSize: 17)),
              const SizedBox(width: 8),
              Text('$done / $total',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Color(0xFFCC3366), fontSize: 15)),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: total > 0 ? done / total : 0,
                    backgroundColor: Colors.pink[50],
                    color: const Color(0xFFFF85B3),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text('선', style: TextStyle(fontSize: 12, color: Colors.black45)),
            ]),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _reset,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFB6D9), Color(0xFFFF85B3)]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFF85B3).withOpacity(0.4), blurRadius: 8, offset: const Offset(0,3)),
              ],
            ),
            child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
          ),
        ),
      ]),
    );
  }
}

// ─── Painter ─────────────────────────────────────────────────────

class _GraphPainter extends CustomPainter {
  final _Puzzle puzzle;
  final Set<String> usedEdges;
  final int currentNode;
  final Offset? fingerPos;
  final bool isComplete;

  const _GraphPainter({
    required this.puzzle,
    required this.usedEdges,
    required this.currentNode,
    required this.fingerPos,
    required this.isComplete,
  });

  String _key(int a, int b) => a < b ? '$a-$b' : '$b-$a';
  Offset _pos(int i, Size s) => Offset(puzzle.nodes[i].dx * s.width, puzzle.nodes[i].dy * s.height);

  void _drawDashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 7.0, gap = 5.0;
    final total = (b - a).distance;
    if (total == 0) return;
    final dir = (b - a) / total;
    double d = 0;
    bool drawing = true;
    while (d < total) {
      final seg = min(drawing ? dash : gap, total - d);
      if (drawing) canvas.drawLine(a + dir * d, a + dir * (d + seg), paint);
      d += seg;
      drawing = !drawing;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final unusedPaint = Paint()
      ..color = const Color(0xFFDDDDDD)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final usedPaint = Paint()
      ..color = const Color(0xFFFF85B3)
      ..strokeWidth = 5.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw edges
    for (final e in puzzle.edges) {
      final a = _pos(e.$1, size), b = _pos(e.$2, size);
      final used = usedEdges.contains(_key(e.$1, e.$2));
      canvas.drawLine(a, b, used ? usedPaint : unusedPaint);
    }

    // Preview line (finger to current node)
    if (fingerPos != null && currentNode >= 0 && !isComplete) {
      final curPos = _pos(currentNode, size);
      final previewPaint = Paint()
        ..color = const Color(0xFFFF85B3).withOpacity(0.35)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      _drawDashed(canvas, curPos, fingerPos!, previewPaint);
    }

    // Draw nodes
    final validStarts = puzzle.validStarts;
    for (int i = 0; i < puzzle.nodes.length; i++) {
      final pos = _pos(i, size);
      final isCurrent = i == currentNode;
      final isValidStart = currentNode == -1 && validStarts.contains(i) &&
          validStarts.length < puzzle.nodes.length;

      // Outer glow for current node
      if (isCurrent) {
        canvas.drawCircle(pos, 28,
            Paint()..color = const Color(0xFFFF85B3).withOpacity(0.18));
      }

      // Valid start indicator (pulsing ring)
      if (isValidStart) {
        canvas.drawCircle(pos, 22,
            Paint()
              ..color = Colors.orange.withOpacity(0.25)
              ..style = PaintingStyle.fill);
        canvas.drawCircle(pos, 22,
            Paint()
              ..color = Colors.orange
              ..strokeWidth = 2.5
              ..style = PaintingStyle.stroke);
      }

      // Node fill
      canvas.drawCircle(pos, isCurrent ? 19 : 15,
          Paint()..color = isCurrent ? const Color(0xFFFF85B3) : Colors.white);

      // Node border
      canvas.drawCircle(pos, isCurrent ? 19 : 15,
          Paint()
            ..color = isCurrent ? const Color(0xFFCC3366) : const Color(0xFFCCCCCC)
            ..strokeWidth = isCurrent ? 3 : 2
            ..style = PaintingStyle.stroke);

      // Node number
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: isCurrent ? Colors.white : Colors.grey[400],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(_GraphPainter old) =>
      old.usedEdges.length != usedEdges.length ||
      old.currentNode != currentNode ||
      old.fingerPos != fingerPos ||
      old.isComplete != isComplete;
}
