import 'package:dog_marker/helper/simple_dialog_cancel.dart';
import 'package:dog_marker/oss_licenses.dart';
import 'package:flutter/material.dart';

class ThirdPartyLicensePage extends StatelessWidget {
  const ThirdPartyLicensePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lizenzen Bibiliotheken"),
      ),
      body: ListView(
        children: allDependencies
            .map((e) => ListTile(
                  title: Text("${e.name} (${e.version})"),
                  subtitle: Text(e.description.trimRight()),
                  onTap: () {
                    final dialog = SimpleDialogCancel.create(
                        context: context,
                        body: SingleChildScrollView(child: Text(e.license ?? "Keine Lizenz gefunden")));
                    showDialog(context: context, builder: (c) => dialog);
                  },
                ))
            .toList(),
      ),
    );
  }
}
