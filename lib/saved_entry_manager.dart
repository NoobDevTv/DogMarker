import 'dart:convert';

import 'package:dog_marker/api.dart';
import 'package:dog_marker/helper/vgyme_uploader.dart';
import 'package:dog_marker/main.dart';
import 'package:dog_marker/main_page.dart';
import 'package:dog_marker/saved_entry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'saved_entry_manager.g.dart';

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
    save(entry);
    state = [...state, entry];
    Api.addNewEntry(ref.read(userIdProvider), entry).then((value) => VgyMeUploader.uploadEntry(entry, this));
  }

  void updateEntry(SavedEntry entry) {
    save(entry);
    state = [...state.where((element) => element.guid != entry.guid)];
    state = [...state, entry];
    Api.updateEntry(ref.read(userIdProvider), entry);
  }

  void deleteEntry(SavedEntry entry) {
    final provider = ref.watch(sharedPreferencesProvider);
    provider.remove('saved_entry_${entry.guid})');
    state = [...state.where((element) => element.guid != entry.guid)];
    Api.deleteEntry(ref.read(userIdProvider), entry.guid).then((value) => VgyMeUploader.deleteEntry(entry));
  }
}
