import 'dart:convert';

import 'package:dog_marker/main.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void addEntry(SavedEntry entry) {
    final provider = ref.watch(sharedPreferencesProvider);
    provider.setString('saved_entry_${entry.guid})', jsonEncode(entry.toJson()));
    state = [...state, entry];
  }

  void deleteEntry(SavedEntry entry) {
    final provider = ref.watch(sharedPreferencesProvider);
    provider.remove('saved_entry_${entry.guid})');
    state = [...state.where((element) => element.guid != entry.guid)];
  }
}
