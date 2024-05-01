import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polygon_drawing/common/theme/app_colors.dart';
import 'package:polygon_drawing/common/theme/app_icons_icons.dart';
import 'package:polygon_drawing/presentation/constants/constants.dart';
import 'package:polygon_drawing/presentation/extensions/point_extension.dart';
import 'package:polygon_drawing/presentation/extensions/widget_ref_extension.dart';
import 'package:polygon_drawing/presentation/providers/state/drawing_notifier.dart';
import 'package:polygon_drawing/presentation/providers/state/drawing_state.dart';

final class PolygonDrawingScreen extends ConsumerWidget {
  static const routeName = '/polygonDrawingScreen';

  const PolygonDrawingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(drawingNotifierProvider);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            _WorkSpace(state),
            _StepActionButton(state),
            _GridModeButton(state),
            CustomPaint(
              painter: _PolygonPainter(
                polygon: state.polygonVertices,
                isComplete: state.isComplete,
              ),
            ),
            _LinesDimensionsDisplay(state),
            if (!state.isComplete && state.polygonVertices.isNotEmpty) _ActivePoint(state),
          ],
        ),
      ),
    );
  }
}

final class _WorkSpace extends ConsumerWidget {
  final PolygonDrawingState state;

  const _WorkSpace(this.state);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onPanEnd: (_) {
        if (!state.isComplete) {
          ref.notifier.registerChanges();
          ref.notifier.tryCompletePolygon();
        }
        ref.notifier.handleIntersections();
      },
      onPanStart: (details) => state.isComplete
          ? ref.notifier.trySelectPointToMove(
              Point(
                details.localPosition.dx,
                details.localPosition.dy,
              ),
            )
          : ref.notifier.addPoint(
              Point(
                details.localPosition.dx,
                details.localPosition.dy,
              ),
            ),
      onPanUpdate: (details) {
        if (state.isComplete && state.indexOfSelectedPoint == null) return;
        ref.notifier.movePoint(
          Point(
            details.localPosition.dx,
            details.localPosition.dy,
          ),
        );
      },
      child: CustomPaint(
        painter: _BackGroundPainter(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
        ),
        size: Size.infinite,
      ),
    );
  }
}

final class _BackGroundPainter extends CustomPainter {
  final double width;
  final double height;

  const _BackGroundPainter({
    required this.width,
    required this.height,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < width; i += Constants.gridCellSize) {
      for (int j = 0; j < height; j += Constants.gridCellSize) {
        canvas.drawCircle(
          Offset(i.toDouble(), j.toDouble()),
          1.25,
          Paint()..color = AppColors.lightBlue,
        );
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

final class _StepActionButton extends ConsumerWidget {
  final PolygonDrawingState state;

  const _StepActionButton(this.state);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      left: 8,
      top: 16,
      child: Container(
        width: 80,
        height: 32,
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.all(Radius.circular(5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: state.previousSteps.isNotEmpty ? () => ref.notifier.stepBack() : null,
              child: Icon(
                AppIcons.arrow_left,
                size: 20,
                color: state.previousSteps.isNotEmpty ? AppColors.grey : AppColors.lightGrey,
              ),
            ),
            const VerticalDivider(
              color: AppColors.lightGrey,
              thickness: 0.44,
              indent: 10,
              endIndent: 10,
              width: 20,
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: state.followingSteps.isNotEmpty ? () => ref.notifier.stepForward() : null,
              child: Icon(
                AppIcons.arrow_right,
                size: 20,
                color: state.followingSteps.isNotEmpty ? AppColors.grey : AppColors.lightGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _GridModeButton extends ConsumerWidget {
  final PolygonDrawingState state;

  const _GridModeButton(this.state);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      right: 16,
      top: 10,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.notifier.toggleGridMode(),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                offset: Offset(0, 2),
                color: AppColors.shadow,
                spreadRadius: 0,
                blurRadius: 10,
              )
            ],
          ),
          padding: const EdgeInsets.all(13),
          child: Icon(
            AppIcons.sharp,
            size: 20,
            color: state.gridModeEnabled ? AppColors.grey : AppColors.lightGrey,
          ),
        ),
      ),
    );
  }
}

final class _PolygonPainter extends CustomPainter {
  final List<Point> polygon;
  final bool isComplete;

  _PolygonPainter({
    required this.polygon,
    required this.isComplete,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();

    final linePaint = Paint()
      ..color = AppColors.black
      ..strokeWidth = 7.0;

    final circleFillPaint = Paint()
      ..color = isComplete ? AppColors.white : AppColors.blue
      ..style = PaintingStyle.fill;

    final circleBorderPaint = Paint()
      ..color = isComplete ? AppColors.grey : AppColors.white
      ..strokeWidth = isComplete ? 1 : 1.77
      ..style = PaintingStyle.stroke;

    final polygonFillPaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.fill;

    if (polygon.isNotEmpty) {
      path.moveTo(polygon[0].x.toDouble(), polygon[0].y.toDouble());
    }

    for (int i = 1; i < polygon.length; i++) {
      path.lineTo(polygon[i].x.toDouble(), polygon[i].y.toDouble());
    }

    if (isComplete) {
      canvas.drawPath(path, polygonFillPaint);
    }

    for (int i = 0; i < polygon.length - 1; i++) {
      canvas.drawLine(
        Offset(polygon[i].x.toDouble(), polygon[i].y.toDouble()),
        Offset(polygon[i + 1].x.toDouble(), polygon[i + 1].y.toDouble()),
        linePaint,
      );
      canvas.drawCircle(
        Offset(polygon[i].x.toDouble(), polygon[i].y.toDouble()),
        isComplete ? 5.4 : 6.25,
        circleFillPaint,
      );
      canvas.drawCircle(
        Offset(polygon[i].x.toDouble(), polygon[i].y.toDouble()),
        isComplete ? 5.4 : 6.25,
        circleBorderPaint,
      );
    }

    if (isComplete) {
      canvas.drawCircle(
        Offset(polygon.last.x.toDouble(), polygon.last.y.toDouble()),
        5.4,
        circleFillPaint,
      );
      canvas.drawCircle(
        Offset(polygon.last.x.toDouble(), polygon.last.y.toDouble()),
        5.4,
        circleBorderPaint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

final class _LinesDimensionsDisplay extends ConsumerWidget {
  final PolygonDrawingState state;

  const _LinesDimensionsDisplay(this.state);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Builder(
      builder: (context) {
        if (!state.isComplete) return const SizedBox();

        final List<Widget> lineLengthWidgets = [];
        final List<Point> polygonVertices = state.polygonVertices;

        for (int i = 0; i < polygonVertices.length - 1; i++) {
          final point1 = polygonVertices[i];
          final point2 = polygonVertices[i + 1];

          final lineLength = point1.distanceTo(point2);
          final lineInclinationAngle = point1.angleTo(point2);
          final sinLineInclinationAngle = sin(lineInclinationAngle);
          final cosLineInclinationAngle = cos(lineInclinationAngle);
          final flipCondition = lineInclinationAngle < -pi / 2 || lineInclinationAngle > pi / 2;
          final isPointInside =
              ref.notifier.isPointInsidePolygon(Point(15 * sinLineInclinationAngle, 15 * cosLineInclinationAngle));
          final offsetByLineCenter = Offset(
            isPointInside ? 15 * sinLineInclinationAngle : -15 * sinLineInclinationAngle,
            isPointInside ? -15 * cosLineInclinationAngle : 15 * cosLineInclinationAngle,
          );
          lineLengthWidgets.add(
            Positioned(
              left: (point1.x + point2.x) / 2 - 15,
              top: (point1.y + point2.y) / 2 - 6.5,
              child: Transform.translate(
                offset: offsetByLineCenter,
                child: Transform.rotate(
                  angle: lineInclinationAngle,
                  child: Transform.flip(
                    flipY: flipCondition,
                    flipX: flipCondition,
                    child: SizedBox(
                      width: 30,
                      height: 13,
                      child: Text(
                        (lineLength / 160 * 2.54).toStringAsFixed(2), //160 dp = 1 inch = 2.54 cm
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Stack(children: lineLengthWidgets);
      },
    );
  }
}

final class _ActivePoint extends StatelessWidget {
  final PolygonDrawingState state;

  const _ActivePoint(this.state);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: state.polygonVertices.last.x - 20,
      top: state.polygonVertices.last.y - 20,
      child: SvgPicture.asset(
        'assets/images/active_point.svg',
        width: 40,
        height: 40,
      ),
    );
  }
}
