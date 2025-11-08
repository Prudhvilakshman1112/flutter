// main.dart
// Algorithm Visualizer Lite — Responsive version (single-file)
// Keeps all features: algorithms, binary target, play/step/speed, export
// Responsive: wide / medium / narrow breakpoints

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// ---------- Models & Actions ----------
enum ActionType { compare, swap, assign, markSorted, highlight, rangeUpdate }

class AlgoAction {
  final ActionType type;
  final int a;
  final int b;
  final String note;
  AlgoAction({required this.type, required this.a, required this.b, this.note = ''});
  @override
  String toString() {
    final mid = (type == ActionType.assign && b >= 0) ? '= $b' : (b >= 0 ? '<-> $b' : '');
    return '${type.name.toUpperCase()}: $a $mid ${note.isNotEmpty ? '// $note' : ''}';
  }
}

// ---------- State ----------
class VisualizerState extends ChangeNotifier {
  List<int> values = [];
  List<int> displayValues = [];
  List<AlgoAction> actions = [];
  int actionIndex = -1;

  bool playing = false;
  double speed = 1.0;
  String selectedAlgo = 'Bubble Sort';
  String codeText = '';
  int highlightLine = -1;
  int comparisons = 0;
  int swaps = 0;

  int bsL = -1, bsR = -1;
  int? binaryTarget;

  List<int>? _initialSnapshot;
  Timer? _playTimer;
  bool _animating = false;

  VisualizerState() {
    _seedRandom(12);
    setAlgorithm('Bubble Sort', generate: false);
  }

  void _seedRandom(int n) {
    final rnd = Random();
    values = List.generate(n, (_) => 20 + rnd.nextInt(180));
    displayValues = List<int>.from(values);
    actions = [];
    actionIndex = -1;
    comparisons = 0;
    swaps = 0;
    bsL = bsR = -1;
    binaryTarget = null;
    notifyListeners();
  }

  void randomize(int n) {
    _seedRandom(n);
  }

  void setAlgorithm(String name, {bool generate = true}) {
    selectedAlgo = name;
    switch (name) {
      case 'Bubble Sort':
        codeText = _bubbleCode;
        break;
      case 'Selection Sort':
        codeText = _selectionCode;
        break;
      case 'Insertion Sort':
        codeText = _insertionCode;
        break;
      case 'Binary Search':
        codeText = _binaryCode;
        values = List<int>.from(values)..sort();
        displayValues = List<int>.from(values);
        break;
      default:
        codeText = '';
    }
    actions = [];
    actionIndex = -1;
    highlightLine = -1;
    comparisons = 0;
    swaps = 0;
    bsL = bsR = -1;
    if (generate) generateActions();
    notifyListeners();
  }

  void setValuesFromList(List<int> list) {
    values = List<int>.from(list);
    displayValues = List<int>.from(list);
    actions = [];
    actionIndex = -1;
    comparisons = swaps = 0;
    bsL = bsR = -1;
    notifyListeners();
  }

  void setBinaryTarget(int? target, {bool regenerate = true}) {
    binaryTarget = target;
    if (selectedAlgo == 'Binary Search') {
      values = List<int>.from(values)..sort();
      displayValues = List<int>.from(values);
    }
    if (regenerate) generateActions(); else notifyListeners();
  }

  void generateActions() {
    actions = [];
    comparisons = 0;
    swaps = 0;
    bsL = bsR = -1;
    List<int> arr = List<int>.from(values);
    if (selectedAlgo == 'Binary Search') {
      arr = List<int>.from(arr)..sort();
      setValuesFromList(arr);
    }
    switch (selectedAlgo) {
      case 'Bubble Sort':
        _genBubble(arr);
        break;
      case 'Selection Sort':
        _genSelection(arr);
        break;
      case 'Insertion Sort':
        _genInsertion(arr);
        break;
      case 'Binary Search':
        final t = binaryTarget ?? (arr.isNotEmpty ? arr[arr.length ~/ 2] : 0);
        _genBinarySearch(arr, t);
        break;
    }
    actionIndex = -1;
    highlightLine = -1;
    _initialSnapshot = List<int>.from(displayValues);
    notifyListeners();
  }

  void stepForward() {
    if (_animating) return;
    if (actionIndex + 1 >= actions.length) return;
    actionIndex++;
    _applyActionAnimated(actions[actionIndex]);
  }

  void stepBackward() {
    if (_animating) return;
    if (actionIndex < 0) return;
    actionIndex--;
    _rebuildFromSnapshot();
  }

  void _rebuildFromSnapshot() {
    if (_initialSnapshot == null) return;
    final arr = List<int>.from(_initialSnapshot!);
    bsL = bsR = -1;
    comparisons = swaps = 0;
    for (int i = 0; i <= actionIndex; i++) {
      final a = actions[i];
      if (a.type == ActionType.swap) {
        final tmp = arr[a.a];
        arr[a.a] = arr[a.b];
        arr[a.b] = tmp;
        swaps++;
      } else if (a.type == ActionType.assign) {
        arr[a.a] = a.b;
      } else if (a.type == ActionType.compare) {
        comparisons++;
      } else if (a.type == ActionType.rangeUpdate) {
        bsL = a.a; bsR = a.b;
      }
    }
    values = List<int>.from(arr);
    displayValues = List<int>.from(arr);
    highlightLine = (actionIndex >= 0 && actionIndex < actions.length) ? _lineForAction(actions[actionIndex]) : -1;
    notifyListeners();
  }

  void play() {
    if (playing) return;
    if (actions.isEmpty) generateActions();
    playing = true;
    _startTimer();
    notifyListeners();
  }

  void stop() {
    playing = false;
    _playTimer?.cancel();
    _playTimer = null;
    notifyListeners();
  }

  void _startTimer() {
    _playTimer?.cancel();
    final ms = max(40, (700 / (speed.clamp(0.3, 3.0))).round());
    _playTimer = Timer.periodic(Duration(milliseconds: ms), (_) {
      if (!playing) { _playTimer?.cancel(); _playTimer = null; return; }
      if (actionIndex + 1 >= actions.length) { stop(); return; }
      stepForward();
    });
  }

  void setSpeed(double s) {
    speed = s;
    if (playing) _startTimer(); else notifyListeners();
  }

  void reset() {
    stop();
    if (_initialSnapshot != null) {
      values = List<int>.from(_initialSnapshot!);
      displayValues = List<int>.from(_initialSnapshot!);
    }
    actionIndex = -1;
    highlightLine = -1;
    comparisons = 0;
    swaps = 0;
    bsL = bsR = -1;
    notifyListeners();
  }

  String exportStepsText() {
    final b = StringBuffer();
    b.writeln('Algorithm: $selectedAlgo');
    b.writeln('Initial array: ${_initialSnapshot ?? displayValues}');
    b.writeln('Actions (${actions.length}):');
    for (int i = 0; i < actions.length; i++) b.writeln('${i + 1}. ${actions[i].toString()}');
    b.writeln('Comparisons: $comparisons, Swaps: $swaps');
    return b.toString();
  }

  Future<void> _applyActionAnimated(AlgoAction a) async {
    if (a.type == ActionType.swap) {
      await _animateSwap(a.a, a.b);
      swaps++;
      highlightLine = _lineForAction(a);
      notifyListeners();
    } else if (a.type == ActionType.assign) {
      await _animateAssign(a.a, a.b);
      highlightLine = _lineForAction(a);
      notifyListeners();
    } else if (a.type == ActionType.compare) {
      highlightLine = _lineForAction(a);
      comparisons++;
      notifyListeners();
      await Future.delayed(Duration(milliseconds: max(40, (220 ~/ speed))));
    } else if (a.type == ActionType.markSorted) {
      highlightLine = _lineForAction(a);
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 120));
    } else if (a.type == ActionType.highlight) {
      highlightLine = _lineForAction(a);
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 180));
    } else if (a.type == ActionType.rangeUpdate) {
      bsL = a.a; bsR = a.b;
      highlightLine = _lineForAction(a);
      notifyListeners();
      await Future.delayed(Duration(milliseconds: max(40, (180 ~/ speed))));
    }
  }

  Future<void> _animateSwap(int i, int j) async {
    if (_animating) return;
    _animating = true;
    final aVal = displayValues[i]; final bVal = displayValues[j];
    final durationMs = max(80, (260 ~/ speed));
    final steps = (durationMs / 16).ceil();
    for (int s = 1; s <= steps; s++) {
      final t = s / steps;
      displayValues[i] = (aVal + (bVal - aVal) * t).round();
      displayValues[j] = (bVal + (aVal - bVal) * t).round();
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 16));
    }
    final tmp = values[i]; values[i] = values[j]; values[j] = tmp;
    displayValues[i] = values[i]; displayValues[j] = values[j];
    _animating = false;
  }

  Future<void> _animateAssign(int index, int newVal) async {
    if (_animating) return;
    _animating = true;
    final oldVal = displayValues[index];
    final durationMs = max(80, (260 ~/ speed));
    final steps = (durationMs / 16).ceil();
    for (int s = 1; s <= steps; s++) {
      final t = s / steps;
      displayValues[index] = (oldVal + (newVal - oldVal) * t).round();
      notifyListeners();
      await Future.delayed(const Duration(milliseconds: 16));
    }
    values[index] = newVal; displayValues[index] = newVal;
    _animating = false;
  }

  int _lineForAction(AlgoAction a) {
    switch (selectedAlgo) {
      case 'Bubble Sort':
        if (a.type == ActionType.compare) return 3; if (a.type == ActionType.swap) return 4; return 1;
      case 'Selection Sort':
        if (a.type == ActionType.compare) return 4; if (a.type == ActionType.swap) return 5; return 1;
      case 'Insertion Sort':
        if (a.type == ActionType.compare) return 4; if (a.type == ActionType.assign) return 5; return 1;
      case 'Binary Search':
        if (a.type == ActionType.rangeUpdate) return 2; if (a.type == ActionType.compare) return 3; if (a.type == ActionType.highlight) return 4; return 1;
      default:
        return 1;
    }
  }

  void _genBubble(List<int> arr) {
    _initialSnapshot = List<int>.from(arr); final n = arr.length;
    for (int i = 0; i < n - 1; i++) {
      for (int j = 0; j < n - i - 1; j++) {
        actions.add(AlgoAction(type: ActionType.compare, a: j, b: j + 1, note: 'compare'));
        if (arr[j] > arr[j + 1]) {
          actions.add(AlgoAction(type: ActionType.swap, a: j, b: j + 1, note: 'swap'));
          final tmp = arr[j]; arr[j] = arr[j + 1]; arr[j + 1] = tmp;
        }
      }
      actions.add(AlgoAction(type: ActionType.markSorted, a: n - i - 1, b: -1, note: 'sorted'));
    }
  }

  void _genSelection(List<int> arr) {
    _initialSnapshot = List<int>.from(arr); final n = arr.length;
    for (int i = 0; i < n - 1; i++) {
      int minIdx = i;
      for (int j = i + 1; j < n; j++) {
        actions.add(AlgoAction(type: ActionType.compare, a: minIdx, b: j, note: 'compare'));
        if (arr[j] < arr[minIdx]) minIdx = j;
      }
      if (minIdx != i) {
        actions.add(AlgoAction(type: ActionType.swap, a: i, b: minIdx, note: 'swap'));
        final tmp = arr[i]; arr[i] = arr[minIdx]; arr[minIdx] = tmp;
      }
      actions.add(AlgoAction(type: ActionType.markSorted, a: i, b: -1, note: 'fixed'));
    }
    actions.add(AlgoAction(type: ActionType.markSorted, a: n - 1, b: -1, note: 'last'));
  }

  void _genInsertion(List<int> arr) {
    _initialSnapshot = List<int>.from(arr); final n = arr.length;
    for (int i = 1; i < n; i++) {
      final key = arr[i]; int j = i - 1;
      actions.add(AlgoAction(type: ActionType.highlight, a: i, b: -1, note: 'key'));
      while (j >= 0) {
        actions.add(AlgoAction(type: ActionType.compare, a: j, b: i, note: 'compare'));
        if (arr[j] > key) {
          actions.add(AlgoAction(type: ActionType.assign, a: j + 1, b: arr[j], note: 'shift'));
          arr[j + 1] = arr[j]; j--;
        } else break;
      }
      actions.add(AlgoAction(type: ActionType.assign, a: j + 1, b: key, note: 'insert'));
      arr[j + 1] = key;
    }
  }

  void _genBinarySearch(List<int> arr, int target) {
    _initialSnapshot = List<int>.from(arr);
    int l = 0, r = arr.length - 1;
    while (l <= r) {
      final mid = (l + r) >> 1;
      actions.add(AlgoAction(type: ActionType.rangeUpdate, a: l, b: r, note: 'range'));
      actions.add(AlgoAction(type: ActionType.compare, a: mid, b: -1, note: 'compare mid'));
      if (arr[mid] == target) {
        actions.add(AlgoAction(type: ActionType.highlight, a: mid, b: -1, note: 'found')); return;
      } else if (arr[mid] < target) l = mid + 1; else r = mid - 1;
    }
    actions.add(AlgoAction(type: ActionType.highlight, a: -1, b: -1, note: 'not found'));
  }
}

// ---------- pseudo code strings ----------
const _bubbleCode = '''
1 for i = 0 to n-2
2   for j = 0 to n-i-2
3     if arr[j] > arr[j+1] then
4       swap arr[j], arr[j+1]
5   mark arr[n-i-1] as sorted
''';
const _selectionCode = '''
1 for i = 0 to n-2
2   minIdx = i
3   for j = i+1 to n-1
4     if arr[j] < arr[minIdx] then minIdx = j
5   if minIdx != i then swap arr[i], arr[minIdx]
6   mark i as sorted
''';
const _insertionCode = '''
1 for i = 1 to n-1
2   key = arr[i]
3   j = i - 1
4   while j >= 0 and arr[j] > key
5     arr[j+1] = arr[j]
6     j = j - 1
7   arr[j+1] = key
''';
const _binaryCode = '''
1 l = 0, r = n-1
2 while l <= r
3   mid = (l+r)/2
4   if arr[mid] == target -> found
5   else if arr[mid] < target -> l = mid+1
6   else r = mid-1
''';

// ---------- App entry ----------
void main() => runApp(const AlgoVisualizerApp());

class AlgoVisualizerApp extends StatelessWidget {
  const AlgoVisualizerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Algorithm Visualizer — Responsive',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: _ProviderHost(child: const VisualizerHome()),
    );
  }
}

class _ProviderHost extends InheritedWidget {
  final VisualizerState state = VisualizerState();
  _ProviderHost({super.key, required Widget child}) : super(child: child);
  static VisualizerState of(BuildContext c) {
    final host = c.dependOnInheritedWidgetOfExactType<_ProviderHost>();
    assert(host != null, 'ProviderHost missing');
    return host!.state;
  }
  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}

// ---------- UI: Home ----------
class VisualizerHome extends StatefulWidget {
  const VisualizerHome({super.key});
  @override
  State<VisualizerHome> createState() => _VisualizerHomeState();
}

class _VisualizerHomeState extends State<VisualizerHome> with TickerProviderStateMixin {
  VisualizerState? state;
  late final AnimationController _bgPulse;
  @override
  void initState() {
    super.initState();
    _bgPulse = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    state ??= _ProviderHost.of(context);
  }
  @override
  void dispose() { _bgPulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final st = state!;
    return Scaffold(
      body: Stack(children: [
        AnimatedBuilder(animation: _bgPulse, builder: (_, __) => CustomPaint(painter: _SubtleBackground(t: _bgPulse.value))),
        SafeArea(
          child: LayoutBuilder(builder: (ctx, bc) {
            final width = bc.maxWidth;
            final isWide = width >= 1000;
            final isMedium = width >= 700 && width < 1000;
            final isNarrow = width < 700;
            // top padding scales
            final outerPad = isNarrow ? 8.0 : (isMedium ? 12.0 : 16.0);
            final sidePad = isNarrow ? 8.0 : 14.0;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: sidePad, vertical: outerPad),
              child: Column(children: [
                _buildTopBar(st, isNarrow),
                SizedBox(height: isNarrow ? 8 : 12),
                Expanded(
                  child: isWide
                      ? Row(children: [Expanded(flex: 3, child: _visualPanel(st, isNarrow)), SizedBox(width: 12), SizedBox(width: 420, child: _rightPanel(st, width))])
                      : Column(children: [Expanded(child: _visualPanel(st, isNarrow)), SizedBox(height: 12), if (!isNarrow) SizedBox(height: 360, child: _rightPanel(st, width))]),
                ),
                SizedBox(height: isNarrow ? 6 : 12),
                _controlRow(st, isNarrow),
              ]),
            );
          }),
        ),
      ]),
      // floating action: open right panel on narrow screens
      floatingActionButton: Builder(builder: (ctx) {
        final w = MediaQuery.of(ctx).size.width;
        if (w >= 700) return const SizedBox.shrink();
        return FloatingActionButton.small(
          tooltip: 'Controls & Options',
          onPressed: () => _showRightPanelSheet(ctx, state!),
          child: const Icon(Icons.tune),
        );
      }),
    );
  }

  Widget _buildTopBar(VisualizerState st, bool isNarrow) {
    return Row(children: [
      Text('Algorithm Visualizer', style: TextStyle(fontSize: isNarrow ? 16 : 20, fontWeight: FontWeight.bold)),
      const Spacer(),
      Row(children: [
        FilledButton.tonal(onPressed: () { if (st.actions.isEmpty) st.generateActions(); _showExport(st); }, child: const Text('Export')),
        SizedBox(width: isNarrow ? 6 : 12),
        IconButton(onPressed: () => st.randomize(12), icon: const Icon(Icons.shuffle)),
      ])
    ]);
  }

  Widget _visualPanel(VisualizerState st, bool isCompact) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 10 : 14),
        child: Column(children: [
          Row(children: [
            AnimatedBuilder(animation: st, builder: (_, __) => Text(st.selectedAlgo, style: TextStyle(fontSize: isCompact ? 16 : 18, fontWeight: FontWeight.bold))),
            const SizedBox(width: 8),
            AnimatedBuilder(animation: st, builder: (_, __) => st.selectedAlgo == 'Binary Search' ? Chip(label: Text('Target: ${st.binaryTarget ?? "auto"}')) : const SizedBox.shrink()),
            const Spacer(),
            AnimatedBuilder(animation: st, builder: (_, __) => Text('Items: ${st.displayValues.length}', style: TextStyle(color: Colors.grey.shade600))),
          ]),
          SizedBox(height: isCompact ? 8 : 12),
          _arrayEditor(st, isCompact),
          SizedBox(height: isCompact ? 8 : 12),
          Expanded(child: AnimatedBuilder(animation: st, builder: (_, __) {
            return LayoutBuilder(builder: (c, bc) {
              // let painter adapt: pass available width
              return CustomPaint(
                painter: _BarsPainterResponsive(
                  values: st.displayValues,
                  actions: st.actions,
                  actionIndex: st.actionIndex,
                  bsL: st.bsL,
                  bsR: st.bsR,
                  highlightLine: st.highlightLine,
                  target: st.binaryTarget,
                  availableWidth: bc.maxWidth,
                ),
                size: Size.infinite,
              );
            });
          })),
          SizedBox(height: isCompact ? 6 : 10),
          _miniLegend(st),
        ]),
      ),
    );
  }

  Widget _arrayEditor(VisualizerState st, bool compact) {
    return Row(children: [
      Expanded(
        child: SizedBox(
          height: compact ? 70 : 88,
          child: AnimatedBuilder(animation: st, builder: (_, __) {
            final vs = st.displayValues;
            return ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: vs.length,
              separatorBuilder: (_, __) => SizedBox(width: compact ? 6 : 8),
              itemBuilder: (ctx, i) => GestureDetector(
                onTap: () => _editValue(st, i),
                onVerticalDragUpdate: (d) {
                  final delta = -d.delta.dy ~/ 2;
                  final newVal = (st.values[i] + delta).clamp(5, 400);
                  st.values[i] = newVal; st.displayValues[i] = newVal; st.notifyListeners();
                },
                child: Container(
                  width: compact ? 58 : 72,
                  padding: EdgeInsets.symmetric(vertical: compact ? 6 : 8, horizontal: 6),
                  margin: EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black12)),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text('i:$i', style: TextStyle(color: Colors.grey.shade600, fontSize: compact ? 11 : 12)), SizedBox(height: 6), Text('${vs[i]}', style: const TextStyle(fontWeight: FontWeight.bold))]),
                ),
              ),
            );
          }),
        ),
      ),
      SizedBox(width: compact ? 8 : 12),
      Column(children: [
        FilledButton.icon(onPressed: () {
          final rnd = Random();
          st.values.add(20 + rnd.nextInt(200));
          st.displayValues = List<int>.from(st.values);
          st.notifyListeners();
        }, icon: const Icon(Icons.add), label: const Text('Add')),
        SizedBox(height: 6),
        OutlinedButton.icon(onPressed: () {
          if (st.values.isNotEmpty) {
            st.values.removeLast();
            st.displayValues = List<int>.from(st.values);
            st.notifyListeners();
          }
        }, icon: const Icon(Icons.remove), label: const Text('Remove')),
      ])
    ]);
  }

  Widget _rightPanel(VisualizerState st, double availableWidth) {
    final compact = availableWidth < 420;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.all(compact ? 10 : 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Algorithm', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            AnimatedBuilder(animation: st, builder: (_, __) => DropdownButton<String>(
              value: st.selectedAlgo,
              items: ['Bubble Sort', 'Selection Sort', 'Insertion Sort', 'Binary Search'].map((a) => DropdownMenuItem(value: a, child: Text(a))).toList(),
              onChanged: (v) { if (v == null) return; st.setAlgorithm(v, generate: false); if (v == 'Binary Search') st.setValuesFromList(List.from(st.values)..sort()); st.generateActions(); },
            )),
            const Spacer(),
            FilledButton(onPressed: () { st.generateActions(); }, child: const Text('Generate')),
          ]),
          SizedBox(height: 12),
          AnimatedBuilder(animation: st, builder: (_, __) {
            if (st.selectedAlgo != 'Binary Search') return const SizedBox.shrink();
            return Row(children: [
              const Text('Target:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              Text(st.binaryTarget?.toString() ?? 'auto', style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => _showSetTargetDialog(st),
                style: FilledButton.styleFrom(minimumSize: const Size(64, 36), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                child: const Text('Set'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () { st.setBinaryTarget(null); },
                style: OutlinedButton.styleFrom(minimumSize: const Size(64, 36), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                child: const Text('Auto'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () { // random pick from array
                if (st.values.isNotEmpty) st.setBinaryTarget(st.values[Random().nextInt(st.values.length)]);
              }, child: const Text('Pick')),
            ]);
          }),
          const SizedBox(height: 12),
          const Text('Pseudo-code', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Expanded(child: AnimatedBuilder(animation: st, builder: (_, __) => _PseudoCode(code: st.codeText, highlightLine: st.highlightLine))),
          const SizedBox(height: 12),
          Row(children: [
            OutlinedButton(onPressed: () { _showSamples(st); }, child: const Text('Samples')),
            const SizedBox(width: 8),
            OutlinedButton(onPressed: () { st.reset(); }, child: const Text('Reset')),
          ]),
        ]),
      ),
    );
  }

  Widget _miniLegend(VisualizerState st) {
    return AnimatedBuilder(animation: st, builder: (_, __) => Row(children: [
      _dotLbl(Colors.orange, 'Compare'),
      SizedBox(width: 12),
      _dotLbl(Colors.blue, 'Swap'),
      SizedBox(width: 12),
      _dotLbl(Colors.green, 'Sorted'),
      SizedBox(width: 12),
      Expanded(child: Text('Comparisons: ${st.comparisons}   Swaps: ${st.swaps}', style: const TextStyle(fontSize: 12))),
    ]));
  }

  Widget _dotLbl(Color c, String t) => Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(4))), const SizedBox(width: 6), Text(t)]);

  Widget _controlRow(VisualizerState st, bool compact) {
    return AnimatedBuilder(animation: st, builder: (_, __) {
      final atStart = st.actionIndex < 0;
      final atEnd = st.actionIndex + 1 >= st.actions.length;
      return Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 8 : 10),
        decoration: BoxDecoration(color: Theme.of(context).canvasColor.withOpacity(0.02), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          IconButton(onPressed: atStart ? null : () => st.stepBackward(), icon: const Icon(Icons.skip_previous)),
          IconButton(onPressed: () => st.playing ? st.stop() : st.play(), icon: Icon(st.playing ? Icons.pause_circle_filled : Icons.play_circle)),
          IconButton(onPressed: atEnd ? null : () => st.stepForward(), icon: const Icon(Icons.skip_next)),
          SizedBox(width: compact ? 8 : 12),
          const Text('Speed', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Expanded(child: Slider(value: st.speed, min: 0.3, max: 3.0, divisions: 14, label: '${st.speed.toStringAsFixed(2)}x', onChanged: (v) => st.setSpeed(v))),
          SizedBox(width: compact ? 8 : 12),
          FilledButton.tonal(onPressed: () { if (st.actions.isEmpty) st.generateActions(); _showExport(st); }, child: const Text('Steps')),
        ]),
      );
    });
  }

  // ---------- Helpers (dialogs/sheets) ----------
  void _showRightPanelSheet(BuildContext ctx, VisualizerState st) {
    showModalBottomSheet(context: ctx, isScrollControlled: true, builder: (_) => FractionallySizedBox(
      heightFactor: 0.88,
      child: Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom), child: _rightPanel(st, MediaQuery.of(ctx).size.width)),
    ));
  }

  void _showExport(VisualizerState st) {
    if (st.actions.isEmpty) st.generateActions();
    showModalBottomSheet(context: context, isScrollControlled: true, builder: (ctx) {
      final text = st.exportStepsText();
      return Padding(
        padding: EdgeInsets.only(left: 12, right: 12, top: 12, bottom: MediaQuery.of(ctx).viewInsets.bottom + 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [const Text('Exported Steps', style: TextStyle(fontWeight: FontWeight.bold)), const Spacer(), IconButton(onPressed: () { Navigator.pop(ctx); }, icon: const Icon(Icons.copy))]),
          const SizedBox(height: 8),
          Container(width: double.infinity, constraints: const BoxConstraints(maxHeight: 500), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(10)), child: SingleChildScrollView(padding: const EdgeInsets.all(12), child: SelectableText(text, style: const TextStyle(fontFamily: 'monospace')))),
          const SizedBox(height: 10),
        ]),
      );
    });
  }

  void _showSamples(VisualizerState st) {
    showModalBottomSheet(context: context, builder: (_) => Padding(padding: const EdgeInsets.all(12.0), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Sample arrays', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        ActionChip(label: const Text('Random small'), onPressed: () { st.randomize(8); Navigator.pop(context); }),
        ActionChip(label: const Text('Random medium'), onPressed: () { st.randomize(14); Navigator.pop(context); }),
        ActionChip(label: const Text('Nearly sorted'), onPressed: () { st.setValuesFromList([10,12,15,18,22,30,28,35,37,40]); Navigator.pop(context); }),
        ActionChip(label: const Text('Reverse'), onPressed: () { st.setValuesFromList([90,80,70,60,50,40,30]); Navigator.pop(context); }),
        ActionChip(label: const Text('Duplicates'), onPressed: () { st.setValuesFromList([20,90,20,20,45,90,20,60]); Navigator.pop(context); }),
      ]),
      const SizedBox(height: 12),
    ])));
  }

  Future<void> _editValue(VisualizerState st, int idx) async {
    final ctrl = TextEditingController(text: st.values[idx].toString());
    await showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Edit index $idx'),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          final v = int.tryParse(ctrl.text.trim());
          if (v != null) { st.values[idx] = v.clamp(5, 400); st.displayValues[idx] = st.values[idx]; st.notifyListeners(); }
          Navigator.pop(context);
        }, child: const Text('Save')),
      ],
    ));
  }

  Future<void> _showSetTargetDialog(VisualizerState st) async {
    final ctrl = TextEditingController(text: st.binaryTarget?.toString() ?? '');
    await showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Set Binary Search Target'),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Enter integer')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: () {
          final v = int.tryParse(ctrl.text.trim());
          st.setBinaryTarget(v);
          Navigator.pop(context);
        }, child: const Text('Set')),
      ],
    ));
  }
}

// ---------- Responsive Bars Painter ----------
class _BarsPainterResponsive extends CustomPainter {
  final List<int> values;
  final List<AlgoAction> actions;
  final int actionIndex;
  final int bsL, bsR;
  final int highlightLine;
  final int? target;
  final double availableWidth;
  _BarsPainterResponsive({required this.values, required this.actions, required this.actionIndex, required this.bsL, required this.bsR, required this.highlightLine, required this.availableWidth, this.target});

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n == 0) return;

    // adaptive gap & bar width clamping
    final targetBarWidth = (availableWidth - (n + 1) * 8) / n;
    final w = targetBarWidth.clamp(22.0, 80.0);
    final gap = ((availableWidth - n * w) / (n + 1)).clamp(6.0, 20.0);

    final maxVal = values.isEmpty ? 1 : values.reduce(max).toDouble();
    final baseY = size.height;
    final r = 8.0;

    if (bsL >= 0 && bsR >= bsL) {
      final leftX = gap + bsL * (w + gap);
      final rightX = gap + bsR * (w + gap) + w;
      final rect = Rect.fromLTRB(leftX, 0, rightX, size.height);
      final paint = Paint()..color = Colors.yellow.withOpacity(0.06);
      canvas.drawRect(rect, paint);
    }

    for (int i = 0; i < n; i++) {
      final x = gap + i * (w + gap);
      final h = (values[i] / maxVal) * (size.height - 40);
      final y = baseY - h;

      Color color = Color.lerp(Colors.indigo.shade300, Colors.pink.shade100, i / max(1, n - 1))!;
      double border = 1.0;
      if (actionIndex >= 0 && actionIndex < actions.length) {
        final a = actions[actionIndex];
        if (a.type == ActionType.compare && (a.a == i || a.b == i)) { color = Colors.orange; border = 2.0; }
        else if (a.type == ActionType.swap && (a.a == i || a.b == i)) { color = Colors.blue; border = 2.0; }
        else if (a.type == ActionType.markSorted && a.a == i) { color = Colors.green; border = 2.0; }
        else if (a.type == ActionType.assign && a.a == i) { color = Colors.purple; border = 2.0; }
      }

      if (target != null && values[i] == target) { color = Colors.amber; border = 2.5; }

      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r));
      final paint = Paint()..shader = LinearGradient(colors: [color.withOpacity(0.95), color.withOpacity(0.6)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Rect.fromLTWH(x, y, w, h));
      canvas.drawRRect(rect, paint);

      final stroke = Paint()..style = PaintingStyle.stroke..strokeWidth = border..color = Colors.black.withOpacity(0.08);
      canvas.drawRRect(rect, stroke);

      final tp = TextPainter(text: TextSpan(text: '${values[i]}', style: TextStyle(color: Colors.black.withOpacity(0.85), fontSize: max(10, min(14, w / 5)))), textDirection: TextDirection.ltr)..layout(maxWidth: w);
      tp.paint(canvas, Offset(x + (w - tp.width) / 2, y - 18));

      final idxTp = TextPainter(text: TextSpan(text: '$i', style: TextStyle(color: Colors.black.withOpacity(0.45), fontSize: max(9, min(12, w / 6)))), textDirection: TextDirection.ltr)..layout(maxWidth: w);
      idxTp.paint(canvas, Offset(x + (w - idxTp.width) / 2, size.height - 14));
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainterResponsive old) => old.values != values || old.actionIndex != actionIndex || old.actions != actions || old.bsL != bsL || old.bsR != bsR || old.highlightLine != highlightLine || old.target != target || old.availableWidth != availableWidth;
}

// ---------- Pseudo-code widget ----------
class _PseudoCode extends StatelessWidget {
  final String code; final int highlightLine;
  const _PseudoCode({required this.code, required this.highlightLine});
  @override
  Widget build(BuildContext context) {
    final lines = code.trim().split('\n');
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Theme.of(context).cardColor),
      child: ListView.builder(itemCount: lines.length, itemBuilder: (ctx, i) {
        final isH = highlightLine == i + 1;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(color: isH ? Theme.of(context).colorScheme.primary.withOpacity(0.12) : Colors.transparent, borderRadius: BorderRadius.circular(6)),
          child: Row(children: [SizedBox(width: 28, child: Text('${i + 1}', style: TextStyle(color: isH ? Theme.of(context).colorScheme.primary : Colors.grey, fontWeight: isH ? FontWeight.bold : FontWeight.normal))), Expanded(child: Text(lines[i].trim(), style: const TextStyle(fontFamily: 'monospace', fontSize: 13)))]),
        );
      }),
    );
  }
}

// ---------- Subtle background ----------
class _SubtleBackground extends CustomPainter {
  final double t; _SubtleBackground({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..shader = LinearGradient(colors: [Colors.indigo.shade900, Colors.indigo.shade700], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(rect);
    canvas.drawRect(rect, paint);
    final blobPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
    final c1 = Offset(size.width * (0.2 + 0.02 * sin(t * 2 * pi)), size.height * (0.25 + 0.02 * cos(t * 2 * pi)));
    blobPaint.shader = RadialGradient(colors: [Colors.cyan.withOpacity(0.06), Colors.transparent]).createShader(Rect.fromCircle(center: c1, radius: 220));
    canvas.drawCircle(c1, 220, blobPaint);
    final c2 = Offset(size.width * (0.78 + 0.02 * cos(t * 2 * pi)), size.height * (0.72 + 0.02 * sin(t * 2 * pi)));
    blobPaint.shader = RadialGradient(colors: [Colors.pink.withOpacity(0.05), Colors.transparent]).createShader(Rect.fromCircle(center: c2, radius: 200));
    canvas.drawCircle(c2, 200, blobPaint);
  }
  @override
  bool shouldRepaint(covariant _SubtleBackground old) => old.t != t;
}
