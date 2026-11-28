import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jatiluxe_app/constants/theme.dart';

void main() {
  test('app uses the JatiLuxe dark theme', () {
    expect(AppTheme.darkTheme.brightness, Brightness.dark);
  });
}
