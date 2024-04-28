import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'package:dog_marker/saved_entry.dart';
import 'package:dog_marker/walking_manager.dart';
import 'package:fl_location/fl_location.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundWalkingHandler extends TaskHandler {
  StreamSubscription<Location>? _streamSubscription;

  SendPort? _sendPort;
  List<SavedEntry> savedEntries = [];

  DistanceNotifier? distanceNotifier;
  Location? lastPosition;
  static const distanceHelper = Distance();
  bool isInHomeLocation = false;

  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;

    final plugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    plugin.initialize(const InitializationSettings(android: initializationSettingsAndroid));
    final prefs = await SharedPreferences.getInstance();
    await loadSavedEntries(prefs);
    distanceNotifier = DistanceNotifier(plugin, savedEntries);
    startLocationMonitoring(LocationAccuracy.best, prefs);
  }

  int getLocationInterval(SharedPreferences prefs) => (prefs.getInt("location_refresh_interval") ?? 5) * 1000;

  Future startLocationMonitoring(LocationAccuracy accuracy, SharedPreferences prefs) async {
    await _streamSubscription?.cancel();
    var interval = getLocationInterval(prefs);
    if (accuracy == LocationAccuracy.powerSave) interval = max(interval, 60000);

    _streamSubscription = FlLocation.getLocationStream(accuracy: accuracy, interval: interval).listen((location) {
      if (lastPosition?.longitude == location.longitude && lastPosition?.latitude == location.latitude) return;
      lastPosition = location;
      FlutterForegroundTask.updateService(
        notificationTitle: 'Spaziergang',
        notificationText:
            'Letztes Abfrage: ${DateFormat.Hms().format(DateTime.now())}\nInterval: $interval, Accuracy: $accuracy',
      );
      distanceNotifier?.checkLocation(location.latitude, location.longitude);
      final homeLocationEntered = checkEntersHomeAddress(location, prefs);
      if (isInHomeLocation != homeLocationEntered) {
        isInHomeLocation = homeLocationEntered;
        startLocationMonitoring(isInHomeLocation ? LocationAccuracy.powerSave : LocationAccuracy.best, prefs);
      }
      // _sendPort?.send(jsonEncode(location.toJson()));
    });
  }

  bool checkEntersHomeAddress(Location location, SharedPreferences prefs) {
    final radius = prefs.getInt("homeaddress_radius_value") ?? 0;
    final lat = prefs.getDouble("homeaddress_lat") ?? double.infinity;
    final lon = prefs.getDouble("homeaddress_lon") ?? double.infinity;

    if (radius == 0 || lat == double.infinity || lon == double.infinity) {
      return false;
    }

    final homeAddr = LatLng(lat, lon);
    final curLocation = LatLng(location.latitude, location.longitude);
    final distance = distanceHelper.distance(homeAddr, curLocation);

    return distance < radius;
  }

  Future<void> loadSavedEntries(SharedPreferences prefs) async {
    prefs.reload();

    final keys = prefs.getKeys().where((element) => element.startsWith('saved_entry'));

    for (var element in keys) {
      savedEntries.add(SavedEntry.fromJson(jsonDecode(prefs.getString(element)!)));
    }
  }

  @override
  void onDestroy(DateTime timestamp, SendPort? sendPort) async {
    await _streamSubscription?.cancel();
  }

  // Called when the notification button on the Android platform is pressed.
  @override
  void onNotificationButtonPressed(String id) {
    if (id == "stopButton") {
      _streamSubscription?.cancel();

      FlutterForegroundTask.stopService();
      _sendPort?.send("stopped");
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp("/walking");
    _sendPort?.send('onNotificationPressed');
  }

  @override
  void onRepeatEvent(DateTime timestamp, SendPort? sendPort) {}
}
