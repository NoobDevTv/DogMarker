import 'dart:convert';
import 'dart:io';

import 'package:dog_marker/saved_entry.dart';
import 'package:dog_marker/saved_entry_manager.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'package:html/parser.dart';

part 'vgyme_uploader.g.dart';

class VgyMeUploader {
  static Future uploadEntry(SavedEntry entry, SavedEntryManager manager) async {
    var url = Uri.https('vgy.me', 'upload');

    final stream = http.MultipartRequest("POST", url);
    stream.fields["userkey"] = "HPDcHqGo06n2KHMHxyFCses7AVpyCouW";
    stream.files.add(await http.MultipartFile.fromPath("file", entry.imagePath));
    final res = await stream.send();
    final bres = await res.stream.bytesToString();
    final data = VgyMeUploadData.fromJson(jsonDecode(bres));
    entry.deleteUrl = data.delete;
    entry.imagePath = data.image;
    entry.uploaded = true;
    manager.updateEntry(entry);
  }

  static String _parseCookies(List<String> setCookies) {
    String retValue = "";
    for (var element in setCookies) {
      final cookie = Cookie.fromSetCookieValue(element);
      retValue += "${cookie.name}=${cookie.value};";
    }
    return retValue.substring(0, retValue.length - 1);
  }

  static Future<bool> deleteEntry(SavedEntry entry) async {
    if (entry.deleteUrl == null) return true;
    try {
      final uri = Uri.parse(entry.deleteUrl!);
      final getRes = await http.get(uri);
      final html = parse(getRes.body);
      final tokenElement =
          html.getElementsByTagName("input").firstWhere((element) => element.attributes["name"] == "_token");
      final splitValues = getRes.headersSplitValues["set-cookie"];

      final res = await http.post(uri,
          headers: {"Cookie": _parseCookies(splitValues!)},
          body: {"confirm_delete": "1", tokenElement.attributes["name"]: tokenElement.attributes["value"]});
      if (res.statusCode == 302 || res.statusCode == 200) return true;
    } catch (e) {
      print(e);
    }

    return false;
  }
}

@JsonSerializable()
class VgyMeUploadData {
  bool error;
  String image;
  String delete;

  VgyMeUploadData(this.error, this.image, this.delete);

  factory VgyMeUploadData.fromJson(Map<String, dynamic> json) => _$VgyMeUploadDataFromJson(json);

  Map<String, dynamic> toJson() => _$VgyMeUploadDataToJson(this);
}
