import 'package:flutter/material.dart';

ThemeData transformTheme(ThemeData theme) => theme.copyWith(
  inputDecorationTheme: theme.inputDecorationTheme.copyWith(
    hintStyle: theme.inputDecorationTheme.hintStyle!.copyWith(
      color: Colors.grey[500],
    ),
  ),
);

const ButtonStyle controlButtonStyle = ButtonStyle(
  padding: WidgetStatePropertyAll(.zero),
  minimumSize: WidgetStatePropertyAll(Size(32, 32)),
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
  ),
  iconSize: WidgetStatePropertyAll(18),
);

const ButtonStyle resetButtonStyle = ButtonStyle(
  padding: WidgetStatePropertyAll(.zero),
  minimumSize: WidgetStatePropertyAll(Size(40, 40)),
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
  ),
  iconSize: WidgetStatePropertyAll(18),
);
