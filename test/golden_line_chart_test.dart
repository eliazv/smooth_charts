import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_charts/smooth_charts.dart';

void main() {
  testWidgets('golden - smooth line chart default', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 260));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: const Key('line_chart_golden'),
              child: SizedBox(
                width: 380,
                child: SmoothLineChart(
                  points: [
                    [
                      ChartPair(0, 0),
                      ChartPair(1, 120),
                      ChartPair(2, 90),
                      ChartPair(3, 210),
                    ],
                    [
                      ChartPair(0, 20),
                      ChartPair(1, 100),
                      ChartPair(2, 130),
                      ChartPair(3, 170),
                    ],
                  ],
                  colors: [Colors.teal, Colors.deepOrange],
                  showTooltipForAllLines: true,
                  animationDuration: Duration.zero,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const Key('line_chart_golden')),
      matchesGoldenFile('goldens/line_chart_default.png'),
    );
  });
}
