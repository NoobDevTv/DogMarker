import 'dart:io';
import 'package:dog_marker/main.dart';
import 'package:dog_marker/saved_entry_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

class MainPage extends HookConsumerWidget {
  const MainPage({super.key});

  static String distanceText(double latitute, double longitute, double latitude2, double longitude2) {
    final distInMeters = distanceHelper.distance(LatLng(latitute, longitute), LatLng(latitude2, longitude2));
    if (distInMeters >= 1000) {
      return "${NumberFormat.decimalPatternDigits(locale: 'de', decimalDigits: 2).format(distInMeters / 1000)} km";
    }
    return "$distInMeters m";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(savedEntryManagerProvider);
    final _ = ref.watch(getPermissionProvider);
    final location = ref.watch(locationProvider);
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text(
            "Dog Marker",
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.sort),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                ref.invalidate(locationProvider);
              },
            )
          ],
        ),
        body: ListView(
            children: data.map((e) {
          return Dismissible(
              key: Key(e.guid),
              // direction: DismissDirection.endToStart,
              secondaryBackground: const Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [Icon(Icons.archive)],
              ),
              onDismissed: (direction) {
                if (direction == DismissDirection.startToEnd) {
                  ref.read(savedEntryManagerProvider.notifier).deleteEntry(e);
                }
              },
              background: const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [Icon(Icons.delete)],
              ),
              child: ListTile(
                  leading: kIsWeb ? Image.network(e.imagePath) : Image.file(File(e.imagePath)),
                  title: Text(e.title),
                  subtitle: Text(e.description),
                  trailing: location.when(
                      data: (d) => Text(distanceText(e.latitute, e.longitute, d.latitude, d.longitude),
                          locale: const Locale('de')),
                      error: ((error, stackTrace) => Text(error.toString())),
                      loading: () => const Text("Calculating"))));
        }).toList(growable: false)),
        floatingActionButtonLocation: ExpandableFab.location,
        floatingActionButton: ExpandableFab(
          type: ExpandableFabType.up,
          pos: ExpandableFabPos.right,
          overlayStyle: ExpandableFabOverlayStyle(blur: 3.0),
          openButtonBuilder:
              RotateFloatingActionButtonBuilder(child: const Icon(Icons.pets), fabSize: ExpandableFabSize.regular),
          distance: 64,
          children: [
            FloatingActionButton.small(
              heroTag: "add_action_button",
              tooltip: 'Hinzufügen',
              onPressed: () {
                Navigator.pushNamed(context, "/add");
              },
              child: const Icon(Icons.add),
            ),
            FloatingActionButton.small(
              heroTag: "main_floating",
              child: const Icon(Icons.directions_walk_outlined),
              onPressed: () {
                Navigator.pushNamed(context, "/walking");
              },
            ),
            FloatingActionButton.small(
              heroTag: "shopping_action_button",
              child: const Icon(Icons.shopping_bag),
              onPressed: () {},
            ),
          ],
        )
        // (FloatingActionButton(

        //   onPressed: () {
        //     ;
        //   },
        //   tooltip: 'Hinzufügen',
        //   child: const Icon(Icons.add),
        // ),
        );
  }
}
