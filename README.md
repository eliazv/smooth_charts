# smooth_charts

[![pub package](https://img.shields.io/pub/v/smooth_charts.svg)](https://pub.dev/packages/smooth_charts)
[![likes](https://img.shields.io/pub/likes/smooth_charts)](https://pub.dev/packages/smooth_charts)

Beautiful animated pie and line charts for Flutter.

PinWheel reveal, elastic spring animations, staggered badge labels, touch interactions and gradient fills — extracted and generalized from the [Cashew](https://github.com/jameskokoska/Cashew) budgeting app.

![smooth_charts demo](assets/readme/smooth_charts_demo.gif)

## Features

- **Pie chart** with PinWheel reveal animation on load
- Staggered badge animation (icon + percentage label per slice)
- Elastic spring on touch expand/collapse
- **Line chart** with 2000ms entrance animation
- Touch tooltips with haptic feedback
- Gradient fill above/below the zero line
- Optional reference lines (horizontal budget line, vertical date line)
- Multi-line support with per-line colors
- Adaptive light/dark theme via `dynamicPastel` color utility
- Fully customizable label formatters

## Why this package

Most chart libraries give you low-level primitives. `smooth_charts` gives you:

- Production-ready visual defaults matching modern finance app aesthetics
- Animations that match the quality bar of native apps
- Clean widget API — pass your data, get a chart

## Installation

```yaml
dependencies:
  smooth_charts: ^0.0.1
```

## Pie chart

```dart
import 'package:smooth_charts/smooth_charts.dart';

SmoothPieChart(
  items: [
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
  ],
  onItemSelected: (id, item) => print('selected $id'),
  onItemDeselected: () => print('deselected'),
)
```

### Controlled selection

```dart
SmoothPieChart(
  items: items,
  selectedId: _selectedId,          // control highlight from outside
  onItemSelected: (id, _) => setState(() => _selectedId = id),
  onItemDeselected: () => setState(() => _selectedId = null),
  centerColor: Theme.of(context).colorScheme.surface,
  largeSizeBreakpoint: 700,         // renders larger above this width
)
```

## Line chart

```dart
SmoothLineChart(
  points: [
    [
      ChartPair(0, 0),
      ChartPair(1, 120),
      ChartPair(2, 95),
      ChartPair(3, 210),
    ],
  ],
  color: Colors.teal,
  isCurved: true,
  yLabelFormatter: (v) => '\$${v.toStringAsFixed(0)}',
)
```

### Multi-line with reference lines

```dart
SmoothLineChart(
  points: [line1Points, line2Points],
  colors: [Colors.teal, Colors.deepOrange],
  showTooltipForAllLines: true,
  lineTooltipLabelBuilder: (i) => i == 0 ? 'Current' : 'Projection',
  horizontalLineAt: 500,           // dashed budget/target line
  keepHorizontalLineInView: true,
  yLabelFormatter: (v) => '\$${v.toStringAsFixed(0)}',
  tooltipFormatter: (date, value) =>
      '${date.day}/${date.month}\n\$${value.toStringAsFixed(2)}',
)
```

## API

### `SmoothPieChartItem`

| Field   | Type      | Description                                    |
| ------- | --------- | ---------------------------------------------- |
| `id`    | `String`  | Unique identifier                              |
| `value` | `double`  | Raw value (percentages computed automatically) |
| `color` | `Color`   | Base slice color                               |
| `label` | `String`  | Accessibility label                            |
| `icon`  | `Widget?` | Optional icon inside the badge                 |

### `SmoothPieChart`

| Parameter             | Type                                         | Default  | Description                   |
| --------------------- | -------------------------------------------- | -------- | ----------------------------- |
| `items`               | `List<SmoothPieChartItem>`                   | required | Chart data                    |
| `selectedId`          | `String?`                                    | —        | Controlled highlight          |
| `onItemSelected`      | `void Function(String, SmoothPieChartItem)?` | —        | Tap callback                  |
| `onItemDeselected`    | `void Function()?`                           | —        | Deselect callback             |
| `centerColor`         | `Color?`                                     | surface  | Center hole fill              |
| `largeSizeBreakpoint` | `double`                                     | `700`    | Width to render large variant |

### `SmoothLineChart`

| Parameter                 | Type                                 | Default      | Description                               |
| ------------------------- | ------------------------------------ | ------------ | ----------------------------------------- |
| `points`                  | `List<List<ChartPair>>`              | required     | One list per line                         |
| `color`                   | `Color?`                             | primary      | Primary line color                        |
| `colors`                  | `List<Color>`                        | `[]`         | Per-line colors                           |
| `isCurved`                | `bool`                               | `false`      | Smooth bezier curves                      |
| `endDate`                 | `DateTime?`                          | now          | Reference for x-axis labels               |
| `horizontalLineAt`        | `double?`                            | —            | Dashed reference line                     |
| `verticalLineAt`          | `double?`                            | —            | Dashed reference line                     |
| `showTooltipForAllLines`  | `bool`                               | `false`      | Show one tooltip row for each line        |
| `lineTooltipLabelBuilder` | `String Function(int)?`              | —            | Custom labels for multi-line tooltip rows |
| `yLabelFormatter`         | `String Function(double)?`           | compact      | Y-axis formatter                          |
| `xLabelFormatter`         | `String Function(DateTime)?`         | "Mar 15"     | X-axis formatter                          |
| `tooltipFormatter`        | `String Function(DateTime, double)?` | date + value | Tooltip text                              |

## Utilities

`smooth_charts` also exports its color utilities:

```dart
// Lighten/darken respecting light/dark theme
Color result = dynamicPastel(context, Colors.blue, amountLight: 0.3);

// Parse hex color strings
Color c = HexColor('#FF5733');
```

## Example app

See `example/lib/main.dart` for a complete demo with:

- Pie chart with selection
- Single-line chart with budget line
- Multi-line chart

## Author

Created by Elia Zavatta.

I build production-ready Flutter apps and reusable UI components.

- GitHub: https://github.com/eliazv
- LinkedIn: https://www.linkedin.com/in/eliazavatta/
- Email: info@eliazavatta.it

## Related smooth packages

- [smooth_bottom_sheet](https://pub.dev/packages/smooth_bottom_sheet)
- [smooth_infinite_tab_bar](https://pub.dev/packages/smooth_infinite_tab_bar)
- [smooth_paywall](https://pub.dev/packages/smooth_paywall)

## License

MIT
