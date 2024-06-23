import 'package:dog_marker/api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'entry_category.g.dart';

@JsonSerializable()
@immutable
class EntryCategory {
  final String key;
  final String title;
  final String description;

  const EntryCategory(this.key, this.title, this.description);

  factory EntryCategory.fromJson(Map<String, dynamic> json) => _$EntryCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$EntryCategoryToJson(this);
}

@riverpod
Future<List<EntryCategory>> getCategories(Ref ref) async {
  return await Api.getCategories();
}
