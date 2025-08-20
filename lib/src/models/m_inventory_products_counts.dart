import 'dart:convert';

import 'package:rpsinventory/src/models/m_product.dart';
import 'package:rpsinventory/src/models/m_warehouse.dart';

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

List<InventoryProductsCount> inventoryProductsCountsFromJson(String str) =>
    List<InventoryProductsCount>.from(
        json.decode(str).map((x) => InventoryProductsCount.fromJson(x)));
String inventoryProductsCountToJson(InventoryProductsCount data) =>
    json.encode(data.toMap());

class InventoryProductsCount {
  final int id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? userId;
  final String? warehouseId;
  final String? productId;
  final String? currentQuantity;
  final String? count;
  final DateTime? start;
  final DateTime? end;
  final int? localId;
  final String? username;
  final Product? product;
  final Warehouse? warehouse;

  InventoryProductsCount({
    required this.id,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.userId,
    this.warehouseId,
    this.productId,
    this.currentQuantity,
    this.count,
    this.start,
    this.end,
    this.localId,
    this.username,
    this.product,
    this.warehouse,
  });

  factory InventoryProductsCount.fromJson(Map<String, dynamic> json) {
    return InventoryProductsCount(
      id: json["id"],
      createdAt: _parseDate(json["created_at"]),
      updatedAt: _parseDate(json["updated_at"]),
      deletedAt: _parseDate(json["deleted_at"]),
      userId: json["user_id"],
      warehouseId: json["warehouse_id"],
      productId: json["product_id"],
      currentQuantity: json["current_quantity"],
      count: json["count"],
      start: _parseDate(json["start"]),
      end: _parseDate(json["end"]),
      localId: _parseInt(json["local_id"]),
      username: json["username"],
      product:
      json['product'] != null ? Product.fromMap(json['product']) : null,
      warehouse: json['warehouse'] != null
          ? Warehouse.fromJson(json['warehouse'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
    "id": id,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "deleted_at": deletedAt?.toIso8601String(),
    "user_id": userId,
    "warehouse_id": warehouseId,
    "product_id": productId,
    "current_quantity": currentQuantity,
    "count": count,
    "start": start?.toIso8601String(),
    "end": end?.toIso8601String(),
    "local_id": localId,
    "username": username,
  };
}
