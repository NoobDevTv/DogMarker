import 'package:dog_marker/model/warning_level.dart';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

part 'saved_entry.g.dart';

@immutable
@JsonSerializable()
class SavedEntry {
  bool get ownsEntry => private || deleteUrl != null;

  final String guid;
  final String title;
  final String description;
  final String imagePath;
  final double longitude;
  final double latitude;
  final DateTime createDate;
  final String? deleteUrl;
  final bool? uploaded;
  final bool private;
  final WarningLevel warningLevel;
  final List<String>? categories;

  const SavedEntry(
      this.guid, this.title, this.description, this.imagePath, this.longitude, this.latitude, this.createDate,
      {this.warningLevel = WarningLevel.warning,
      this.uploaded = false,
      this.deleteUrl = "",
      this.private = false,
      this.categories});

  static String getNewGuid() => const Uuid().v4();

  factory SavedEntry.fromJson(Map<String, dynamic> json) => _$SavedEntryFromJson(json);

  Map<String, dynamic> toJson() => _$SavedEntryToJson(this);

  factory SavedEntry.fromApiJson(Map<String, dynamic> json) => SavedEntry(
        json['id'] as String,
        json['title'] as String,
        (json['description'] as String?) ?? "",
        (json['image_path'] as String?) ?? "",
        (json['longitude'] as num).toDouble(),
        (json['latitude'] as num).toDouble(),
        DateTime.parse(json['create_date'] as String),
        categories: (json['categories'] as List).map((e) => e.toString()).toList(),
        warningLevel: $enumDecode(_$WarningLevelEnumMap, json['warning_level']),
        uploaded: json['uploaded'] as bool?,
        deleteUrl: json.containsKey('image_delete_url') ? json['image_delete_url'] as String? : null,
      );

  Map<String, dynamic> toApiJson() {
    return {
      'id': guid,
      'title': title,
      'description': description,
      'image_path': imagePath.startsWith("http") ? imagePath : null,
      'image_delete_url': deleteUrl,
      'longitude': longitude,
      'latitude': latitude,
      'categories': categories,
      'create_date': createDate.toIso8601String(),
      'warning_level': _$WarningLevelEnumMap[warningLevel]!
    };
  }

  SavedEntry copyWith(
      {String? guid,
      String? title,
      String? description,
      String? imagePath,
      double? longitude,
      double? latitude,
      DateTime? createDate,
      List<String>? categories,
      WarningLevel? warningLevel,
      String? deleteUrl,
      bool? uploaded,
      bool? private}) {
    return SavedEntry(
        guid ?? this.guid,
        title ?? this.title,
        description ?? this.description,
        imagePath ?? this.imagePath,
        longitude ?? this.longitude,
        latitude ?? this.latitude,
        createDate ?? this.createDate,
        categories: categories ?? this.categories,
        warningLevel: warningLevel ?? this.warningLevel,
        uploaded: uploaded ?? this.uploaded,
        deleteUrl: deleteUrl ?? this.deleteUrl,
        private: private ?? this.private);
  }

  @override
  bool operator ==(final Object other) =>
      other is SavedEntry &&
      guid == other.guid &&
      title == other.title &&
      description == other.description &&
      imagePath == other.imagePath &&
      longitude == other.longitude &&
      latitude == other.latitude &&
      warningLevel == other.warningLevel &&
      private == other.private &&
      deleteUrl == other.deleteUrl &&
      uploaded == other.uploaded &&
      const ListEquality().equals(categories, other.categories);

  @override
  int get hashCode => Object.hash(
      guid, title, description, imagePath, longitude, latitude, categories, uploaded, deleteUrl, private, warningLevel);
}
