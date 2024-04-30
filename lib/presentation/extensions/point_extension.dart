import 'dart:math';

import 'package:polygon_drawing/presentation/constants/constants.dart';

extension PointExtension on Point {
  Point roundToNearestGridNode() {
    return Point(
      roundByCellSize(x),
      roundByCellSize(y),
    );
  }

  num roundByCellSize(num number) => number % Constants.gridCellSize <= Constants.gridCellSize / 2
      ? number ~/ Constants.gridCellSize * Constants.gridCellSize
      : (number ~/ Constants.gridCellSize + 1) * Constants.gridCellSize;

  double angleTo(Point p) => atan2(y - p.y, x - p.x);
}
