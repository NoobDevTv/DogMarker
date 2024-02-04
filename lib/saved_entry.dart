import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'saved_entry.g.dart';

@JsonSerializable()
class SavedEntry {
  late String guid;
  String title;
  String description;
  String imagePath;
  double longitute;
  double latitute;
  DateTime createDate;

  SavedEntry(this.title, this.description, this.imagePath, this.longitute, this.latitute, this.createDate) {
    guid = const Uuid().v4();
  }

  factory SavedEntry.fromJson(Map<String, dynamic> json) => _$SavedEntryFromJson(json);

  Map<String, dynamic> toJson() => _$SavedEntryToJson(this);
}
