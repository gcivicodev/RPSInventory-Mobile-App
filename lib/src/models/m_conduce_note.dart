import 'dart:convert';

// Helper functions for safe parsing
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

List<ConduceNote> conducesNoteFromJson(String str) => List<ConduceNote>.from(json.decode(str).map((x) => ConduceNote.fromJson(x)));
String conducesNoteToJson(List<ConduceNote> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class ConduceNote {
  final int id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final int? userId;
  final int? conduceId;
  final String? note;
  final String? username;
  final int? editorUserId;
  final String? editorUsername;

  ConduceNote({
    required this.id,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.userId,
    this.conduceId,
    this.note,
    this.username,
    this.editorUserId,
    this.editorUsername,
  });

  factory ConduceNote.fromJson(Map<String, dynamic> json) => ConduceNote(
    id: json["id"],
    createdAt: _parseDate(json["created_at"]),
    updatedAt: _parseDate(json["updated_at"]),
    deletedAt: _parseDate(json["deleted_at"]),
    userId: _parseInt(json["user_id"]),
    conduceId: _parseInt(json["conduce_id"]),
    note: json["note"],
    username: json["username"],
    editorUserId: _parseInt(json["editor_user_id"]),
    editorUsername: json["editor_username"],
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "deleted_at": deletedAt?.toIso8601String(),
    "user_id": userId,
    "conduce_id": conduceId,
    "note": note,
    "username": username,
    "editor_user_id": editorUserId,
    "editor_username": editorUsername,
  };
}
