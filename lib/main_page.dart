import 'dart:io';
import 'package:dog_marker/add_location_page.dart';
import 'package:dog_marker/api.dart';
import 'package:dog_marker/main.dart';
import 'package:dog_marker/saved_entry.dart';
import 'package:dog_marker/saved_entry_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'main_page.g.dart';

@riverpod
Future<List<SavedEntry>> serverEntries(ServerEntriesRef ref) async {
  final location = ref.watch(locationProvider).valueOrNull;
  if (location == null) return [];

  final userId = ref.read(userIdProvider);

  return await Api.getAllEntries(userId: userId, latLng: LatLng(location.latitude, location.longitude));
}

@riverpod
String userId(UserIdRef ref) {
  final sharedPrefs = ref.watch(sharedPreferencesProvider);
  if (sharedPrefs.containsKey("userId")) return sharedPrefs.getString("userId")!;
  final userId = const Uuid().v4().toString();
  sharedPrefs.setString("userId", userId);
  return userId;
}

@riverpod
List<SavedEntry> sortedEntries(SortedEntriesRef ref, int sort) {
  var data = ref.watch(savedEntryManagerProvider);
  final location = ref.watch(locationProvider);

  switch (sort) {
    case 0:
      data.sort((a, b) => a.title.compareTo(b.title));
      break;
    case 1:
      data.sort((a, b) => b.title.compareTo(a.title));
      break;
    case 2:
      location.whenData((l) {
        final curPos = LatLng(l.latitude, l.longitude);
        data.sort((a, b) => distanceHelper
            .distance(LatLng(a.latitude, a.longitude), curPos)
            .compareTo(distanceHelper.distance(LatLng(b.latitude, b.longitude), curPos)));
      });

      break;
    case 3:
      location.whenData((l) {
        final curPos = LatLng(l.latitude, l.longitude);
        data.sort((a, b) => distanceHelper
            .distance(LatLng(b.latitude, b.longitude), curPos)
            .compareTo(distanceHelper.distance(LatLng(a.latitude, a.longitude), curPos)));
      });
      break;
    case 4:
      data.sort((a, b) => a.createDate.compareTo(b.createDate));
      break;
    case 5:
      data.sort((a, b) => b.createDate.compareTo(a.createDate));
      break;
  }
  return data;
}

@riverpod
List<SavedEntry> filterEntries(FilterEntriesRef ref, int sort, String filter) {
  final sorted = ref.watch(sortedEntriesProvider(sort));
  if (filter == "") return sorted;
  return sorted
      .where((element) =>
          element.title.toLowerCase().contains(filter.toLowerCase()) ||
          element.description.toLowerCase().contains(filter.toLowerCase()) ||
          DateFormat("dd.MM.yyyy HH:mm").format(element.createDate).contains(filter))
      .toList();
}

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
    final sortValue = useState<int>(2);
    final searchController = useTextEditingController();
    final searchMode = useState(false);
    final searchText = useState("");
    final data = ref.watch(filterEntriesProvider(sortValue.value, searchText.value));

    final __ = ref.read(serverEntriesProvider).whenData((value) {
      final savedEntryManager = ref.read(savedEntryManagerProvider.notifier);
      for (var element in value) {
        savedEntryManager.updateEntry(element);
      }
    });

    final _ = ref.watch(getPermissionProvider);
    final location = ref.watch(locationProvider);
    return Scaffold(
        appBar: searchMode.value
            ? AppBar(
                // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: SearchBar(
                    controller: searchController,
                    onChanged: (value) {
                      searchText.value = value;
                    },
                    leading: Tooltip(
                      message: 'Disable Search Mode',
                      child: IconButton(
                        onPressed: () {
                          searchMode.value = false;
                          searchController.text = searchText.value = "";
                        },
                        icon: const Icon(Icons.arrow_back_sharp),
                      ),
                    )),
              )
            : AppBar(
                // backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                title: const Text(
                  "Dog Marker",
                ),
                actions: [
                  PopupMenuButton<int>(
                      onSelected: (final value) => sortValue.value = value,
                      itemBuilder: (context) {
                        return [
                          const PopupMenuItem<int>(value: 0, child: Text("Name asc")),
                          const PopupMenuItem<int>(value: 1, child: Text("Name desc")),
                          const PopupMenuItem<int>(value: 2, child: Text("Entfernung asc")),
                          const PopupMenuItem<int>(value: 3, child: Text("Entfernung desc")),
                          const PopupMenuItem<int>(value: 4, child: Text("Alter asc")),
                          const PopupMenuItem<int>(value: 5, child: Text("Alter desc")),
                        ];
                      },
                      icon: const Icon(Icons.sort)),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      searchMode.value = true;
                    },
                  )
                ],
              ),
        body: ListView(
            children: data.map((e) {
          final diffToNow = DateTime.now().difference(e.createDate);
          return Dismissible(
            key: Key(e.guid),
            // direction: DismissDirection.endToStart,
            secondaryBackground: const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [Icon(Icons.archive)],
            ),
            onDismissed: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                ref.read(savedEntryManagerProvider.notifier).deleteEntry(e);
                // VgyMeUploader.deleteEntry(e).then((value) {
                //   if (!value) ref.read(savedEntryManagerProvider.notifier).addEntry(e);
                // });
              }
            },
            background: const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [Icon(Icons.delete)],
            ),
            child: ListTile(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddLocationPage(
                        toEdit: e,
                      ),
                    ));
              },
              leading: kIsWeb || (e.uploaded ?? false) || e.imagePath.startsWith("http")
                  ? Image.network(e.imagePath)
                  : Image.file(File(e.imagePath)),
              title: Text(e.title),
              subtitle: Text(e.description),
              trailing: Column(
                children: [
                  Container(
                    margin: diffToNow.inHours > 24 ? const EdgeInsets.only(bottom: 16.0) : const EdgeInsets.only(),
                    child: Text(DateFormat("dd.MM.yyyy").format(e.createDate)),
                    // Text(DateFormat("HH:mm.ss").format(e.createDate)),
                  ),
                  diffToNow.inHours > 24
                      ? const SizedBox(height: 0, width: 0)
                      : Text(DateFormat("HH:mm").format(e.createDate)),
                  location.when(
                    data: (d) => Text(distanceText(e.latitude, e.longitude, d.latitude, d.longitude),
                        locale: const Locale('de')),
                    error: ((error, stackTrace) => Text(
                          error.toString(),
                        )),
                    loading: () => const Text("Calculating"),
                  )
                ],
              ),
            ),
          );
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
