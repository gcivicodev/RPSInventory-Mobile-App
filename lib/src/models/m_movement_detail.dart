class MovementDetail {
  final int? id;
  final DateTime? createdAt;
  final String? productName;
  final String? sku;
  final String? barcodeNumber;
  final String? size;
  final String? color;
  final String? model;
  final double? productQuantityMoved;
  final String? username;
  final String? warehouseOriginName;
  final String? warehouseOriginType;
  final double? warehouseOriginProductQuantityBeforeMovement;
  final double? warehouseOriginProductQuantityAfterMovement;
  final String? warehouseDestinationName;
  final String? warehouseDestinationType;
  final double? warehouseDestinationProductQuantityBeforeMovement;
  final double? warehouseDestinationProductQuantityAfterMovement;

  MovementDetail({
    this.id,
    this.createdAt,
    this.productName,
    this.sku,
    this.barcodeNumber,
    this.size,
    this.color,
    this.model,
    this.productQuantityMoved,
    this.username,
    this.warehouseOriginName,
    this.warehouseOriginType,
    this.warehouseOriginProductQuantityBeforeMovement,
    this.warehouseOriginProductQuantityAfterMovement,
    this.warehouseDestinationName,
    this.warehouseDestinationType,
    this.warehouseDestinationProductQuantityBeforeMovement,
    this.warehouseDestinationProductQuantityAfterMovement,
  });

  factory MovementDetail.fromMap(Map<String, dynamic> map) {
    DateTime? parsedCreatedAt;
    final rawCreatedAt = map['created_at'];
    if (rawCreatedAt is String && rawCreatedAt.isNotEmpty) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt);
    } else if (rawCreatedAt is DateTime) {
      parsedCreatedAt = rawCreatedAt;
    }

    return MovementDetail(
      id: map['id'],
      createdAt: parsedCreatedAt,
      productName: map['product_name'],
      sku: map['sku'],
      barcodeNumber: map['barcode_number'],
      size: map['size'],
      color: map['color'],
      model: map['model'],
      productQuantityMoved: (map['product_quantity_moved'] as num?)?.toDouble(),
      username: map['username'],
      warehouseOriginName: map['warehouse_origin_name'],
      warehouseOriginType: map['warehouse_origin_type'],
      warehouseOriginProductQuantityBeforeMovement:
      (map['warehouse_origin_product_quantity_before_movement'] as num?)
          ?.toDouble(),
      warehouseOriginProductQuantityAfterMovement:
      (map['warehouse_origin_product_quantity_after_movement'] as num?)
          ?.toDouble(),
      warehouseDestinationName: map['warehouse_destination_name'],
      warehouseDestinationType: map['warehouse_destination_type'],
      warehouseDestinationProductQuantityBeforeMovement:
      (map['warehouse_destination_product_quantity_before_movement']
      as num?)
          ?.toDouble(),
      warehouseDestinationProductQuantityAfterMovement:
      (map['warehouse_destination_product_quantity_after_movement']
      as num?)
          ?.toDouble(),
    );
  }
}
