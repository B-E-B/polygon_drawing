import 'dart:math';

import 'package:equatable/equatable.dart';

final class StepInfo extends Equatable {
  final int index;
  final bool isComplete;
  final Point point;

  const StepInfo({
    required this.index,
    required this.isComplete,
    required this.point,
  });

  @override
  List<Object> get props => [index, isComplete, point];
}
