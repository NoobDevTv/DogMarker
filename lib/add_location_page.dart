import 'dart:io';

import 'package:dog_marker/main.dart';
import 'package:dog_marker/saved_entry_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

class AddLocationPage extends HookConsumerWidget {
  const AddLocationPage({super.key});

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
            minLines: 1,
          ),
        ),
        ListTile(
            title: Row(
          children: [
            Flexible(
              child: TextField(
                  controller: lonEditingController,
                  decoration: const InputDecoration(labelText: "Longitute"),
                  keyboardType: TextInputType.number),
            ),
            const SizedBox(
              width: 32,
            ),
            Flexible(
              child: TextField(
                controller: latEditingController,
                decoration: const InputDecoration(labelText: "Latitute"),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        )),
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
                          child: const Icon(Icons.location_on, color: Colors.purple),
                        ),
                      ])
                    ],
                  ),
          ),
        ),
        ListTile(
          title: imagePathProvider.value == ""
              ? Container()
              : SizedBox(
                  height: 300,
                  child: kIsWeb ? Image.network(imagePathProvider.value) : Image.file(File(imagePathProvider.value))),
          leading: SizedBox(
            width: 100,
            child: Row(
              children: [
                IconButton(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final res = await picker.pickImage(source: ImageSource.camera);
                      imagePathProvider.value = res!.path;
                    },
                    icon: const Icon(Icons.camera)),
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final res = await picker.pickImage(source: ImageSource.gallery);
                    imagePathProvider.value = res!.path;
                  },
                ),
              ],
            ),
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
                double.parse(latEditingController.text),
                DateTime.now()));
            Navigator.pop(context);
          },
          child: const Icon(Icons.save)),
    );
  }
}
