import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:dog_marker/saved_entry.dart';
import 'package:dog_marker/walking_manager.dart';
import 'package:fl_location/fl_location.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundWalkingHandler extends TaskHandler {
  StreamSubscription<Location>? _streamSubscription;

  SendPort? _sendPort;
  List<SavedEntry> savedEntries = [];

  DistanceNotifier? distanceNotifier;
  Location? lastPosition;

  @override
  void onStart(DateTime timestamp, SendPort? sendPort) async {
    _sendPort = sendPort;

    final plugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    plugin.initialize(const InitializationSettings(android: initializationSettingsAndroid));

    await loadSavedEntries();
    distanceNotifier = DistanceNotifier(plugin, savedEntries);

    _streamSubscription = FlLocation.getLocationStream().listen((location) {
      if (lastPosition?.longitude == location.longitude && lastPosition?.latitude == location.latitude) return;
      lastPosition = location;
      FlutterForegroundTask.updateService(
        notificationTitle: 'Spaziergang',
        notificationText:
            'Letztes Abfrage: ${DateFormat.Hms().format(DateTime.now())}\n ${location.latitude}:${location.longitude}',
      );
      distanceNotifier?.checkLocation(location.latitude, location.longitude);
      // _sendPort?.send(jsonEncode(location.toJson()));
    });
  }

  Future<void> loadSavedEntries() async {
    final prefs = await SharedPreferences.getInstance()
      ..reload();

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
