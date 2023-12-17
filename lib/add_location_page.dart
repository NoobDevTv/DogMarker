import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dog_marker/main.dart';
import 'package:dog_marker/saved_entry_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

class AddLocationPage extends HookConsumerWidget {
  const AddLocationPage({super.key});

  String googleDark(int z, int x, int y) {
    final url =
        'https://maps.googleapis.com/maps/vt?pb=!1m5!1m4!1i$z!2i$x!3i$y!4i256!2m3!1e0!2sm!3i556279080!3m17!2sen-US!3sUS!5e18!12m4!1e68!2m2!1sset!2sRoadmap!12m3!1e37!2m1!1ssmartmaps!12m4!1e26!2m2!1sstyles!2zcC52Om9uLHMuZTpsfHAudjpvZmZ8cC5zOi0xMDAscy5lOmwudC5mfHAuczozNnxwLmM6I2ZmMDAwMDAwfHAubDo0MHxwLnY6b2ZmLHMuZTpsLnQuc3xwLnY6b2ZmfHAuYzojZmYwMDAwMDB8cC5sOjE2LHMuZTpsLml8cC52Om9mZixzLnQ6MXxzLmU6Zy5mfHAuYzojZmYwMDAwMDB8cC5sOjIwLHMudDoxfHMuZTpnLnN8cC5jOiNmZjAwMDAwMHxwLmw6MTd8cC53OjEuMixzLnQ6NXxzLmU6Z3xwLmM6I2ZmMDAwMDAwfHAubDoyMCxzLnQ6NXxzLmU6Zy5mfHAuYzojZmY0ZDYwNTkscy50OjV8cy5lOmcuc3xwLmM6I2ZmNGQ2MDU5LHMudDo4MnxzLmU6Zy5mfHAuYzojZmY0ZDYwNTkscy50OjJ8cy5lOmd8cC5sOjIxLHMudDoyfHMuZTpnLmZ8cC5jOiNmZjRkNjA1OSxzLnQ6MnxzLmU6Zy5zfHAuYzojZmY0ZDYwNTkscy50OjN8cy5lOmd8cC52Om9ufHAuYzojZmY3ZjhkODkscy50OjN8cy5lOmcuZnxwLmM6I2ZmN2Y4ZDg5LHMudDo0OXxzLmU6Zy5mfHAuYzojZmY3ZjhkODl8cC5sOjE3LHMudDo0OXxzLmU6Zy5zfHAuYzojZmY3ZjhkODl8cC5sOjI5fHAudzowLjIscy50OjUwfHMuZTpnfHAuYzojZmYwMDAwMDB8cC5sOjE4LHMudDo1MHxzLmU6Zy5mfHAuYzojZmY3ZjhkODkscy50OjUwfHMuZTpnLnN8cC5jOiNmZjdmOGQ4OSxzLnQ6NTF8cy5lOmd8cC5jOiNmZjAwMDAwMHxwLmw6MTYscy50OjUxfHMuZTpnLmZ8cC5jOiNmZjdmOGQ4OSxzLnQ6NTF8cy5lOmcuc3xwLmM6I2ZmN2Y4ZDg5LHMudDo0fHMuZTpnfHAuYzojZmYwMDAwMDB8cC5sOjE5LHMudDo2fHAuYzojZmYyYjM2Mzh8cC52Om9uLHMudDo2fHMuZTpnfHAuYzojZmYyYjM2Mzh8cC5sOjE3LHMudDo2fHMuZTpnLmZ8cC5jOiNmZjI0MjgyYixzLnQ6NnxzLmU6Zy5zfHAuYzojZmYyNDI4MmIscy50OjZ8cy5lOmx8cC52Om9mZixzLnQ6NnxzLmU6bC50fHAudjpvZmYscy50OjZ8cy5lOmwudC5mfHAudjpvZmYscy50OjZ8cy5lOmwudC5zfHAudjpvZmYscy50OjZ8cy5lOmwuaXxwLnY6b2Zm!4e0';
    return url;
  }

  String osmGerman(int z, int x, int y) {
    return "https://tile.openstreetmap.de/$z/$x/$y.png";
  }

  Widget _buildMarkerWidget(Offset pos, Color color, [IconData icon = Icons.circle]) {
    return Positioned(
        left: pos.dx - 12,
        top: pos.dy - 12,
        width: 24,
        height: 24,
        child: Icon(
          icon,
          color: color,
          size: 24,
        ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleEditingController = useTextEditingController();
    final descriptionEditingController = useTextEditingController();
    final lonEditingController = useTextEditingController();
    final latEditingController = useTextEditingController();
    final imagePathProvider = useState("");
    final location = ref.watch(locationProvider);

    location.whenData(
      (value) {
        lonEditingController.text = value.longitude.toString();
        latEditingController.text = value.latitude.toString();
      },
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Neuer Ort"), actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.invalidate(locationProvider);
          },
        )
      ]),
      body: ListView(children: [
        ListTile(
          title: TextField(controller: titleEditingController, decoration: const InputDecoration(labelText: "Titel")),
        ),
        ListTile(
          title: TextField(
            controller: descriptionEditingController,
            decoration: const InputDecoration(labelText: "Beschreibung", helperText: "* Optional"),
            maxLines: 10,
            minLines: 3,
          ),
        ),
        ListTile(
          title: TextField(
              controller: lonEditingController,
              decoration: const InputDecoration(labelText: "Longitute"),
              keyboardType: TextInputType.number),
        ),
        ListTile(
          title: TextField(
            controller: latEditingController,
            decoration: const InputDecoration(labelText: "Latitute"),
            keyboardType: TextInputType.number,
          ),
        ),
        ListTile(
          title: SizedBox(
            height: 300,
            child: location.isLoading
                ? Container()
                : FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(location.value!.latitude, location.value!.longitude),
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
                          point: LatLng(location.value!.latitude, location.value!.longitude),
                          rotate: false,
                          alignment: Alignment.topCenter,
                          child: Icon(Icons.location_on, color: Colors.purple),
                        ),
                      ])
                    ],
                  ),
          ),
        ),
        ListTile(
          title: imagePathProvider.value == "" ? Container() : Image.file(File(imagePathProvider.value)),
          leading: IconButton(
            icon: const Icon(Icons.image),
            onPressed: () async {
              final ImagePicker picker = ImagePicker();
              final res = await picker.pickImage(source: ImageSource.gallery);
              imagePathProvider.value = res!.path;
            },
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            final data = ref.read(savedEntryManagerProvider.notifier);
            data.addEntry(SavedEntry(
                titleEditingController.text,
                descriptionEditingController.text,
                imagePathProvider.value,
                double.parse(lonEditingController.text),
                double.parse(latEditingController.text)));
            Navigator.pop(context);
          },
          child: const Icon(Icons.save)),
    );
  }
}
