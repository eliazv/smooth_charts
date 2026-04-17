import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_charts/smooth_charts.dart';

void main() {
  testWidgets('golden - smooth pie chart default', (tester) async {
    await tester.binding.setSurfaceSize(const Size(420, 420));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: const Key('pie_chart_golden'),
              child: SmoothPieChart(
                items: const [
                  SmoothPieChartItem(
                    id: 'food',
                    value: 320,
                    color: Colors.orange,
                    label: 'Food',
                  ),
                  SmoothPieChartItem(
                    id: 'rent',
                    value: 850,
                    color: Colors.blue,
                    label: 'Rent',
                  ),
                  SmoothPieChartItem(
                    id: 'transport',
                    value: 120,
                    color: Colors.green,
                    label: 'Transport',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 3));
    await expectLater(
      find.byKey(const Key('pie_chart_golden')),
      matchesGoldenFile('goldens/pie_chart_default.png'),
    );
  });
}
