import 'dart:io';

import 'package:dog_marker/background_walking_handler.dart';
import 'package:dog_marker/walking_manager.dart';
import 'package:fl_location/fl_location.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'my_app.dart';

part 'main.g.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

const distanceHelper = Distance();

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(BackgroundWalkingHandler());
}

final locationIntervalProvider =
    StateProvider<int>((ref) => (ref.read(sharedPreferencesProvider).getInt("location_refresh_interval") ?? 5) * 1000);

@riverpod
Future<LocationPermission> getPermission(GetPermissionRef ref) async {
  // final permission = await Geolocator.checkPermission();
  final permission = await FlLocation.checkLocationPermission();

  if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
    return permission;
  }

  return await FlLocation.requestLocationPermission();
  // await Geolocator.requestPermission();
  // return await Geolocator.checkPermission();
}

@riverpod
Stream<Location> location(LocationRef ref) {
  final interval = ref.watch(locationIntervalProvider);
  if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
    return FlLocation.getLocationStream(interval: interval);
  }

  return const Stream.empty();
  // if (kIsWeb) {
  //   return Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.best));
  // }
  // if (Platform.isAndroid) {
  //   return Geolocator.getPositionStream(
  //       locationSettings:
  //           AndroidSettings(accuracy: LocationAccuracy.best, intervalDuration: const Duration(seconds: 2)));
  // }

  // return Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.best));
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  return runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const _EagerInitialization(
      child: MyApp(),
    ),
  ));
}

class _EagerInitialization extends ConsumerWidget {
  const _EagerInitialization({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _ = ref.watch(walkingManagerProvider);
    // Eagerly initialize providers by watching them.
    // By using "watch", the provider will stay alive and not be disposed.
    return child;
  }
}
// final getSavedEntriesProvider = StateProvider<List<SavedEntry>>((ref) => [
//       SavedEntry("Test 1", "Hundeaa", "imagePath", 50.8, 7.77),
//       SavedEntry("Test 2", "Scherben am Wegrand", "imagePath", 51.01, 7.56),
//     ]);


