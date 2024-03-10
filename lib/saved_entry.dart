import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'saved_entry.g.dart';

@JsonSerializable()
class SavedEntry {
  late String guid;
  String title;
  String description;
  String imagePath;
  double longitude;
  double latitude;
  DateTime createDate;
  String? deleteUrl;
  bool? uploaded = false;

  SavedEntry(this.title, this.description, this.imagePath, this.longitude, this.latitude, this.createDate) {
    guid = const Uuid().v4();
  }

  factory SavedEntry.fromJson(Map<String, dynamic> json) => _$SavedEntryFromJson(json);

  Map<String, dynamic> toJson() => _$SavedEntryToJson(this);

  factory SavedEntry.fromApiJson(Map<String, dynamic> json) => SavedEntry(
        json['title'] as String,
        (json['description'] as String?) ?? "",
        (json['image_path'] as String?) ?? "",
        (json['longitute'] as num).toDouble(),
        (json['latitute'] as num).toDouble(),
        DateTime.parse(json['create_date'] as String),
      )
        ..guid = json['id'] as String
        ..deleteUrl = json.containsKey('image_delete_url') ? json['image_delete_url'] as String? : null
        ..uploaded = json['uploaded'] as bool?;

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
}
