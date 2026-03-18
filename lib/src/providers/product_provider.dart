import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/models/m_product.dart';

final dbHelperProvider = Provider<DBHelper>((ref) => DBHelper.instance);

/// --- NUEVO: Clase para pasar parámetros al provider ---
/// Usamos esta clase para encapsular los IDs necesarios.
class ProductProviderParams {
  final int productId;
  final int conduceId;

  ProductProviderParams({required this.productId, required this.conduceId});

  // Sobrescribir `==` y `hashCode` es crucial para que Riverpod
  // pueda cachear y diferenciar correctamente las instancias del provider.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ProductProviderParams &&
              runtimeType == other.runtimeType &&
              productId == other.productId &&
              conduceId == other.conduceId;

  @override
  int get hashCode => productId.hashCode ^ conduceId.hashCode;
}

/// --- MODIFICADO: El provider ahora usa ProductProviderParams ---
final productProvider =
FutureProvider.autoDispose.family<Product, ProductProviderParams>(
        (ref, params) async {
      final dbHelper = ref.watch(dbHelperProvider);
      // Llamamos a getProduct con ambos parámetros.
      return dbHelper.getProduct(params.productId, params.conduceId);
    });

final productByBarcodeNumberProvider =
FutureProvider.autoDispose.family<Product?, String>((ref, barcode) async {
  if (barcode.isEmpty) {
    return null;
  }
  final dbHelper = ref.watch(dbHelperProvider);
  return await dbHelper.getProductByBarcodeNumber(barcode);
});

class ProductByBarcodeParams {
  final String barcode;
  final int warehouseId;

  ProductByBarcodeParams({required this.barcode, required this.warehouseId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ProductByBarcodeParams &&
              runtimeType == other.runtimeType &&
              barcode == other.barcode &&
              warehouseId == other.warehouseId;

  @override
  int get hashCode => barcode.hashCode ^ warehouseId.hashCode;
}

final productByBarcodeNumberAndWarehouseProvider =
FutureProvider.autoDispose.family<Product?, ProductByBarcodeParams>(
        (ref, params) async {
      if (params.barcode.isEmpty) {
        return null;
      }
      final dbHelper = ref.watch(dbHelperProvider);
      return await dbHelper.getProductByBarcodeNumberAndWarehouse(
          params.barcode, params.warehouseId);
    });
