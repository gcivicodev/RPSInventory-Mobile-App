import 'dart:convert';

// Helper functions for safe parsing
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
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

List<ConduceDetail> conducesDetailFromJson(String str) => List<ConduceDetail>.from(json.decode(str).map((x) => ConduceDetail.fromJson(x)));
String conducesDetailToJson(List<ConduceDetail> data) => json.encode(List<dynamic>.from(data.map((x) => x.toMap())));

class ConduceDetail {
  final int id;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final int? conduceId;
  final int? userId;
  final String? username;
  final int? productId;
  final int? productCategoryId;
  final String? productName;
  final String? productItemNumber;
  final String? productBarcodeNumber;
  final String? productSku;
  final double? productQuantity;
  final String? productDeductible;
  final String? productDeductibleType;
  final String? productDeductibleTotal;
  final int? productManufactured;
  final String? amountPaid;
  final String? productExtra;
  final int? movementId;
  final String? tagNumber;
  final String? productHcpcCode;
  final String? productHcpcShortDescription;
  final String? productSize;
  final String? productModel;
  final String? productColor;
  // Se añade la nueva propiedad warehouseId.
  final int? warehouseId;

  ConduceDetail({
    required this.id,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.conduceId,
    this.userId,
    this.username,
    this.productId,
    this.productCategoryId,
    this.productName,
    this.productItemNumber,
    this.productBarcodeNumber,
    this.productSku,
    this.productQuantity,
    this.productDeductible,
    this.productDeductibleType,
    this.productDeductibleTotal,
    this.productManufactured,
    this.amountPaid,
    this.productExtra,
    this.movementId,
    this.tagNumber,
    this.productHcpcCode,
    this.productHcpcShortDescription,
    this.productSize,
    this.productModel,
    this.productColor,
    // Se añade al constructor.
    this.warehouseId,
  });

  factory ConduceDetail.fromJson(Map<String, dynamic> json) => ConduceDetail(
    id: json["id"],
    createdAt: _parseDate(json["created_at"]),
    updatedAt: _parseDate(json["updated_at"]),
    deletedAt: _parseDate(json["deleted_at"]),
    conduceId: _parseInt(json["conduce_id"]),
    userId: _parseInt(json["user_id"]),
    username: json["username"],
    productId: _parseInt(json["product_id"]),
    productCategoryId: _parseInt(json["product_category_id"]),
    productName: json["product_name"],
    productItemNumber: json["product_item_number"],
    productBarcodeNumber: json["product_barcode_number"],
    productSku: json["product_sku"],
    productQuantity: _parseDouble(json["product_quantity"]),
    productDeductible: json["product_deductible"],
    productDeductibleType: json["product_deductible_type"],
    productDeductibleTotal: json["product_deductible_total"],
    productManufactured: _parseInt(json["product_manufactured"]),
    amountPaid: json["amount_paid"],
    productExtra: json["product_extra"],
    movementId: _parseInt(json["movement_id"]),
    tagNumber: json["tag_number"],
    productHcpcCode: json["product_hcpc_code"],
    productHcpcShortDescription: json["product_hcpc_short_description"],
    productSize: json["product_size"],
    productModel: json["product_model"],
    productColor: json["product_color"],
    // Se parsea desde el JSON.
    warehouseId: _parseInt(json["warehouse_id"]),
  );

  Map<String, dynamic> toMap() => {
    "id": id,
    "created_at": createdAt?.toIso8601String(),
    "updated_at": updatedAt?.toIso8601String(),
    "deleted_at": deletedAt?.toIso8601String(),
    "conduce_id": conduceId,
    "user_id": userId,
    "username": username,
    "product_id": productId,
    "product_category_id": productCategoryId,
    "product_name": productName,
    "product_item_number": productItemNumber,
    "product_barcode_number": productBarcodeNumber,
    "product_sku": productSku,
    "product_quantity": productQuantity,
    "product_deductible": productDeductible,
    "product_deductible_type": productDeductibleType,
    "product_deductible_total": productDeductibleTotal,
    "product_manufactured": productManufactured,
    "amount_paid": amountPaid,
    "product_extra": productExtra,
    "movement_id": movementId,
    "tag_number": tagNumber,
    "product_hcpc_code": productHcpcCode,
    "product_hcpc_short_description": productHcpcShortDescription,
    "product_size": productSize,
    "product_model": productModel,
    "product_color": productColor,
    // Se añade al mapa para la base de datos.
    "warehouse_id": warehouseId,
  };
}
