import 'package:flutter/material.dart';
import 'package:polygon_drawing/common/theme/app_colors.dart';

class AppTheme {
  static ThemeData defaults() {
    const mainFontFamily = 'SFProText';

    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: const TextTheme(
        //line length
        titleMedium: TextStyle(
          fontFamily: mainFontFamily,
          color: AppColors.blue,
          fontWeight: FontWeight.w500,
          fontStyle: FontStyle.normal,
          fontSize: 11,
          height: 1.18,
        ),
      ),
    );
  }
}
