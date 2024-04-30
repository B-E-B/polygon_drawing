import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:polygon_drawing/common/theme/app_colors.dart';
import 'package:polygon_drawing/common/theme/app_icons_icons.dart';
import 'package:polygon_drawing/presentation/constants/constants.dart';
import 'package:polygon_drawing/presentation/extensions/point_extension.dart';
import 'package:polygon_drawing/presentation/providers/state/drawing_notifier.dart';
import 'package:polygon_drawing/presentation/providers/state/drawing_state.dart';

class PolygonDrawingScreen extends ConsumerWidget {
  static const routeName = '/polygonDrawingScreen';

  PolygonDrawingScreen({Key? key}) : super(key: key);
  final drawingNotifierProvider = StateNotifierProvider<DrawingNotifier, PolygonDrawingState>(
    (ref) => DrawingNotifier(),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(drawingNotifierProvider);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onPanEnd: (details) {
                if (!state.isComplete) {
                  ref.read(drawingNotifierProvider.notifier).registerChanges();
                  ref.read(drawingNotifierProvider.notifier).tryCompletePolygon();
                  ref.read(drawingNotifierProvider.notifier).handleIntersections();
                }
              },
              onPanStart: (details) {
                if (state.isComplete) {
                  ref.read(drawingNotifierProvider.notifier).trySelectPointToMove(
                        Point(
                          details.localPosition.dx,
                          details.localPosition.dy,
                        ),
                      );
                  ref.read(drawingNotifierProvider.notifier).registerChanges();
                } else {
                  ref.read(drawingNotifierProvider.notifier).addPoint(
                        Point(
                          details.localPosition.dx,
                          details.localPosition.dy,
                        ),
                      );
                }
              },
              onPanUpdate: (details) {
                if (state.isComplete && state.indexOfSelectedPoint == null) {
                  return;
                }
                ref.read(drawingNotifierProvider.notifier).movePoint(
                      Point(
                        details.localPosition.dx,
                        details.localPosition.dy,
                      ),
                    );
              },
              child: CustomPaint(
                painter: BackGroundPainter(context: context),
                size: Size.infinite,
              ),
            ),
            Positioned(
              left: 8,
              top: 16,
              child: Container(
                width: 80,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: state.previousSteps.isNotEmpty
                            ? () => ref.read(drawingNotifierProvider.notifier).stepBack()
                            : null,
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
                        onTap: state.followingSteps.isNotEmpty
                            ? () => ref.read(drawingNotifierProvider.notifier).stepForward()
                            : null,
                        child: Icon(
                          AppIcons.arrow_right,
                          size: 20,
                          color: state.followingSteps.isNotEmpty ? AppColors.grey : AppColors.lightGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 10,
              child: GestureDetector(
                onTap: () => ref.read(drawingNotifierProvider.notifier).toggleGridMode(),
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
            ),
            CustomPaint(
              painter: PolygonPainter(
                polygon: state.polygon,
                isComplete: state.isComplete,
              ),
            ),
            Builder(builder: (context) {
              final List<Widget> lineLengths = [];
              if (state.isComplete) {
                for (int i = 0; i < state.polygon.length - 1; i++) {
                  lineLengths.add(
                    Positioned(
                      left: (state.polygon[i].x + state.polygon[i + 1].x) / 2,
                      top: (state.polygon[i].y + state.polygon[i + 1].y) / 2,
                      child: Transform.translate(
                        offset: const Offset(0, 0),
                        child: Transform.rotate(
                          angle: state.polygon[i].angleTo(state.polygon[i + 1]),
                          child: Text(
                            (state.polygon[i].distanceTo(state.polygon[i + 1]) / 160 * 2.54).toStringAsFixed(2),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                    ),
                  );
                }
              }
              return Stack(children: lineLengths);
            }),
            if (!state.isComplete && state.polygon.isNotEmpty)
              Positioned(
                left: state.polygon.last.x - 20,
                top: state.polygon.last.y - 20,
                child: SvgPicture.asset(
                  'assets/images/active_point.svg',
                  width: 40,
                  height: 40,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PolygonPainter extends CustomPainter {
  final List<Point> polygon;
  final bool isComplete;

  PolygonPainter({
    required this.polygon,
    required this.isComplete,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Path path = Path();

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
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class BackGroundPainter extends CustomPainter {
  final BuildContext context;

  BackGroundPainter({required this.context});

  @override
  void paint(Canvas canvas, Size size) {
    double w = MediaQuery.of(context).size.width;
    double h = MediaQuery.of(context).size.height;
    for (int i = 0; i < w; i += Constants.gridCellSize) {
      for (int j = 0; j < h; j += Constants.gridCellSize) {
        canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 1.25, Paint()..color = AppColors.lightblue);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
