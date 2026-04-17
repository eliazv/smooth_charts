import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/color_utils.dart';

/// A simple (x, y) data point, optionally associated with a [DateTime].
class ChartPair {
  ChartPair(this.x, this.y, {this.dateTime});

  double x;
  double y;
  DateTime? dateTime;

  @override
  String toString() => 'x:$x y:$y dateTime:$dateTime';
}

/// Animated line chart with touch tooltips, optional reference lines,
/// gradient fill and configurable formatters.
///
/// ```dart
/// SmoothLineChart(
///   points: [
///     [ChartPair(0, 0), ChartPair(1, 120), ChartPair(2, 80)],
///   ],
///   color: Colors.teal,
///   yLabelFormatter: (v) => '\$${v.toStringAsFixed(0)}',
/// )
/// ```
class SmoothLineChart extends StatelessWidget {
  const SmoothLineChart({
    Key? key,
    required this.points,
    this.color,
    this.colors = const [],
    this.isCurved = false,
    this.endDate,
    this.verticalLineAt,
    this.horizontalLineAt,
    this.enableTouch = true,
    this.keepHorizontalLineInView = false,
    this.amountBefore = 0,
    this.removeZeroEntries = false,
    this.cumulativeMode = false,
    this.yLabelFormatter,
    this.xLabelFormatter,
    this.tooltipFormatter,
    this.showTooltipForAllLines = false,
    this.lineTooltipLabelBuilder,
  }) : super(key: key);

  /// One inner list = one line on the chart.
  final List<List<ChartPair>> points;

  /// Primary line color. Defaults to [ColorScheme.primary].
  final Color? color;

  /// Per-line colors (overrides [color] when provided).
  final List<Color> colors;

  final bool isCurved;

  /// Reference date for the rightmost data point label.
  final DateTime? endDate;

  /// Draws a dashed vertical line at this x offset from the right.
  final double? verticalLineAt;

  /// Draws a dashed horizontal line at this y value.
  final double? horizontalLineAt;

  final bool enableTouch;
  final bool keepHorizontalLineInView;

  /// Starting y value before the first point (used to initialise
  /// the min/max bounds during the entrance animation).
  final double amountBefore;

  /// Drop points where y == 0 (non-cumulative: skip, cumulative: flatten).
  final bool removeZeroEntries;

  /// Show running total instead of per-day values.
  final bool cumulativeMode;

  /// Format a y-axis value. Defaults to compact number formatting.
  final String Function(double value)? yLabelFormatter;

  /// Format a date label on the x-axis. Defaults to "Mar 15" style.
  final String Function(DateTime date)? xLabelFormatter;

  /// Format the tooltip text. Defaults to "<date>\n<value>".
  /// Receives (date, value).
  final String Function(DateTime date, double value)? tooltipFormatter;

  /// When true, shows one tooltip row per visible line at touched x.
  /// When false, only the first line tooltip is shown.
  final bool showTooltipForAllLines;

  /// Optional label builder used in multi-line tooltips.
  /// Defaults to "Line 1", "Line 2", ...
  final String Function(int lineIndex)? lineTooltipLabelBuilder;

  // ── helpers ──────────────────────────────────────────────────────────

  static String _defaultY(double v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
  }

  static String _defaultDate(DateTime d) {
    const m = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${m[d.month - 1]} ${d.day}';
  }

  static DateTime _shiftDay(DateTime base, int offset) {
    final r = DateTime(base.year, base.month, base.day + offset);
    return r;
  }

  List<ChartPair> _filterPoints(List<ChartPair> pts) {
    if (removeZeroEntries && !cumulativeMode) {
      final out = pts.where((p) => p.y != 0).toList();
      if (out.isEmpty) return [ChartPair(0, 0)];
      if (out.last.x != pts.last.x) out.add(ChartPair(pts.last.x, 0));
      return out;
    }
    if (removeZeroEntries && cumulativeMode) {
      final out = [pts.first];
      double prev = 0;
      for (final p in pts) {
        if (prev != p.y) out.add(ChartPair(p.x, p.y));
        prev = p.y;
      }
      if (out.isEmpty) return [ChartPair(0, 0)];
      if (out.last.x != pts.last.x) {
        out.add(ChartPair(pts.last.x, pts.last.y));
      }
      return out;
    }
    return pts;
  }

  List<List<FlSpot>> _toSpots(List<List<ChartPair>> lists) => lists
      .map((l) => _filterPoints(l).map((p) => FlSpot(p.x, p.y)).toList())
      .toList();

  ChartPair _max(List<List<ChartPair>> lists) {
    var m = ChartPair(
      0,
      amountBefore != 0 && lists.isNotEmpty && lists[0].isNotEmpty
          ? lists[0][0].y
          : 0,
    );
    for (final l in lists) {
      for (final p in l) {
        if (p.x > m.x) m.x = p.x;
        if (p.y > m.y) m.y = p.y;
      }
    }
    if (keepHorizontalLineInView &&
        horizontalLineAt != null &&
        horizontalLineAt != double.infinity &&
        m.y < (horizontalLineAt! + horizontalLineAt! * 0.1)) {
      m.y = horizontalLineAt! + horizontalLineAt! * 0.1;
    }
    return m;
  }

  ChartPair _min(List<List<ChartPair>> lists) {
    var m = ChartPair(
      0,
      amountBefore != 0 && lists.isNotEmpty && lists[0].isNotEmpty
          ? lists[0][0].y
          : 0,
    );
    for (final l in lists) {
      for (final p in l) {
        if (p.x < m.x) m.x = p.x;
        if (p.y < m.y) m.y = p.y;
      }
    }
    return m;
  }

  @override
  Widget build(BuildContext context) {
    final maxP = _max(points);
    final minP = _min(points);
    final effectiveMax = maxP.y == minP.y
        ? ChartPair(maxP.x, maxP.y + 1)
        : maxP;
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return ClipRect(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, top: 18, right: 7),
        height: MediaQuery.sizeOf(context).width > 700 ? 300 : 175,
        child: _LineChartInternal(
          spots: _toSpots(points),
          maxPair: effectiveMax,
          minPair: minP,
          color: effectiveColor,
          colors: colors,
          isCurved: isCurved,
          endDate: endDate,
          verticalLineAt: verticalLineAt,
          horizontalLineAt: horizontalLineAt,
          enableTouch: enableTouch,
          amountBefore: amountBefore,
          yLabel: yLabelFormatter ?? _defaultY,
          xLabel: xLabelFormatter ?? _defaultDate,
          tooltip:
              tooltipFormatter ??
              (d, v) =>
                  '${_defaultDate(d)}\n${(yLabelFormatter ?? _defaultY)(v)}',
          shiftDay: _shiftDay,
          showTooltipForAllLines: showTooltipForAllLines,
          lineTooltipLabelBuilder: lineTooltipLabelBuilder,
        ),
      ),
    );
  }
}

// ── Internal stateful widget ──────────────────────────────────────────

class _LineChartInternal extends StatefulWidget {
  const _LineChartInternal({
    required this.spots,
    required this.maxPair,
    required this.minPair,
    required this.color,
    required this.colors,
    required this.isCurved,
    required this.endDate,
    required this.verticalLineAt,
    required this.horizontalLineAt,
    required this.enableTouch,
    required this.amountBefore,
    required this.yLabel,
    required this.xLabel,
    required this.tooltip,
    required this.shiftDay,
    required this.showTooltipForAllLines,
    required this.lineTooltipLabelBuilder,
  });

  final List<List<FlSpot>> spots;
  final ChartPair maxPair;
  final ChartPair minPair;
  final Color color;
  final List<Color> colors;
  final bool isCurved;
  final DateTime? endDate;
  final double? verticalLineAt;
  final double? horizontalLineAt;
  final bool enableTouch;
  final double amountBefore;
  final String Function(double) yLabel;
  final String Function(DateTime) xLabel;
  final String Function(DateTime, double) tooltip;
  final DateTime Function(DateTime, int) shiftDay;
  final bool showTooltipForAllLines;
  final String Function(int lineIndex)? lineTooltipLabelBuilder;

  @override
  State<_LineChartInternal> createState() => _LineChartInternalState();
}

class _LineChartInternalState extends State<_LineChartInternal> {
  bool _loaded = false;
  int? _touchedX;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (mounted) setState(() => _loaded = true);
    });
  }

  bool get _isFullScreen => MediaQuery.sizeOf(context).width > 700;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 15, top: 8),
      child: LineChart(
        _buildData(context),
        duration: const Duration(milliseconds: 2000),
        curve: Curves.fastLinearToSlowEaseIn,
      ),
    );
  }

  LineChartData _buildData(BuildContext context) {
    final maxX = widget.maxPair.x;
    final maxY = widget.maxPair.y;
    final minY = widget.minPair.y;

    return LineChartData(
      lineTouchData: _touchData(context),
      gridData: _grid(context),
      borderData: FlBorderData(show: false),
      lineBarsData: _bars(),
      minX: 0,
      maxX: _loaded ? maxX : maxX - maxX * 0.7,
      minY: _loaded
          ? (minY == 0 ? -0.000001 : minY)
          : minY - (minY - widget.amountBefore) * 0.7,
      maxY: _loaded
          ? (maxY == 0 ? 0.000001 : maxY)
          : maxY + (maxY - widget.amountBefore) * 0.7,
      titlesData: _titles(context),
      extraLinesData: _extraLines(context),
    );
  }

  List<LineChartBarData> _bars() => [
    for (int i = 0; i < widget.spots.length; i++) _barData(widget.spots[i], i),
  ];

  LineChartBarData _barData(List<FlSpot> spots, int i) {
    final c = widget.colors.isNotEmpty
        ? lightenPastel(widget.colors[i], amount: 0.3)
        : lightenPastel(widget.color, amount: 0.3);
    final maxY = widget.maxPair.y;
    final minY = widget.minPair.y;
    final span = (maxY.abs() + minY.abs());

    return LineChartBarData(
      color: c,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      isCurved: widget.isCurved,
      curveSmoothness: 0.3,
      preventCurveOverShooting: true,
      preventCurveOvershootingThreshold: 8,
      belowBarData: BarAreaData(
        applyCutOffY: true,
        cutOffY: 0,
        show: !(minY <= 0 && maxY <= 0),
        gradient: LinearGradient(
          colors: [
            i == 0 ? widget.color.withAlpha(100) : widget.color.withAlpha(1),
            widget.color.withAlpha(1),
          ],
          begin: Alignment.topCenter,
          end: Alignment(0, span == 0 ? 1 : maxY.abs() / span),
        ),
      ),
      aboveBarData: BarAreaData(
        applyCutOffY: true,
        cutOffY: 0,
        show: !(minY >= 0 && maxY >= 0) && i == 0,
        gradient: LinearGradient(
          colors: [
            i == 0 ? widget.color.withAlpha(100) : widget.color.withAlpha(1),
            widget.color.withAlpha(1),
          ],
          begin: Alignment.bottomCenter,
          end: Alignment(0, span == 0 ? -1 : -(minY.abs() / span)),
        ),
      ),
      spots: spots,
    );
  }

  ExtraLinesData _extraLines(BuildContext context) {
    final c = dynamicPastel(context, widget.color, amount: 0.3);
    final minY = widget.minPair.y;
    final maxY = widget.maxPair.y;
    return ExtraLinesData(
      horizontalLines: [
        if (!((minY > 0 && maxY > 0) || (minY < 0 && maxY < 0)))
          HorizontalLine(y: 0, strokeWidth: 2, color: c.withOpacity(0.4)),
        if (widget.horizontalLineAt != null)
          HorizontalLine(
            y: widget.horizontalLineAt!,
            color: c.withOpacity(0.7),
            dashArray: [2, 2],
          ),
      ],
      verticalLines: [
        VerticalLine(
          x: 0.0001,
          dashArray: [2, 5],
          strokeWidth: 2,
          color: c.withOpacity(0.2),
        ),
        if (widget.verticalLineAt != null)
          VerticalLine(
            x: widget.maxPair.x - widget.verticalLineAt!,
            dashArray: [2, 2],
            strokeWidth: 2,
            color: c.withOpacity(0.7),
          ),
      ],
    );
  }

  FlGridData _grid(BuildContext context) {
    final c = dynamicPastel(context, widget.color, amount: 0.3);
    final maxX = widget.maxPair.x;
    final maxY = widget.maxPair.y;
    final minY = widget.minPair.y;
    final ySpan = (maxY - minY).abs();
    final xSpan = maxX.abs();
    final ticks = _isFullScreen ? 6 : 4;

    return FlGridData(
      show: true,
      verticalInterval: double.parse((xSpan / ticks).toStringAsFixed(5)) == 0
          ? 5
          : xSpan / ticks,
      horizontalInterval: double.parse(ySpan.toStringAsFixed(5)) == 0
          ? 0.001
          : (ySpan / (_isFullScreen ? 7 : 4)).abs(),
      getDrawingVerticalLine: (_) =>
          FlLine(color: c.withOpacity(0.2), strokeWidth: 2, dashArray: [2, 8]),
      getDrawingHorizontalLine: (_) =>
          FlLine(color: c.withOpacity(0.2), strokeWidth: 2, dashArray: [2, 8]),
    );
  }

  FlTitlesData _titles(BuildContext context) {
    final c = widget.color;
    final maxX = widget.maxPair.x;
    final maxY = widget.maxPair.y;
    final minY = widget.minPair.y;
    final ySpan = (maxY - minY).abs();
    final ticks = _isFullScreen ? 6 : 4;

    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: maxX / ticks == 0 ? 5 : maxX / ticks,
          getTitlesWidget: (value, meta) {
            if (value == maxX + 1) return const SizedBox.shrink();
            final date = widget.shiftDay(
              widget.endDate ?? DateTime.now(),
              -maxX.toInt() + value.round(),
            );
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.noScaling),
                child: Text(
                  widget.xLabel(date),
                  style: TextStyle(
                    fontSize: 13,
                    color: dynamicPastel(
                      context,
                      c,
                      amount: 0.8,
                      inverse: true,
                    ).withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            );
          },
        ),
      ),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: _leftReservedSize(),
          interval: double.parse(ySpan.toStringAsFixed(5)) == 0.0
              ? 0.001
              : (ySpan / (_isFullScreen ? 7 : 4)).abs(),
          getTitlesWidget: (value, meta) {
            if (value == meta.max || value == meta.min) {
              return const SizedBox.shrink();
            }
            final inRange =
                (value == 0) ||
                (value < maxY && value > 1 && value < meta.max) ||
                (value > minY && value < 1 && value > meta.min);
            if (!inRange) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.noScaling),
                child: Text(
                  widget.yLabel(value),
                  style: TextStyle(
                    overflow: TextOverflow.fade,
                    fontSize: 13,
                    color: dynamicPastel(
                      context,
                      c,
                      amount: 0.5,
                      inverse: true,
                    ).withOpacity(0.3),
                  ),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  softWrap: false,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _leftReservedSize() {
    final minY = widget.minPair.y;
    final maxY = widget.maxPair.y;
    if (minY <= -10000) return 72;
    if (minY <= -1000) return 62;
    if (minY <= -100) return 57;
    if (maxY >= 1000) return 54;
    if (maxY >= 100) return 50;
    return 42;
  }

  LineTouchData _touchData(BuildContext context) {
    final primaryBaseColor = widget.colors.isNotEmpty
        ? widget.colors.first
        : widget.color;
    final primaryColor = lightenPastel(primaryBaseColor, amount: 0.3);
    final scheme = Theme.of(context).colorScheme;

    return LineTouchData(
      enabled: widget.enableTouch,
      touchSpotThreshold: 1000,
      getTouchedSpotIndicator: (barData, spotIndexes) {
        final shouldHide =
            !widget.showTooltipForAllLines && barData.color != primaryColor;
        return spotIndexes.map((i) {
          final lc = shouldHide
              ? Colors.transparent
              : (barData.color ?? widget.color).withOpacity(0.95);
          return TouchedSpotIndicatorData(
            FlLine(color: lc, strokeWidth: 2, dashArray: [2, 2]),
            FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: lc,
                strokeWidth: 2,
                strokeColor: lc,
              ),
            ),
          );
        }).toList();
      },
      touchCallback: (event, response) {
        if (!event.isInterestedForInteractions || response == null) {
          _touchedX = null;
          return;
        }
        final x = response.lineBarSpots![0].x;
        if (event is FlLongPressStart) {
          HapticFeedback.selectionClick();
        } else if (_touchedX != x.toInt() &&
            (event is FlLongPressMoveUpdate || event is FlPanUpdateEvent)) {
          HapticFeedback.selectionClick();
        }
        _touchedX = x.toInt();
      },
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => widget.showTooltipForAllLines
            ? scheme.surface.withOpacity(0.95)
            : widget.color.withOpacity(0.7),
        tooltipRoundedRadius: 8,
        fitInsideVertically: true,
        fitInsideHorizontally: true,
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        getTooltipItems: (spots) => spots.map((spot) {
          final isPrimaryLine = spot.bar.color == primaryColor;
          if (!widget.showTooltipForAllLines && !isPrimaryLine) {
            return null;
          }

          final date = SmoothLineChart._shiftDay(
            widget.endDate ?? DateTime.now(),
            -widget.maxPair.x.toInt() + spot.x.toInt(),
          );

          if (widget.showTooltipForAllLines) {
            final lineLabel =
                widget.lineTooltipLabelBuilder?.call(spot.barIndex) ??
                'Line ${spot.barIndex + 1}';
            final dateLabel = spot.barIndex == 0
                ? '${widget.xLabel(date)}\n'
                : '';

            return LineTooltipItem(
              dateLabel,
              TextStyle(
                color: scheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              children: [
                TextSpan(
                  text: '● ',
                  style: TextStyle(
                    color: spot.bar.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                TextSpan(
                  text: '$lineLabel: ${widget.yLabel(spot.y)}',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          }

          return LineTooltipItem(
            widget.tooltip(date, spot.y),
            const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          );
        }).toList(),
      ),
    );
  }
}
