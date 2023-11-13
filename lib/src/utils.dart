import 'dart:developer' as developer;
import 'package:flutter/material.dart';

void debugMsg(String msg) {
  developer.log(msg, name: 'xc-ski-tracker.info');
}

void errorMsg(String msg) {
  developer.log(msg, name: 'xc-ski-tracker.error');
}

int fibonacci(int n) => n <= 2 ? 1 : fibonacci(n - 2) + fibonacci(n - 1);

Map<String, Color> nameToColor = {
  'Red': Colors.red,
  'Orange': Colors.orange,
  'Yellow': Colors.yellow,
  'Green': Colors.green,
  'Blue': Colors.blue,
  'Indigo': Colors.indigo,
  'White': Colors.white,
  'Magenta': Colors.purpleAccent,
  'Plum': Colors.purple,
  'TrackMe': Colors.blueAccent
};
