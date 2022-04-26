import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

void debugMsg(String msg) {
  developer.log(msg, name: 'xc-ski-tracker.info');
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

showDesc(BuildContext context, String title, String desc) async {
  await showDialog<String>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: Html(data: desc),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, 'OK'),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
