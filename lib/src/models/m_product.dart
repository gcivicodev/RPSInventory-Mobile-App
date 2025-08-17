import 'dart:convert';

List<Product> productsFromJson(String str) => List<Product>.from(json.decode(str).map((x) => Product.fromJson(x)));

class Product {
  final int id;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final String? itemNumber;
  final String? sku;
  final String? tagNumber;
  final int? categoryId;
  final String? category;
  final String? name;
  final String? description;
  final String? size;
  final String? color;
  final String? model;
  final String? extra;
  final String? barcodeNumber;
  final String? barcodeImage;
  final String? deductible;
  final String? deductibleType;
  final String? price;
  final int? manufactured;
  final String? hcpcCode;
  final String? hcpcShortDescription;
  final String? deductibles;
  final double? currentQuantity;
  final String? pdeductible;
  final String? pdeductibleType;

  Product({
    required this.id,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.itemNumber,
    this.sku,
    this.tagNumber,
    this.categoryId,
    this.category,
    this.name,
    this.description,
    this.size,
    this.color,
    this.model,
    this.extra,
    this.barcodeNumber,
    this.barcodeImage,
    this.deductible,
    this.deductibleType,
    this.price,
    this.manufactured,
    this.hcpcCode,
    this.hcpcShortDescription,
    this.deductibles,
    this.currentQuantity,
    this.pdeductible,
    this.pdeductibleType,
  });

  /// Helper function to safely parse a value to an integer.
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Factory for creating from the API's JSON
  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json["id"], // Assuming 'id' is always a valid integer from the API
    createdAt: json["created_at"],
    updatedAt: json["updated_at"],
    deletedAt: json["deleted_at"],
    itemNumber: json["item_number"],
    sku: json["sku"],
    tagNumber: json["tag_number"],
    categoryId: _parseInt(json["category_id"]),
    category: json["category"],
    name: json["name"],
    description: json["description"],
    size: json["size"],
    color: json["color"],
    model: json["model"],
    extra: json["extra"],
    barcodeNumber: json["barcode_number"],
    barcodeImage: json["barcode_image"],
    deductible: json["deductible"],
    deductibleType: json["deductible_type"],
    price: json["price"],
    manufactured: _parseInt(json["manufactured"]), // Safely parsing the value
    hcpcCode: json["hcpc_code"],
    hcpcShortDescription: json["hcpc_short_description"],
    deductibles: jsonEncode(json["deductibles"]),
  );

  // Method to convert to a Map for the DB
  Map<String, dynamic> toMap() => {
    "id": id,
    "created_at": createdAt,
    "updated_at": updatedAt,
    "deleted_at": deletedAt,
    "item_number": itemNumber,
    "sku": sku,
    "tag_number": tagNumber,
    "category_id": categoryId,
    "category": category,
    "name": name,
    "description": description,
    "size": size,
    "color": color,
    "model": model,
    "extra": extra,
    "barcode_number": barcodeNumber,
    "barcode_image": barcodeImage,
    "deductible": deductible,
    "deductible_type": deductibleType,
    "price": price,
    "manufactured": manufactured,
    "hcpc_code": hcpcCode,
    "hcpc_short_description": hcpcShortDescription,
  };

  // Factory for creating from a DB Map
  factory Product.fromMap(Map<String, dynamic> map) => Product(
    id: map["id"],
    createdAt: map["created_at"],
    updatedAt: map["updated_at"],
    deletedAt: map["deleted_at"],
    itemNumber: map["item_number"],
    sku: map["sku"],
    tagNumber: map["tag_number"],
    categoryId: map["category_id"],
    category: map["category"],
    name: map["name"],
    description: map["description"],
    size: map["size"],
    color: map["color"],
    model: map["model"],
    extra: map["extra"],
    barcodeNumber: map["barcode_number"],
    barcodeImage: map["barcode_image"],
    deductible: map["deductible"],
    deductibleType: map["deductible_type"],
    price: map["price"],
    manufactured: map["manufactured"],
    hcpcCode: map["hcpc_code"],
    hcpcShortDescription: map["hcpc_short_description"],
    currentQuantity: map["current_quantity"],
    pdeductible: map['pdeductible']?.toString(), // Added pdeductible
    pdeductibleType: map['pdeductible_type'], // Added pdeductible_type
  );
}
