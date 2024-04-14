import 'package:flutter/material.dart';

class SimpleDialogCancel {
  static AlertDialog create(
      {String title = "", Widget? body, ValueChanged<String>? onSubmitted, required BuildContext context}) {
    return AlertDialog(title: title == "" ? null : Text(title), content: body, actions: <Widget>[
      TextButton(child: const Text("Abbrechen"), onPressed: () => Navigator.pop(context, "")),
    ]);
  }
}
