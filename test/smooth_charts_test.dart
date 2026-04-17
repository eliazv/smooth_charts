import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smooth_charts/smooth_charts.dart';

// Animations use Future.delayed internally. We advance fake time past all
// timers to avoid "pending timers" failures in the Flutter test framework.
const _drainPie = Duration(seconds: 2);
const _drainLine = Duration(seconds: 3);

void main() {
  // ── Pie chart ─────────────────────────────────────────────────────

  testWidgets('SmoothPieChart renders with items', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmoothPieChart(
            items: const [
              SmoothPieChartItem(id: 'a', value: 100, color: Colors.red),
              SmoothPieChartItem(id: 'b', value: 200, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
    await tester.pump(_drainPie);
    expect(find.byType(SmoothPieChart), findsOneWidget);
  });

  testWidgets('SmoothPieChart renders empty state when all values are zero', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmoothPieChart(
            items: const [
              SmoothPieChartItem(id: 'a', value: 0, color: Colors.red),
            ],
          ),
        ),
      ),
    );
    await tester.pump(_drainPie);
    expect(find.byType(SmoothPieChart), findsOneWidget);
  });

  testWidgets('SmoothPieChart accepts selectedId and callbacks', (
    tester,
  ) async {
    bool deselected = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmoothPieChart(
            items: const [
              SmoothPieChartItem(id: 'a', value: 100, color: Colors.red),
              SmoothPieChartItem(id: 'b', value: 100, color: Colors.blue),
            ],
            selectedId: 'a',
            onItemDeselected: () => deselected = true,
          ),
        ),
      ),
    );
    await tester.pump(_drainPie);
    expect(find.byType(SmoothPieChart), findsOneWidget);
    expect(deselected, false);
  });

  // ── Line chart ────────────────────────────────────────────────────

  testWidgets('SmoothLineChart renders with points', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmoothLineChart(
            points: [
              [
                ChartPair(0, 0),
                ChartPair(1, 100),
                ChartPair(2, 80),
                ChartPair(3, 150),
              ],
            ],
            color: Colors.teal,
          ),
        ),
      ),
    );
    await tester.pump(_drainLine);
    expect(find.byType(SmoothLineChart), findsOneWidget);
  });

  testWidgets('SmoothLineChart renders multi-line', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SmoothLineChart(
            points: [
              [ChartPair(0, 0), ChartPair(1, 100)],
              [ChartPair(0, 50), ChartPair(1, 80)],
            ],
            colors: [Colors.teal, Colors.orange],
          ),
        ),
      ),
    );
    await tester.pump(_drainLine);
    expect(find.byType(SmoothLineChart), findsOneWidget);
  });

  // ── Color utils ───────────────────────────────────────────────────

  test('lightenPastel returns lighter color', () {
    const base = Color(0xFF0000FF);
    final lighter = lightenPastel(base, amount: 0.5);
    expect(
      (lighter.b * 255).round().clamp(0, 255),
      greaterThanOrEqualTo((base.b * 255).round().clamp(0, 255)),
    );
  });

  test('darkenPastel returns darker color', () {
    const base = Color(0xFF8888FF);
    final darker = darkenPastel(base, amount: 0.5);
    expect(
      (darker.b * 255).round().clamp(0, 255),
      lessThanOrEqualTo((base.b * 255).round().clamp(0, 255)),
    );
  });

  test('HexColor parses 6-digit hex', () {
    final c = HexColor('#FF5733');
    expect((c.r * 255).round().clamp(0, 255), 0xFF);
    expect((c.g * 255).round().clamp(0, 255), 0x57);
    expect((c.b * 255).round().clamp(0, 255), 0x33);
  });

  test('HexColor parses 8-digit hex with alpha', () {
    final c = HexColor('FFFF5733');
    expect((c.r * 255).round().clamp(0, 255), 0xFF);
    expect((c.g * 255).round().clamp(0, 255), 0x57);
  });

  test('HexColor returns fallback for null', () {
    final c = HexColor(null, defaultColor: Colors.grey);
    expect(c.toARGB32(), Colors.grey.toARGB32());
  });
}
