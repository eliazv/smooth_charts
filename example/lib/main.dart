import 'package:flutter/material.dart';
import 'package:smooth_charts/smooth_charts.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'smooth_charts example',
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const _HomePage(),
    );
  }
}

class _HomePage extends StatefulWidget {
  const _HomePage();

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  String? _selectedPieId;
  int _pieReplayToken = 0;
  int _lineReplayToken = 0;
  int _multiLineReplayToken = 0;

  static final _pieItems = [
    SmoothPieChartItem(
      id: 'food',
      value: 320,
      color: Colors.orange,
      label: 'Food',
      icon: const Icon(Icons.fastfood, size: 20),
    ),
    SmoothPieChartItem(
      id: 'rent',
      value: 850,
      color: Colors.blue,
      label: 'Rent',
      icon: const Icon(Icons.home, size: 20),
    ),
    SmoothPieChartItem(
      id: 'transport',
      value: 180,
      color: Colors.green,
      label: 'Transport',
      icon: const Icon(Icons.directions_car, size: 20),
    ),
    SmoothPieChartItem(
      id: 'health',
      value: 95,
      color: Colors.red,
      label: 'Health',
      icon: const Icon(Icons.favorite, size: 20),
    ),
    SmoothPieChartItem(
      id: 'leisure',
      value: 210,
      color: Colors.purple,
      label: 'Leisure',
      icon: const Icon(Icons.sports_esports, size: 20),
    ),
  ];

  static final _linePoints = [
    [
      for (int i = 0; i <= 30; i++) ChartPair(i.toDouble(), _mockSpending(i)),
    ],
  ];

  static double _mockSpending(int day) {
    final base = [
      0,
      45,
      45,
      120,
      120,
      120,
      200,
      200,
      265,
      265,
      310,
      310,
      380,
      430,
      430,
      430,
      510,
      510,
      580,
      640,
      640,
      700,
      700,
      760,
      760,
      820,
      870,
      870,
      920,
      960,
      1010,
    ];
    return base[day].toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('smooth_charts')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Pie chart ──────────────────────────────────────
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pie Chart',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _pieReplayToken++;
                      _selectedPieId = null;
                    });
                  },
                  icon: const Icon(Icons.replay),
                  label: const Text('Replay'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedPieId != null)
              Text('Selected: $_selectedPieId',
                  style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            Center(
              child: SmoothPieChart(
                key: ValueKey('pie_replay_$_pieReplayToken'),
                items: _pieItems,
                selectedId: _selectedPieId,
                onItemSelected: (id, _) => setState(() => _selectedPieId = id),
                onItemDeselected: () => setState(() => _selectedPieId = null),
              ),
            ),

            const SizedBox(height: 40),

            // ── Line chart ─────────────────────────────────────
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Line Chart',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _lineReplayToken++),
                  icon: const Icon(Icons.replay),
                  label: const Text('Replay'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SmoothLineChart(
              key: ValueKey('line_replay_$_lineReplayToken'),
              points: _linePoints,
              color: Theme.of(context).colorScheme.primary,
              isCurved: true,
              yLabelFormatter: (v) => '\$${v.toStringAsFixed(0)}',
              horizontalLineAt: 800,
              keepHorizontalLineInView: true,
            ),

            const SizedBox(height: 40),

            // ── Multi-line ─────────────────────────────────────
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Multi-line Chart',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _multiLineReplayToken++),
                  icon: const Icon(Icons.replay),
                  label: const Text('Replay'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SmoothLineChart(
              key: ValueKey('multi_line_replay_$_multiLineReplayToken'),
              points: [
                _linePoints[0],
                [
                  for (int i = 0; i <= 30; i++)
                    ChartPair(i.toDouble(), _mockSpending(i) * 0.6),
                ],
              ],
              colors: [Colors.teal, Colors.deepOrange],
              yLabelFormatter: (v) => '\$${v.toStringAsFixed(0)}',
              showTooltipForAllLines: true,
              lineTooltipLabelBuilder: (lineIndex) {
                if (lineIndex == 0) return 'Current';
                if (lineIndex == 1) return 'Projection';
                return 'Line ${lineIndex + 1}';
              },
            ),
          ],
        ),
      ),
    );
  }
}
