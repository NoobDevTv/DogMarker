import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'saved_entry.g.dart';

@immutable
@JsonSerializable()
class SavedEntry {
  final String guid;
  final String title;
  final String description;
  final String imagePath;
  final double longitude;
  final double latitude;
  final DateTime createDate;
  final String? deleteUrl;
  final bool? uploaded;

  const SavedEntry(
      this.guid, this.title, this.description, this.imagePath, this.longitude, this.latitude, this.createDate,
      [this.uploaded = false, this.deleteUrl = ""]);

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
        json['uploaded'] as bool?,
        json.containsKey('image_delete_url') ? json['image_delete_url'] as String? : null,
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
      'create_date': createDate.toIso8601String()
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
      String? deleteUrl,
      bool? uploaded}) {
    return SavedEntry(
        guid ?? this.guid,
        title ?? this.title,
        description ?? this.description,
        imagePath ?? this.imagePath,
        longitude ?? this.longitude,
        latitude ?? this.latitude,
        createDate ?? this.createDate,
        uploaded ?? this.uploaded,
        deleteUrl ?? this.deleteUrl);
  }

  @override
  bool operator ==(final Object other) =>
      other is SavedEntry &&
      guid == other.guid &&
      title == other.title &&
      description == other.description &&
      imagePath == other.imagePath &&
      longitude == other.longitude &&
      latitude == other.latitude;

  @override
  int get hashCode => Object.hash(guid, title, description, imagePath, longitude, latitude);
}
