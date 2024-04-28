import 'package:flutter/material.dart';

class SimpleDialogAcceptDeny {
  static AlertDialog create(
      {String title = "",
      Widget? body,
      ValueChanged<String>? onSubmitted,
      bool showCancel = true,
      required BuildContext context}) {
    return AlertDialog(title: title == "" ? null : Text(title), content: body, actions: <Widget>[
      showCancel
          ? TextButton(child: const Text("Abbrechen"), onPressed: () => Navigator.pop(context, ""))
          : Container(),
      TextButton(
          child: const Text("Akzeptieren"),
          onPressed: () {
            Navigator.pop(context, "");
            onSubmitted!("");
          })
    ]);
  }
}
