import 'dart:convert';

// Funciones auxiliares para parseo seguro
int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is String) return double.tryParse(value);
  if (value is int) return value.toDouble();
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

List<WarehouseProduct> warehouseProductsFromJson(String str) => List<WarehouseProduct>.from(json.decode(str).map((x) => WarehouseProduct.fromJson(x)));
String warehouseProductToJson(WarehouseProduct data) => json.encode(data.toMap());

class WarehouseProduct {
  final int id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? warehouseId;
  final int? productId;
  final double? beforeLastMovementQuantity;
  final double? currentQuantity;

  WarehouseProduct({
    required this.id,
    this.createdAt,
    this.updatedAt,
    this.warehouseId,
    this.productId,
    this.beforeLastMovementQuantity,
    this.currentQuantity,
  });

  factory WarehouseProduct.fromJson(Map<String, dynamic> json) => WarehouseProduct(
    id: json["id"],
    createdAt: _parseDate(json["created_at"]),
    updatedAt: _parseDate(json["updated_at"]),
    warehouseId: _parseInt(json["warehouse_id"]),
    productId: _parseInt(json["product_id"]),
    beforeLastMovementQuantity: _parseDouble(json["before_last_movement_quantity"]),
    currentQuantity: _parseDouble(json["current_quantity"]),
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "warehouse_id": warehouseId,
    "product_id": productId,
    "before_last_movement_quantity": beforeLastMovementQuantity,
    "current_quantity": currentQuantity,
  };
}
