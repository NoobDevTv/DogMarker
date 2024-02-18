import 'dart:io';

import 'package:dog_marker/background_walking_handler.dart';
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
  if (kIsWeb || Platform.isAndroid || Platform.isIOS) return FlLocation.getLocationStream();

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
    child: const MyApp(),
  ));
}

// final getSavedEntriesProvider = StateProvider<List<SavedEntry>>((ref) => [
//       SavedEntry("Test 1", "Hundeaa", "imagePath", 50.8, 7.77),
//       SavedEntry("Test 2", "Scherben am Wegrand", "imagePath", 51.01, 7.56),
//     ]);


