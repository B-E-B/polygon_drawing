import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:polygon_drawing/presentation/models/step_info.dart';

class PolygonDrawingState extends Equatable {
  const PolygonDrawingState({
    required this.polygon,
    this.isComplete = false,
    this.gridModeEnabled = false,
    this.indexOfSelectedPoint,
    this.previousSteps = const [],
    this.followingSteps = const [],
  });

  final List<Point> polygon;
  final bool isComplete;
  final bool gridModeEnabled;
  final int? indexOfSelectedPoint;
  final List<StepInfo> previousSteps;
  final List<StepInfo> followingSteps;

  PolygonDrawingState copyWith({
    List<Point>? polygon,
    bool? isComplete,
    bool? gridModeEnabled,
    int? indexOfSelectedPoint,
    List<StepInfo>? previousSteps,
    List<StepInfo>? followingSteps,
  }) {
    return PolygonDrawingState(
      polygon: polygon ?? this.polygon,
      isComplete: isComplete ?? this.isComplete,
      gridModeEnabled: gridModeEnabled ?? this.gridModeEnabled,
      indexOfSelectedPoint: indexOfSelectedPoint ?? this.indexOfSelectedPoint,
      previousSteps: previousSteps ?? this.previousSteps,
      followingSteps: followingSteps ?? this.followingSteps,
    );
  }

  @override
  List<Object?> get props => [
        polygon,
        isComplete,
        gridModeEnabled,
        indexOfSelectedPoint,
        previousSteps,
        followingSteps,
      ];
}
