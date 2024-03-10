import 'dart:convert';

import 'package:dog_marker/saved_entry.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class Api {
  static String url = "dog.susch.eu";
  static String basePath = "/v1/";

  static Future<dynamic> _request<T>(String path, T Function(dynamic) decodeFunc, T defaultRet,
      {Map<String, dynamic>? queryParameters}) async {
    final requestUrl = Uri.https(url, basePath + path, queryParameters);
    final res = await http.get(requestUrl);

    if (res.statusCode < 300 && res.statusCode > 199) {
      if (res.body.isEmpty) return decodeFunc(res.body);
      return decodeFunc(jsonDecode(res.body));
    }

    print(res.statusCode);
    print(res.reasonPhrase);
    print(res.body);

    return defaultRet;
  }

  static Future<dynamic> _requestWithBody<T>(
      Future<http.Response> Function(Uri, {Map<String, String>? headers, Object? body, Encoding? encoding}) httpFunc,
      String path,
      T Function(dynamic) decodeFunc,
      T defaultRet,
      {Map<String, dynamic>? queryParameters,
      Object? body}) async {
    final requestUrl = Uri.https(url, basePath + path, queryParameters);
    final res = await httpFunc(requestUrl, headers: {"Content-Type": "application/json"}, body: body);

    if (res.statusCode < 300 && res.statusCode > 199) {
      if (res.body.isEmpty) return decodeFunc(res.body);
      return decodeFunc(jsonDecode(res.body));
    }

    print(res.statusCode);
    print(res.reasonPhrase);
    print(res.body);

    return defaultRet;
  }

  static Future<List<SavedEntry>> getAllEntries({String? userId, int? skip, int? limit, LatLng? latLng}) async {
    Map<String, dynamic> queryParameters = {};
    if (userId != null) queryParameters["user_id"] = userId;
    if (skip != null) queryParameters["skip"] = skip;
    if (limit != null) queryParameters["limit"] = limit;
    if (latLng != null) {
      queryParameters["longitude"] = latLng.longitude;
      queryParameters["latitude"] = latLng.latitude;
    }

    return await _request<List<SavedEntry>>("entries", (t) {
      final jsonRes = t as List<Map<String, dynamic>>;
      return jsonRes.map((e) => SavedEntry.fromJson(e)).toList();
    }, [], queryParameters: queryParameters);
  }

  static Future<SavedEntry?> getEntryById(String entryId) async {
    return await _request<SavedEntry?>("entries/$entryId", (t) => SavedEntry.fromJson(t), null);
  }

  static Future<List<SavedEntry>> getUserEntries(String userId) async {
    return await _request<List<SavedEntry>>("user/$userId/entries}", (t) {
      final jsonRes = t as List<Map<String, dynamic>>;
      return jsonRes.map((e) => SavedEntry.fromJson(e)).toList();
    }, []);
  }

  static Future<bool> addNewEntry(String userId, SavedEntry entry) async {
    return await _requestWithBody<bool>(http.post, "user/$userId/entries", (_) => true, false,
        body: jsonEncode(entry.toApiJson()));
  }

  static Future<bool> updateEntry(String userId, SavedEntry entry) async {
    return await _requestWithBody<bool>(http.put, "user/$userId/entries/${entry.guid}", (_) => true, false,
        body: jsonEncode(entry.toApiJson()));
  }

  static Future<bool> deleteEntry(String userId, String entryId) async {
    return await _requestWithBody<bool>(http.delete, "user/$userId/entries/$entryId", (_) => true, false);
  }
}
