import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rpsinventory/src/db_helper.dart';
import 'package:rpsinventory/src/models/m_product.dart';

/// Provider para manejar la actualización de un `ConduceDetail`.
///
/// Este provider de familia toma los datos necesarios para la actualización
/// y ejecuta la operación en la base de datos a través de `DBHelper`.

// Se actualiza el tipo de la familia para incluir el warehouseId.
final updateConduceDetailProvider = FutureProvider.autoDispose.family<void, ({int originalDetailId, Product product, String tag, int warehouseId})>(
      (ref, data) async {
    final db = DBHelper.instance;

    // Prepara el mapa de datos a actualizar.
    // Se incluyen los campos especificados y una marca de tiempo de actualización.
    final Map<String, dynamic> updatedData = {
      'product_id': data.product.id,
      'product_name': data.product.name,
      'product_item_number': data.product.itemNumber,
      'product_barcode_number': data.product.barcodeNumber,
      'product_sku': data.product.sku,
      'product_color': data.product.color,
      'product_size': data.product.size,
      'product_model': data.product.model,
      'product_manufactured': data.product.manufactured,
      'product_deductible': data.product.pdeductible,
      'product_deductible_type': data.product.pdeductibleType,
      'product_deductible_total': (double.parse(data.product.price!) * data.product.currentQuantity! ?? 0.0) - double.parse(data.product.pdeductible!),
      'tag_number': data.tag,
      // Se añade el warehouse_id al mapa de datos para la actualización.
      'warehouse_id': data.warehouseId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Llama al método del DBHelper para realizar la actualización en la base de datos.
    await db.updateConduceDetail(data.originalDetailId, updatedData);
  },
);
