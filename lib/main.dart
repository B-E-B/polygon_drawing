import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:polygon_drawing/common/theme/app_theme.dart';
import 'package:polygon_drawing/presentation/screens/polygon_drawing_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await configureDependencies(Environment.dev);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Polygon Drawing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.defaults(),
      initialRoute: PolygonDrawingScreen.routeName,
      routes: {
        PolygonDrawingScreen.routeName: (context) => PolygonDrawingScreen(),
      },
    );
  }
}
