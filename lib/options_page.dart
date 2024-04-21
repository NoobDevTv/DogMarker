import 'dart:collection';

import 'package:dog_marker/helper/iterable_extensions.dart';
import 'package:dog_marker/helper/simple_dialog_accept_deny.dart';
import 'package:dog_marker/main.dart';
import 'package:dog_marker/pages/set_home_location_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OptionsPage extends HookConsumerWidget {
  const OptionsPage({super.key});
  static const List<String> warningLevels = <String>["Information", "Warnung", "Gefahr"];

  static const privacyLevels = {
    "Upload und Download": "Volle Serverkommunikation",
    "Nur Upload": "Steuere neue Beiträge zum Community bei, aber erhalte keine",
    "Nur Download": "Lade Einträge von anderen, aber deine werden nicht geteilt",
    "Volle Privatsphäre": "Es werden keine Einträge herunter oder hochgeladen"
  };
/*
   1. Radius für Entries
   2. Home Location (Local Only!) (Possibility to disable)
   3. Warnstufe
   4. Upload / Downloader Konfigurierbar (Privacy)
    = {
    0: 1,
    1: 2,
    2: 3,
    3: 4,
    4: 5,
    5: 10,
    6: 15,
    7: 20,
    8: 30,
    9: 50,
    10: 75,
    11: 100,
    12: 200,
    13: 300,
    14: 400,
    15: 20000
  }
 */
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyValueStore = ref.watch(sharedPreferencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Optionen")),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Setze Heimatadresse"),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const SetHomeLocationPage(
                            radiusMap: [
                              0.01,
                              0.02,
                              0.03,
                              0.04,
                              0.05,
                              0.1,
                              0.2,
                              0.3,
                              0.4,
                              0.5,
                              0.75,
                              1,
                              1.5,
                            ],
                          ),
                      fullscreenDialog: true));
            },
          ),
          ListTile(
            title: Text("Setzte Warnstufe"),
            onTap: () {
              final diag = SimpleDialogAcceptDeny.create(
                context: context,
                body: HookBuilder(
                  builder: ((context) {
                    final warningLevel = useState(keyValueStore.getInt("warning_level") ?? 0);
                    return Column(
                      // alignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: warningLevels
                          .mapIndexed(
                            (e, i) => RadioListTile<int>(
                                title: Text(e),
                                value: i,
                                groupValue: warningLevel.value,
                                onChanged: (v) {
                                  warningLevel.value = v!;
                                  keyValueStore.setInt("warning_level", v);
                                }),
                          )
                          .toList(),
                    );
                  }),
                ),
                onSubmitted: (value) {},
              );
              showDialog(
                context: context,
                builder: (context) => diag,
              );
            },
          ),
          ListTile(
            title: Text("Datenschutzeinstellungen"),
            onTap: () {
              final diag = SimpleDialogAcceptDeny.create(
                context: context,
                body: HookBuilder(
                  builder: ((context) {
                    final privacyLevel = useState(keyValueStore.getInt("privacy_level") ?? 0);
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: privacyLevels.entries
                          .mapIndexed(
                            (e, i) => RadioListTile<int>(
                                isThreeLine: true,
                                title: Text(e.key),
                                subtitle: Text(e.value),
                                value: i,
                                groupValue: privacyLevel.value,
                                onChanged: (v) {
                                  keyValueStore.setInt("privacy_level", v!);
                                  privacyLevel.value = v;
                                }),
                          )
                          .toList(),
                    );
                  }),
                ),
                onSubmitted: (value) {},
              );
              showDialog(
                context: context,
                builder: (context) => diag,
              );
            },
          )
        ],
      ),
    );
  }
}
