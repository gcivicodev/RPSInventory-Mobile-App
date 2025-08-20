import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/models/m_product.dart';

final dbHelperProvider = Provider<DBHelper>((ref) => DBHelper.instance);

final productsProvider = FutureProvider.autoDispose.family<List<Product>, String>((ref, hcpcCode) async {
  final dbHelper = ref.watch(dbHelperProvider);
  return dbHelper.getProducts(hcpcCode: hcpcCode);
});




class ProductsByWarehouseParams {
  final int warehouseId;
  final String? barcode;
  final String? hcpcCode;

  ProductsByWarehouseParams({
    required this.warehouseId,
    this.barcode,
    this.hcpcCode,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ProductsByWarehouseParams &&
              runtimeType == other.runtimeType &&
              warehouseId == other.warehouseId &&
              barcode == other.barcode &&
              hcpcCode == other.hcpcCode;

  @override
  int get hashCode =>
      warehouseId.hashCode ^
      barcode.hashCode ^
      hcpcCode.hashCode;
}




final getProductsByWarehouseProvider = FutureProvider.autoDispose.family<List<Product>, ProductsByWarehouseParams>((ref, params) async {
  final dbHelper = ref.watch(dbHelperProvider);

  return dbHelper.getProductsByWarehouse(
    warehouseId: params.warehouseId,
    productBarcodeNumber: params.barcode,
    hcpcCode: params.hcpcCode,
  );
});


final allProductsProvider = FutureProvider<List<Product>>((ref) async {
  final dbHelper = DBHelper.instance;
  return dbHelper.getAllProducts();
});