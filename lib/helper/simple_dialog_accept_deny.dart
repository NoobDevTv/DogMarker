import 'package:flutter/material.dart';

class SimpleDialogAcceptDeny {
  static AlertDialog create(
      {String title = "", Widget? body, ValueChanged<String>? onSubmitted, required BuildContext context}) {
    return AlertDialog(title: title == "" ? null : Text(title), content: body, actions: <Widget>[
      TextButton(child: const Text("Abbrechen"), onPressed: () => Navigator.pop(context, "")),
      TextButton(
          child: const Text("Akzeptieren"),
          onPressed: () {
            Navigator.pop(context, "");
            onSubmitted!("");
          })
    ]);
  }
}
