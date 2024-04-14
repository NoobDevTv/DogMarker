import 'dart:math';

import 'package:dog_marker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';

class SetHomeLocationPage extends HookConsumerWidget {
  static const Map<int, double> radiusMap = {
    0: 1,
    1: 2,
    2: 3,
    3: 4,
    4: 5,
    5: 10,
    6: 15,
    7: 20,
    8: 30,
    9: 50,
    10: 75,
    11: 100,
    12: 200,
    13: 300,
    14: 400,
    15: 20000
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.read(locationProvider);
    LatLng locationVal = const LatLng(50.9210664, 10.2999251);
    location.whenData(
      (value) {
        locationVal = LatLng(value.latitude, value.longitude);
      },
    );
    final mapController = useState(MapController());

    return Scaffold(
      appBar: AppBar(
        title: const Text("Setzte Heimatadresse"),
      ),
      body: HookBuilder(builder: (context) {
        final currentLocation = useState(locationVal);

        final radius = useState(4);
        print((radiusMap.length - radius.value).toDouble());
        return Column(
          children: [
            Slider(
              value: radius.value.toDouble(),
              min: 0,
              max: radiusMap.length.toDouble() - 1,
              divisions: radiusMap.length - 1,
              label: "${radiusMap[radius.value]}km",
              onChanged: (value) {
                radius.value = value.round();
                mapController.value.fitCamera(getCameraFit(radius, currentLocation.value));
              },
            ),
            Expanded(
              child: FlutterMap(
                mapController: mapController.value,
                options: MapOptions(
                  initialCenter: currentLocation.value,
                  minZoom: 1,
                  maxZoom: 20,
                  initialCameraFit: getCameraFit(radius, currentLocation.value),
                  onTap: (tapPosition, point) {
                    print("Point: $point");
                    currentLocation.value = point;
                  },
                ),
                children: [
                  TileLayer(
                    maxZoom: 20,
                    urlTemplate: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
                  ),
                  CircleLayer(
                    circles: [
                      CircleMarker(
                          point: currentLocation.value,
                          radius: radiusMap[radius.value]! * 1000,
                          useRadiusInMeter: true,
                          borderColor: Colors.purple,
                          borderStrokeWidth: 1,
                          color: Colors.purple.withAlpha(25))
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: currentLocation.value,
                        rotate: false,
                        alignment: Alignment.center,
                        child: const Icon(Icons.person_pin_circle, color: Colors.purple),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  CameraFit getCameraFit(ValueNotifier<int> radius, LatLng currentLocation) {
    final dist = (radiusMap[radius.value]! * sqrt2) * 1.05;
    final ul = distanceHelper.offset(currentLocation, dist * 1000, -315);
    final dr = distanceHelper.offset(currentLocation, dist * 1000, -135);

    return CameraFit.bounds(bounds: LatLngBounds(ul, dr));
  }
}
