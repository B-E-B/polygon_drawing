import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polygon_drawing/presentation/constants/constants.dart';
import 'package:polygon_drawing/presentation/extensions/point_extension.dart';
import 'package:polygon_drawing/presentation/models/step_info.dart';
import 'package:polygon_drawing/presentation/providers/state/drawing_state.dart';

class DrawingNotifier extends StateNotifier<PolygonDrawingState> {
  DrawingNotifier() : super(const PolygonDrawingState(polygon: []));

  void addPoint(Point newPoint) {
    if (!state.isComplete) {
      final newPolygon = [...state.polygon, newPoint];
      state = state.copyWith(
        polygon: newPolygon,
        followingSteps: [],
      );
    }
  }

  void trySelectPointToMove(Point panStartPoint) {
    for (var point in state.polygon) {
      if (panStartPoint.distanceTo(point) < Constants.selectPolygonDistance) {
        state = state.copyWith(indexOfSelectedPoint: state.polygon.indexOf(point));
        return;
      }
    }
    state = state.copyWith(indexOfSelectedPoint: null);
  }

  void movePoint(Point point) {
    final newPoint = state.gridModeEnabled ? point.roundToNearestGridNode() : point;
    final len = state.polygon.length;
    final index = state.indexOfSelectedPoint ?? len;
    late final List<Point> newPolygon;

    if (!state.isComplete) {
      newPolygon = [...state.polygon.getRange(0, len - 1), newPoint];
    } else {
      if (index == len || index == 0) {
        newPolygon = [
          newPoint,
          ...state.polygon.getRange(1, len - 1),
          newPoint,
        ];
      } else {
        newPolygon = [
          ...state.polygon.getRange(0, index),
          newPoint,
          ...state.polygon.getRange(index + 1, len),
        ];
      }
    }
    state = state.copyWith(
      polygon: newPolygon,
    );
  }

  void registerChanges() {
    late final List<StepInfo> newPreviousSteps;
    if (state.indexOfSelectedPoint == null) {
      newPreviousSteps = [
        ...state.previousSteps,
        StepInfo(
          point: state.polygon.last,
          index: state.polygon.length - 1,
          isComplete: state.isComplete,
        )
      ];
    } else {
      newPreviousSteps = [
        ...state.previousSteps,
        StepInfo(
          point: state.polygon[state.indexOfSelectedPoint!],
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
      point: state.polygon[lastStep.index],
    );
    final newPreviousSteps = state.previousSteps.getRange(0, state.previousSteps.length - 1).toList();
    final newFollowingSteps = [...state.followingSteps, currentStep];
    final len = state.polygon.length;
    late final List<Point> newPolygon;

    if (!lastStep.isComplete) {
      newPolygon = state.polygon.getRange(0, len - 1).toList();
    } else if (lastStep.index == 0) {
      newPolygon = [
        lastStep.point,
        ...state.polygon.getRange(1, len - 1),
        lastStep.point,
      ];
    } else {
      newPolygon = [
        ...state.polygon.getRange(0, lastStep.index),
        lastStep.point,
        ...state.polygon.getRange(lastStep.index + 1, len)
      ];
    }
    state = state.copyWith(
      polygon: newPolygon,
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
            point: state.polygon[nextStep.index],
          )
        : nextStep;
    final len = state.polygon.length;
    final newPreviousSteps = [...state.previousSteps, currentStep];
    final newFollowingSteps = state.followingSteps.getRange(0, state.followingSteps.length - 1).toList();
    late final List<Point> newPolygon;

    if (!nextStep.isComplete) {
      newPolygon = [...state.polygon, nextStep.point];
    } else if (nextStep.index == 0) {
      newPolygon = [
        nextStep.point,
        ...state.polygon.getRange(1, len - 1),
        nextStep.point,
      ];
    } else {
      newPolygon = [
        ...state.polygon.getRange(0, nextStep.index),
        nextStep.point,
        ...state.polygon.getRange(nextStep.index + 1, len)
      ];
    }
    state = state.copyWith(
      polygon: newPolygon,
      followingSteps: newFollowingSteps,
      previousSteps: newPreviousSteps,
    );
    tryCompletePolygon();
  }

  void tryCompletePolygon() {
    if (state.polygon.length >= 3 &&
        state.polygon.first.distanceTo(state.polygon.last) < Constants.maxDistanceToCompletePolygon) {
      completePolygon();
    } else {
      state = state.copyWith(isComplete: false);
    }
  }

  void completePolygon() {
    final newPolygon = [...state.polygon.getRange(0, state.polygon.length - 1), state.polygon.first];
    state = state.copyWith(
      isComplete: true,
      polygon: newPolygon,
    );
  }

  void toggleGridMode() {
    if (!state.gridModeEnabled) {
      onGridModeEnabled();
    }
    state = state.copyWith(gridModeEnabled: !state.gridModeEnabled);
  }

  void onGridModeEnabled() {
    final newPolygon = state.polygon.map((point) => point.roundToNearestGridNode()).toList();
    state = state.copyWith(polygon: newPolygon);
  }

  void handleIntersections() {
    if (state.polygon.length < 3 || state.isComplete) {
      return;
    }
    final len = state.polygon.length;
    for (int i = 0; i < len - 3; i++) {
      if (checkIntersection(state.polygon[len - 2], state.polygon[len - 1], state.polygon[i], state.polygon[i + 1])) {
        state = state.copyWith(polygon: state.polygon.getRange(0, len - 1).toList());
        return;
      }
    }
  }

  bool checkIntersection(Point p1, Point p2, Point p3, Point p4) {
    int o1 = orientation(p1, p2, p3);
    int o2 = orientation(p1, p2, p4);
    int o3 = orientation(p3, p4, p1);
    int o4 = orientation(p3, p4, p2);

    if (o1 != o2 && o3 != o4) {
      return true;
    }
    if (o1 == 0 && onSegment(p1, p2, p3)) {
      return true;
    }
    if (o2 == 0 && onSegment(p1, p2, p4)) {
      return true;
    }
    if (o3 == 0 && onSegment(p3, p4, p1)) {
      return true;
    }
    if (o4 == 0 && onSegment(p3, p4, p2)) {
      return true;
    }

    return false;
  }

  int orientation(Point p, Point q, Point r) {
    num val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y);
    if (val == 0) {
      return 0;
    }
    return (val > 0) ? 1 : 2;
  }

  bool onSegment(Point p, Point q, Point r) {
    if (q.x <= max(p.x, r.x) && q.x >= min(p.x, r.x) && q.y <= max(p.y, r.y) && q.y >= min(p.y, r.y)) {
      return true;
    }
    return false;
  }

  bool isPointInsidePolygon(Point point) {
    final len = state.polygon.length;

    int crossings = 0;

    for (int i = 0; i < len; i++) {
      Point a = state.polygon[i];
      Point b = state.polygon[(i + 1) % len];

      if ((a.y < point.y && b.y >= point.y || b.y < point.y && a.y >= point.y) &&
          (a.x >= point.x || b.x >= point.x) &&
          (point.x < (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.y)) {
        crossings++;
      }
    }

    return crossings % 2 == 1;
  }
}
