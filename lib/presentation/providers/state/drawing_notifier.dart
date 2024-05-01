import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polygon_drawing/presentation/constants/constants.dart';
import 'package:polygon_drawing/presentation/extensions/point_extension.dart';
import 'package:polygon_drawing/presentation/models/step_info.dart';
import 'package:polygon_drawing/presentation/providers/state/drawing_state.dart';

final drawingNotifierProvider = StateNotifierProvider<PolygonDrawingNotifier, PolygonDrawingState>(
  (_) => PolygonDrawingNotifier(),
);

final class PolygonDrawingNotifier extends StateNotifier<PolygonDrawingState> {
  PolygonDrawingNotifier() : super(PolygonDrawingState.initial());

  void addPoint(Point newPoint) {
    if (state.isComplete) return;
    state = state.copyWith(
      polygonVertices: [...state.polygonVertices, newPoint],
      followingSteps: const [],
    );
  }

  void trySelectPointToMove(Point panStartPoint) {
    for (final point in state.polygonVertices) {
      if (panStartPoint.distanceTo(point) < Constants.selectPolygonDistance) {
        state = state.copyWith(indexOfSelectedPoint: state.polygonVertices.indexOf(point));
        registerChanges();
        return;
      }
    }
    state = state.copyWith(indexOfSelectedPoint: null);
  }

  void movePoint(Point point) {
    final newPoint = state.gridModeEnabled ? point.roundedToNearestGridNode : point;
    final len = state.polygonVertices.length;
    final index = state.indexOfSelectedPoint ?? len;
    List<Point> newPolygon;

    if (!state.isComplete) {
      newPolygon = [...state.polygonVertices.getRange(0, len - 1), newPoint];
    } else {
      if (index == len || index == 0) {
        newPolygon = [
          newPoint,
          ...state.polygonVertices.getRange(1, len - 1),
          newPoint,
        ];
      } else {
        newPolygon = [
          ...state.polygonVertices.getRange(0, index),
          newPoint,
          ...state.polygonVertices.getRange(index + 1, len),
        ];
      }
    }
    state = state.copyWith(polygonVertices: newPolygon);
  }

  void registerChanges() {
    late final List<StepInfo> newPreviousSteps;
    if (state.indexOfSelectedPoint == null) {
      newPreviousSteps = [
        ...state.previousSteps,
        StepInfo(
          point: state.polygonVertices.last,
          index: state.polygonVertices.length - 1,
          isComplete: state.isComplete,
        )
      ];
    } else {
      newPreviousSteps = [
        ...state.previousSteps,
        StepInfo(
          point: state.polygonVertices[state.indexOfSelectedPoint!],
          index: state.indexOfSelectedPoint!,
          isComplete: state.isComplete,
        )
      ];
    }
    state = state.copyWith(previousSteps: newPreviousSteps);
  }

  void stepBack() {
    final lastStep = state.previousSteps.last;
    final currentStep = StepInfo(
      index: lastStep.index,
      isComplete: lastStep.isComplete,
      point: state.polygonVertices[lastStep.index],
    );
    final newPreviousSteps = state.previousSteps.getRange(0, state.previousSteps.length - 1).toList();
    final newFollowingSteps = [...state.followingSteps, currentStep];
    final len = state.polygonVertices.length;
    late final List<Point> newPolygon;

    if (!lastStep.isComplete) {
      newPolygon = state.polygonVertices.getRange(0, len - 1).toList();
    } else if (lastStep.index == 0) {
      newPolygon = [
        lastStep.point,
        ...state.polygonVertices.getRange(1, len - 1),
        lastStep.point,
      ];
    } else {
      newPolygon = [
        ...state.polygonVertices.getRange(0, lastStep.index),
        lastStep.point,
        ...state.polygonVertices.getRange(lastStep.index + 1, len)
      ];
    }
    state = state.copyWith(
      polygonVertices: newPolygon,
      followingSteps: newFollowingSteps,
      previousSteps: newPreviousSteps,
    );
    tryCompletePolygon();
  }

  void stepForward() {
    final nextStep = state.followingSteps.last;
    final currentStep = state.isComplete
        ? StepInfo(
            index: nextStep.index,
            isComplete: state.isComplete,
            point: state.polygonVertices[nextStep.index],
          )
        : nextStep;
    final len = state.polygonVertices.length;
    final newPreviousSteps = [...state.previousSteps, currentStep];
    final newFollowingSteps = state.followingSteps.getRange(0, state.followingSteps.length - 1).toList();
    late final List<Point> newPolygon;

    if (!nextStep.isComplete) {
      newPolygon = [...state.polygonVertices, nextStep.point];
    } else if (nextStep.index == 0) {
      newPolygon = [
        nextStep.point,
        ...state.polygonVertices.getRange(1, len - 1),
        nextStep.point,
      ];
    } else {
      newPolygon = [
        ...state.polygonVertices.getRange(0, nextStep.index),
        nextStep.point,
        ...state.polygonVertices.getRange(nextStep.index + 1, len)
      ];
    }
    state = state.copyWith(
      polygonVertices: newPolygon,
      followingSteps: newFollowingSteps,
      previousSteps: newPreviousSteps,
    );
    tryCompletePolygon();
  }

  void tryCompletePolygon() {
    if (_canCompletePolygon) return _completePolygon();
    state = state.copyWith(isComplete: false);
  }

  void toggleGridMode() {
    if (!state.gridModeEnabled) _onGridModeEnabled();
    state = state.copyWith(gridModeEnabled: !state.gridModeEnabled);
  }

  void handleIntersections() {
    if (state.polygonVertices.length < 4 || (state.indexOfSelectedPoint == null && state.isComplete)) {
      return;
    }
    final len = state.polygonVertices.length;
    List<Point>? newPolygon;

    if (state.indexOfSelectedPoint != null) {
      final int selectedIndex = state.indexOfSelectedPoint!;
      for (int i = 0; i < len - 1; i++) {
        final p1 = state.polygonVertices[selectedIndex];
        final p2a = state.polygonVertices[selectedIndex == len - 1 ? 1 : selectedIndex + 1];
        final p2b = state.polygonVertices[selectedIndex == 0 ? len - 2 : selectedIndex - 1];
        final p3 = state.polygonVertices[i];
        final p4 = state.polygonVertices[i + 1];
        if (p1 == p3 || p1 == p4) continue;
        if ((p2a != p3 && p2a != p4 && _checkIntersection(p1, p2a, p3, p4)) ||
            (p2b != p3 && p2b != p4 && _checkIntersection(p1, p2b, p3, p4))) {
          final lastStep = state.previousSteps.last;
          newPolygon = lastStep.index == 0
              ? [
                  lastStep.point,
                  ...state.polygonVertices.getRange(1, len - 1),
                  lastStep.point,
                ]
              : [
                  ...state.polygonVertices.getRange(0, lastStep.index),
                  lastStep.point,
                  ...state.polygonVertices.getRange(lastStep.index + 1, len),
                ];
          break;
        }
      }
    } else {
      for (int i = 0; i < len - 3; i++) {
        if (_checkIntersection(state.polygonVertices[len - 2], state.polygonVertices[len - 1], state.polygonVertices[i],
            state.polygonVertices[i + 1])) {
          newPolygon = state.polygonVertices.getRange(0, len - 1).toList();
          break;
        }
      }
    }
    state = state.copyWith(polygonVertices: newPolygon ?? state.polygonVertices);
  }

//Метод isPointInsidePolygon определяет, находится ли точка внутри многоугольника.
//Он подсчитывает количество пересечений сторон многоугольника с лучом, исходящим из точки вверх.
//Если количество пересечений нечетное, точка находится внутри многоугольника.

  bool isPointInsidePolygon(Point point) {
    final len = state.polygonVertices.length;

    int crossings = 0;

    for (int i = 0; i < len; i++) {
      final a = state.polygonVertices[i];
      final b = state.polygonVertices[(i + 1) % len];

      if ((a.y < point.y && b.y >= point.y || b.y < point.y && a.y >= point.y) &&
          (a.x >= point.x || b.x >= point.x) &&
          (point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.y)) {
        crossings++;
      }
    }

    return crossings % 2 == 1;
  }

  bool get _canCompletePolygon =>
      state.polygonVertices.length > 3 &&
      state.polygonVertices.first.distanceTo(state.polygonVertices.last) < Constants.maxDistanceToCompletePolygon;

  void _completePolygon() {
    final newPolygon = [
      ...state.polygonVertices.getRange(0, state.polygonVertices.length - 1),
      state.polygonVertices.first
    ];
    state = state.copyWith(
      isComplete: true,
      polygonVertices: newPolygon,
    );
  }

  void _onGridModeEnabled() {
    final newPolygon = state.polygonVertices.map((e) => e.roundedToNearestGridNode).toList();
    state = state.copyWith(polygonVertices: newPolygon);
  }

//Метод _checkIntersection проверяет наличие пересечений между отрезками p1p2 и p3p4.
//_orientation определяет ориентацию тройки точек.
//_onSegment проверяет, лежит ли точка на отрезке.
//Если ориентация двух из троек различна и одна из точек лежит на отрезке, то отрезки пересекаются.

  bool _checkIntersection(Point p1, Point p2, Point p3, Point p4) {
    final o1 = _orientation(p1, p2, p3);
    final o2 = _orientation(p1, p2, p4);
    final o3 = _orientation(p3, p4, p1);
    final o4 = _orientation(p3, p4, p2);

    if (o1 != o2 && o3 != o4) {
      return true;
    }
    if (o1 == 0 && _onSegment(p1, p2, p3)) {
      return true;
    }
    if (o2 == 0 && _onSegment(p1, p2, p4)) {
      return true;
    }
    if (o3 == 0 && _onSegment(p3, p4, p1)) {
      return true;
    }
    if (o4 == 0 && _onSegment(p3, p4, p2)) {
      return true;
    }

    return false;
  }

  int _orientation(Point p, Point q, Point r) {
    final val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y);
    if (val == 0) return 0;
    return (val > 0) ? 1 : 2;
  }

  bool _onSegment(Point p, Point q, Point r) {
    if (q.x <= max(p.x, r.x) && q.x >= min(p.x, r.x) && q.y <= max(p.y, r.y) && q.y >= min(p.y, r.y)) {
      return true;
    }
    return false;
  }
}
