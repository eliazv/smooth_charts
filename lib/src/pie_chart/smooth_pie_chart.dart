import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../utils/color_utils.dart';
import '../utils/animation_utils.dart';

/// Data model for a single pie chart slice.
class SmoothPieChartItem {
  const SmoothPieChartItem({
    required this.id,
    required this.value,
    required this.color,
    this.label = '',
    this.icon,
  });

  /// Unique identifier — used to highlight a specific slice.
  final String id;

  /// Raw value (absolute). Percentages are computed automatically.
  final double value;

  /// Base color for the slice and its badge border.
  final Color color;

  /// Short label (accessibility / tooltip).
  final String label;

  /// Optional icon shown inside the badge circle.
  /// Typically 28–34 px square.
  final Widget? icon;
}

/// Donut-style pie chart with PinWheel reveal, staggered badge
/// animations and touch interaction.
///
/// ```dart
/// SmoothPieChart(
///   items: [
///     SmoothPieChartItem(id: 'food', value: 300, color: Colors.orange,
///         label: 'Food', icon: Icon(Icons.fastfood)),
///     SmoothPieChartItem(id: 'rent', value: 800, color: Colors.blue,
///         label: 'Rent', icon: Icon(Icons.home)),
///   ],
///   onItemSelected: (id) => print('selected $id'),
/// )
/// ```
class SmoothPieChart extends StatelessWidget {
  const SmoothPieChart({
    Key? key,
    required this.items,
    this.selectedId,
    this.onItemSelected,
    this.onItemDeselected,
    this.centerColor,
    this.largeSizeBreakpoint = 700,
  }) : super(key: key);

  final List<SmoothPieChartItem> items;

  /// ID of the currently highlighted slice (controlled externally).
  final String? selectedId;

  final void Function(String id, SmoothPieChartItem item)? onItemSelected;
  final void Function()? onItemDeselected;

  /// Background color of the center hole.
  final Color? centerColor;

  /// Width breakpoint (logical px) above which the chart renders larger.
  final double largeSizeBreakpoint;

  @override
  Widget build(BuildContext context) {
    final isLarge = MediaQuery.sizeOf(context).width >= largeSizeBreakpoint;
    final chartSize = isLarge ? 300.0 : 200.0;
    final holeOuter = isLarge ? 130.0 : 105.0;
    final holeInner = isLarge ? 110.0 : 80.0;

    final nonZero = items.where((e) => e.value != 0).toList(growable: false);
    final allZero = nonZero.isEmpty;
    final surface = centerColor ?? Theme.of(context).colorScheme.surface;

    return SizedBox(
      width: chartSize,
      height: chartSize,
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          ScaledAnimatedSwitcher(
            keyToWatch: allZero.toString(),
            child: allZero
                ? Container(
                    key: const ValueKey('empty'),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer.withOpacity(0.3),
                    ),
                  )
                : _SmoothPieChartDisplay(
                    key: ValueKey('chart'),
                    items: nonZero,
                    selectedId: selectedId,
                    onItemSelected: onItemSelected,
                    onItemDeselected: onItemDeselected,
                    isLarge: isLarge,
                  ),
          ),
          // Outer translucent ring
          IgnorePointer(
            child: Container(
              width: holeOuter,
              height: holeOuter,
              decoration: BoxDecoration(
                color: surface.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Inner opaque center
          IgnorePointer(
            child: Container(
              width: holeInner,
              height: holeInner,
              decoration: BoxDecoration(color: surface, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmoothPieChartDisplay extends StatefulWidget {
  const _SmoothPieChartDisplay({
    Key? key,
    required this.items,
    required this.isLarge,
    this.selectedId,
    this.onItemSelected,
    this.onItemDeselected,
  }) : super(key: key);

  final List<SmoothPieChartItem> items;
  final bool isLarge;
  final String? selectedId;
  final void Function(String id, SmoothPieChartItem item)? onItemSelected;
  final void Function()? onItemDeselected;

  @override
  State<_SmoothPieChartDisplay> createState() => _SmoothPieChartDisplayState();
}

class _SmoothPieChartDisplayState extends State<_SmoothPieChartDisplay> {
  int _touchedIndex = -1;
  int _showLabels = 0;

  int _indexFromId(String? id) {
    if (id == null) return -1;
    return widget.items.indexWhere((e) => e.id == id);
  }

  @override
  void initState() {
    super.initState();
    _touchedIndex = _indexFromId(widget.selectedId);
    _startLabelAnimation();
  }

  @override
  void didUpdateWidget(covariant _SmoothPieChartDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId ||
        oldWidget.items != widget.items) {
      final nextIndex = _indexFromId(widget.selectedId);
      if (nextIndex != _touchedIndex) {
        setState(() => _touchedIndex = nextIndex);
      }
    }
  }

  void _startLabelAnimation() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final total = widget.items.length + 5;
    for (int i = 1; i <= total; i++) {
      await Future.delayed(const Duration(milliseconds: 70));
      if (mounted) setState(() => _showLabels = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PinWheelReveal(
      duration: const Duration(milliseconds: 850),
      child: PieChart(
        PieChartData(
          startDegreeOffset: -45,
          pieTouchData: PieTouchData(
            touchCallback: (event, response) {
              setState(() {
                if (!event.isInterestedForInteractions ||
                    response == null ||
                    response.touchedSection == null)
                  return;

                final idx = response.touchedSection!.touchedSectionIndex;
                if (event is FlTapDownEvent) {
                  if (_touchedIndex != idx) {
                    _touchedIndex = idx;
                    widget.onItemSelected?.call(
                      widget.items[idx].id,
                      widget.items[idx],
                    );
                  } else {
                    _touchedIndex = -1;
                    widget.onItemDeselected?.call();
                  }
                } else if (event is FlLongPressMoveUpdate) {
                  _touchedIndex = idx;
                  widget.onItemSelected?.call(
                    widget.items[idx].id,
                    widget.items[idx],
                  );
                }
              });
            },
          ),
          borderData: FlBorderData(show: false),
          sectionsSpace: 0,
          centerSpaceRadius: 0,
          sections: _buildSections(context),
        ),
        swapAnimationDuration: const Duration(milliseconds: 1300),
        swapAnimationCurve: const ElasticOutCurve(0.6),
      ),
    );
  }

  List<PieChartSectionData> _buildSections(BuildContext context) {
    final total = widget.items.fold<double>(0, (sum, e) => sum + e.value.abs());
    double accumulated = 0;

    return List.generate(widget.items.length, (i) {
      final item = widget.items[i];
      final isTouched = i == _touchedIndex;
      final percent = total == 0 ? 0.0 : (item.value / total * 100).abs();
      accumulated += percent;

      final prev = i > 0 ? widget.items[i - 1] : null;
      final next = i < widget.items.length - 1 ? widget.items[i + 1] : null;
      final sameNeighbor =
          prev?.color == item.color || next?.color == item.color;

      final color = dynamicPastel(
        context,
        item.color,
        amountLight:
            0.3 +
            (sameNeighbor && i % 3 == 0 ? 0.2 : 0) +
            (sameNeighbor && i % 3 == 1 ? 0.35 : 0),
        amountDark:
            0.1 +
            (sameNeighbor && i % 3 == 0 ? 0.2 : 0) +
            (sameNeighbor && i % 3 == 1 ? 0.35 : 0),
      );

      final radius = widget.isLarge
          ? (isTouched ? 146.0 : 136.0)
          : (isTouched ? 106.0 : 100.0);

      return PieChartSectionData(
        color: color,
        value: total == 0 ? 5 : (item.value / total).abs(),
        title: '',
        radius: radius,
        badgeWidget: _Badge(
          totalPercentAccumulated: accumulated,
          showLabel: i < _showLabels,
          scale: isTouched ? 1.3 : 1.0,
          borderColor: color,
          itemColor: item.color,
          icon: item.icon,
          percent: percent,
          isTouched: isTouched,
        ),
        badgePositionPercentageOffset: .98,
      );
    });
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.totalPercentAccumulated,
    required this.showLabel,
    required this.scale,
    required this.borderColor,
    required this.itemColor,
    required this.percent,
    required this.isTouched,
    this.icon,
  });

  final double totalPercentAccumulated;
  final bool showLabel;
  final double scale;
  final Color borderColor;
  final Color itemColor;
  final Widget? icon;
  final double percent;
  final bool isTouched;

  @override
  Widget build(BuildContext context) {
    final isSmallSlice = percent.abs() < 5;
    final visible = isSmallSlice ? isTouched : (showLabel || isTouched);
    final surface = Theme.of(context).colorScheme.surface;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final labelAbove = totalPercentAccumulated - percent / 2 < 50;

    return AnimatedScale(
      curve: isSmallSlice
          ? Curves.easeInOutCubicEmphasized
          : const ElasticOutCurve(0.6),
      duration: isSmallSlice
          ? const Duration(milliseconds: 700)
          : const Duration(milliseconds: 1300),
      scale: visible ? scale : 0,
      child: SizedBox(
        height: 45,
        width: 45,
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            // Circular frame
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2.5),
                color: surface,
              ),
            ),

            // Percentage label (floats above or below)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: scale == 1.0 ? 0 : 1,
              child: Transform.translate(
                offset: Offset(0, labelAbove ? -34 : 34),
                child: IntrinsicWidth(
                  child: Container(
                    height: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: borderColor, width: 1.5),
                      color: surface,
                    ),
                    child: Center(
                      child: Text(
                        '${percent.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textScaler: TextScaler.noScaling,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Icon content
            if (icon != null)
              Container(
                decoration: BoxDecoration(
                  color: isLight
                      ? dynamicPastel(
                          context,
                          itemColor,
                          amountLight: 0.55,
                          amountDark: 0.35,
                        )
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(8),
                child: SizedBox(width: 28, height: 28, child: icon!),
              ),
          ],
        ),
      ),
    );
  }
}
