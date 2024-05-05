import 'dart:collection';

import 'package:dog_marker/helper/iterable_extensions.dart';
import 'package:dog_marker/helper/simple_dialog_accept_deny.dart';
import 'package:dog_marker/main.dart';
import 'package:dog_marker/pages/location_radius_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
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

  Future restartForegroundService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    }
  }

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
                          builder: (context) => const LocationRadiusPage(
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
                                title: Text("Heimatadresse"),
                              ),
                          fullscreenDialog: true))
                  .then((value) => restartForegroundService());
            },
          ),
          ListTile(
            title: const Text("Setze Warnradius"),
            onTap: () {
              Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LocationRadiusPage(
                                radiusMap: [
                                  0.01,
                                  0.02,
                                  0.03,
                                  0.04,
                                  0.05,
                                  0.075,
                                  0.1,
                                  0.125,
                                  0.15,
                                  0.175,
                                  0.2,
                                  0.25,
                                  0.3,
                                  0.35,
                                  0.4,
                                  0.45,
                                  0.5
                                ],
                                title: Text("Warnradius"),
                                keyValueStorePrefix: "warnradius",
                                showAddressInformation: false,
                              ),
                          fullscreenDialog: true))
                  .then((value) => restartForegroundService());
            },
          ),
          ListTile(
            title: const Text("Setze Abfrageradius"),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const LocationRadiusPage(
                            radiusMap: [
                              1,
                              2,
                              3,
                              4,
                              5,
                              7.5,
                              10,
                              12.5,
                              15,
                              17.5,
                              20,
                              25,
                              30,
                              35,
                              40,
                              50,
                              60,
                              70,
                              80,
                              100,
                              120,
                              140,
                              160,
                              180,
                              200,
                              250,
                              300,
                              350,
                              400,
                              550,
                              600,
                              700,
                              800,
                              900,
                              1000
                            ],
                            title: Text("Abfrageradius"),
                            keyValueStorePrefix: "entryradius",
                            showAddressInformation: false,
                          ),
                      fullscreenDialog: true));
            },
          ),
          ListTile(
            title: Text("Setzte Warnstufe"),
            onTap: () {
              final diag = SimpleDialogAcceptDeny.create(
                context: context,
                showCancel: false,
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
                showCancel: false,
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
          ),
          ListTile(
            title: Text("Standortabfrageintervalleinstellung"),
            onTap: () {
              final diag = SimpleDialogAcceptDeny.create(
                context: context,
                showCancel: false,
                body: HookBuilder(
                  builder: ((context) {
                    final refreshinterval = useState(keyValueStore.getInt("location_refresh_interval") ?? 5);
                    return Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text(
                          "Einstellung der Häufigkeit der Abfrage des Standorts in Sekunden.\r\nZu hohe Werte könnten zu verspäteten Benachrichtiungen führen."),
                      Container(
                        height: 16,
                      ),
                      Slider(
                          value: refreshinterval.value.toDouble(),
                          min: 1,
                          max: 300,
                          divisions: 300,
                          label: "${refreshinterval.value}s",
                          onChanged: (v) {
                            refreshinterval.value = v.toInt();
                            keyValueStore.setInt("location_refresh_interval", refreshinterval.value);
                            ref.read(locationIntervalProvider.notifier).state = v.toInt() * 1000;
                          }),
                      Text("${refreshinterval.value} Sekunden"),
                    ]);
                  }),
                ),
                onSubmitted: (value) {
                  restartForegroundService();
                },
              );
              showDialog(
                context: context,
                builder: (context) => diag,
              );
            },
          ),
          ListTile(
            title: const Text("Über"),
            onTap: () => {Navigator.pushNamed(context, "/about")},
          )
        ],
      ),
    );
  }
}
