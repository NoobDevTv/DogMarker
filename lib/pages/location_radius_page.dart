import 'dart:math';

import 'package:dog_marker/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:nominatim_flutter/model/request/request.dart';
import 'package:nominatim_flutter/nominatim_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationRadiusPage extends HookConsumerWidget {
  final List<double> radiusMap;
  final String keyValueStorePrefix;
  final Widget? title;
  final bool showAddressInformation;

  const LocationRadiusPage(
      {super.key,
      required this.radiusMap,
      this.showAddressInformation = true,
      this.keyValueStorePrefix = "homeaddress",
      this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keyValueStore = ref.watch(sharedPreferencesProvider);

    final homeLat = keyValueStore.getDouble("${keyValueStorePrefix}_lat");
    final homeLon = keyValueStore.getDouble("${keyValueStorePrefix}_lon");
    LatLng locationVal = LatLng(homeLat ?? 50.9210664, homeLon ?? 10.2999251);
    if (homeLat == null && homeLon == null) {
      final location = ref.read(locationProvider);
      location.whenData(
        (value) {
          locationVal = LatLng(value.latitude, value.longitude);
        },
      );
    }
    final mapController = useState(MapController());
    final currentLocation = useState(locationVal);

    return Scaffold(
      appBar: AppBar(
        title: title,
        leading: IconButton(
          icon: Icon(Icons.save),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final location = ref.read(locationProvider);
          location.whenData(
            (value) {
              setNewLocation(currentLocation, LatLng(value.latitude, value.longitude), keyValueStore);
              mapController.value.move(currentLocation.value, mapController.value.camera.zoom);
            },
          );
        },
        child: const Icon(Icons.location_searching),
      ),
      body: HookBuilder(builder: (context) {
        final textController = useTextEditingController();
        if (showAddressInformation) getAddress(currentLocation.value).then((e) => textController.text = e);
        final radius = useState(keyValueStore.getInt("${keyValueStorePrefix}_radius_index") ?? 4);
        var radiusVal = radiusMap[radius.value];

        final useMeters = radiusMap[radius.value] < 1.0;
        if (useMeters) radiusVal *= 1000;
        final distanceString = "$radiusVal ${useMeters ? 'm' : 'km'}";
        // final address = useState()
        return Column(
          children: [
            if (showAddressInformation)
              TextField(
                controller: textController,
              ),
            Column(
              children: [
                Text("Umkreis: $distanceString"),
                Slider(
                  value: radius.value.toDouble(),
                  min: 0,
                  max: radiusMap.length.toDouble() - 1,
                  divisions: radiusMap.length - 1,
                  label: distanceString,
                  onChanged: (value) {
                    radius.value = value.round();
                    keyValueStore.setInt("${keyValueStorePrefix}_radius_index", radius.value);
                    keyValueStore.setInt(
                        "${keyValueStorePrefix}_radius_value", (radiusMap[radius.value] * 1000).toInt());
                    final fit = getCameraFit(radius, currentLocation.value);
                    mapController.value.fitCamera(fit);
                  },
                ),
              ],
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
                    if (showAddressInformation) setNewLocation(currentLocation, point, keyValueStore);
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
                          radius: radiusMap[radius.value] * 1000,
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
    final dist = (radiusMap[radius.value] * sqrt2) * 1.05;
    final ul = distanceHelper.offset(currentLocation, dist * 1000, -315);
    final dr = distanceHelper.offset(currentLocation, dist * 1000, -135);

    return CameraFit.bounds(bounds: LatLngBounds(ul, dr));
  }

  void setNewLocation(ValueNotifier<LatLng> currentLocation, LatLng point, SharedPreferences keyValueStore) {
    currentLocation.value = point;
    keyValueStore.setDouble("${keyValueStorePrefix}_lat", point.latitude);
    keyValueStore.setDouble("${keyValueStorePrefix}_lon", point.longitude);
  }

  Future<String> getAddress(LatLng latLng) async {
    final reverseRequest = ReverseRequest(
      lat: latLng.latitude,
      lon: latLng.longitude,
      addressDetails: true,
      extraTags: false,
      nameDetails: false,
    );

    final response = await NominatimFlutter.instance.reverse(
      reverseRequest: reverseRequest,
      // language: 'de-DE,de;q=0.5', // Specify the desired language(s) here
    );
    final addr = response.address;
    if (addr == null) return response.displayName ?? "";

    String addressRet = "";
    if (addr.containsKey("road")) addressRet += addr["road"] + ", ";
    if (addr.containsKey("house_number")) addressRet = addressRet.replaceFirst(",", "") + addr["house_number"] + ", ";
    if (addr.containsKey("postcode")) addressRet += addr["postcode"] + " ";
    if (addr.containsKey("city")) addressRet += addr["city"] + ", ";
    if (addr.containsKey("state")) addressRet += addr["state"];

    return addressRet;
  }
}
