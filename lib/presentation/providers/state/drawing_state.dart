import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:polygon_drawing/presentation/models/step_info.dart';

final class PolygonDrawingState extends Equatable {
  final List<Point> polygonVertices;
  final bool isComplete;
  final bool gridModeEnabled;
  final int? indexOfSelectedPoint;
  final List<StepInfo> previousSteps;
  final List<StepInfo> followingSteps;

  const PolygonDrawingState._({
    required this.polygonVertices,
    required this.isComplete,
    required this.gridModeEnabled,
    required this.indexOfSelectedPoint,
    required this.previousSteps,
    required this.followingSteps,
  });

  factory PolygonDrawingState.initial() => const PolygonDrawingState._(
        polygonVertices: [],
        isComplete: false,
        gridModeEnabled: false,
        indexOfSelectedPoint: null,
        previousSteps: [],
        followingSteps: [],
      );

  @override
  List<Object?> get props => [
        polygonVertices,
        isComplete,
        gridModeEnabled,
        indexOfSelectedPoint,
        previousSteps,
        followingSteps,
      ];

  PolygonDrawingState copyWith({
    List<Point>? polygonVertices,
    bool? isComplete,
    bool? gridModeEnabled,
    int? indexOfSelectedPoint,
    List<StepInfo>? previousSteps,
    List<StepInfo>? followingSteps,
  }) =>
      PolygonDrawingState._(
        polygonVertices: polygonVertices ?? this.polygonVertices,
        isComplete: isComplete ?? this.isComplete,
        gridModeEnabled: gridModeEnabled ?? this.gridModeEnabled,
        indexOfSelectedPoint: indexOfSelectedPoint ?? this.indexOfSelectedPoint,
        previousSteps: previousSteps ?? this.previousSteps,
        followingSteps: followingSteps ?? this.followingSteps,
      );
}
