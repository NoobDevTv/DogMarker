import 'dart:convert';

import 'package:dog_marker/api.dart';
import 'package:dog_marker/helper/vgyme_uploader.dart';
import 'package:dog_marker/main.dart';
import 'package:dog_marker/main_page.dart';
import 'package:dog_marker/saved_entry.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'saved_entry_manager.g.dart';

final _readFromDateTime = StateProvider<DateTime>((ref) => DateTime.now().toUtc().add(const Duration(days: -7)));

@riverpod
Future<List<SavedEntry>> serverEntries(ServerEntriesRef ref) async {
  final location = ref.read(locationProvider).valueOrNull;

  Future.delayed(const Duration(minutes: 1)).then((value) => ref.invalidateSelf());

  if (location == null) return [];

  final userId = ref.read(userIdProvider);
  final dateFrom = ref.read(_readFromDateTime.notifier);
  final futureTo = DateTime.now().toUtc();
  var result = await Api.getAllEntries(
      userId: userId, latLng: LatLng(location.latitude, location.longitude), from: dateFrom.state);
  print("Got response from server with ${result.length} entries since ${dateFrom.state}");
  dateFrom.state = futureTo;
  return result;
}

@riverpod
class SavedEntryManager extends _$SavedEntryManager {
  @override
  List<SavedEntry> build() {
    final provider = ref.watch(sharedPreferencesProvider);

    List<SavedEntry> ret = [];

    final keys = provider.getKeys().where((element) => element.startsWith('saved_entry'));

    for (var element in keys) {
      ret.add(SavedEntry.fromJson(jsonDecode(provider.getString(element)!)));
    }

    return ret;
  }

  void save(SavedEntry entry) {
    final provider = ref.watch(sharedPreferencesProvider);
    provider.setString('saved_entry_${entry.guid})', jsonEncode(entry.toJson()));
  }

  void addEntry(SavedEntry entry) {
    if (state.any((element) => element == entry)) return;
    save(entry);
    state = [...state, entry];
    Api.addNewEntry(ref.read(userIdProvider), entry).then((value) => VgyMeUploader.uploadEntry(entry, this));
  }

  void updateEntry(SavedEntry entry, [bool uploadToServer = false]) {
    if (state.any((element) => element == entry)) return;
    save(entry);
    if (state.any((element) => element.guid == entry.guid)) {
      state = [...state.where((element) => element.guid != entry.guid)];
    }
    state = [...state, entry];
    if (uploadToServer) Api.updateEntry(ref.read(userIdProvider), entry);
  }

  void deleteEntry(SavedEntry entry) {
    if (!state.any((element) => element == entry)) return;
    final provider = ref.watch(sharedPreferencesProvider);
    provider.remove('saved_entry_${entry.guid})');
    state = [...state.where((element) => element.guid != entry.guid)];
    Api.deleteEntry(ref.read(userIdProvider), entry.guid).then((value) => VgyMeUploader.deleteEntry(entry));
  }
}
