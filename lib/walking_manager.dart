import 'package:dog_marker/main.dart';
import 'package:dog_marker/saved_entry.dart';
import 'package:dog_marker/saved_entry_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'walking_manager.g.dart';

@riverpod
FlutterLocalNotificationsPlugin getNotificationPlugin(GetNotificationPluginRef ref) {
  final plugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  plugin.initialize(const InitializationSettings(android: initializationSettingsAndroid));
  return plugin;
}

@riverpod
DistanceNotifier getDistanceNotifier(
    GetDistanceNotifierRef ref, FlutterLocalNotificationsPlugin notificationPlugin, List<SavedEntry> entries) {
  return DistanceNotifier(notificationPlugin, entries);
}

@riverpod
class WalkingManager extends _$WalkingManager {
  @override
  Future<void> build() async {
    final notificationPlugin = ref.watch(getNotificationPluginProvider);
    final entries = ref.watch(savedEntryManagerProvider);
    final notifier = ref.watch(getDistanceNotifierProvider(notificationPlugin, entries));

    ref.watch(locationProvider).whenData((value) async {
      await notifier.checkLocation(value.latitude, value.longitude);
    });
  }
}

class DistanceNotifier {
  FlutterLocalNotificationsPlugin notificationPlugin;
  final AndroidNotificationDetails _androidPlatformChannelSpecifics = const AndroidNotificationDetails(
      'walkingMode', 'Warnung Meldungen',
      channelDescription: 'Benachrichtigungen über nahe Irgendwas',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Dog Marker');

  List<SavedEntry> entries;
  final _notifiedEntries = <SavedEntry>[];
  int _notificationId = 0;
  late NotificationDetails platformChannelSpecifics;

  DistanceNotifier(this.notificationPlugin, this.entries) {
    platformChannelSpecifics = NotificationDetails(android: _androidPlatformChannelSpecifics);
  }

  Future<bool> checkLocation(double latitude, double longitude) async {
    bool found = false;
    for (var item in entries) {
      final dist = distanceHelper.distance(LatLng(item.latitute, item.longitute), LatLng(latitude, longitude));
      final contains = _notifiedEntries.contains(item);
      if (contains && dist > 150) {
        _notifiedEntries.remove(item);
      } else if (!contains && dist < 100) {
        await notificationPlugin.show(_notificationId++, "Achtung ${item.title} in $dist m",
            "Beschreibung: ${item.description}", platformChannelSpecifics);
        found = true;
        _notifiedEntries.add(item);
      }
    }
    return found;
  }
}
