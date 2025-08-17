// To parse this JSON data, do
//
//     final movement = movementFromJson(jsonString);

import 'dart:convert';
import 'dart:typed_data';

List<Movement> movementsFromJson(String str) => List<Movement>.from(json.decode(str).map((x) => Movement.fromJson(x)));

String movementsToJson(List<Movement> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

Movement movementFromJson(String str) => Movement.fromJson(json.decode(str));

String movementToJson(Movement data) => json.encode(data.toJson());

class Movement {
  int? id;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;
  int? userId;
  String? username;
  int? warehouse_origin_id;
  String? warehouse_origin;
  int? warehouse_destination_id;
  String? warehouse_destination;
  int? product_id;
  String? product;
  double? product_quantity_moved;
  int? localId;
  String? error;

  Movement({
    this.id,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.userId,
    this.username,
    this.warehouse_origin_id,
    this.warehouse_origin,
    this.warehouse_destination_id,
    this.warehouse_destination,
    this.product_id,
    this.product,
    this.product_quantity_moved,
    this.localId,
    this.error,
  });

  factory Movement.fromJson(Map<String, dynamic> json) => Movement(
    id: json["id"] is int ? json["id"] : int.tryParse(json["id"] ?? '0'),
    createdAt: json["created_at"] == null ? null : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? null : DateTime.parse(json["updated_at"]),
    deletedAt: json["deleted_at"] == null ? null : DateTime.parse(json["deleted_at"]),
    userId: json["user_id"] is int ? json["user_id"] : int.tryParse(json["user_id"] ?? '0'),
    username: json["username"],
    warehouse_origin_id: json["warehouse_origin_id"] is int ? json["warehouse_origin_id"] : int.tryParse(json["warehouse_origin_id"] ?? '0'),
    warehouse_origin: json["warehouse_origin"],
    warehouse_destination_id: json["warehouse_destination_id"] is int ? json["warehouse_destination_id"] : int.tryParse(json["warehouse_destination_id"] ?? '0'),
    warehouse_destination: json["warehouse_destination"],
    product_id: json["product_id"] is int ? json["product_id"] : int.tryParse(json["product_id"] ?? '0'),
    product: json["product"],
    product_quantity_moved: json["product_quantity_moved"] is double ? json["product_quantity_moved"] : double.tryParse(json["product_quantity_moved"] ?? '0.0'),
    localId: json["local_id"] is int ? json["local_id"] : int.tryParse(json["local_id"] ?? '0'),
    error: json["error"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "deleted_at": deletedAt?.toIso8601String(),
    "user_id": userId,
    "username": username,
    "warehouse_origin_id": warehouse_origin_id,
    "warehouse_origin": warehouse_origin,
    "warehouse_destination_id": warehouse_destination_id,
    "warehouse_destination": warehouse_destination,
    "product_id": product_id,
    "product": product,
    "product_quantity_moved": product_quantity_moved,
    "local_id": localId,
    "error": error,
  };
}
