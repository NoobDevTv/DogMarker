import 'dart:io';

import 'package:dog_marker/add_location_page.dart';
import 'package:dog_marker/saved_entry_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:geolocator/geolocator.dart';

part 'main.g.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

@riverpod
Future<LocationPermission> getPermission(GetPermissionRef ref) async {
  final permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
    return permission;
  }

  await Geolocator.requestPermission();
  return await Geolocator.checkPermission();
}

@riverpod
Stream<Position> location(LocationRef ref) {
  if (Platform.isAndroid) {
    return Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.best,
            intervalDuration: Duration(seconds: 2),
            foregroundNotificationConfig: ForegroundNotificationConfig(
                notificationTitle: "Hundegang",
                notificationText: "Aktuell wird die Hunderunde getrackt",
                enableWakeLock: true)));
  }

  return Geolocator.getPositionStream(locationSettings: LocationSettings(accuracy: LocationAccuracy.best));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  return runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const MyApp(),
  ));
}

// final getSavedEntriesProvider = StateProvider<List<SavedEntry>>((ref) => [
//       SavedEntry("Test 1", "Hundeaa", "imagePath", 50.8, 7.77),
//       SavedEntry("Test 2", "Scherben am Wegrand", "imagePath", 51.01, 7.56),
//     ]);

@JsonSerializable()
class SavedEntry {
  late String guid;
  String title;
  String description;
  String imagePath;
  double longitute;
  double latitute;

  SavedEntry(this.title, this.description, this.imagePath, this.longitute, this.latitute) {
    guid = const Uuid().v4();
  }

  factory SavedEntry.fromJson(Map<String, dynamic> json) => _$SavedEntryFromJson(json);

  Map<String, dynamic> toJson() => _$SavedEntryToJson(this);
}

class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices =>
      {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.stylus, PointerDeviceKind.trackpad};
}

class MyApp extends HookConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
        scrollBehavior: CustomScrollBehavior(),
        debugShowCheckedModeBanner: false,
        title: 'Dog Marker',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const MainPage());
  }
}

class MainPage extends HookConsumerWidget {
  const MainPage({super.key});

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
                  //leading: kIsWeb ? Container() : Image.file(File(e.imagePath)),
                  title: Text(e.title),
                  subtitle: Text(e.description),
                  trailing: const Text("500m")));
        }).toList(growable: false)),
        floatingActionButtonLocation: ExpandableFab.location,
        floatingActionButton: ExpandableFab(
          type: ExpandableFabType.up,
          pos: ExpandableFabPos.right,
          overlayStyle: ExpandableFabOverlayStyle(blur: 3.0),
          openButtonBuilder:
              RotateFloatingActionButtonBuilder(child: const Icon(Icons.pets), fabSize: ExpandableFabSize.regular),
          children: [
            FloatingActionButton.small(
              child: Icon(Icons.add),
              tooltip: 'Hinzufügen',
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (c) => const AddLocationPage()));
              },
            ),
            FloatingActionButton.small(
              child: Icon(Icons.directions_walk_outlined),
              onPressed: () {},
            ),
            FloatingActionButton.small(
              child: Icon(Icons.shopping_bag),
              onPressed: () {},
            ),
          ],
          distance: 64,
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
