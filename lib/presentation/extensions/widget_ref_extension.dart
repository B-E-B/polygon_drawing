import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polygon_drawing/presentation/providers/state/drawing_notifier.dart';

extension WidgetRefExtension on WidgetRef {
  PolygonDrawingNotifier get notifier => read(drawingNotifierProvider.notifier);
}
