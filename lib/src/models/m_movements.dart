import 'dart:convert';

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

List<Movement> movementsFromJson(String str) => List<Movement>.from(json.decode(str).map((x) => Movement.fromJson(x)));
String movementToJson(Movement data) => json.encode(data.toMap());

class Movement {
  final int id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final int? userId;
  final int? warehouseOriginId;
  final int? productId;
  final double? warehouseOriginProductQuantityBeforeMovement;
  final double? productQuantityMoved;
  final double? warehouseOriginProductQuantityAfterMovement;
  final int? warehouseDestinationId;
  final double? warehouseDestinationProductQuantityBeforeMovement;
  final double? warehouseDestinationProductQuantityAfterMovement;
  final String? username;
  final int? localId;

  Movement({
    required this.id,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.userId,
    this.warehouseOriginId,
    this.productId,
    this.warehouseOriginProductQuantityBeforeMovement,
    this.productQuantityMoved,
    this.warehouseOriginProductQuantityAfterMovement,
    this.warehouseDestinationId,
    this.warehouseDestinationProductQuantityBeforeMovement,
    this.warehouseDestinationProductQuantityAfterMovement,
    this.username,
    this.localId,
  });

  factory Movement.fromJson(Map<String, dynamic> json) => Movement(
    id: json["id"],
    createdAt: _parseDate(json["created_at"]),
    updatedAt: _parseDate(json["updated_at"]),
    deletedAt: _parseDate(json["deleted_at"]),
    userId: _parseInt(json["user_id"]),
    warehouseOriginId: _parseInt(json["warehouse_origin_id"]),
    productId: _parseInt(json["product_id"]),
    warehouseOriginProductQuantityBeforeMovement: _parseDouble(json["warehouse_origin_product_quantity_before_movement"]),
    productQuantityMoved: _parseDouble(json["product_quantity_moved"]),
    warehouseOriginProductQuantityAfterMovement: _parseDouble(json["warehouse_origin_product_quantity_after_movement"]),
    warehouseDestinationId: _parseInt(json["warehouse_destination_id"]),
    warehouseDestinationProductQuantityBeforeMovement: _parseDouble(json["warehouse_destination_product_quantity_before_movement"]),
    warehouseDestinationProductQuantityAfterMovement: _parseDouble(json["warehouse_destination_product_quantity_after_movement"]),
    username: json["username"],
    localId: _parseInt(json["local_id"] ?? json["id"]),
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "deleted_at": deletedAt?.toIso8601String(),
    "user_id": userId,
    "warehouse_origin_id": warehouseOriginId,
    "product_id": productId,
    "warehouse_origin_product_quantity_before_movement": warehouseOriginProductQuantityBeforeMovement,
    "product_quantity_moved": productQuantityMoved,
    "warehouse_origin_product_quantity_after_movement": warehouseOriginProductQuantityAfterMovement,
    "warehouse_destination_id": warehouseDestinationId,
    "warehouse_destination_product_quantity_before_movement": warehouseDestinationProductQuantityBeforeMovement,
    "warehouse_destination_product_quantity_after_movement": warehouseDestinationProductQuantityAfterMovement,
    "username": username,
    "local_id": localId,
  };
}
