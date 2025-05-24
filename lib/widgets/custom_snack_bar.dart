import 'package:flutter/material.dart';

import '../global/colors.dart';

void showCustomSnackBar(BuildContext context, String text) {
  final snackBar = SnackBar(
    content: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: snackBarColor,
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: mainTextColor,
          fontSize: 16.0,
        ),
      ),
    ),
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    elevation: 0,
    margin: const EdgeInsets.only(
      bottom: 50,
      left: 70,
      right: 70,
    ),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}