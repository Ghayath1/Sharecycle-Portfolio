import 'package:flutter/material.dart';
import 'package:sharecycleapp/theme/color.dart'; // ✅ correct

import 'package:sharecycleapp/theme/type.dart'; // 👈 Add this import

final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: purple40,
  fontFamily: 'Roboto',
  textTheme: appTextTheme, // 👈 Custom typography
  colorScheme: ColorScheme.light(
    primary: purple40,
    secondary: purpleGrey40,
    tertiary: pink40,
    background: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onTertiary: Colors.white,
    onBackground: Colors.black,
    surface: Colors.white,
    onSurface: Colors.black,
  ),
);

final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: purple80,
  fontFamily: 'Roboto',
  textTheme: appTextTheme, // 👈 Custom typography
  colorScheme: ColorScheme.dark(
    primary: purple80,
    secondary: purpleGrey80,
    tertiary: pink80,
    background: Colors.black,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onTertiary: Colors.white,
    onBackground: Colors.white,
    surface: Colors.grey[900]!,
    onSurface: Colors.white,
    
  ),
);
