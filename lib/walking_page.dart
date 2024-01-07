import 'dart:io';

import 'package:dog_marker/main.dart';
import 'package:dog_marker/saved_entry_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';

class WalkingPage extends HookConsumerWidget {
  const WalkingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = ref.watch(locationProvider);
    final savedEntries = ref.watch(savedEntryManagerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("I'm walking here"), actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.invalidate(locationProvider);
          },
        )
      ]),
      body: location.when(
        data: (d) => FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(d.latitude, d.longitude),
            minZoom: 12,
            maxZoom: 20,
            initialZoom: 18,
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
              ...savedEntries.map(
                (e) => Marker(
                    point: LatLng(e.latitute, e.longitute),
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
                                      child: Text(e.title, style: const TextStyle(fontSize: 18)),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 16),
                                      height: 250,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: kIsWeb
                                                ? Image.network(e.imagePath)
                                                : Image.file(
                                                    File(e.imagePath),
                                                  ),
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
                      color: Colors.red,
                    ),
                    alignment: Alignment.topCenter,
                    rotate: false),
              )
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
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.stop)),
    );
  }
}
