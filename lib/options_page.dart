import 'package:dog_marker/helper/simple_dialog_accept_deny.dart';
import 'package:dog_marker/main.dart';
import 'package:dog_marker/pages/set_home_location_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';

class OptionsPage extends HookConsumerWidget {
  const OptionsPage({super.key});
  static const List<String> warningLevels = <String>["Information", "Warnung", "Gefahr"];
/*
   1. Radius für Entries
   2. Home Location (Local Only!)
   3. Warnstufe
   4. Upload / Downloader Konfigurierbar (Privacy)
 */
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text("Optionen")),
      body: ListView(
        children: [
          ListTile(
            title: const Text("Setze Heimatadresse"),
            onTap: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => SetHomeLocationPage(), fullscreenDialog: true));
            },
          ),
          ListTile(
            title: DropdownMenu<String>(
              initialSelection: warningLevels.first,
              onSelected: (String? value) {},
              label: const Text("Warnstufe"),
              dropdownMenuEntries: warningLevels.map<DropdownMenuEntry<String>>((String value) {
                return DropdownMenuEntry<String>(value: value, label: value);
              }).toList(),
            ),
          )
        ],
      ),
    );
  }
}
