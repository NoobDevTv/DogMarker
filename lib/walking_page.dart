import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:dog_marker/main.dart';
import 'package:dog_marker/model/saved_entry.dart';
import 'package:dog_marker/saved_entry_manager.dart';
import 'package:fl_location_platform_interface/src/models/location.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'main_page.dart';

class WalkingPage extends HookConsumerWidget {
  const WalkingPage({super.key});

  Future<void> _requestPermissionForAndroid() async {
    if (!Platform.isAndroid) {
      return;
    }

    // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
    // onNotificationPressed function to be called.
    //
    // When the notification is pressed while permission is denied,
    // the onNotificationPressed function is not called and the app opens.
    //
    // If you do not use the onNotificationPressed or launchApp function,
    // you do not need to write this code.
    if (!await FlutterForegroundTask.canDrawOverlays) {
      // This function requires `android.permission.SYSTEM_ALERT_WINDOW` permission.
      await FlutterForegroundTask.openSystemAlertWindowSettings();
    }

    // Android 12 or higher, there are restrictions on starting a foreground service.
    //
    // To restart the service on device reboot or unexpected problem, you need to allow below permission.
    if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
      await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    }

    // Android 13 and higher, you need to allow notification permission to expose foreground service notification.
    final NotificationPermission notificationPermissionStatus =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermissionStatus != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  Future<bool> _startForegroundTask(ValueNotifier<ReceivePort?> port, ValueNotifier<bool> walkingMode) async {
    // You can save data using the saveData function.
    if (Platform.isAndroid) {
      await _requestPermissionForAndroid();
      _initForegroundTask();
    }
    await FlutterForegroundTask.saveData(key: 'customData', value: 'hello');

    // Register the receivePort before starting the service.
    final oldPort = port.value;
    final receivePort = port.value = FlutterForegroundTask.receivePort;
    final bool isRegistered = _registerReceivePort(receivePort, oldPort, walkingMode);
    if (!isRegistered) {
      print('Failed to register receivePort!');
      return false;
    }

    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.restartService();
    } else {
      return FlutterForegroundTask.startService(
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        callback: startCallback,
      );
    }
  }

  Future<bool> _stopForegroundTask(ValueNotifier<ReceivePort?> port) {
    port.value?.close();
    return FlutterForegroundTask.stopService();
  }

  bool _registerReceivePort(ReceivePort? newReceivePort, ReceivePort? oldPort, ValueNotifier<bool> walkingMode) {
    if (newReceivePort == null) {
      return false;
    }

    _closeReceivePort(oldPort);
    newReceivePort.listen((data) {
      if (data is String && data == "stopped") {
        walkingMode.value = false;
      }
    });

    return true;
  }

  void _closeReceivePort(ReceivePort? receivePort) {
    receivePort?.close();
    receivePort = null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationProvider);
    final savedEntries = ref.watch(savedEntryManagerProvider);
    final inWalkingMode = useState(false);
    final port = useState<ReceivePort?>(null);
    final mapController = useState<MapController>(MapController());
    final trackWithLocation = useState(true);

    return WithForegroundTask(
      child: Scaffold(
        appBar: AppBar(title: const Text("Walkingmode"), actions: [
          location.when(
              data: (d) {
                if (trackWithLocation.value) {
                  try {
                    mapController.value.move(LatLng(d.latitude, d.longitude), mapController.value.camera.zoom);
                  } catch (e) {}
                }

                return IconButton(
                    icon: trackWithLocation.value ? const Icon(Icons.gps_fixed) : const Icon(Icons.gps_not_fixed),
                    onPressed: () {
                      trackWithLocation.value = !trackWithLocation.value;
                    });
              },
              error: (error, stackTrace) => Container(),
              loading: () => Container())
        ]),
        body: location.when(
          data: (d) => FlutterMap(
            mapController: mapController.value,
            options: MapOptions(
              initialCenter: LatLng(d.latitude, d.longitude),
              minZoom: 12,
              maxZoom: 20,
              initialZoom: 18,
              onMapEvent: (mapEvent) {
                if (mapEvent.source == MapEventSource.onDrag && trackWithLocation.value) {
                  trackWithLocation.value = false;
                  print("Kamen rein");
                }
              },
            ),
            children: [
              TileLayer(
                maxZoom: 20,
                urlTemplate: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: LatLng(d.latitude, d.longitude),
                  rotate: false,
                  alignment: Alignment.topCenter,
                  child: const Icon(Icons.person_pin_circle, color: Colors.purple),
                ),
                ...mapSavendEntryMarkers(context, savedEntries, d, Colors.red)
              ])
            ],
          ),
          error: (error, stackTrace) {
            return null;
          },
          loading: () => Container(
            margin: const EdgeInsets.only(top: 32),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
            heroTag: "main_floating",
            onPressed: () {
              if (inWalkingMode.value) {
                _stopForegroundTask(port);
              } else {
                _startForegroundTask(port, inWalkingMode);
              }
              inWalkingMode.value = !inWalkingMode.value;
            },
            child: inWalkingMode.value ? const Icon(Icons.stop) : const Icon(Icons.play_arrow)),
      ),
    );
  }

  static Iterable<Marker> mapSavendEntryMarkers(
      BuildContext context, List<SavedEntry> savedEntries, Location d, Color markerColor) {
    return savedEntries.map(
      (e) => Marker(
          point: LatLng(e.latitude, e.longitude),
          child: IconButton(
            onPressed: () {
              showModalBottomSheet(
                enableDrag: true,
                showDragHandle: true,
                context: context,
                builder: (context) {
                  return SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(e.title, style: const TextStyle(fontSize: 18)),
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                ),
                                Text("(${MainPage.distanceText(e.latitude, e.longitude, d.latitude, d.longitude)})"),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            height: 250,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: e.imagePath.isEmpty
                                      ? Image.asset("assets/app_icon/dog_icon.png")
                                      : kIsWeb || (e.uploaded ?? false) || e.imagePath.startsWith("http")
                                          ? Image.network(e.imagePath)
                                          : Image.file(File(e.imagePath)),
                                ),
                                const SizedBox(
                                  width: 16,
                                ),
                                Expanded(
                                  child: ListView(
                                    children: [
                                      Text(
                                        e.description,
                                        softWrap: true,
                                      )
                                    ],
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            icon: const Icon(Icons.location_on),
            color: markerColor,
          ),
          alignment: Alignment.topCenter,
          rotate: false),
    );
  }

  void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Spaziergang',
        channelDescription: 'Sie werden überwacht!',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        buttons: [
          const NotificationButton(id: 'stopButton', text: 'Stop'),
          const NotificationButton(id: 'secondButton', text: 'Test'),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 1000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }
}
