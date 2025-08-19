class MovementDetail {
  final int id;
  final String? productName;
  final double? productQuantityMoved;
  final String? username;
  final String? warehouseOriginName;
  final double? warehouseOriginProductQuantityBeforeMovement;
  final double? warehouseOriginProductQuantityAfterMovement;
  final String? warehouseDestinationName;
  final double? warehouseDestinationProductQuantityBeforeMovement;
  final double? warehouseDestinationProductQuantityAfterMovement;
  final String? sku;
  final String? barcodeNumber;
  final String? size;
  final String? color;
  final String? model;

  MovementDetail({
    required this.id,
    this.productName,
    this.productQuantityMoved,
    this.username,
    this.warehouseOriginName,
    this.warehouseOriginProductQuantityBeforeMovement,
    this.warehouseOriginProductQuantityAfterMovement,
    this.warehouseDestinationName,
    this.warehouseDestinationProductQuantityBeforeMovement,
    this.warehouseDestinationProductQuantityAfterMovement,
    this.sku,
    this.barcodeNumber,
    this.size,
    this.color,
    this.model,
  });

  factory MovementDetail.fromMap(Map<String, dynamic> map) {
    return MovementDetail(
      id: map['id'],
      productName: map['product_name'],
      productQuantityMoved: map['product_quantity_moved'],
      username: map['username'],
      warehouseOriginName: map['warehouse_origin_name'],
      warehouseOriginProductQuantityBeforeMovement: map['warehouse_origin_product_quantity_before_movement'],
      warehouseOriginProductQuantityAfterMovement: map['warehouse_origin_product_quantity_after_movement'],
      warehouseDestinationName: map['warehouse_destination_name'],
      warehouseDestinationProductQuantityBeforeMovement: map['warehouse_destination_product_quantity_before_movement'],
      warehouseDestinationProductQuantityAfterMovement: map['warehouse_destination_product_quantity_after_movement'],
      sku: map['sku'],
      barcodeNumber: map['barcode_number'],
      size: map['size'],
      color: map['color'],
      model: map['model'],
    );
  }
}
