import 'dart:convert';

import 'package:dog_marker/api.dart';
import 'package:dog_marker/helper/vgyme_uploader.dart';
import 'package:dog_marker/main.dart';
import 'package:dog_marker/main_page.dart';
import 'package:dog_marker/saved_entry.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'saved_entry_manager.g.dart';

final _readFromDateTime = StateProvider<DateTime>((ref) => DateTime.now().toUtc().add(const Duration(days: -7)));

@riverpod
Future<List<SavedEntry>> serverEntries(ServerEntriesRef ref) async {
  final kvs = ref.watch(sharedPreferencesProvider);
  final privacyLevel = kvs.getInt("privacy_level");
  if (privacyLevel == 1 || privacyLevel == 3) return [];

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
  late SharedPreferences sharedPreferences;

  @override
  List<SavedEntry> build() {
    sharedPreferences = ref.watch(sharedPreferencesProvider);

    List<SavedEntry> ret = [];

    final keys = sharedPreferences.getKeys().where((element) => element.startsWith('saved_entry'));

    for (var element in keys) {
      ret.add(SavedEntry.fromJson(jsonDecode(sharedPreferences.getString(element)!)));
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
    if ((sharedPreferences.getInt("privacy_level") ?? 0) < 2) {
      Api.addNewEntry(ref.read(userIdProvider), entry).then((value) => VgyMeUploader.uploadEntry(entry, this));
    }
  }

  void updateEntry(SavedEntry entry, [bool uploadToServer = false]) {
    if (state.any((element) => element == entry)) return;
    save(entry);
    if (state.any((element) => element.guid == entry.guid)) {
      state = [...state.where((element) => element.guid != entry.guid)];
    }
    state = [...state, entry];
    if ((sharedPreferences.getInt("privacy_level") ?? 0) < 2 && uploadToServer) {
      Api.updateEntry(ref.read(userIdProvider), entry);
    }
  }

  void deleteEntry(SavedEntry entry) {
    if (!state.any((element) => element == entry)) return;
    final provider = ref.watch(sharedPreferencesProvider);
    provider.remove('saved_entry_${entry.guid})');
    state = [...state.where((element) => element.guid != entry.guid)];
    if ((sharedPreferences.getInt("privacy_level") ?? 0) < 2) {
      Api.deleteEntry(ref.read(userIdProvider), entry.guid).then((value) => VgyMeUploader.deleteEntry(entry));
    }
  }
}
