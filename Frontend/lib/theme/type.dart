import 'package:flutter/material.dart';

final TextTheme appTextTheme = const TextTheme(
  bodyLarge: TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.normal,
    fontSize: 16,
    height: 1.5, // 24 / 16 = 1.5
    letterSpacing: 0.5,
  ),
  // Optional additional text styles:
  /*
  titleLarge: TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.normal,
    fontSize: 22,
    height: 1.27, // 28 / 22
    letterSpacing: 0,
  ),
  labelSmall: TextStyle(
    fontFamily: 'Roboto',
    fontWeight: FontWeight.w500,
    fontSize: 11,
    height: 1.45, // 16 / 11
    letterSpacing: 0.5,
  ),
  */
);
