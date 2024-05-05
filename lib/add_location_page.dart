import 'dart:io';

import 'package:dog_marker/main.dart';
import 'package:dog_marker/saved_entry.dart';
import 'package:dog_marker/saved_entry_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

class AddLocationPage extends HookConsumerWidget {
  final SavedEntry? toEdit;
  get _editMode => toEdit != null;

  const AddLocationPage({super.key, this.toEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleEditingController = useTextEditingController();
    final descriptionEditingController = useTextEditingController();
    final lonEditingController = useTextEditingController();
    final latEditingController = useTextEditingController();
    final imagePathProvider = useState("");
    final useLocationAsLatLng = useState(!_editMode);
    final firstLoad = useState(true);
    final location = ref.watch(locationProvider);
    if (_editMode && firstLoad.value) {
      firstLoad.value = false;
      titleEditingController.text = toEdit!.title;
      descriptionEditingController.text = toEdit!.description;
      lonEditingController.text = toEdit!.longitude.toString();
      latEditingController.text = toEdit!.latitude.toString();
      imagePathProvider.value = toEdit!.imagePath;
    }

    if (useLocationAsLatLng.value) {
      location.whenData(
        (value) {
          lonEditingController.text = value.longitude.toString();
          latEditingController.text = value.latitude.toString();
        },
      );
    }
    double? parsedLat = double.tryParse(latEditingController.text);
    double? parsedLon = double.tryParse(lonEditingController.text);

    return Scaffold(
      appBar: AppBar(title: _editMode ? const Text("Ort bearbeiten") : const Text("Neuer Ort"), actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            ref.invalidate(locationProvider);
          },
        )
      ]),
      body: ListView(children: [
        Card.outlined(
          child: Column(
            children: [
              ListTile(
                title: TextField(
                    controller: titleEditingController, decoration: const InputDecoration(labelText: "Titel")),
              ),
              ListTile(
                title: TextField(
                  controller: descriptionEditingController,
                  decoration: const InputDecoration(labelText: "Beschreibung", helperText: "* Optional"),
                  maxLines: 10,
                  minLines: 1,
                ),
              ),
            ],
          ),
        ),
        Card.outlined(
          child: Column(
            children: [
              ListTile(
                title: SizedBox(
                  height: 300,
                  child: location.isLoading
                      ? Container()
                      : FlutterMap(
                          options: MapOptions(
                            initialCenter: (parsedLon == null || parsedLat == null)
                                ? LatLng(location.value!.latitude, location.value!.longitude)
                                : LatLng(parsedLat, parsedLon),
                            minZoom: 12,
                            maxZoom: 20,
                            initialZoom: 18,
                            onTap: (tapPosition, point) {
                              useLocationAsLatLng.value = false;
                              latEditingController.text = point.latitude.toString();
                              lonEditingController.text = point.longitude.toString();
                            },
                          ),
                          children: [
                            TileLayer(
                              maxZoom: 20,
                              urlTemplate: 'https://tile.openstreetmap.de/{z}/{x}/{y}.png',
                            ),
                            MarkerLayer(
                                markers: [
                                      Marker(
                                        point: LatLng(location.value!.latitude, location.value!.longitude),
                                        rotate: false,
                                        alignment: Alignment.topCenter,
                                        child: const Icon(Icons.person_pin_circle, color: Colors.purple),
                                      ),
                                    ] +
                                    (parsedLon == null || parsedLat == null
                                        ? []
                                        : [
                                            Marker(
                                                point: LatLng(parsedLat, parsedLon),
                                                child: const Icon(Icons.location_on, color: Colors.red),
                                                rotate: false,
                                                alignment: Alignment.topCenter)
                                          ]))
                          ],
                        ),
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
            ],
          ),
        ),
        Card.outlined(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text("Neues Foto aufnehmen"),
                onTap: () async {
                  final ImagePicker picker = ImagePicker();
                  final res = await picker.pickImage(source: ImageSource.camera);
                  if (res == null) return;
                  imagePathProvider.value = res.path;
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text("Foto auswählen"),
                onTap: () async {
                  final ImagePicker picker = ImagePicker();
                  final res = await picker.pickImage(source: ImageSource.gallery);
                  if (res == null) return;
                  imagePathProvider.value = res.path;
                },
              ),
              ListTile(
                title: imagePathProvider.value == ""
                    ? Container()
                    : SizedBox(
                        height: 300,
                        child: imagePathProvider.value.isEmpty
                            ? null
                            : kIsWeb || (toEdit?.uploaded ?? false) || imagePathProvider.value.startsWith("http")
                                ? Image.network(imagePathProvider.value)
                                : Image.file(File(imagePathProvider.value))),
              ),
            ],
          ),
        )
      ]),
      floatingActionButton: FloatingActionButton(
          heroTag: "main_floating",
          onPressed: () {
            final data = ref.read(savedEntryManagerProvider.notifier);
            if (_editMode) {
              data.updateEntry(toEdit!.copyWith(
                title: titleEditingController.text,
                description: descriptionEditingController.text,
                imagePath: imagePathProvider.value,
                longitude: double.parse(lonEditingController.text),
                latitude: double.parse(latEditingController.text),
              ));
            } else {
              data.addEntry(SavedEntry(
                  SavedEntry.getNewGuid(),
                  titleEditingController.text,
                  descriptionEditingController.text,
                  imagePathProvider.value,
                  double.parse(lonEditingController.text),
                  double.parse(latEditingController.text),
                  DateTime.now()));
            }
            Navigator.pop(context);
          },
          child: const Icon(Icons.save)),
    );
  }
}
